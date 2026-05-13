// src/controllers/authController.js
const jwt = require('jsonwebtoken');
const db = require('../config/db');

const login = async (req, res) => {
    // SỬA Ở ĐÂY: Viết hoa TenDangNhap và MatKhau cho khớp với JSON Body
    const { TenDangNhap, MatKhau } = req.body;

    if (!TenDangNhap || !MatKhau) {
        return res.status(400).json({ message: 'Vui lòng nhập đầy đủ Tên đăng nhập và Mật khẩu' });
    }

    try {
        const result = await db.executeSP('sp_Auth_Login', [
            // Cập nhật lại tên biến ở value
            { name: 'TenDangNhap', type: db.sql.VarChar(50), value: TenDangNhap },
            { name: 'MatKhau', type: db.sql.VarChar(100), value: MatKhau }
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
                token,
                user: {
                    MaNV: record.MaNV,
                    HoTen: record.HoTen,
                    Email: record.Email,
                    MaPhong: record.MaPhong,
                    TenPhongBan: record.TenPhongBan,
                    MaVaiTro: record.MaVaiTro,
                    TenVaiTro: record.TenVaiTro,
                    TenDangNhap: record.TenDangNhap,
                    TrangThaiTaiKhoan: record.TrangThaiTaiKhoan,
                    IsLocked: record.IsLocked
                }
            });
        }

        return res.status(401).json({ message: 'Tên đăng nhập hoặc mật khẩu không đúng, hoặc tài khoản đã bị khóa' });
    } catch (error) {
        console.error('Lỗi đăng nhập:', error);
        return res.status(500).json({ message: 'Lỗi server', error: error.message });
    }
};

const me = async (req, res) => {
    try {
        const result = await db.executeSP('sp_Auth_Me', [
            { name: 'MaNV_Input', type: db.sql.VarChar(10), value: req.user.MaNV }
        ], req.user);

        return res.status(200).json(result[0] || {});
    } catch (error) {
        return res.status(500).json({ message: 'Lỗi lấy thông tin người dùng', error: error.message });
    }
};

const changePassword = async (req, res) => {
    // Hứng dữ liệu từ Body mà bác gửi lên từ ProfilePage
    const { MatKhauCu, MatKhauMoi } = req.body;

    if (!MatKhauCu || !MatKhauMoi) {
        return res.status(400).json({ message: 'Vui lòng nhập đầy đủ mật khẩu cũ và mới' });
    }

    try {
        await db.executeSP('sp_Auth_DoiMatKhau', [
            { name: 'MaNV', type: db.sql.VarChar(10), value: req.user.MaNV },
            { name: 'MatKhauCu', type: db.sql.VarChar(100), value: MatKhauCu },
            { name: 'MatKhauMoi', type: db.sql.VarChar(100), value: MatKhauMoi }
        ], req.user); 

        return res.status(200).json({ message: 'Đổi mật khẩu thành công' });
    } catch (error) {
        return res.status(400).json({ 
            message: error.message || 'Lỗi khi đổi mật khẩu' 
        });
    }
};

module.exports = {
    login,
    me,
    changePassword
};