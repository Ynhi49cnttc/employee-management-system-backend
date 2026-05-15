// src/controllers/hrController.js
const db = require('../config/db');

const pick = (body, keys, fallback = null) => {
    for (const key of keys) {
        if (body[key] !== undefined && body[key] !== '') return body[key];
    }
    return fallback;
};

const buildEmployeeParams = (body) => ([
    { name: 'HoTen', type: db.sql.NVarChar(100), value: pick(body, ['HoTen', 'hoTen']) },
    { name: 'NgaySinh', type: db.sql.Date, value: pick(body, ['NgaySinh', 'ngaySinh']) },
    { name: 'Email', type: db.sql.VarChar(100), value: pick(body, ['Email', 'email']) },
    { name: 'SoDienThoai', type: db.sql.VarChar(15), value: pick(body, ['SoDienThoai', 'soDienThoai']) },
    { name: 'GioiTinh', type: db.sql.VarChar(10), value: pick(body, ['GioiTinh', 'gioiTinh']) },
    { name: 'DiaChi', type: db.sql.NVarChar(255), value: pick(body, ['DiaChi', 'diaChi']) },
    { name: 'CCCD', type: db.sql.VarChar(20), value: pick(body, ['CCCD', 'cccd']) },
    { name: 'MaPhong', type: db.sql.VarChar(10), value: pick(body, ['MaPhong', 'maPhong', 'phongBanId']) },
    { name: 'ChucVu', type: db.sql.NVarChar(100), value: pick(body, ['ChucVu', 'chucVu', 'chucVuTen']) },
    { name: 'LoaiNhanVien', type: db.sql.VarChar(20), value: pick(body, ['LoaiNhanVien', 'loaiNhanVien']) },
    { name: 'TrangThai', type: db.sql.VarChar(20), value: pick(body, ['TrangThai', 'trangThai']) },
    { name: 'NgayVaoLam', type: db.sql.Date, value: pick(body, ['NgayVaoLam', 'ngayVaoLam']) },
    { name: 'Luong', type: db.sql.Decimal(18, 2), value: pick(body, ['Luong', 'luongCoBan', 'tongLuong']) },
    { name: 'MaSoThue', type: db.sql.VarChar(20), value: pick(body, ['MaSoThue', 'maSoThue']) },
    { name: 'AvatarUrl', type: db.sql.NVarChar(500), value: pick(body, ['AvatarUrl', 'avatarUrl']) }
]);

const getAllEmployees = async (req, res) => {
    try {
        const result = await db.executeSP('sp_HRManager_XemTatCaNhanVien', [], req.user);
        res.status(200).json(result || []);
    } catch (error) {
        res.status(500).json({ message: 'Lỗi lấy danh sách nhân viên', error: error.message });
    }
};

const addEmployeeHRM = async (req, res) => {
    const MaNV = pick(req.body, ['MaNV', 'maNV']);
    const HoTen = pick(req.body, ['HoTen', 'hoTen']);
    const MaPhong = pick(req.body, ['MaPhong', 'maPhong', 'phongBanId']);
    
    let TenDangNhap = pick(req.body, ['TenDangNhap', 'tenDangNhap', 'username']); 
    const MatKhau = pick(req.body, ['MatKhau', 'matKhau', 'password'], '123456');
    const MaVaiTro = pick(req.body, ['MaVaiTro', 'maVaiTro', 'role'], 'EMP');

    if (!MaNV || !HoTen || !MaPhong) {
        return res.status(400).json({ message: 'Vui lòng nhập MaNV, HoTen, MaPhong ' });
    }

    if (!TenDangNhap) {
        const Email = pick(req.body, ['Email', 'email']);
        if (Email) {
            TenDangNhap = Email.split('@')[0];
        } else {
            TenDangNhap = MaNV.toLowerCase(); 
        }
    }
    // ------------------------------------------

    try {
        await db.executeSP('sp_HRManager_InsertNhanVien', [
            { name: 'MaNV', type: db.sql.VarChar(10), value: MaNV },
            ...buildEmployeeParams(req.body),
            { name: 'TenDangNhap', type: db.sql.VarChar(50), value: TenDangNhap },
            { name: 'MatKhau', type: db.sql.VarChar(100), value: MatKhau },
            { name: 'MaVaiTro', type: db.sql.VarChar(10), value: MaVaiTro }
        ], req.user);

        res.status(201).json({ message: 'Thêm nhân viên và tài khoản thành công' });
    } catch (error) {
        if (error.number === 2601 || error.number === 2627) {
            return res.status(400).json({ message: 'Thất bại: Email, Số điện thoại, CCCD hoặc Mã số thuế này đã tồn tại trong hệ thống!' });
        }
        res.status(500).json({ message: error.message || 'Lỗi thêm nhân viên' });
    }
};

