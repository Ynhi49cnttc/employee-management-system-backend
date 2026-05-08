// src/controllers/authController.js
const jwt = require('jsonwebtoken');
const db = require('../config/db');

const login = async (req, res) => {
    const { tenDangNhap, matKhau } = req.body;

    if (!tenDangNhap || !matKhau) {
        return res.status(400).json({ message: 'Vui lòng nhập đầy đủ Tên đăng nhập và Mật khẩu' });
    }

    try {
        const result = await db.executeSP('sp_Auth_Login', [
            { name: 'TenDangNhap', type: db.sql.VarChar(50), value: tenDangNhap },
            { name: 'MatKhau', type: db.sql.VarChar(100), value: matKhau }
        ]);

        const record = result[0];

        if (record && record.Status === 'Success') {
            const payload = {
                MaNV: record.MaNV,
                MaVaiTro: record.MaVaiTro
            };

            const token = jwt.sign(payload, process.env.JWT_SECRET, { expiresIn: '1d' });

            return res.status(200).json({
                message: 'Đăng nhập thành công',
                token: token,
                user: payload
            });
        } else {
            return res.status(401).json({ message: 'Tên đăng nhập hoặc mật khẩu không đúng, hoặc tài khoản đã bị khóa' });
        }
    } catch (error) {
        console.error('Lỗi đăng nhập:', error);
        return res.status(500).json({ message: 'Lỗi server', error: error.message });
    }
};

module.exports = {
    login
};