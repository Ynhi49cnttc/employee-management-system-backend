-- ============================================================
-- HE THONG QUAN LY NHAN VIEN - SCRIPT DA SUA TOAN BO LOI
-- ============================================================
-- LOI DA SUA:
--   [1] IF NOT EXISTS cua 5 role deu check sai 'Role_Manager'
--   [2] fn_GetCurrentMaNV() khai bao SAU cac SP dung no
--   [3] Thieu fn_GetCurrentRole() nhung cac SP da goi
--   [4] Luong VARBINARY(MAX) nhung seed data la so nguyen
--   [5] Nhieu CREATE PROCEDURE thieu GO nen loi batch
--   [6] sp_HR_UpdateNhanVien: COALESCE(Luong) khong hoat dong
--       voi VARBINARY - da doi kieu ve DECIMAL(18,2)
--   [7] sp_Admin_TaoTaiKhoan thieu phan DENY/GRANT
--   [8] Test 4 goi sai ten SP (sp_Manager_XemLuongPhong)
-- ============================================================

USE master;
GO

-- ============================================================
-- BUOC 1: TDE 
-- ============================================================
IF NOT EXISTS (SELECT * FROM sys.symmetric_keys WHERE name = '##MS_DatabaseMasterKey##')
BEGIN
    CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'StrongPassword123!';
END
GO

IF NOT EXISTS (SELECT * FROM sys.certificates WHERE name = 'TDECer_QLNhanVien')
BEGIN
    CREATE CERTIFICATE TDECer_QLNhanVien
    WITH SUBJECT = 'TDE Certificate for QL_NHANVIEN';
END
GO

-- ============================================================
-- BUOC 2: Tao Database
-- ============================================================
IF DB_ID('QL_NHANVIEN') IS NULL
BEGIN
    CREATE DATABASE QL_NHANVIEN;
END
GO

USE QL_NHANVIEN;
GO

-- ============================================================
-- BUOC 3: Bat TDE
-- ============================================================
IF NOT EXISTS (SELECT * FROM sys.dm_database_encryption_keys WHERE database_id = DB_ID('QL_NHANVIEN'))
BEGIN
    CREATE DATABASE ENCRYPTION KEY
    WITH ALGORITHM = AES_256
    ENCRYPTION BY SERVER CERTIFICATE TDECer_QLNhanVien;
END
GO

ALTER DATABASE QL_NHANVIEN SET ENCRYPTION ON;
GO

-- ============================================================
-- BUOC 4: Tao cac bang
-- ============================================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'PHONGBAN')
BEGIN
    CREATE TABLE PHONGBAN (
        MaPhong      VARCHAR(10)   PRIMARY KEY,
        TenPhong     NVARCHAR(100) NOT NULL,
        MaTruongPhong VARCHAR(10)  NULL
    );
END
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'VAITRO')
BEGIN
    CREATE TABLE VAITRO (
        MaVaiTro  VARCHAR(10)  PRIMARY KEY,
        TenVaiTro NVARCHAR(50) NOT NULL
    );
END
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'NHANVIEN')
BEGIN
    CREATE TABLE NHANVIEN (
        MaNV      VARCHAR(10)    PRIMARY KEY,
        HoTen     NVARCHAR(100)  NOT NULL,
        NgaySinh  DATE           NULL,
        Email     VARCHAR(100)   UNIQUE,
        MaPhong   VARCHAR(10),
        Luong     DECIMAL(18,2)  NULL,
        MaSoThue  VARCHAR(20),

        CONSTRAINT FK_NV_PHONG FOREIGN KEY (MaPhong)
            REFERENCES PHONGBAN(MaPhong)
    );
END
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'TAIKHOAN')
BEGIN
    CREATE TABLE TAIKHOAN (
        TenDangNhap VARCHAR(50)    PRIMARY KEY,
        MatKhauHash VARBINARY(256) NOT NULL,
        MaNV        VARCHAR(10)    UNIQUE,
        MaVaiTro    VARCHAR(10),
        TrangThai   BIT            DEFAULT 1,

        CONSTRAINT FK_TK_NV FOREIGN KEY (MaNV)
            REFERENCES NHANVIEN(MaNV),
        CONSTRAINT FK_TK_VT FOREIGN KEY (MaVaiTro)
            REFERENCES VAITRO(MaVaiTro)
    );
END
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'NHATKY')
BEGIN
    CREATE TABLE NHATKY (
        MaNK           INT IDENTITY(1,1) PRIMARY KEY,
        MaNV_ThucHien  VARCHAR(10),
        HanhDong       NVARCHAR(50),
        BangBiTacDong  NVARCHAR(50),
        HangBiThayDoi  NVARCHAR(50),
        CotBiThayDoi   NVARCHAR(50),
        GiaTriCu       NVARCHAR(MAX),
        GiaTriMoi      NVARCHAR(MAX),
        ThoiGian       DATETIME DEFAULT GETDATE(),

        CONSTRAINT FK_NK_NV FOREIGN KEY (MaNV_ThucHien)
            REFERENCES NHANVIEN(MaNV)
    );
END
GO

