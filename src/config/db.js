// src/config/db.js
const sql = require('mssql');
require('dotenv').config();

const dbConfig = {
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    server: process.env.DB_SERVER,
    database: process.env.DB_NAME,
    options: {
        encrypt: true, // Tùy chọn bảo mật (thường dùng cho Azure SQL)
        trustServerCertificate: true // Rất quan trọng khi chạy Local để không bị lỗi chứng chỉ SSL
    }
};

// Khởi tạo Connection Pool (chỉ kết nối 1 lần và tái sử dụng)
const poolPromise = new sql.ConnectionPool(dbConfig)
    .connect()
    .then(pool => {
        console.log('✅ Kết nối CSDL MSSQL (QL_NHANVIEN) thành công!');
        return pool;
    })
    .catch(err => {
        console.error('❌ Lỗi kết nối CSDL:', err.message);
        process.exit(1);
    });

/**
 * Hàm hỗ trợ gọi Stored Procedure có tích hợp SESSION_CONTEXT
 * @param {string} spName - Tên Stored Procedure (ví dụ: 'sp_HRManager_UpdateNhanVien')
 * @param {Array} params - Mảng các tham số [{ name: 'MaNV', type: sql.VarChar, value: 'NV01' }]
 * @param {Object} userContext - Thông tin user đang login { MaNV: 'NV04', MaVaiTro: 'HRM' }
 */
const executeSP = async (spName, params = [], userContext = null) => {
    const pool = await poolPromise;
    
    // Sử dụng Transaction để đảm bảo sp_set_session_context và SP nghiệp vụ chạy trên cùng 1 session
    const transaction = new sql.Transaction(pool);

    try {
        await transaction.begin();

        // 1. Cài đặt ngữ cảnh người dùng (SESSION_CONTEXT) cho Trigger ghi Log
        if (userContext && userContext.MaNV) {
            const contextReq = new sql.Request(transaction);
            contextReq.input('ContextMaNV', sql.VarChar(10), userContext.MaNV);
            contextReq.input('ContextRole', sql.VarChar(10), userContext.MaVaiTro || '');
            
            await contextReq.query(`
                EXEC sp_set_session_context @key = N'MaNV', @value = @ContextMaNV;
                EXEC sp_set_session_context @key = N'Role', @value = @ContextRole;
            `);
        }

        // 2. Thực thi Stored Procedure chính
        const spReq = new sql.Request(transaction);
        
        // Nạp các tham số truyền vào
        params.forEach(param => {
            spReq.input(param.name, param.type, param.value);
        });

        const result = await spReq.execute(spName);

        // 3. Commit nếu mọi thứ thành công
        await transaction.commit();
        
        // Trả về recordset (danh sách data) nếu SP có lệnh SELECT, nếu không sẽ undefined
        return result.recordset || result.recordsets || true;

    } catch (error) {
        // Rollback nếu có bất kỳ lỗi gì (Lỗi T-SQL RAISERROR cũng sẽ nhảy vào đây)
        await transaction.rollback();
        throw error; 
    }
};

module.exports = {
    sql,
    poolPromise,
    executeSP
};