const express = require('express');
const cors = require('cors');
const authRoutes = require('./routes/authRoutes');

const app = express();

app.use(cors()); 
app.use(express.json());

app.get('/', (req, res) => {
    res.json({ message: 'Chào mừng đến với API Quản lý nhân viên!' });
});

app.use('/api/auth', authRoutes); 

const employeeRoutes = require('./routes/employeeRoutes');
app.use('/api/employee', employeeRoutes);

const hrRoutes = require('./routes/hrRoutes');
app.use('/api/hr', hrRoutes);

const adminRoutes = require('./routes/adminRoutes');
app.use('/api/admin', adminRoutes);

module.exports = app;