const express = require('express');
const jwt = require('jsonwebtoken');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3002;
const SECRET_KEY = process.env.SECRET_KEY || 'supersecretkey';

app.use(express.json());

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

app.post('/send', authenticateToken, (req, res) => {
    const { to, message } = req.body;
    console.log(`User ${req.user.username} sending notification to ${to}: ${message}`);
    // Mock sending email/sms
    res.json({ 
        status: 'sent',
        sender: req.user.username
    });
});

// Health Check Endpoint
app.get('/health', (req, res) => {
    res.json({ status: 'Notification Service is UP' });
});

app.listen(PORT, () => {
    console.log(`Notification Service running on port ${PORT}`);
});