const updateEmployeeHRM = async (req, res) => {
    const { MaNV } = req.params;
    const MaVaiTro = pick(req.body, ['MaVaiTro', 'maVaiTro', 'role']);

    try {
        await db.executeSP('sp_HRManager_UpdateNhanVien', [
            { name: 'MaNV', type: db.sql.VarChar(10), value: MaNV },
            ...buildEmployeeParams(req.body),
            { name: 'MaVaiTro', type: db.sql.VarChar(10), value: MaVaiTro }
        ], req.user);

        res.status(200).json({ message: 'Cập nhật nhân viên thành công' });
    } catch (error) {
        if (error.number === 2601 || error.number === 2627) {
            return res.status(400).json({ message: 'Thất bại: Email, Số điện thoại, CCCD hoặc Mã số thuế này đã bị trùng với người khác!' });
        }
        res.status(500).json({ message: error.message || 'Lỗi cập nhật' });
    }
};

const deleteEmployeeHRM = async (req, res) => {
    const { MaNV } = req.params;
    try {
        await db.executeSP('sp_HRManager_DeleteNhanVien', [
            { name: 'MaNV', type: db.sql.VarChar(10), value: MaNV }
        ], req.user);
        res.status(200).json({ message: 'Đã xóa nhân viên và tài khoản' });
    } catch (error) {
        res.status(500).json({ message: error.message || 'Lỗi khi xóa' });
    }
};

const getAuditLogs = async (req, res) => {
    try {
        const result = await db.executeSP('sp_HRManager_XemNhatKy', [], req.user);
        res.status(200).json(result || []);
    } catch (error) {
        res.status(500).json({ message: 'Lỗi lấy nhật ký', error: error.message });
    }
};

const getAllAccounts = async (req, res) => {
    try {
        const result = await db.executeSP('sp_HRManager_XemTaiKhoan', [], req.user);
        res.status(200).json(result || []);
    } catch (error) {
        res.status(500).json({ message: 'Lỗi lấy danh sách tài khoản', error: error.message });
    }
};

const toggleAccountStatus = async (req, res) => {
    const TenDangNhap = pick(req.body, ['TenDangNhap', 'tenDangNhap', 'username']);
    const TrangThai = pick(req.body, ['TrangThai', 'trangThai', 'isActive']);

    if (!TenDangNhap || TrangThai === null || TrangThai === undefined) {
        return res.status(400).json({ message: 'Thiếu thông tin tài khoản hoặc trạng thái' });
    }

    try {
        await db.executeSP('sp_HRManager_DoiTrangThaiTaiKhoan', [
            { name: 'TenDangNhap', type: db.sql.VarChar(50), value: TenDangNhap },
            { name: 'TrangThai', type: db.sql.Bit, value: Boolean(TrangThai) }
        ], req.user);

        res.status(200).json({ message: Boolean(TrangThai) ? 'Đã mở khóa tài khoản' : 'Đã khóa tài khoản' });
    } catch (error) {
        res.status(500).json({ message: error.message || 'Lỗi cập nhật trạng thái tài khoản' });
    }
};

const changeRole = async (req, res) => {
    const TenDangNhap = pick(req.body, ['TenDangNhap', 'tenDangNhap', 'username']);
    const MaVaiTroMoi = pick(req.body, ['MaVaiTroMoi', 'maVaiTroMoi', 'MaVaiTro', 'maVaiTro', 'role']);

    if (!TenDangNhap || !MaVaiTroMoi) {
        return res.status(400).json({ message: 'Thiếu thông tin tài khoản hoặc vai trò mới' });
    }

    try {
        await db.executeSP('sp_HRManager_DoiVaiTro', [
            { name: 'TenDangNhap', type: db.sql.VarChar(50), value: TenDangNhap },
            { name: 'MaVaiTroMoi', type: db.sql.VarChar(10), value: MaVaiTroMoi }
        ], req.user);

        res.status(200).json({ message: 'Đã đổi vai trò thành công' });
    } catch (error) {
        res.status(500).json({ message: error.message || 'Lỗi đổi vai trò' });
    }
};

module.exports = {
    getAllEmployees,
    addEmployeeHRM,
    updateEmployeeHRM,
    deleteEmployeeHRM,
    getAuditLogs,
    getAllAccounts,
    toggleAccountStatus,
    changeRole
};
