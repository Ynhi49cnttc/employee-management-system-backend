const express = require('express');
const router = express.Router();
const employeeController = require('../controllers/employeeController');
const { verifyToken } = require('../middlewares/authMiddleware');

router.use(verifyToken);

router.get('/profile', employeeController.getProfile);
router.get('/peers', employeeController.getDepartmentPeers);

module.exports = router;