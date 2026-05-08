// src/routes/hrRoutes.js
const express = require('express');
const router = express.Router();
const hrController = require('../controllers/hrController');
const { verifyToken, checkRole } = require('../middlewares/authMiddleware');

router.use(verifyToken);

router.get('/all', checkRole(['HRM']), hrController.getAllEmployees);
router.post('/add', checkRole(['HRM']), hrController.addEmployeeHRM);
router.get('/logs', checkRole(['HRM']), hrController.getAuditLogs);


module.exports = router;