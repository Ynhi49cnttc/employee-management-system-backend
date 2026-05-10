const express = require('express');
const router = express.Router();
const managerController = require('../controllers/managerController');
const { verifyToken, checkRole } = require('../middlewares/authMiddleware');

// Chỉ Role Trưởng phòng (MAN) mới được truy cập
router.get('/department', verifyToken, checkRole(['MAN']), managerController.getDepartmentEmployees);

module.exports = router;