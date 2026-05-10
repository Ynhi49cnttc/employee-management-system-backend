const db = require('../config/db');

// Trưởng phòng xem nhân sự phòng mình (có kèm lương)
const getDepartmentEmployees = async (req, res) => {
    try {
        const result = await db.executeSP('sp_Manager_XemNhanVienCungPhong', [
            { name: 'MaNV_Input', type: db.sql.VarChar(10), value: req.user.MaNV }
        ], req.user);
        res.status(200).json(result || []);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

module.exports = { getDepartmentEmployees };