const express = require('express');
const router = express.Router();
const hrStaffController = require('../controllers/hrStaffController');
const { verifyToken, checkRole } = require('../middlewares/authMiddleware');

// Chỉ cấp quyền cho Nhân viên nhân sự (HR)
router.use(verifyToken, checkRole(['HR']));

router.get('/others', hrStaffController.getOtherEmployees);
router.put('/update/:MaNV', hrStaffController.updateOtherEmployee);

module.exports = router;