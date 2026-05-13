USE QL_NHANVIEN;
GO

PRINT N'BẮT ĐẦU CHÈN DỮ LIỆU MẪU MỚI (SEED DATA V2)...';
GO

-- ============================================================
-- 1. LÀM SẠCH DỮ LIỆU CŨ
-- ============================================================
ALTER TABLE PHONGBAN DROP CONSTRAINT FK_PHONG_TRUONGPHONG;
DELETE FROM NHATKY;
DELETE FROM TAIKHOAN;
DELETE FROM NHANVIEN;
DELETE FROM PHONGBAN;
DELETE FROM VAITRO;

-- ============================================================
-- 2. DỮ LIỆU BẢNG: VAITRO
-- ============================================================
INSERT INTO VAITRO (MaVaiTro, TenVaiTro) VALUES
('EMP', N'Nhân viên'),
('MAN', N'Quản lý / Trưởng phòng'),
('FIN', N'Kế toán / Tài chính'),
('HR',  N'Chuyên viên Nhân sự'),
('HRM', N'Trưởng phòng Nhân sự');
PRINT N'Đã chèn dữ liệu bảng VAITRO.';

-- ============================================================
-- 3. DỮ LIỆU BẢNG: PHONGBAN 
-- ============================================================
INSERT INTO PHONGBAN (MaPhong, TenPhong, MaTruongPhong) VALUES
('P001', N'Phòng Kỹ thuật / IT', NULL),
('P002', N'Phòng Nhân sự',        NULL),
('P003', N'Phòng Hành chính',     NULL),
('P004', N'Phòng Kinh doanh',     NULL),
('P005', N'Phòng Tài chính',      NULL);
PRINT N'Đã chèn dữ liệu bảng PHONGBAN.';

-- ============================================================
-- 4. DỮ LIỆU BẢNG: NHANVIEN (Định dạng NV00x + Quy tắc Email)
-- ============================================================
INSERT INTO NHANVIEN 
    (MaNV, HoTen, NgaySinh, Email, SoDienThoai, GioiTinh, DiaChi, CCCD, MaPhong, ChucVu, LoaiNhanVien, TrangThai, NgayVaoLam, Luong, MaSoThue) 
VALUES
-- P001: IT
('NV001', N'Nguyễn Văn An',  '1995-01-15', 'annv@employee.com', '0901234561', 'NAM', N'Quận 1, TP.HCM', '079095000001', 'P001', N'Frontend Developer', 'FULLTIME', 'ACTIVE', '2022-03-01', 25000000, '8234567801'),
('NV002', N'Trần Thị Bình',  '1990-05-20', 'binhtt@employee.com', '0901234562', 'NU',  N'Quận 3, TP.HCM', '079090000002', 'P001', N'Trưởng phòng IT', 'FULLTIME', 'ACTIVE', '2020-01-15', 45000000, '8234567802'),
('NV003', N'Lê Quang Long',  '1998-02-10', 'longlq@employee.com', '0901234571', 'NAM', N'Quận 10, TP.HCM','079098000123', 'P001', N'Backend Developer', 'FULLTIME', 'ACTIVE', '2023-05-01', 22000000, '8234567811'),

-- P002: Nhân sự
('NV004', N'Phạm Thị Dung',  '1988-12-05', 'dungpt@employee.com', '0901234564', 'NU',  N'Quận Phú Nhuận, TP.HCM','079088000004', 'P002', N'Trưởng phòng Nhân sự', 'FULLTIME', 'ACTIVE', '2019-05-20', 40000000, '8234567804'),
('NV005', N'Lê Văn Cường',   '1996-08-12', 'cuonglv@employee.com',  '0901234563', 'NAM', N'Quận Gò Vấp, TP.HCM', '079096000003', 'P002', N'Chuyên viên Tuyển dụng', 'FULLTIME', 'ACTIVE', '2021-11-01', 18000000, '8234567803'),
('NV006', N'Ngô Ý Nhi',      '2003-05-20', 'nhiny@employee.com',   '0901234999', 'NU',  N'TP. Thủ Đức, TP.HCM',  '079003001234', 'P002', N'Chuyên viên Nhân sự', 'FULLTIME', 'ACTIVE', '2024-01-01', 20000000, '8234567899'),

-- P005: Tài chính
('NV007', N'Vũ Thị Phương',  '1985-10-30', 'phuongvt@employee.com', '0901234566', 'NU',  N'Quận 10, TP.HCM', '079085000006', 'P005', N'Kế toán trưởng', 'FULLTIME', 'ACTIVE', '2018-02-10', 50000000, '8234567806'),
('NV008', N'Hoàng Văn Em',   '1994-04-25', 'emhv@employee.com',  '0901234565', 'NAM', N'Quận Tân Bình, TP.HCM','079094000005', 'P005', N'Kế toán viên', 'FULLTIME', 'ACTIVE', '2022-08-15', 20000000, '8234567805'),
('NV009', N'Lý Thị Linh',    '1999-11-11', 'linhlt@employee.com',   '0901234570', 'NU',  N'Quận 4, TP.HCM', '079099000010', 'P005', N'Thực tập sinh Kế toán', 'INTERN', 'ACTIVE', '2024-01-05', 5000000, '8234567810'),

