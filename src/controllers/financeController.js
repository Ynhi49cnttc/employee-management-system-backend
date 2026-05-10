const db = require('../config/db');

// Kế toán xem lương toàn công ty (trừ phòng kế toán)
const getCompanySalary = async (req, res) => {
    try {
        const result = await db.executeSP('sp_Finance_XemLuongCongTy', [
            { name: 'MaNV_Input', type: db.sql.VarChar(10), value: req.user.MaNV }
        ], req.user);
        res.status(200).json(result || []);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

module.exports = { getCompanySalary };