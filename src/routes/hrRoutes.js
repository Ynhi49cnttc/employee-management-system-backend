// src/routes/hrRoutes.js
const express = require('express');
const router = express.Router();
const hrController = require('../controllers/hrController');
const { verifyToken, checkRole } = require('../middlewares/authMiddleware');

// Đăng nhập VÀ phải là HR Manager ('HRM')
router.use(verifyToken, checkRole(['HRM']));

// Quản lý Nhân sự & Nhật ký
router.get('/all', hrController.getAllEmployees);
router.post('/add', hrController.addEmployeeHRM);
router.get('/logs', hrController.getAuditLogs);

// Quản lý Tài khoản & Phân quyền
router.get('/accounts', hrController.getAllAccounts);
router.put('/accounts/status', hrController.toggleAccountStatus);
router.put('/accounts/role', hrController.changeRole);

router.put('/update/:MaNV', hrController.updateEmployeeHRM);
router.delete('/delete/:MaNV', hrController.deleteEmployeeHRM);

module.exports = router;