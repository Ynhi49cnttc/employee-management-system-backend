const db = require('../config/db');

// Lấy danh sách nhân viên ngoài phòng HR
const getOtherEmployees = async (req, res) => {
    try {
        const result = await db.executeSP('sp_HR_XemNhanVienNgoaiPhong', [
            { name: 'MaNV_Input', type: db.sql.VarChar(10), value: req.user.MaNV }
        ], req.user);
        res.status(200).json(result || []);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

// Cập nhật nhân viên ngoài phòng HR
const updateOtherEmployee = async (req, res) => {
    const { MaNV } = req.params; // MaNV cần sửa
    const { HoTen, NgaySinh, Email, MaPhong, Luong, MaSoThue } = req.body;

    try {
        await db.executeSP('sp_HR_UpdateNhanVien', [
            { name: 'MaNV_Input', type: db.sql.VarChar(10), value: req.user.MaNV }, // Người thực hiện
            { name: 'MaNV', type: db.sql.VarChar(10), value: MaNV }, // Nạn nhân
            { name: 'HoTen', type: db.sql.NVarChar(100), value: HoTen },
            { name: 'NgaySinh', type: db.sql.Date, value: NgaySinh },
            { name: 'Email', type: db.sql.VarChar(100), value: Email },
            { name: 'MaPhong', type: db.sql.VarChar(10), value: MaPhong },
            { name: 'Luong', type: db.sql.Decimal(18,2), value: Luong },
            { name: 'MaSoThue', type: db.sql.VarChar(20), value: MaSoThue }
        ], req.user);
        res.status(200).json({ message: 'Cập nhật thành công!' });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

module.exports = { getOtherEmployees, updateOtherEmployee };