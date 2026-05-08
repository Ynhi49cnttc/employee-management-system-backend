// src/routes/adminRoutes.js
const express = require('express');
const router = express.Router();
const adminController = require('../controllers/adminController');
const { verifyToken, checkRole } = require('../middlewares/authMiddleware');

router.use(verifyToken, checkRole(['ADM']));

router.get('/accounts', adminController.getAllAccounts);
router.post('/accounts/create', adminController.createAccount);
router.put('/accounts/status', adminController.toggleAccountStatus);
router.put('/accounts/role', adminController.changeRole);

module.exports = router;