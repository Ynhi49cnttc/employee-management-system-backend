// src/controllers/departmentController.js
const db = require('../config/db');

const pick = (body, keys, fallback = null) => {
    for (const key of keys) {
        if (body[key] !== undefined && body[key] !== '') return body[key];
    }
    return fallback;
};

const getDepartments = async (req, res) => {
    try {
        const result = await db.executeSP('sp_HRManager_XemDanhSachPhongBan', [], req.user);
        res.status(200).json(result || []);
    } catch (error) {
        res.status(500).json({ message: 'Lỗi lấy danh sách phòng ban', error: error.message });
    }
};

const createDepartment = async (req, res) => {
    const MaPhong = pick(req.body, ['MaPhong', 'maPhong']);
    const TenPhong = pick(req.body, ['TenPhong', 'tenPhong']);

    if (!MaPhong || !TenPhong) {
        return res.status(400).json({ message: 'Vui lòng cung cấp đầy đủ Mã phòng ban và Tên phòng ban.' });
    }

    try {
        await db.executeSP('sp_HRManager_ThemPhongBan', [
            { name: 'MaPhong', type: db.sql.VarChar(10), value: MaPhong },
            { name: 'TenPhong', type: db.sql.NVarChar(100), value: TenPhong }
        ], req.user);

        res.status(201).json({ message: 'Thêm phòng ban mới thành công' });
    } catch (error) {
        res.status(500).json({ message: error.message || 'Lỗi thêm phòng ban' });
    }
};

const updateDepartment = async (req, res) => {
    const { id } = req.params; // Lấy Mã phòng từ URL
    const TenPhong = pick(req.body, ['TenPhong', 'tenPhong']);
    const MaTruongPhong = pick(req.body, ['MaTruongPhong', 'maTruongPhong']);

    if (!TenPhong && !MaTruongPhong) {
        return res.status(400).json({ message: 'Không có dữ liệu thay đổi nào được gửi lên.' });
    }

    try {
        await db.executeSP('sp_HRManager_CapNhatPhongBan', [
            { name: 'MaPhong', type: db.sql.VarChar(10), value: id },
            { name: 'TenPhong', type: db.sql.NVarChar(100), value: TenPhong },
            { name: 'MaTruongPhong', type: db.sql.VarChar(10), value: MaTruongPhong }
        ], req.user);

        res.status(200).json({ message: 'Cập nhật phòng ban thành công' });
    } catch (error) {
        res.status(500).json({ message: error.message || 'Lỗi cập nhật phòng ban' });
    }
};

module.exports = {
    getDepartments,
    createDepartment,
    updateDepartment
};