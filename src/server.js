// src/server.js
require('dotenv').config(); 
const app = require('./app'); 

const PORT = process.env.PORT || 5000;

// Khởi chạy server
app.listen(PORT, () => {
    console.log(`🚀 Server đang chạy tại http://localhost:${PORT}`);
});