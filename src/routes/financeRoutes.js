const express = require('express');
const router = express.Router();
const financeController = require('../controllers/financeController');
const { verifyToken, checkRole } = require('../middlewares/authMiddleware');

// Chỉ Role Kế toán (FIN) mới được truy cập
router.get('/salary', verifyToken, checkRole(['FIN']), financeController.getCompanySalary);

module.exports = router;