// src/controllers/adminController.js
const db = require('../config/db');

// 1. [GET] Xem danh sách tài khoản
const getAllAccounts = async (req, res) => {
    try {
        const result = await db.executeSP('sp_Admin_XemTaiKhoan', [], req.user);
        res.status(200).json(result || []);
    } catch (error) {
        res.status(500).json({ message: 'Lỗi lấy danh sách tài khoản', error: error.message });
    }
};

// 2. [POST] Tạo tài khoản mới (Admin tạo cả Nhân viên + Tài khoản)
const createAccount = async (req, res) => {
    const { MaNV, HoTen, Email, MaPhong, TenDangNhap, MatKhau, MaVaiTro } = req.body;

    if (!MaNV || !HoTen || !MaPhong || !TenDangNhap || !MatKhau || !MaVaiTro) {
        return res.status(400).json({ message: 'Vui lòng nhập đầy đủ các trường bắt buộc' });
    }

    try {
        await db.executeSP('sp_Admin_TaoTaiKhoan', [
            { name: 'MaNV', type: db.sql.VarChar(10), value: MaNV },
            { name: 'HoTen', type: db.sql.NVarChar(100), value: HoTen },
            { name: 'Email', type: db.sql.VarChar(100), value: Email || null },
            { name: 'MaPhong', type: db.sql.VarChar(10), value: MaPhong },
            { name: 'TenDangNhap', type: db.sql.VarChar(50), value: TenDangNhap },
            { name: 'MatKhau', type: db.sql.VarChar(100), value: MatKhau },
            { name: 'MaVaiTro', type: db.sql.VarChar(10), value: MaVaiTro }
        ], req.user);

        res.status(201).json({ message: 'Tạo tài khoản thành công' });
    } catch (error) {
        res.status(500).json({ message: 'Lỗi tạo tài khoản', error: error.message });
    }
};

// 3. [PUT] Khóa / Mở tài khoản
const toggleAccountStatus = async (req, res) => {
    const { TenDangNhap, TrangThai } = req.body; // TrangThai: 1 (Mở) hoặc 0 (Khóa)

    if (!TenDangNhap || TrangThai === undefined) {
        return res.status(400).json({ message: 'Thiếu thông tin Tên đăng nhập hoặc Trạng thái' });
    }

    try {
        await db.executeSP('sp_Admin_DoiTrangThaiTaiKhoan', [
            { name: 'TenDangNhap', type: db.sql.VarChar(50), value: TenDangNhap },
            { name: 'TrangThai', type: db.sql.Bit, value: TrangThai }
        ], req.user);

        res.status(200).json({ message: TrangThai ? 'Đã mở khóa tài khoản' : 'Đã khóa tài khoản' });
    } catch (error) {
        res.status(500).json({ message: 'Lỗi cập nhật trạng thái', error: error.message });
    }
};

// 4. [PUT] Đổi vai trò (Role)
const changeRole = async (req, res) => {
    const { TenDangNhap, MaVaiTroMoi } = req.body;

    if (!TenDangNhap || !MaVaiTroMoi) {
        return res.status(400).json({ message: 'Thiếu thông tin yêu cầu' });
    }

    try {
        await db.executeSP('sp_Admin_DoiVaiTro', [
            { name: 'TenDangNhap', type: db.sql.VarChar(50), value: TenDangNhap },
            { name: 'MaVaiTroMoi', type: db.sql.VarChar(10), value: MaVaiTroMoi }
        ], req.user);

        res.status(200).json({ message: 'Đã đổi vai trò thành công' });
    } catch (error) {
        res.status(500).json({ message: 'Lỗi đổi vai trò', error: error.message });
    }
};

module.exports = { getAllAccounts, createAccount, toggleAccountStatus, changeRole };