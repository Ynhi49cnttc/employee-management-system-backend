// src/config/db.js
const sql = require('mssql');
require('dotenv').config();

const dbConfig = {
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    server: process.env.DB_SERVER,
    database: process.env.DB_NAME,
    options: {
        encrypt: true, 
        trustServerCertificate: true,
        useUTC: false
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
 
    const transaction = new sql.Transaction(pool);

    try {
        await transaction.begin();

        if (userContext && userContext.MaNV) {
            const contextReq = new sql.Request(transaction);
            contextReq.input('ContextMaNV', sql.VarChar(10), userContext.MaNV);
            contextReq.input('ContextRole', sql.VarChar(10), userContext.MaVaiTro || '');
            
            await contextReq.query(`
                EXEC sp_set_session_context @key = N'MaNV', @value = @ContextMaNV;
                EXEC sp_set_session_context @key = N'Role', @value = @ContextRole;
            `);
        }

        const spReq = new sql.Request(transaction);

        params.forEach(param => {
            spReq.input(param.name, param.type, param.value);
        });

        const result = await spReq.execute(spName);

        await transaction.commit();
        
        return result.recordset || result.recordsets || true;

    } catch (error) {
        await transaction.rollback();
        throw error; 
    }
};

module.exports = {
    sql,
    poolPromise,
    executeSP
};