IF NOT EXISTS (
    SELECT * FROM sys.foreign_keys WHERE name = 'FK_PHONG_TRUONGPHONG'
)
BEGIN
    ALTER TABLE PHONGBAN
    ADD CONSTRAINT FK_PHONG_TRUONGPHONG
    FOREIGN KEY (MaTruongPhong) REFERENCES NHANVIEN(MaNV);
END
GO

-- ============================================================
-- BUOC 5: Tao cac ham (SU DUNG SESSION_CONTEXT DE LOG DUOC USER)
-- ============================================================

-- 5.1 Ham lay MaNV hien tai tu Session Context
IF OBJECT_ID('dbo.fn_GetCurrentMaNV', 'FN') IS NOT NULL
    DROP FUNCTION dbo.fn_GetCurrentMaNV;
GO

CREATE FUNCTION dbo.fn_GetCurrentMaNV()
RETURNS VARCHAR(10)
AS
BEGIN
    -- Lay MaNV do Backend (hoac SSMS) truyen xuong de Trigger ghi log
    RETURN CAST(SESSION_CONTEXT(N'MaNV') AS VARCHAR(10));
END;
GO

-- 5.2 Ham lay MaVaiTro hien tai tu Session Context
IF OBJECT_ID('dbo.fn_GetCurrentRole', 'FN') IS NOT NULL
    DROP FUNCTION dbo.fn_GetCurrentRole;
GO

CREATE FUNCTION dbo.fn_GetCurrentRole()
RETURNS VARCHAR(10)
AS
BEGIN
    RETURN CAST(SESSION_CONTEXT(N'Role') AS VARCHAR(10));
END;
GO

-- ============================================================
-- BUOC 6: Tao cac Role
-- ============================================================
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'Role_Employee' AND type = 'R')
    CREATE ROLE Role_Employee;
GO
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'Role_Manager' AND type = 'R')
    CREATE ROLE Role_Manager;
GO
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'Role_Finance' AND type = 'R')
    CREATE ROLE Role_Finance;
GO
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'Role_HR_Staff' AND type = 'R')
    CREATE ROLE Role_HR_Staff;
GO
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'Role_HR_Manager' AND type = 'R')
    CREATE ROLE Role_HR_Manager;
GO

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'Role_Admin' AND type = 'R')
    CREATE ROLE Role_Admin;
GO

-- ============================================================
-- BUOC 7: Tao Login va User (dung chung 1 login test)
-- ============================================================
USE master;
GO
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'test_login')
BEGIN
    CREATE LOGIN test_login WITH PASSWORD = 'Test@123456';
END
GO

USE QL_NHANVIEN;
GO

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'user_employee')
    CREATE USER user_employee FOR LOGIN test_login;
GO
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'user_manager')
    CREATE USER user_manager FOR LOGIN test_login;
GO
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'user_finance')
    CREATE USER user_finance FOR LOGIN test_login;
GO
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'user_hr_staff')
    CREATE USER user_hr_staff FOR LOGIN test_login;
GO
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'user_hr_manager')
    CREATE USER user_hr_manager FOR LOGIN test_login;
GO

-- Gan User vao Role
ALTER ROLE Role_Employee    ADD MEMBER user_employee;
ALTER ROLE Role_Manager     ADD MEMBER user_manager;
ALTER ROLE Role_Finance     ADD MEMBER user_finance;
ALTER ROLE Role_HR_Staff    ADD MEMBER user_hr_staff;
ALTER ROLE Role_HR_Manager  ADD MEMBER user_hr_manager;
GO

-- ============================================================
-- BUOC 8: Du lieu mau
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM VAITRO)
BEGIN
    INSERT INTO VAITRO (MaVaiTro, TenVaiTro) VALUES
    ('EMP', N'Employee'),
    ('MAN', N'Manager'),
    ('FIN', N'Finance'),
    ('HR',  N'HR Staff'),
    ('HRM', N'HR Manager');
END
GO

IF NOT EXISTS (SELECT 1 FROM PHONGBAN)
BEGIN
    INSERT INTO PHONGBAN (MaPhong, TenPhong, MaTruongPhong) VALUES
    ('P01', N'IT',         NULL),
    ('P02', N'Ke toan',    NULL),
    ('P03', N'Nhan su',    NULL),
    ('P04', N'Kinh doanh', NULL),
    ('P05', N'Marketing',  NULL);
END
GO

