const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const path = require('path');
const fs = require('fs');

// 1. ROUTES IMPORT (Dito ilagay ang import)
const authRoutes = require('./routes/authRoutes');
const roomRoutes = require('./routes/roomRoutes');
const tenantRoutes = require('./routes/tenantRoutes');
const reportRoutes = require('./routes/reportRoutes');
const paymentRoutes = require('./routes/paymentRoutes');

const app = express();

// MIDDLEWARES (Dapat mauna ang mga ito bago ang routes)
app.use(cors());
app.use(express.json()); 
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// Uploads setup
const uploadDir = './uploads';
if (!fs.existsSync(uploadDir)) {
    fs.mkdirSync(uploadDir);
}
app.use('/uploads', express.static('uploads'));

// 2. USE ROUTES (Dito ikakabit ang endpoint)
app.use('/api/auth', authRoutes);
app.use('/api/rooms', roomRoutes);
app.use('/api/tenants', tenantRoutes); // <--- DITO NAKAKABIT ANG TENANT LOGIC
app.use('/api/reports', reportRoutes);
app.use('/api/payments', paymentRoutes);

const PORT = 3000;
app.listen(PORT, () => {
    console.log(`=========================================`);
    console.log(`Apartment System V1 Server Running!`);
    console.log(`Port: ${PORT}`);
    console.log(`Tenant Route: http://localhost:${PORT}/api/tenants`); // Debug info
    console.log(`=========================================`);
});