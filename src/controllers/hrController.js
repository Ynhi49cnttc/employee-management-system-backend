// src/controllers/hrController.js
const db = require('../config/db');

// 1. [GET] Xem tất cả nhân viên
const getAllEmployees = async (req, res) => {
    try {
        const result = await db.executeSP('sp_HRManager_XemTatCaNhanVien', [], req.user);
        res.status(200).json(result || []);
    } catch (error) {
        res.status(500).json({ message: 'Lỗi lấy danh sách nhân viên', error: error.message });
    }
};

// 2. [POST] Thêm nhân viên mới 
const addEmployeeHRM = async (req, res) => {
    const { MaNV, HoTen, NgaySinh, Email, MaPhong, Luong, MaSoThue, TenDangNhap, MatKhau, MaVaiTro } = req.body;
    if (!MaNV || !HoTen || !MaPhong || !TenDangNhap || !MatKhau) {
        return res.status(400).json({ message: 'Vui lòng nhập đầy đủ các trường bắt buộc' });
    }
    try {
        await db.executeSP('sp_HRManager_InsertNhanVien', [
            { name: 'MaNV', type: db.sql.VarChar(10), value: MaNV },
            { name: 'HoTen', type: db.sql.NVarChar(100), value: HoTen },
            { name: 'NgaySinh', type: db.sql.Date, value: NgaySinh || null },
            { name: 'Email', type: db.sql.VarChar(100), value: Email || null },
            { name: 'MaPhong', type: db.sql.VarChar(10), value: MaPhong },
            { name: 'Luong', type: db.sql.Decimal(18,2), value: Luong || null },
            { name: 'MaSoThue', type: db.sql.VarChar(20), value: MaSoThue || null },
            { name: 'TenDangNhap', type: db.sql.VarChar(50), value: TenDangNhap },
            { name: 'MatKhau', type: db.sql.VarChar(100), value: MatKhau },
            { name: 'MaVaiTro', type: db.sql.VarChar(10), value: MaVaiTro || 'EMP' }
        ], req.user);
        res.status(201).json({ message: 'Thêm nhân viên và tài khoản thành công' });
    } catch (error) {
        res.status(500).json({ message: 'Lỗi thêm nhân viên', error: error.message });
    }
};

// 3. [GET] Xem nhật ký hệ thống
const getAuditLogs = async (req, res) => {
    try {
        const result = await db.executeSP('sp_HRManager_XemNhatKy', [], req.user);
        res.status(200).json(result || []);
    } catch (error) {
        res.status(500).json({ message: 'Lỗi lấy nhật ký', error: error.message });
    }
};

// --------------------------------------------------------
// CÁC HÀM QUẢN LÝ TÀI KHOẢN 
// --------------------------------------------------------

// 4. [GET] Xem danh sách tài khoản
const getAllAccounts = async (req, res) => {
    try {
        const result = await db.executeSP('sp_HRManager_XemTaiKhoan', [], req.user);
        res.status(200).json(result || []);
    } catch (error) {
        res.status(500).json({ message: 'Lỗi lấy danh sách tài khoản', error: error.message });
    }
};

// 5. [PUT] Khóa / Mở tài khoản
const toggleAccountStatus = async (req, res) => {
    const { TenDangNhap, TrangThai } = req.body;
    if (!TenDangNhap || TrangThai === undefined) {
        return res.status(400).json({ message: 'Thiếu thông tin' });
    }
    try {
        await db.executeSP('sp_HRManager_DoiTrangThaiTaiKhoan', [
            { name: 'TenDangNhap', type: db.sql.VarChar(50), value: TenDangNhap },
            { name: 'TrangThai', type: db.sql.Bit, value: TrangThai }
        ], req.user);
        res.status(200).json({ message: TrangThai ? 'Đã mở khóa tài khoản' : 'Đã khóa tài khoản' });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

// 6. [PUT] Đổi vai trò
const changeRole = async (req, res) => {
    const { TenDangNhap, MaVaiTroMoi } = req.body;
    if (!TenDangNhap || !MaVaiTroMoi) {
        return res.status(400).json({ message: 'Thiếu thông tin' });
    }
    try {
        await db.executeSP('sp_HRManager_DoiVaiTro', [
            { name: 'TenDangNhap', type: db.sql.VarChar(50), value: TenDangNhap },
            { name: 'MaVaiTroMoi', type: db.sql.VarChar(10), value: MaVaiTroMoi }
        ], req.user);
        res.status(200).json({ message: 'Đã đổi vai trò thành công' });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

// 7. [PUT] Cập nhật thông tin nhân viên
const updateEmployeeHRM = async (req, res) => {
    // Lấy mã nhân viên từ đường dẫn (URL)
    const { MaNV } = req.params; 
    const { HoTen, NgaySinh, Email, MaPhong, Luong, MaSoThue, MaVaiTro } = req.body;

    try {
        await db.executeSP('sp_HRManager_UpdateNhanVien', [
            { name: 'MaNV', type: db.sql.VarChar(10), value: MaNV },
            { name: 'HoTen', type: db.sql.NVarChar(100), value: HoTen },
            { name: 'NgaySinh', type: db.sql.Date, value: NgaySinh },
            { name: 'Email', type: db.sql.VarChar(100), value: Email },
            { name: 'MaPhong', type: db.sql.VarChar(10), value: MaPhong },
            { name: 'Luong', type: db.sql.Decimal(18,2), value: Luong },
            { name: 'MaSoThue', type: db.sql.VarChar(20), value: MaSoThue },
            { name: 'MaVaiTro', type: db.sql.VarChar(10), value: MaVaiTro }
        ], req.user);
        
        res.status(200).json({ message: 'Cập nhật nhân viên thành công' });
    } catch (error) {
        res.status(500).json({ message: 'Lỗi cập nhật', error: error.message });
    }
};

// 8. [DELETE] Xóa nhân viên và tài khoản
const deleteEmployeeHRM = async (req, res) => {
    const { MaNV } = req.params;
    try {
        await db.executeSP('sp_HRManager_DeleteNhanVien', [
            { name: 'MaNV', type: db.sql.VarChar(10), value: MaNV }
        ], req.user);
        res.status(200).json({ message: 'Đã xóa nhân viên và tài khoản' });
    } catch (error) {
        res.status(500).json({ message: 'Lỗi khi xóa', error: error.message });
    }
};

module.exports = {
    getAllEmployees, addEmployeeHRM, getAuditLogs, 
    getAllAccounts, toggleAccountStatus, changeRole,
    updateEmployeeHRM, deleteEmployeeHRM 
};
