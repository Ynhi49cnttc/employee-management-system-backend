const cors = require('cors');
const express = require('express');

const authRoutes = require('./routes/authRoutes');
const employeeRoutes = require('./routes/employeeRoutes');
const hrRoutes = require('./routes/hrRoutes');
const financeRoutes = require('./routes/financeRoutes'); 
const managerRoutes = require('./routes/managerRoutes');
const hrStaffRoutes = require('./routes/hrStaffRoutes'); 

const app = express();

app.use(cors()); 
app.use(express.json()); 

app.get('/', (req, res) => {
    res.send('Chào mừng đến với hệ thống Backend Quản lý Nhân viên!');
});

app.use('/api/auth', authRoutes);
app.use('/api/employee', employeeRoutes);
app.use('/api/hr', hrRoutes);
app.use('/api/finance', financeRoutes); 
app.use('/api/manager', managerRoutes);
app.use('/api/hr-staff', hrStaffRoutes); 

module.exports = app;