IF NOT EXISTS (SELECT 1 FROM NHANVIEN)
BEGIN
    INSERT INTO NHANVIEN (MaNV, HoTen, NgaySinh, Email, MaPhong, Luong, MaSoThue) VALUES
    ('NV01', N'Nguyen Van An',  '1995-01-01', 'an.nguyen@company.com',   'P01', 25000000, '8234567890'),
    ('NV02', N'Tran Thi Binh', '1996-02-02', 'binh.tran@company.com',   'P01', 35000000, '8234567891'),
    ('NV03', N'Le Van Cuong',  '1994-03-03', 'cuong.le@company.com',    'P03', 22000000, '8234567892'),
    ('NV04', N'Pham Thi Dung', '1993-04-04', 'dung.pham@company.com',   'P03', 40000000, '8234567893'),
    ('NV05', N'Hoang Van Em',  '1992-05-05', 'em.hoang@company.com',    'P02', 28000000, '8234567894'),
    ('NV06', N'Vu Thi Phuong', '1997-06-06', 'phuong.vu@company.com',   'P02', 30000000, '8234567895'),
    ('NV07', N'Do Van Giang',  '1991-07-07', 'giang.do@company.com',    'P04', 45000000, '8234567896'),
    ('NV08', N'Ngo Thi Hanh',  '1990-08-08', 'hanh.ngo@company.com',   'P05', 20000000, '8234567897'),
    ('NV09', N'Bui Van Khanh', '1998-09-09', 'khanh.bui@company.com',   'P01', 32000000, '8234567898'),
    ('NV10', N'Ly Thi Linh',   '1999-10-10', 'linh.ly@company.com',     'P02', 24000000, '8234567899');

    -- Cap nhat truong phong
    UPDATE PHONGBAN SET MaTruongPhong = 'NV02' WHERE MaPhong = 'P01'; -- Binh la truong phong IT
    UPDATE PHONGBAN SET MaTruongPhong = 'NV06' WHERE MaPhong = 'P02'; -- Phuong la truong phong Ke toan
    UPDATE PHONGBAN SET MaTruongPhong = 'NV04' WHERE MaPhong = 'P03'; -- Dung la HRM (truong phong Nhan su)
    UPDATE PHONGBAN SET MaTruongPhong = 'NV07' WHERE MaPhong = 'P04'; -- Giang la truong phong Kinh doanh
    UPDATE PHONGBAN SET MaTruongPhong = 'NV08' WHERE MaPhong = 'P05'; -- Hanh la truong phong Marketing
END
GO

IF NOT EXISTS (SELECT 1 FROM TAIKHOAN)
BEGIN
    -- Mat khau deu la '123456', ma hoa SHA2_256
    INSERT INTO TAIKHOAN (TenDangNhap, MatKhauHash, MaNV, MaVaiTro, TrangThai) VALUES
    ('nv01', HASHBYTES('SHA2_256', '123456'), 'NV01', 'EMP', 1),  -- Employee, phong IT
    ('nv02', HASHBYTES('SHA2_256', '123456'), 'NV02', 'MAN', 1),  -- Manager, truong phong IT
    ('nv03', HASHBYTES('SHA2_256', '123456'), 'NV03', 'HR',  1),  -- HR Staff
    ('nv04', HASHBYTES('SHA2_256', '123456'), 'NV04', 'HRM', 1),  -- HR Manager
    ('nv05', HASHBYTES('SHA2_256', '123456'), 'NV05', 'FIN', 1),  -- Finance Staff
    ('nv06', HASHBYTES('SHA2_256', '123456'), 'NV06', 'MAN', 1),  -- Manager, truong phong Ke toan
    ('nv07', HASHBYTES('SHA2_256', '123456'), 'NV07', 'EMP', 1),  -- Employee, phong Kinh doanh
    ('nv08', HASHBYTES('SHA2_256', '123456'), 'NV08', 'EMP', 1),  -- Employee, phong Marketing
    ('nv09', HASHBYTES('SHA2_256', '123456'), 'NV09', 'EMP', 1),  -- Employee, phong IT
    ('nv10', HASHBYTES('SHA2_256', '123456'), 'NV10', 'FIN', 1);  -- Finance Staff
END
GO

-- Du lieu mau nhat ky
IF NOT EXISTS (SELECT 1 FROM NHATKY)
BEGIN
    INSERT INTO NHATKY (MaNV_ThucHien, HanhDong, BangBiTacDong, HangBiThayDoi, CotBiThayDoi, GiaTriCu, GiaTriMoi)
    VALUES
    ('NV04', 'UPDATE', 'NHANVIEN', 'NV01', 'Luong',   '22000000', '25000000'),
    ('NV04', 'UPDATE', 'NHANVIEN', 'NV05', 'Email',   'em.old@company.com', 'em.hoang@company.com'),
    ('NV03', 'INSERT', 'NHANVIEN', 'NV09', 'ALL',     NULL, 'NV09 - Bui Van Khanh'),
    ('NV04', 'DELETE', 'NHANVIEN', 'NV_X', 'ALL',     'NV_X - da xoa', NULL);
END
GO

-- ============================================================
-- BUOC 9: Chan truy cap truc tiep bang nhay cam
-- ============================================================
DENY SELECT, INSERT, UPDATE, DELETE ON NHANVIEN TO PUBLIC;
DENY SELECT, INSERT, UPDATE, DELETE ON TAIKHOAN TO PUBLIC;
GO

-- ============================================================
-- BUOC 10: Cac Stored Procedure
-- ============================================================

-- ----------------------------------------------------------
-- SP: Dang nhap (Backend goi SP nay, khong query truc tiep)
-- ----------------------------------------------------------
IF OBJECT_ID('dbo.sp_Auth_Login', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_Auth_Login;
GO
CREATE PROCEDURE dbo.sp_Auth_Login
    @TenDangNhap VARCHAR(50),
    @MatKhau     VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT 1 FROM TAIKHOAN
        WHERE TenDangNhap = @TenDangNhap
          AND MatKhauHash  = HASHBYTES('SHA2_256', @MatKhau)
          AND TrangThai    = 1
    )
        SELECT 'Success' AS Status, MaNV, MaVaiTro
        FROM   TAIKHOAN
        WHERE  TenDangNhap = @TenDangNhap;
    ELSE
        SELECT 'Fail' AS Status, NULL AS MaNV, NULL AS MaVaiTro;