-- P004: Kinh doanh
('NV010', N'Đỗ Văn Giang',   '1992-07-07', 'giangdv@employee.com',  '0901234567', 'NAM', N'Quận 2, TP.HCM', '079092000007', 'P004', N'Trưởng phòng Kinh doanh', 'FULLTIME', 'ACTIVE', '2020-09-01', 42000000, '8234567807'),
('NV011', N'Nguyễn Minh Tâm', '1997-03-22', 'tamnm@employee.com',   '0901234588', 'NAM', N'Quận 8, TP.HCM', '079097000888', 'P004', N'Nhân viên Kinh doanh', 'FULLTIME', 'ACTIVE', '2023-01-10', 18000000, '8234567812'),

-- P003: Hành chính
('NV012', N'Ngô Thị Hạnh',   '1997-02-18', 'hanhnt@employee.com',  '0901234568', 'NU',  N'Bình Thạnh, TP.HCM', '079097000008', 'P003', N'Chuyên viên Hành chính', 'FULLTIME', 'ACTIVE', '2023-03-15', 15000000, '8234567808');

PRINT N'Đã chèn dữ liệu bảng NHANVIEN.';

-- ============================================================
-- 5. DỮ LIỆU BẢNG: TAIKHOAN (Quy tắc Username mới)
-- Tên đăng nhập: [tên][họ lót]_[vai trò]
-- ============================================================
INSERT INTO TAIKHOAN (TenDangNhap, MatKhauHash, MaNV, MaVaiTro, TrangThai) VALUES
('annv_emp',    HASHBYTES('SHA2_256', '123456'), 'NV001', 'EMP', 1),
('binhtt_man',  HASHBYTES('SHA2_256', '123456'), 'NV002', 'MAN', 1),
('longlq_emp',  HASHBYTES('SHA2_256', '123456'), 'NV003', 'EMP', 1),
('dungpt_hrm',  HASHBYTES('SHA2_256', '123456'), 'NV004', 'HRM', 1),
('cuonglv_hr',  HASHBYTES('SHA2_256', '123456'), 'NV005', 'HR',  1),
('nhiny_hr',    HASHBYTES('SHA2_256', '123456'), 'NV006', 'HR',  1),
('phuongvt_man',HASHBYTES('SHA2_256', '123456'), 'NV007', 'MAN', 1),
('emhv_fin',    HASHBYTES('SHA2_256', '123456'), 'NV008', 'FIN', 1),
('linhlt_fin',  HASHBYTES('SHA2_256', '123456'), 'NV009', 'FIN', 1),
('giangdv_man', HASHBYTES('SHA2_256', '123456'), 'NV010', 'MAN', 1),
('tamnm_emp',   HASHBYTES('SHA2_256', '123456'), 'NV011', 'EMP', 1),
('hanhnt_emp',  HASHBYTES('SHA2_256', '123456'), 'NV012', 'EMP', 1);

PRINT N'Đã chèn dữ liệu bảng TAIKHOAN (Mật khẩu: 123456).';

-- ============================================================
-- 6. CẬP NHẬT TRƯỞNG PHÒNG & THIẾT LẬP LẠI RÀNG BUỘC
-- ============================================================
UPDATE PHONGBAN SET MaTruongPhong = 'NV002' WHERE MaPhong = 'P001';
UPDATE PHONGBAN SET MaTruongPhong = 'NV004' WHERE MaPhong = 'P002';
UPDATE PHONGBAN SET MaTruongPhong = 'NV012' WHERE MaPhong = 'P003';
UPDATE PHONGBAN SET MaTruongPhong = 'NV010' WHERE MaPhong = 'P004';
UPDATE PHONGBAN SET MaTruongPhong = 'NV007' WHERE MaPhong = 'P005';

ALTER TABLE PHONGBAN ADD CONSTRAINT FK_PHONG_TRUONGPHONG FOREIGN KEY (MaTruongPhong) REFERENCES NHANVIEN(MaNV);
PRINT N'Đã cập nhật Trưởng phòng và thiết lập lại ràng buộc.';

-- ============================================================
-- 7. DỮ LIỆU BẢNG: NHATKY
-- ============================================================
INSERT INTO NHATKY (MaNV_ThucHien, HanhDong, BangBiTacDong, HangBiThayDoi, CotBiThayDoi, GiaTriCu, GiaTriMoi, ThoiGian)
VALUES
('NV004', 'INSERT', 'NHANVIEN', 'HỆ THỐNG', 'ALL', NULL, N'Cập nhật dữ liệu hệ thống chuẩn V2', GETDATE());

PRINT N'HOÀN TẤT CHÈN DỮ LIỆU MẪU MỚI!';
GO