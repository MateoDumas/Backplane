const express = require('express');
const jwt = require('jsonwebtoken');
const { Pool } = require('pg');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;
const SECRET_KEY = process.env.SECRET_KEY || 'supersecretkey';

// Chaos Variables
let latencyEnabled = false;

app.use(express.json());

// Chaos Middleware for Latency
app.use(async (req, res, next) => {
    if (latencyEnabled) {
        console.log('Simulating latency (2000ms)...');
        await new Promise(resolve => setTimeout(resolve, 2000));
    }
    next();
});

// Chaos Toggle Endpoint
app.post('/chaos/latency', (req, res) => {
    const { enabled } = req.body;
    latencyEnabled = enabled;
    res.json({ message: `Latency simulation ${enabled ? 'ENABLED' : 'DISABLED'}` });
});

// Initialize PostgreSQL Connection
const pool = new Pool({
    connectionString: process.env.DATABASE_URL || 'postgresql://postgres:postgres@localhost:5432/auth_db',
});

// Initialize Table
const initDB = async (retries = 5) => {
    while (retries > 0) {
        try {
            await pool.query(`
                CREATE TABLE IF NOT EXISTS users (
                    id SERIAL PRIMARY KEY,
                    username VARCHAR(255) UNIQUE NOT NULL,
                    password VARCHAR(255) NOT NULL
                )
            `);
            console.log('Users table initialized');
            
            // Check for admin user
            const res = await pool.query('SELECT * FROM users WHERE username = $1', ['admin']);
            if (res.rows.length === 0) {
                await pool.query('INSERT INTO users (username, password) VALUES ($1, $2)', ['admin', 'password']);
                console.log('Admin user created');
            }
            break; // Success
        } catch (err) {
            console.error(`Error initializing database (retries left: ${retries}):`, err.message);
            retries -= 1;
            if (retries === 0) {
                console.error('Max retries reached. Exiting...');
                // No exitimos el proceso, pero logueamos el fallo final
            }
            // Esperar 5 segundos antes de reintentar
            await new Promise(res => setTimeout(res, 5000));
        }
    }
};

initDB();

// Register Endpoint
app.post('/register', async (req, res) => {
    const { username, password } = req.body;
    if (!username || !password) {
        return res.status(400).json({ message: 'Username and password required' });
    }
    
    try {
        const result = await pool.query(
            'INSERT INTO users (username, password) VALUES ($1, $2) RETURNING id',
            [username, password]
        );
        res.status(201).json({ message: 'User registered successfully', userId: result.rows[0].id });
    } catch (err) {
        if (err.code === '23505') { // Unique violation
            return res.status(400).json({ message: 'User already exists' });
        }
        res.status(500).json({ message: 'Database error', error: err.message });
    }
});

// Login Endpoint
app.post('/login', async (req, res) => {
    const { username, password } = req.body;
    
    try {
        const result = await pool.query('SELECT * FROM users WHERE username = $1 AND password = $2', [username, password]);
        
        if (result.rows.length > 0) {
            const user = result.rows[0];
            const token = jwt.sign({ username: user.username, id: user.id }, SECRET_KEY, { expiresIn: '1h' });
            return res.json({ token });
        }
        res.status(401).json({ message: 'Invalid credentials' });
    } catch (err) {
        res.status(500).json({ message: 'Database error' });
    }
});

// Verify Endpoint
app.get('/verify', (req, res) => {
    const token = req.headers['authorization']?.split(' ')[1];
    if (!token) return res.status(401).json({ message: 'No token provided' });

    jwt.verify(token, SECRET_KEY, (err, decoded) => {
        if (err) return res.status(403).json({ message: 'Invalid token' });
        res.json({ valid: true, user: decoded });
    });
});

// Health Check Endpoint
app.get('/health', (req, res) => {
    res.json({ status: 'Auth Service is UP' });
});

app.listen(PORT, () => {
    console.log(`Auth Service running on port ${PORT}`);
});
