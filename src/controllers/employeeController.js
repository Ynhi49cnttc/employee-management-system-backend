const db = require('../config/db');

// Xem hồ sơ của chính mình
const getProfile = async (req, res) => {
    try {
        const result = await db.executeSP('sp_Employee_XemThongTinCaNhan', [
            { name: 'MaNV_Input', type: db.sql.VarChar(10), value: req.user.MaNV }
        ], req.user);
        res.status(200).json(result[0] || {}); 
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

// Xem đồng nghiệp cùng phòng (Không có lương)
const getDepartmentPeers = async (req, res) => {
    try {
        const result = await db.executeSP('sp_Employee_XemNhanVienCungPhong', [
            { name: 'MaNV_Input', type: db.sql.VarChar(10), value: req.user.MaNV }
        ], req.user);
        res.status(200).json(result || []);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

module.exports = { getProfile, getDepartmentPeers };