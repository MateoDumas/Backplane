const express = require('express');
const jwt = require('jsonwebtoken');
const { Pool } = require('pg');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3001;
const SECRET_KEY = process.env.SECRET_KEY || 'supersecretkey';

// Database Connection
const pool = new Pool({
    connectionString: process.env.DATABASE_URL
});

// Create Table if not exists
pool.query(`
    CREATE TABLE IF NOT EXISTS payments (
        id SERIAL PRIMARY KEY,
        user_id VARCHAR(255) NOT NULL,
        amount DECIMAL(10, 2) NOT NULL,
        currency VARCHAR(3) NOT NULL,
        status VARCHAR(50) NOT NULL,
        transaction_id VARCHAR(255) NOT NULL,
        idempotency_key VARCHAR(255) UNIQUE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
`).then(() => console.log('✅ Payments table ready'))
  .catch(err => console.error('❌ Error creating table', err));

// Chaos Variables
let failureEnabled = false;
let isServiceDown = false;

app.use(express.json());

// Chaos Middleware: Simulated Crash
app.use((req, res, next) => {
    // Permitir acceso al endpoint de control para poder "revivir" el servicio
    if (req.path === '/chaos/crash') return next();

    if (isServiceDown) {
        console.log('💀 Request blocked: Service is in simulated CRASH state');
        return res.status(503).json({ message: 'Service Unavailable (Simulated Crash)' });
    }
    next();
});

// Chaos Middleware for Failures
app.use((req, res, next) => {
    // Skip failure check for the toggle endpoint itself
    if (req.path === '/chaos/failure') return next();

    if (failureEnabled && Math.random() < 0.7) { // 70% chance of failure
        console.log('Simulating random failure (500)...');
        return res.status(500).json({ message: 'CHAOS MONKEY STRIKES! Service crashed randomly.' });
    }
    next();
});

// Chaos Toggle Endpoint
app.post('/chaos/failure', (req, res) => {
    const { enabled } = req.body;
    failureEnabled = enabled;
    res.json({ message: `Failure simulation ${enabled ? 'ENABLED' : 'DISABLED'}` });
});

// Chaos Toggle Endpoint: Crash
app.post('/chaos/crash', (req, res) => {
    const { enabled } = req.body;
    isServiceDown = enabled;
    console.log(`💀 Chaos: Service crash simulation ${enabled ? 'ENABLED' : 'DISABLED'}`);
    res.json({ message: `Service crash simulation ${enabled ? 'ENABLED' : 'DISABLED'}` });
});

// Middleware de autenticación
const authenticateToken = (req, res, next) => {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];

    if (!token) return res.status(401).json({ message: 'No token provided' });

    jwt.verify(token, SECRET_KEY, (err, user) => {
        if (err) return res.status(403).json({ message: 'Invalid or expired token' });
        req.user = user;
        next();
    });
};

app.post('/process', authenticateToken, async (req, res) => {
    const { amount, currency } = req.body;
    const idempotencyKey = req.headers['idempotency-key'];
    const username = req.user.username;

    console.log(`User ${username} processing payment: ${amount} ${currency} (Key: ${idempotencyKey || 'NONE'})`);

    try {
        // Generate Transaction ID
        const transactionId = `txn_${Math.random().toString(36).substr(2, 9)}`;

        // Insert into DB with Idempotency Check
        const result = await pool.query(
            `INSERT INTO payments (user_id, amount, currency, status, transaction_id, idempotency_key)
             VALUES ($1, $2, $3, 'success', $4, $5)
             RETURNING *`,
            [username, amount, currency, transactionId, idempotencyKey]
        );

        res.json({ 
            status: 'success', 
            transactionId: result.rows[0].transaction_id,
            processedBy: username,
            message: 'Payment processed successfully'
        });

    } catch (err) {
        // Handle Unique Constraint Violation (Idempotency)
        if (err.code === '23505' && err.constraint === 'payments_idempotency_key_key') {
            console.log(`♻️ Idempotency hit! Returning cached response for key: ${idempotencyKey}`);
            
            const cached = await pool.query(
                `SELECT * FROM payments WHERE idempotency_key = $1`, 
                [idempotencyKey]
            );

            return res.json({
                status: 'success',
                transactionId: cached.rows[0].transaction_id,
                processedBy: cached.rows[0].user_id,
                message: 'Payment already processed (Idempotent Result)',
                cached: true
            });
        }

        console.error('Database error:', err);
        res.status(500).json({ message: 'Internal Server Error' });
    }
});

// Health Check Endpoint
app.get('/health', (req, res) => {
    res.json({ status: 'Payment Service is UP' });
});

app.listen(PORT, () => {
    console.log(`Payment Service running on port ${PORT}`);
});
