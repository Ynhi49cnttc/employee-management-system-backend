const express = require('express');
const router = express.Router();
const financeController = require('../controllers/financeController');
const { verifyToken, checkRole } = require('../middlewares/authMiddleware');

// FIN xem bảng lương. HRM cũng được mở để frontend HRM vào trang bảng lương.
router.get('/salary', verifyToken, checkRole(['FIN', 'HRM']), financeController.getCompanySalary);

module.exports = router;