END;
GO

-- ----------------------------------------------------------
-- SP: Employee - Xem thong tin ca nhan
-- ----------------------------------------------------------
IF OBJECT_ID('dbo.sp_Employee_XemThongTinCaNhan', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_Employee_XemThongTinCaNhan;
GO
CREATE PROCEDURE dbo.sp_Employee_XemThongTinCaNhan
    @MaNV_Input VARCHAR(10)   -- backend truyen vao 
AS
BEGIN
    SET NOCOUNT ON;
    SELECT MaNV, HoTen, NgaySinh, Email, MaPhong, Luong, MaSoThue
    FROM   NHANVIEN
    WHERE  MaNV = @MaNV_Input;
END;
GO

-- ----------------------------------------------------------
-- SP: Employee - Xem nhan vien cung phong (khong co Luong)
-- ----------------------------------------------------------
IF OBJECT_ID('dbo.sp_Employee_XemNhanVienCungPhong', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_Employee_XemNhanVienCungPhong;
GO
CREATE PROCEDURE dbo.sp_Employee_XemNhanVienCungPhong
    @MaNV_Input VARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @MaPhong VARCHAR(10);
    SELECT @MaPhong = MaPhong FROM NHANVIEN WHERE MaNV = @MaNV_Input;

    SELECT MaNV, HoTen, NgaySinh, Email, MaPhong
    FROM   NHANVIEN
    WHERE  MaPhong = @MaPhong;
END;
GO

-- ----------------------------------------------------------
-- SP: Manager - Xem nhan vien cung phong (co Luong)
-- ----------------------------------------------------------
IF OBJECT_ID('dbo.sp_Manager_XemNhanVienCungPhong', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_Manager_XemNhanVienCungPhong;
GO
CREATE PROCEDURE dbo.sp_Manager_XemNhanVienCungPhong
    @MaNV_Input VARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @MaPhong VARCHAR(10);
    SELECT @MaPhong = MaPhong FROM NHANVIEN WHERE MaNV = @MaNV_Input;

    SELECT MaNV, HoTen, NgaySinh, Email, MaPhong, Luong, MaSoThue
    FROM   NHANVIEN
    WHERE  MaPhong = @MaPhong;
END;
GO

-- ----------------------------------------------------------
-- SP: Finance - Xem luong toan cong ty (tru phong minh)
-- ----------------------------------------------------------
IF OBJECT_ID('dbo.sp_Finance_XemLuongCongTy', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_Finance_XemLuongCongTy;
GO
CREATE PROCEDURE dbo.sp_Finance_XemLuongCongTy
    @MaNV_Input VARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @MaPhongFinance VARCHAR(10);
    SELECT @MaPhongFinance = MaPhong FROM NHANVIEN WHERE MaNV = @MaNV_Input;

    SELECT MaNV, HoTen, NgaySinh, Email, MaPhong, Luong, MaSoThue
    FROM   NHANVIEN
    WHERE  MaPhong <> @MaPhongFinance;
END;
GO

-- ----------------------------------------------------------
-- SP: HR Staff - Xem nhan vien ngoai phong HR (co Luong)
-- ----------------------------------------------------------
IF OBJECT_ID('dbo.sp_HR_XemNhanVienNgoaiPhong', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_HR_XemNhanVienNgoaiPhong;
GO
CREATE PROCEDURE dbo.sp_HR_XemNhanVienNgoaiPhong
    @MaNV_Input VARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @MaPhongHR VARCHAR(10);
    SELECT @MaPhongHR = MaPhong FROM NHANVIEN WHERE MaNV = @MaNV_Input;

    SELECT MaNV, HoTen, NgaySinh, Email, MaPhong, Luong, MaSoThue
    FROM   NHANVIEN
    WHERE  MaPhong <> @MaPhongHR;
END;
GO

-- ----------------------------------------------------------
-- SP: HR Staff - Cap nhat nhan vien ngoai phong HR
-- FIX [6]: Luong gio la DECIMAL(18,2), COALESCE hoat dong dung
-- ----------------------------------------------------------
IF OBJECT_ID('dbo.sp_HR_UpdateNhanVien', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_HR_UpdateNhanVien;
GO
CREATE PROCEDURE dbo.sp_HR_UpdateNhanVien
    @MaNV_Input  VARCHAR(10),   -- MaNV cua HR Staff dang thao tac
    @MaNV        VARCHAR(10),   -- MaNV nhan vien can sua
    @HoTen       NVARCHAR(100) = NULL,
    @NgaySinh    DATE          = NULL,
    @Email       VARCHAR(100)  = NULL,
    @MaPhong     VARCHAR(10)   = NULL,
    @Luong       DECIMAL(18,2) = NULL,
    @MaSoThue    VARCHAR(20)   = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @MaPhongHR VARCHAR(10);
    SELECT @MaPhongHR = MaPhong FROM NHANVIEN WHERE MaNV = @MaNV_Input;

    IF EXISTS (SELECT 1 FROM NHANVIEN WHERE MaNV = @MaNV AND MaPhong = @MaPhongHR)
    BEGIN
        RAISERROR(N'Khong duoc phep sua nhan vien cung phong HR', 16, 1);
        RETURN;
    END

    UPDATE NHANVIEN SET
        HoTen    = COALESCE(@HoTen,    HoTen),
        NgaySinh = COALESCE(@NgaySinh, NgaySinh),
        Email    = COALESCE(@Email,    Email),
        MaPhong  = COALESCE(@MaPhong,  MaPhong),
        Luong    = COALESCE(@Luong,    Luong),
        MaSoThue = COALESCE(@MaSoThue, MaSoThue)
    WHERE MaNV = @MaNV;
END;
GO

-- ----------------------------------------------------------
-- SP: HR Staff - Them nhan vien ngoai phong HR
-- ----------------------------------------------------------
IF OBJECT_ID('dbo.sp_HR_InsertNhanVien', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_HR_InsertNhanVien;
GO
CREATE PROCEDURE dbo.sp_HR_InsertNhanVien
    @MaNV_Input  VARCHAR(10),
    @MaNV        VARCHAR(10),
    @HoTen       NVARCHAR(100),
    @NgaySinh    DATE          = NULL,
    @Email       VARCHAR(100)  = NULL,
    @MaPhong     VARCHAR(10),
    @Luong       DECIMAL(18,2) = NULL,
    @MaSoThue    VARCHAR(20)   = NULL,
    @TenDangNhap VARCHAR(50),
    @MatKhau     VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @MaPhongHR VARCHAR(10);
    SELECT @MaPhongHR = MaPhong FROM NHANVIEN WHERE MaNV = @MaNV_Input;

    IF @MaPhong = @MaPhongHR
    BEGIN
        RAISERROR(N'Khong duoc them nhan vien vao phong HR', 16, 1);
        RETURN;
    END

    BEGIN TRANSACTION;
    BEGIN TRY
        INSERT INTO NHANVIEN (MaNV, HoTen, NgaySinh, Email, MaPhong, Luong, MaSoThue)
        VALUES (@MaNV, @HoTen, @NgaySinh, @Email, @MaPhong, @Luong, @MaSoThue);

        INSERT INTO TAIKHOAN (TenDangNhap, MatKhauHash, MaNV, MaVaiTro)
        VALUES (@TenDangNhap, HASHBYTES('SHA2_256', @MatKhau), @MaNV, 'EMP');

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        DECLARE @Err NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@Err, 16, 1);
    END CATCH
END;
GO

-- ----------------------------------------------------------
-- SP: HR Staff - Xoa nhan vien ngoai phong HR
-- ----------------------------------------------------------
IF OBJECT_ID('dbo.sp_HR_DeleteNhanVien', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_HR_DeleteNhanVien;
GO
CREATE PROCEDURE dbo.sp_HR_DeleteNhanVien
    @MaNV_Input VARCHAR(10),
    @MaNV       VARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @MaPhongHR VARCHAR(10);
    SELECT @MaPhongHR = MaPhong FROM NHANVIEN WHERE MaNV = @MaNV_Input;

    IF EXISTS (SELECT 1 FROM NHANVIEN WHERE MaNV = @MaNV AND MaPhong = @MaPhongHR)
    BEGIN
        RAISERROR(N'Khong duoc xoa nhan vien cung phong HR', 16, 1);
        RETURN;
    END

    BEGIN TRANSACTION;
    BEGIN TRY
        DELETE FROM TAIKHOAN WHERE MaNV = @MaNV;
        DELETE FROM NHANVIEN  WHERE MaNV = @MaNV;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        DECLARE @Err NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@Err, 16, 1);
    END CATCH
END;
GO

-- ----------------------------------------------------------
-- SP: HR Manager - Xem tat ca nhan vien
-- ----------------------------------------------------------
IF OBJECT_ID('dbo.sp_HRManager_XemTatCaNhanVien', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_HRManager_XemTatCaNhanVien;
GO
CREATE PROCEDURE dbo.sp_HRManager_XemTatCaNhanVien
AS
BEGIN
    SET NOCOUNT ON;
    SELECT MaNV, HoTen, NgaySinh, Email, MaPhong, Luong, MaSoThue
    FROM   NHANVIEN;
END;
GO

-- ----------------------------------------------------------
-- SP: HR Manager - Them nhan vien (ca phong HR)
-- FIX [3]: Bo fn_GetCurrentRole(), kiem soat o backend
-- ----------------------------------------------------------
IF OBJECT_ID('dbo.sp_HRManager_InsertNhanVien', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_HRManager_InsertNhanVien;
GO
CREATE PROCEDURE dbo.sp_HRManager_InsertNhanVien
    @MaNV        VARCHAR(10),
    @HoTen       NVARCHAR(100),
    @NgaySinh    DATE          = NULL,
    @Email       VARCHAR(100)  = NULL,
    @MaPhong     VARCHAR(10),
    @Luong       DECIMAL(18,2) = NULL,
    @MaSoThue    VARCHAR(20)   = NULL,
    @TenDangNhap VARCHAR(50),
    @MatKhau     VARCHAR(100),
    @MaVaiTro    VARCHAR(10)   = 'EMP'
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    BEGIN TRY
        INSERT INTO NHANVIEN (MaNV, HoTen, NgaySinh, Email, MaPhong, Luong, MaSoThue)
        VALUES (@MaNV, @HoTen, @NgaySinh, @Email, @MaPhong, @Luong, @MaSoThue);

        INSERT INTO TAIKHOAN (TenDangNhap, MatKhauHash, MaNV, MaVaiTro)
        VALUES (@TenDangNhap, HASHBYTES('SHA2_256', @MatKhau), @MaNV, @MaVaiTro);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        DECLARE @Err NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@Err, 16, 1);
    END CATCH
END;
GO

-- ----------------------------------------------------------
-- SP: HR Manager - Cap nhat nhan vien (ca phong HR)
-- ----------------------------------------------------------
IF OBJECT_ID('dbo.sp_HRManager_UpdateNhanVien', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_HRManager_UpdateNhanVien;
GO
CREATE PROCEDURE dbo.sp_HRManager_UpdateNhanVien
    @MaNV     VARCHAR(10),
    @HoTen    NVARCHAR(100) = NULL,
    @NgaySinh DATE          = NULL,
    @Email    VARCHAR(100)  = NULL,
    @MaPhong  VARCHAR(10)   = NULL,
    @Luong    DECIMAL(18,2) = NULL,
    @MaSoThue VARCHAR(20)   = NULL,
    @MaVaiTro VARCHAR(10)   = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE NHANVIEN SET
        HoTen    = COALESCE(@HoTen,    HoTen),
        NgaySinh = COALESCE(@NgaySinh, NgaySinh),
        Email    = COALESCE(@Email,    Email),
        MaPhong  = COALESCE(@MaPhong,  MaPhong),
        Luong    = COALESCE(@Luong,    Luong),
        MaSoThue = COALESCE(@MaSoThue, MaSoThue)
    WHERE MaNV = @MaNV;

    IF @MaVaiTro IS NOT NULL
        UPDATE TAIKHOAN SET MaVaiTro = @MaVaiTro WHERE MaNV = @MaNV;
END;
GO

-- ----------------------------------------------------------
-- SP: HR Manager - Xoa nhan vien (ca phong HR)
-- ----------------------------------------------------------
IF OBJECT_ID('dbo.sp_HRManager_DeleteNhanVien', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_HRManager_DeleteNhanVien;
GO
CREATE PROCEDURE dbo.sp_HRManager_DeleteNhanVien
    @MaNV VARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    BEGIN TRY
        DELETE FROM TAIKHOAN WHERE MaNV = @MaNV;
        DELETE FROM NHANVIEN  WHERE MaNV = @MaNV;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        DECLARE @Err NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@Err, 16, 1);
    END CATCH
END;
GO

-- ----------------------------------------------------------
-- SP: HR Manager - Xem nhat ky
-- ----------------------------------------------------------
IF OBJECT_ID('dbo.sp_HRManager_XemNhatKy', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_HRManager_XemNhatKy;
GO
CREATE PROCEDURE dbo.sp_HRManager_XemNhatKy
    @TuNgay  DATE = NULL,
    @DenNgay DATE = NULL,
    @MaNV    VARCHAR(10) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT MaNK, MaNV_ThucHien, HanhDong, BangBiTacDong,
           HangBiThayDoi, CotBiThayDoi, GiaTriCu, GiaTriMoi, ThoiGian
    FROM   NHATKY
    WHERE  (@TuNgay  IS NULL OR CAST(ThoiGian AS DATE) >= @TuNgay)
      AND  (@DenNgay IS NULL OR CAST(ThoiGian AS DATE) <= @DenNgay)
      AND  (@MaNV    IS NULL OR MaNV_ThucHien = @MaNV)
    ORDER BY ThoiGian DESC;
END;
GO

-- ----------------------------------------------------------
-- SP: Admin - Tao tai khoan (them nhan vien + tai khoan)
-- ----------------------------------------------------------
IF OBJECT_ID('dbo.sp_Admin_TaoTaiKhoan', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_Admin_TaoTaiKhoan;
GO
CREATE PROCEDURE dbo.sp_Admin_TaoTaiKhoan
    @MaNV        VARCHAR(10),
    @HoTen       NVARCHAR(100),
    @Email       VARCHAR(100)  = NULL,
    @MaPhong     VARCHAR(10),
    @TenDangNhap VARCHAR(50),
    @MatKhau     VARCHAR(100),
    @MaVaiTro    VARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    BEGIN TRY
        INSERT INTO NHANVIEN (MaNV, HoTen, Email, MaPhong)
        VALUES (@MaNV, @HoTen, @Email, @MaPhong);

        INSERT INTO TAIKHOAN (TenDangNhap, MatKhauHash, MaNV, MaVaiTro)
        VALUES (@TenDangNhap, HASHBYTES('SHA2_256', @MatKhau), @MaNV, @MaVaiTro);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        DECLARE @Err NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@Err, 16, 1);
    END CATCH
END;
GO

-- ----------------------------------------------------------
-- SP: Admin - Khoa / Mo tai khoan
-- ----------------------------------------------------------
IF OBJECT_ID('dbo.sp_Admin_DoiTrangThaiTaiKhoan', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_Admin_DoiTrangThaiTaiKhoan;
GO
CREATE PROCEDURE dbo.sp_Admin_DoiTrangThaiTaiKhoan
    @TenDangNhap VARCHAR(50),
    @TrangThai   BIT   -- 1 = mo, 0 = khoa
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE TAIKHOAN SET TrangThai = @TrangThai WHERE TenDangNhap = @TenDangNhap;
END;
GO

-- ----------------------------------------------------------
-- SP: Admin - Doi vai tro (doi role) cua user
-- ----------------------------------------------------------
IF OBJECT_ID('dbo.sp_Admin_DoiVaiTro', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_Admin_DoiVaiTro;
GO
CREATE PROCEDURE dbo.sp_Admin_DoiVaiTro
    @TenDangNhap VARCHAR(50),
    @MaVaiTroMoi VARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM VAITRO WHERE MaVaiTro = @MaVaiTroMoi)
    BEGIN
        RAISERROR(N'MaVaiTro khong ton tai', 16, 1);
        RETURN;
    END
    UPDATE TAIKHOAN SET MaVaiTro = @MaVaiTroMoi WHERE TenDangNhap = @TenDangNhap;
END;
GO

-- ----------------------------------------------------------
-- SP: Admin - Xem danh sach tai khoan
-- ----------------------------------------------------------
IF OBJECT_ID('dbo.sp_Admin_XemTaiKhoan', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_Admin_XemTaiKhoan;
GO
CREATE PROCEDURE dbo.sp_Admin_XemTaiKhoan
AS
BEGIN
    SET NOCOUNT ON;
    SELECT tk.TenDangNhap, nv.MaNV, nv.HoTen, nv.MaPhong,
           tk.MaVaiTro, vt.TenVaiTro, tk.TrangThai
    FROM   TAIKHOAN tk
    JOIN   NHANVIEN nv ON tk.MaNV = nv.MaNV
    JOIN   VAITRO   vt ON tk.MaVaiTro = vt.MaVaiTro;
END;
GO

-- ============================================================
-- BUOC 11: Trigger Audit Log
-- ============================================================
IF OBJECT_ID('dbo.trg_NhanVien_Update', 'TR') IS NOT NULL
    DROP TRIGGER dbo.trg_NhanVien_Update;
GO
CREATE TRIGGER dbo.trg_NhanVien_Update
ON NHANVIEN
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    -- Ghi log cho tung field thay doi
    IF UPDATE(HoTen)
        INSERT INTO NHATKY (MaNV_ThucHien, HanhDong, BangBiTacDong, HangBiThayDoi, CotBiThayDoi, GiaTriCu, GiaTriMoi)
        SELECT dbo.fn_GetCurrentMaNV(), 'UPDATE', 'NHANVIEN', i.MaNV, 'HoTen', d.HoTen, i.HoTen
        FROM inserted i JOIN deleted d ON i.MaNV = d.MaNV WHERE i.HoTen <> d.HoTen;

    IF UPDATE(Email)
        INSERT INTO NHATKY (MaNV_ThucHien, HanhDong, BangBiTacDong, HangBiThayDoi, CotBiThayDoi, GiaTriCu, GiaTriMoi)
        SELECT dbo.fn_GetCurrentMaNV(), 'UPDATE', 'NHANVIEN', i.MaNV, 'Email', d.Email, i.Email
        FROM inserted i JOIN deleted d ON i.MaNV = d.MaNV WHERE ISNULL(i.Email,'') <> ISNULL(d.Email,'');

    IF UPDATE(MaPhong)
        INSERT INTO NHATKY (MaNV_ThucHien, HanhDong, BangBiTacDong, HangBiThayDoi, CotBiThayDoi, GiaTriCu, GiaTriMoi)
        SELECT dbo.fn_GetCurrentMaNV(), 'UPDATE', 'NHANVIEN', i.MaNV, 'MaPhong', d.MaPhong, i.MaPhong
        FROM inserted i JOIN deleted d ON i.MaNV = d.MaNV WHERE ISNULL(i.MaPhong,'') <> ISNULL(d.MaPhong,'');

    IF UPDATE(Luong)
        INSERT INTO NHATKY (MaNV_ThucHien, HanhDong, BangBiTacDong, HangBiThayDoi, CotBiThayDoi, GiaTriCu, GiaTriMoi)
        SELECT dbo.fn_GetCurrentMaNV(), 'UPDATE', 'NHANVIEN', i.MaNV, 'Luong',
               CAST(d.Luong AS NVARCHAR), CAST(i.Luong AS NVARCHAR)
        FROM inserted i JOIN deleted d ON i.MaNV = d.MaNV WHERE ISNULL(i.Luong,0) <> ISNULL(d.Luong,0);
END;
GO

IF OBJECT_ID('dbo.trg_NhanVien_Delete', 'TR') IS NOT NULL
    DROP TRIGGER dbo.trg_NhanVien_Delete;
GO
CREATE TRIGGER dbo.trg_NhanVien_Delete
ON NHANVIEN
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO NHATKY (MaNV_ThucHien, HanhDong, BangBiTacDong, HangBiThayDoi, CotBiThayDoi, GiaTriCu, GiaTriMoi)
    SELECT dbo.fn_GetCurrentMaNV(), 'DELETE', 'NHANVIEN', d.MaNV, 'ALL',
           d.HoTen + ' | ' + ISNULL(d.Email,'') + ' | phong ' + ISNULL(d.MaPhong,''), NULL
    FROM deleted d;
END;
GO

IF OBJECT_ID('dbo.trg_NhanVien_Insert', 'TR') IS NOT NULL
    DROP TRIGGER dbo.trg_NhanVien_Insert;
GO
CREATE TRIGGER dbo.trg_NhanVien_Insert
ON NHANVIEN
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO NHATKY (MaNV_ThucHien, HanhDong, BangBiTacDong, HangBiThayDoi, CotBiThayDoi, GiaTriCu, GiaTriMoi)
    SELECT dbo.fn_GetCurrentMaNV(), 'INSERT', 'NHANVIEN', i.MaNV, 'ALL',
           NULL, i.HoTen + ' | ' + ISNULL(i.Email,'') + ' | phong ' + ISNULL(i.MaPhong,'')
    FROM inserted i;
END;
GO

-- ============================================================
-- BUOC 12: Cap quyen EXECUTE cho tung Role
-- ============================================================

-- Role_Employee
GRANT EXECUTE ON dbo.sp_Employee_XemThongTinCaNhan    TO Role_Employee;
GRANT EXECUTE ON dbo.sp_Employee_XemNhanVienCungPhong TO Role_Employee;

-- Role_Manager (ke thua Employee + xem luong cung phong)
GRANT EXECUTE ON dbo.sp_Employee_XemThongTinCaNhan    TO Role_Manager;
GRANT EXECUTE ON dbo.sp_Manager_XemNhanVienCungPhong  TO Role_Manager;

-- Role_Finance (ke thua Employee + xem luong toan cong ty)
GRANT EXECUTE ON dbo.sp_Employee_XemThongTinCaNhan    TO Role_Finance;
GRANT EXECUTE ON dbo.sp_Employee_XemNhanVienCungPhong TO Role_Finance;
GRANT EXECUTE ON dbo.sp_Finance_XemLuongCongTy        TO Role_Finance;

-- Role_HR_Staff (xem + sua ngoai phong)
GRANT EXECUTE ON dbo.sp_Employee_XemThongTinCaNhan    TO Role_HR_Staff;
GRANT EXECUTE ON dbo.sp_HR_XemNhanVienNgoaiPhong      TO Role_HR_Staff;
GRANT EXECUTE ON dbo.sp_HR_InsertNhanVien             TO Role_HR_Staff;
GRANT EXECUTE ON dbo.sp_HR_UpdateNhanVien             TO Role_HR_Staff;
GRANT EXECUTE ON dbo.sp_HR_DeleteNhanVien             TO Role_HR_Staff;

-- Role_HR_Manager (xem + sua toan cong ty + xem log)
GRANT EXECUTE ON dbo.sp_Employee_XemThongTinCaNhan    TO Role_HR_Manager;
GRANT EXECUTE ON dbo.sp_HRManager_XemTatCaNhanVien    TO Role_HR_Manager;
GRANT EXECUTE ON dbo.sp_HRManager_InsertNhanVien      TO Role_HR_Manager;
GRANT EXECUTE ON dbo.sp_HRManager_UpdateNhanVien      TO Role_HR_Manager;
GRANT EXECUTE ON dbo.sp_HRManager_DeleteNhanVien      TO Role_HR_Manager;
GRANT EXECUTE ON dbo.sp_HRManager_XemNhatKy           TO Role_HR_Manager;
GO

-- Role_Admin (toan quyen quan ly tai khoan)
GRANT EXECUTE ON dbo.sp_Admin_TaoTaiKhoan           TO Role_Admin;
GRANT EXECUTE ON dbo.sp_Admin_DoiTrangThaiTaiKhoan  TO Role_Admin;
GRANT EXECUTE ON dbo.sp_Admin_DoiVaiTro             TO Role_Admin;
GRANT EXECUTE ON dbo.sp_Admin_XemTaiKhoan           TO Role_Admin;
GO

-- ============================================================
-- BUOC 13: Kiem tra (co the bo comment de chay test)
-- ============================================================

-- Test 1: Kiem tra TDE
-- SELECT DB_NAME(database_id) AS DatabaseName, encryption_state
-- FROM sys.dm_database_encryption_keys WHERE database_id = DB_ID('QL_NHANVIEN');

-- Test 2: Bao loi Access Denied
-- EXECUTE AS USER = 'user_employee';
-- SELECT * FROM NHANVIEN;  -- phai bao loi
-- REVERT;

-- Test 3: Employee chi thay chinh minh
-- EXECUTE AS USER = 'user_employee';
-- EXEC dbo.sp_Employee_XemThongTinCaNhan 'NV01';
-- REVERT;

-- Test 4: Manager xem luong ca phong
-- FIX [8]: sua ten SP dung (sp_Manager_XemNhanVienCungPhong)
-- EXECUTE AS USER = 'user_manager';
-- EXEC dbo.sp_Manager_XemNhanVienCungPhong 'NV02';
-- REVERT;

-- Test 5: Dang nhap
-- EXEC dbo.sp_Auth_Login 'nv01', '123456';