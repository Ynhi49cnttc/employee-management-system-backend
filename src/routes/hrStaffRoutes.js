const express = require('express');
const router = express.Router();
const hrStaffController = require('../controllers/hrStaffController');
const { verifyToken, checkRole } = require('../middlewares/authMiddleware');

router.use(verifyToken, checkRole(['HR']));

router.get('/others', hrStaffController.getOtherEmployees);
router.post('/add', hrStaffController.addOtherEmployee);
router.put('/update/:MaNV', hrStaffController.updateOtherEmployee);
router.delete('/delete/:MaNV', hrStaffController.deleteOtherEmployee);

module.exports = router;
