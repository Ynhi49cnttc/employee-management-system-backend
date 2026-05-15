USE QL_NHANVIEN;
GO

-- ============================================================
-- 1. LÀM SẠCH DỮ LIỆU CŨ 
-- ============================================================
IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_PHONG_TRUONGPHONG')
BEGIN
    ALTER TABLE PHONGBAN DROP CONSTRAINT FK_PHONG_TRUONGPHONG;
END
GO

DELETE FROM NHATKY;
DBCC CHECKIDENT ('NHATKY', RESEED, 0);

DELETE FROM TAIKHOAN;
DELETE FROM NHANVIEN;
DELETE FROM PHONGBAN;
DELETE FROM VAITRO;
GO

-- ============================================================
-- TRANSACTION 
-- ============================================================
BEGIN TRY
    BEGIN TRANSACTION;

    EXEC sp_set_session_context @key = N'MaNV', @value = 'NV004';

    -- 2. DỮ LIỆU BẢNG: VAITRO
    INSERT INTO VAITRO (MaVaiTro, TenVaiTro) VALUES
    ('EMP', N'Nhân viên'),
    ('MAN', N'Quản lý / Trưởng phòng'),
    ('FIN', N'Kế toán / Tài chính'),
    ('HR',  N'Chuyên viên Nhân sự'),
    ('HRM', N'Trưởng phòng Nhân sự');

    -- 3. DỮ LIỆU BẢNG: PHONGBAN 
    INSERT INTO PHONGBAN (MaPhong, TenPhong, MaTruongPhong) VALUES
    ('P001', N'Phòng Kỹ thuật / IT', NULL),
    ('P002', N'Phòng Nhân sự',       NULL),
    ('P003', N'Phòng Hành chính',    NULL),
    ('P004', N'Phòng Kinh doanh',    NULL),
    ('P005', N'Phòng Tài chính',     NULL);

	EXEC dbo.sp_CreateSalaryKeyForPhong 'P001';
	EXEC dbo.sp_CreateSalaryKeyForPhong 'P002';
	EXEC dbo.sp_CreateSalaryKeyForPhong 'P003';
	EXEC dbo.sp_CreateSalaryKeyForPhong 'P004';
	EXEC dbo.sp_CreateSalaryKeyForPhong 'P005';

	EXEC dbo.sp_OpenAllSalaryKeys;

   -- 4. DỮ LIỆU BẢNG: NHANVIEN 
    INSERT INTO NHANVIEN 
        (MaNV, HoTen, NgaySinh, Email, SoDienThoai, GioiTinh, DiaChi, CCCD, MaPhong, ChucVu, LoaiNhanVien, TrangThai, NgayVaoLam, LuongEncrypted, MaSoThue, AvatarUrl) 
    VALUES
    -- P001: IT
    ('NV001', N'Nguyễn Văn An',  '1995-01-15', 'annv@employee.com', '0901234561', 'NAM', N'Quận 1, TP.HCM', '079095000001', 'P001', N'Frontend Developer', 'FULLTIME', 'ACTIVE', '2022-03-01', EncryptByKey(Key_GUID('SymKey_P001'), CONVERT(VARCHAR(50), 25000000), 1, CONVERT(VARCHAR(10), 'NV001')), '8234567801', 'https://th.bing.com/th/id/OIP.fD95bEoLykm2y1FXmklo5wHaLH?o=7rm=3&rs=1&pid=ImgDetMain&o=7&rm=3'),
    ('NV002', N'Trần Thị Bình',  '1990-05-20', 'binhtt@employee.com', '0901234562', 'NU',  N'Quận 3, TP.HCM', '079090000002', 'P001', N'Trưởng phòng IT', 'FULLTIME', 'ACTIVE', '2020-01-15', EncryptByKey(Key_GUID('SymKey_P001'), CONVERT(VARCHAR(50), 45000000), 1, CONVERT(VARCHAR(10), 'NV002')), '8234567802', 'https://tse4.mm.bing.net/th/id/OIP.ABQPaakLPS9lJ2UMtx-ouwHaK6?rs=1&pid=ImgDetMain&o=7&rm=3'),
    ('NV003', N'Lê Quang Long',  '1998-02-10', 'longlq@employee.com', '0901234571', 'NAM', N'Quận 10, TP.HCM','079098000123', 'P001', N'Backend Developer', 'FULLTIME', 'ACTIVE', '2023-05-01', EncryptByKey(Key_GUID('SymKey_P001'), CONVERT(VARCHAR(50), 22000000), 1, CONVERT(VARCHAR(10), 'NV003')), '8234567811', NULL),

    -- P002: Nhân sự
    ('NV004', N'Phạm Thị Dung',  '1988-12-05', 'dungpt@employee.com', '0901234564', 'NU',  N'Quận Phú Nhuận, TP.HCM','079088000004', 'P002', N'Trưởng phòng Nhân sự', 'FULLTIME', 'ACTIVE', '2019-05-20', EncryptByKey(Key_GUID('SymKey_P002'), CONVERT(VARCHAR(50), 40000000), 1, CONVERT(VARCHAR(10), 'NV004')), '8234567804', 'https://i.pinimg.com/originals/0a/fa/d5/0afad5f90caa30b6d7ad63c66afeffb5.jpg'),
    ('NV005', N'Lê Văn Cường',   '1996-08-12', 'cuonglv@employee.com',  '0901234563', 'NAM', N'Quận Gò Vấp, TP.HCM', '079096000003', 'P002', N'Chuyên viên Tuyển dụng', 'FULLTIME', 'ACTIVE', '2021-11-01', EncryptByKey(Key_GUID('SymKey_P002'), CONVERT(VARCHAR(50), 18000000), 1, CONVERT(VARCHAR(10), 'NV005')), '8234567803', NULL),
    ('NV006', N'Ngô Ý Nhi',      '2003-05-20', 'nhiny@employee.com',   '0901234999', 'NU',  N'TP. Thủ Đức, TP.HCM',  '079003001234', 'P002', N'Chuyên viên Nhân sự', 'FULLTIME', 'ACTIVE', '2024-01-01', EncryptByKey(Key_GUID('SymKey_P002'), CONVERT(VARCHAR(50), 20000000), 1, CONVERT(VARCHAR(10), 'NV006')), '8234567899', 'https://tse3.mm.bing.net/th/id/OIP.D3XHQViR2YKuxlOQqMrq6AHaK0?w=819&h=1197&rs=1&pid=ImgDetMain&o=7&rm=3'),

    -- P005: Tài chính 
    ('NV007', N'Vũ Thị Phương',  '1985-10-30', 'phuongvt@employee.com', '0901234566', 'NU',  N'Quận 10, TP.HCM', '079085000006', 'P005', N'Kế toán trưởng', 'FULLTIME', 'ACTIVE', '2018-02-10', EncryptByKey(Key_GUID('SymKey_P005'), CONVERT(VARCHAR(50), 50000000), 1, CONVERT(VARCHAR(10), 'NV007')), '8234567806', NULL),
    ('NV008', N'Hoàng Văn Em',   '1994-04-25', 'emhv@employee.com',  '0901234565', 'NAM', N'Quận Tân Bình, TP.HCM','079094000005', 'P005', N'Chuyên viên Tài chính', 'FULLTIME', 'ACTIVE', '2022-08-15', EncryptByKey(Key_GUID('SymKey_P005'), CONVERT(VARCHAR(50), 20000000), 1, CONVERT(VARCHAR(10), 'NV008')), '8234567805', NULL),
    ('NV009', N'Lý Thị Linh',    '1999-11-11', 'linhlt@employee.com',   '0901234570', 'NU',  N'Quận 4, TP.HCM', '079099000010', 'P005', N'Thực tập sinh Kế toán', 'INTERN', 'ACTIVE', '2024-01-05', EncryptByKey(Key_GUID('SymKey_P005'), CONVERT(VARCHAR(50), 5000000), 1, CONVERT(VARCHAR(10), 'NV009')), '8234567810', NULL),

    -- P004: Kinh doanh 
    ('NV010', N'Đỗ Văn Giang',   '1992-07-07', 'giangdv@employee.com',  '0901234567', 'NAM', N'Quận 2, TP.HCM', '079092000007', 'P004', N'Trưởng phòng Kinh doanh', 'FULLTIME', 'ACTIVE', '2020-09-01', EncryptByKey(Key_GUID('SymKey_P004'), CONVERT(VARCHAR(50), 42000000), 1, CONVERT(VARCHAR(10), 'NV010')), '8234567807', 'https://tse3.mm.bing.net/th/id/OIP.bhmRCVc3Rf-50LSuUxVSkwHaIh?w=1000&h=1150&rs=1&pid=ImgDetMain&o=7&rm=3'),
    ('NV011', N'Nguyễn Minh Tâm', '1997-03-22', 'tamnm@employee.com',   '0901234588', 'NAM', N'Quận 8, TP.HCM', '079097000888', 'P004', N'Nhân viên Kinh doanh', 'FULLTIME', 'ACTIVE', '2023-01-10', EncryptByKey(Key_GUID('SymKey_P004'), CONVERT(VARCHAR(50), 18000000), 1, CONVERT(VARCHAR(10), 'NV011')), '8234567812', NULL),
    ('NV013', N'Lê Văn Đạt',      '2000-05-15', 'datlv@employee.com',   '0901112233', 'NAM', N'Quận 7, TP.HCM', '079000111222', 'P004', N'Cộng tác viên KD', 'PARTTIME', 'INACTIVE', '2023-08-01', EncryptByKey(Key_GUID('SymKey_P004'), CONVERT(VARCHAR(50), 8000000), 1, CONVERT(VARCHAR(10), 'NV013')), '8234567813', NULL),

    -- P003: Hành chính 
    ('NV012', N'Ngô Thị Hạnh',   '1997-02-18', 'hanhnt@employee.com',  '0901234568', 'NU',  N'Bình Thạnh, TP.HCM', '079097000008', 'P003', N'Trưởng phòng Hành chính', 'FULLTIME', 'ACTIVE', '2023-03-15', EncryptByKey(Key_GUID('SymKey_P003'), CONVERT(VARCHAR(50), 25000000), 1, CONVERT(VARCHAR(10), 'NV012')), '8234567808', 'https://tse1.mm.bing.net/th/id/OIP.CLrEPsczRcT3s91U9BUGVQHaJ3?w=1060&h=1413&rs=1&pid=ImgDetMain&o=7&rm=3'),
    ('NV014', N'Trần Hữu Khoa',  '1995-10-10', 'khoath@employee.com',  '0901999888', 'NAM', N'Quận 5, TP.HCM', '079095999888', 'P003', N'Nhân viên Hành chính', 'FULLTIME', 'ACTIVE', '2024-06-01', EncryptByKey(Key_GUID('SymKey_P003'), CONVERT(VARCHAR(50), 12000000), 1, CONVERT(VARCHAR(10), 'NV014')), '8234567814', NULL);
    -- Đóng khóa
    EXEC dbo.sp_CloseAllSalaryKeys;

    -- 5. DỮ LIỆU BẢNG: TAIKHOAN
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
    ('hanhnt_man',  HASHBYTES('SHA2_256', '123456'), 'NV012', 'MAN', 1),
    ('datlv_emp',   HASHBYTES('SHA2_256', '123456'), 'NV013', 'EMP', 1),
    ('khoath_emp',  HASHBYTES('SHA2_256', '123456'), 'NV014', 'EMP', 0); -- Tài khoản bị khóa (0)

    -- 6. CẬP NHẬT TRƯỞNG PHÒNG & THIẾT LẬP LẠI RÀNG BUỘC
    UPDATE PHONGBAN SET MaTruongPhong = 'NV002' WHERE MaPhong = 'P001';
    UPDATE PHONGBAN SET MaTruongPhong = 'NV004' WHERE MaPhong = 'P002';
    UPDATE PHONGBAN SET MaTruongPhong = 'NV012' WHERE MaPhong = 'P003';
    UPDATE PHONGBAN SET MaTruongPhong = 'NV010' WHERE MaPhong = 'P004';
    UPDATE PHONGBAN SET MaTruongPhong = 'NV007' WHERE MaPhong = 'P005';

    ALTER TABLE PHONGBAN ADD CONSTRAINT FK_PHONG_TRUONGPHONG FOREIGN KEY (MaTruongPhong) REFERENCES NHANVIEN(MaNV);

    -- 7. DỮ LIỆU BẢNG: NHATKY (Làm giả lập Log đa dạng hơn)
    INSERT INTO NHATKY (MaNV_ThucHien, HanhDong, BangBiTacDong, HangBiThayDoi, CotBiThayDoi, GiaTriCu, GiaTriMoi, ThoiGian)
    VALUES
    ('NV004', 'INSERT', 'NHANVIEN', 'HỆ THỐNG', 'ALL', NULL, N'Khởi tạo dữ liệu hệ thống chuẩn', DATEADD(day, -5, GETDATE())),
    ('NV002', 'LOGIN', 'TAIKHOAN', 'NV002', 'LastLogin', NULL, N'Đăng nhập thành công', DATEADD(day, -2, GETDATE())),
    ('NV004', 'UPDATE', 'NHANVIEN', 'NV013', 'TrangThai', N'ACTIVE', N'INACTIVE', DATEADD(day, -1, GETDATE())),
    ('NV004', 'LOCK_ACCOUNT', 'TAIKHOAN', 'NV014', 'TrangThai', N'1', N'0', GETDATE());

    EXEC sp_set_session_context @key = N'MaNV', @value = NULL;

    COMMIT TRANSACTION;
    PRINT N'HOÀN TẤT CHÈN DỮ LIỆU MẪU MỚI THÀNH CÔNG!';
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    PRINT N'CÓ LỖI XẢY RA TRONG QUÁ TRÌNH SEED DỮ LIỆU:';
    PRINT ERROR_MESSAGE();
END CATCH
GO
