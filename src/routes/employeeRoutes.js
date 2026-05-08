// src/routes/employeeRoutes.js
const express = require('express');
const router = express.Router();
const employeeController = require('../controllers/employeeController');
const { verifyToken } = require('../middlewares/authMiddleware');

// Route này sẽ bị chặn lại bởi verifyToken
router.get('/profile', verifyToken, employeeController.getProfile);

module.exports = router;