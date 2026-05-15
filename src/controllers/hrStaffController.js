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

const getOtherEmployees = async (req, res) => {
    try {
        const result = await db.executeSP('sp_HR_XemNhanVienNgoaiPhong', [
            { name: 'MaNV_Input', type: db.sql.VarChar(10), value: req.user.MaNV }
        ], req.user);
        res.status(200).json(result || []);
    } catch (error) {
        res.status(500).json({ message: 'Lỗi lấy danh sách nhân viên', error: error.message });
    }
};

const addOtherEmployee = async (req, res) => {
    const MaNV = pick(req.body, ['MaNV', 'maNV']);
    const HoTen = pick(req.body, ['HoTen', 'hoTen']);
    const MaPhong = pick(req.body, ['MaPhong', 'maPhong', 'phongBanId']);
    
    let TenDangNhap = pick(req.body, ['TenDangNhap', 'tenDangNhap', 'username']);
    const MatKhau = pick(req.body, ['MatKhau', 'matKhau', 'password'], '123456');

    if (!MaNV || !HoTen || !MaPhong) {
        return res.status(400).json({ message: 'Vui lòng nhập MaNV, HoTen, MaPhong' });
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
        await db.executeSP('sp_HR_InsertNhanVien', [
            { name: 'MaNV_Input', type: db.sql.VarChar(10), value: req.user.MaNV },
            { name: 'MaNV', type: db.sql.VarChar(10), value: MaNV },
            ...buildEmployeeParams(req.body),
            { name: 'TenDangNhap', type: db.sql.VarChar(50), value: TenDangNhap },
            { name: 'MatKhau', type: db.sql.VarChar(100), value: MatKhau }
        ], req.user);

        res.status(201).json({ message: 'Thêm nhân viên thành công' });
    } catch (error) {
        if (error.number === 2601 || error.number === 2627) {
            return res.status(400).json({ message: 'Thất bại: Email, Số điện thoại, CCCD hoặc Mã số thuế này đã tồn tại trong hệ thống!' });
        }
        res.status(500).json({ message: 'Lỗi thêm nhân viên', error: error.message });
    }
};

const updateOtherEmployee = async (req, res) => {
    const { MaNV } = req.params;

    try {
        await db.executeSP('sp_HR_UpdateNhanVien', [
            { name: 'MaNV_Input', type: db.sql.VarChar(10), value: req.user.MaNV },
            { name: 'MaNV', type: db.sql.VarChar(10), value: MaNV },
            ...buildEmployeeParams(req.body)
        ], req.user);

        res.status(200).json({ message: 'Cập nhật thành công' });
    } catch (error) {
        if (error.number === 2601 || error.number === 2627) {
            return res.status(400).json({ message: 'Thất bại: Email, Số điện thoại, CCCD hoặc Mã số thuế này đã bị trùng với người khác!' });
        }
        res.status(500).json({ message: 'Lỗi cập nhật nhân viên', error: error.message });
    }
};

const deleteOtherEmployee = async (req, res) => {
    const { MaNV } = req.params;

    try {
        await db.executeSP('sp_HR_DeleteNhanVien', [
            { name: 'MaNV_Input', type: db.sql.VarChar(10), value: req.user.MaNV },
            { name: 'MaNV', type: db.sql.VarChar(10), value: MaNV }
        ], req.user);

        res.status(200).json({ message: 'Xóa nhân viên thành công' });
    } catch (error) {
        res.status(500).json({ message: 'Lỗi xóa nhân viên', error: error.message });
    }
};

module.exports = {
    getOtherEmployees,
    addOtherEmployee,
    updateOtherEmployee,
    deleteOtherEmployee
};
