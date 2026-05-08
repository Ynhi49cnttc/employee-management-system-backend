// src/controllers/hrController.js
const db = require('../config/db');

// 1. [GET] Xem tất cả nhân viên (Dành cho HR Manager)
const getAllEmployees = async (req, res) => {
    try {
        const result = await db.executeSP('sp_HRManager_XemTatCaNhanVien', [], req.user);

        res.status(200).json(result[0] || []);
    } catch (error) {
        console.error('Lỗi lấy danh sách:', error);
        res.status(500).json({ message: 'Lỗi server khi lấy danh sách nhân viên', error: error.message });
    }
};

// 2. [POST] Thêm nhân viên mới (Dành cho HR Manager)
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
        console.error('Lỗi thêm nhân viên:', error);
        res.status(500).json({ message: 'Không thể thêm nhân viên', error: error.message });
    }
};

// 3. [GET] Xem nhật ký hệ thống (Dành cho HR Manager)
const getAuditLogs = async (req, res) => {
    try {
        const result = await db.executeSP('sp_HRManager_XemNhatKy', [], req.user);
        res.status(200).json(result[0] || []);
    } catch (error) {
        res.status(500).json({ message: 'Lỗi lấy nhật ký', error: error.message });
    }
};

module.exports = {
    getAllEmployees,
    addEmployeeHRM,
    getAuditLogs
};