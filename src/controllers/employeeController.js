// src/controllers/employeeController.js
const db = require('../config/db');

const getProfile = async (req, res) => {
    try {
        // Lấy MaNV từ token đã được giải mã ở middleware
        const { MaNV } = req.user; 
        
        // Gọi Store Procedure
        const result = await db.executeSP('sp_Employee_XemThongTinCaNhan', [
            { name: 'MaNV_Input', type: db.sql.VarChar(10), value: MaNV }
        ], req.user); 

        if (result && result[0]) {
            res.status(200).json(result[0]);
        } else {
            res.status(404).json({ message: 'Không tìm thấy thông tin nhân viên' });
        }
    } catch (error) {
        console.error('Lỗi lấy profile:', error);
        res.status(500).json({ message: 'Lỗi server', error: error.message });
    }
};

module.exports = { getProfile };