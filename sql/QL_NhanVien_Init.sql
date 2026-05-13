USE master;
GO

-- Drop database 
IF DB_ID('QL_NHANVIEN') IS NOT NULL
BEGIN
    ALTER DATABASE QL_NHANVIEN SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE QL_NHANVIEN;
END
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
        MaNV          VARCHAR(10)    PRIMARY KEY,
        HoTen         NVARCHAR(100)  NOT NULL,
        NgaySinh      DATE           NULL,
        Email         VARCHAR(100)   UNIQUE,
        SoDienThoai   VARCHAR(15)    NULL,
        GioiTinh      VARCHAR(10)    NULL,
        DiaChi        NVARCHAR(255)  NULL,
        CCCD          VARCHAR(20)    NULL,
        MaPhong       VARCHAR(10),
        ChucVu        NVARCHAR(100)  NULL,
        LoaiNhanVien  VARCHAR(20)    NOT NULL CONSTRAINT DF_NV_LoaiNhanVien DEFAULT 'FULLTIME',
        TrangThai     VARCHAR(20)    NOT NULL CONSTRAINT DF_NV_TrangThai DEFAULT 'ACTIVE',
        NgayVaoLam    DATE           NULL CONSTRAINT DF_NV_NgayVaoLam DEFAULT CAST(GETDATE() AS DATE),
        Luong         DECIMAL(18,2)  NULL,
        MaSoThue      VARCHAR(20),
        AvatarUrl     NVARCHAR(500)  NULL,
        CreatedAt     DATETIME       NOT NULL CONSTRAINT DF_NV_CreatedAt DEFAULT GETDATE(),
        UpdatedAt     DATETIME       NOT NULL CONSTRAINT DF_NV_UpdatedAt DEFAULT GETDATE(),

        CONSTRAINT FK_NV_PHONG FOREIGN KEY (MaPhong) REFERENCES PHONGBAN(MaPhong),
        CONSTRAINT CK_NV_GioiTinh CHECK (GioiTinh IS NULL OR GioiTinh IN ('NAM', 'NU', 'KHAC')),
        CONSTRAINT CK_NV_LoaiNhanVien CHECK (LoaiNhanVien IN ('FULLTIME', 'PARTTIME', 'INTERN')),
        CONSTRAINT CK_NV_TrangThai CHECK (TrangThai IN ('ACTIVE', 'INACTIVE'))
    );
END
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'TAIKHOAN')
BEGIN
    CREATE TABLE TAIKHOAN (
        TenDangNhap         VARCHAR(50)    PRIMARY KEY,
        MatKhauHash         VARBINARY(256) NOT NULL,
        MaNV                VARCHAR(10)    UNIQUE,
        MaVaiTro            VARCHAR(10),
        TrangThai           BIT            DEFAULT 1,
        CreatedAt           DATETIME       NOT NULL CONSTRAINT DF_TK_CreatedAt DEFAULT GETDATE(),
        LastLogin           DATETIME       NULL,
        FailedLoginAttempts INT            NOT NULL CONSTRAINT DF_TK_FailedLoginAttempts DEFAULT 0,

        CONSTRAINT FK_TK_NV FOREIGN KEY (MaNV) REFERENCES NHANVIEN(MaNV),
        CONSTRAINT FK_TK_VT FOREIGN KEY (MaVaiTro) REFERENCES VAITRO(MaVaiTro)
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

        CONSTRAINT FK_NK_NV FOREIGN KEY (MaNV_ThucHien) REFERENCES NHANVIEN(MaNV)
    );
END
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_PHONG_TRUONGPHONG')
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
IF OBJECT_ID('dbo.fn_GetCurrentMaNV', 'FN') IS NOT NULL DROP FUNCTION dbo.fn_GetCurrentMaNV;
GO
CREATE FUNCTION dbo.fn_GetCurrentMaNV()
RETURNS VARCHAR(10)
AS
BEGIN
    RETURN CAST(SESSION_CONTEXT(N'MaNV') AS VARCHAR(10));
END;
GO

-- 5.2 Ham lay MaVaiTro hien tai tu Session Context
IF OBJECT_ID('dbo.fn_GetCurrentRole', 'FN') IS NOT NULL DROP FUNCTION dbo.fn_GetCurrentRole;
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

-- ============================================================
-- BUOC 7: Tao Login va User (dung chung 1 login test cho Backend)
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

-- 7.1 Tạo 1 User chính thức cho Backend (Node.js) kết nối
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'test_user')
    CREATE USER test_user FOR LOGIN test_login;
GO

ALTER ROLE Role_Employee    ADD MEMBER test_user;
ALTER ROLE Role_Manager     ADD MEMBER test_user;
ALTER ROLE Role_Finance     ADD MEMBER test_user;
ALTER ROLE Role_HR_Staff    ADD MEMBER test_user;
ALTER ROLE Role_HR_Manager  ADD MEMBER test_user;
GO

-- 7.2 Tạo các User "Ảo" (WITHOUT LOGIN) để Test RBAC
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'user_employee')
    CREATE USER user_employee WITHOUT LOGIN;
GO
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'user_manager')
    CREATE USER user_manager WITHOUT LOGIN;
GO
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'user_finance')
    CREATE USER user_finance WITHOUT LOGIN;
GO
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'user_hr_staff')
    CREATE USER user_hr_staff WITHOUT LOGIN;
GO
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'user_hr_manager')
    CREATE USER user_hr_manager WITHOUT LOGIN;
GO

ALTER ROLE Role_Employee    ADD MEMBER user_employee;
ALTER ROLE Role_Manager     ADD MEMBER user_manager;
ALTER ROLE Role_Finance     ADD MEMBER user_finance;
ALTER ROLE Role_HR_Staff    ADD MEMBER user_hr_staff;
ALTER ROLE Role_HR_Manager  ADD MEMBER user_hr_manager;
GO

-- ============================================================
-- BUOC 8: Chan truy cap truc tiep bang nhay cam
-- ============================================================
DENY SELECT, INSERT, UPDATE, DELETE ON NHANVIEN TO PUBLIC;
DENY SELECT, INSERT, UPDATE, DELETE ON TAIKHOAN TO PUBLIC;
GO

-- ============================================================
-- BUOC 9: Cac Stored Procedure
-- ============================================================

-- 9.1 Dang nhap & Kiem tra token
IF OBJECT_ID('dbo.sp_Auth_Login', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_Auth_Login;
GO
CREATE PROCEDURE dbo.sp_Auth_Login
    @TenDangNhap VARCHAR(50),
    @MatKhau     VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT 1
        FROM TAIKHOAN tk
        JOIN NHANVIEN nv ON tk.MaNV = nv.MaNV
        WHERE tk.TenDangNhap = @TenDangNhap
          AND tk.MatKhauHash = HASHBYTES('SHA2_256', @MatKhau)
          AND tk.TrangThai = 1
          AND nv.TrangThai = 'ACTIVE'
    )
    BEGIN
        UPDATE TAIKHOAN SET LastLogin = GETDATE(), FailedLoginAttempts = 0 WHERE TenDangNhap = @TenDangNhap;
        SELECT 'Success' AS Status, tk.TenDangNhap, nv.MaNV, nv.HoTen, nv.Email, nv.MaPhong,
               pb.TenPhong AS TenPhongBan, tk.MaVaiTro, vt.TenVaiTro, tk.TrangThai AS TrangThaiTaiKhoan,
               CAST(CASE WHEN tk.TrangThai = 1 THEN 0 ELSE 1 END AS BIT) AS IsLocked
        FROM TAIKHOAN tk
        JOIN NHANVIEN nv ON tk.MaNV = nv.MaNV
        LEFT JOIN PHONGBAN pb ON nv.MaPhong = pb.MaPhong
        LEFT JOIN VAITRO vt ON tk.MaVaiTro = vt.MaVaiTro
        WHERE tk.TenDangNhap = @TenDangNhap;
    END
    ELSE
    BEGIN
        UPDATE TAIKHOAN SET FailedLoginAttempts = FailedLoginAttempts + 1 WHERE TenDangNhap = @TenDangNhap;
        SELECT 'Fail' AS Status, NULL AS MaNV, NULL AS MaVaiTro;
    END
END;
GO

IF OBJECT_ID('dbo.sp_Auth_Me', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_Auth_Me;
GO
CREATE PROCEDURE dbo.sp_Auth_Me
    @MaNV_Input VARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT tk.TenDangNhap, nv.MaNV, nv.HoTen, nv.Email, nv.SoDienThoai, nv.MaPhong,
           pb.TenPhong AS TenPhongBan, tk.MaVaiTro, vt.TenVaiTro, tk.TrangThai AS TrangThaiTaiKhoan,
           CAST(CASE WHEN tk.TrangThai = 1 THEN 0 ELSE 1 END AS BIT) AS IsLocked, tk.LastLogin
    FROM NHANVIEN nv
    LEFT JOIN TAIKHOAN tk ON nv.MaNV = tk.MaNV
    LEFT JOIN PHONGBAN pb ON nv.MaPhong = pb.MaPhong
    LEFT JOIN VAITRO vt ON tk.MaVaiTro = vt.MaVaiTro
    WHERE nv.MaNV = @MaNV_Input;
END;
GO
-- 9.2 Ho so va Dong nghiep (EMP/MAN)
IF OBJECT_ID('dbo.sp_Employee_XemThongTinCaNhan', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_Employee_XemThongTinCaNhan;
GO
CREATE PROCEDURE dbo.sp_Employee_XemThongTinCaNhan
    @MaNV_Input VARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT nv.MaNV, nv.HoTen, nv.NgaySinh, nv.Email, nv.SoDienThoai, nv.GioiTinh,
           nv.DiaChi, nv.CCCD, nv.MaSoThue, nv.MaPhong, pb.TenPhong AS TenPhongBan,
           mgr.HoTen AS managerName, -
           nv.ChucVu, nv.LoaiNhanVien, nv.TrangThai, nv.NgayVaoLam, nv.AvatarUrl,
           nv.Luong, tk.TenDangNhap, tk.MaVaiTro, vt.TenVaiTro, tk.TrangThai AS TrangThaiTaiKhoan,
           CAST(CASE WHEN tk.TrangThai = 1 THEN 0 ELSE 1 END AS BIT) AS IsLocked,
           tk.LastLogin, nv.CreatedAt, nv.UpdatedAt
    FROM NHANVIEN nv
    LEFT JOIN PHONGBAN pb ON nv.MaPhong = pb.MaPhong
    LEFT JOIN NHANVIEN mgr ON pb.MaTruongPhong = mgr.MaNV 
    LEFT JOIN TAIKHOAN tk ON nv.MaNV = tk.MaNV
    LEFT JOIN VAITRO vt ON tk.MaVaiTro = vt.MaVaiTro
    WHERE nv.MaNV = @MaNV_Input;
END;
GO

IF OBJECT_ID('dbo.sp_Employee_XemNhanVienCungPhong', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_Employee_XemNhanVienCungPhong;
GO
CREATE PROCEDURE dbo.sp_Employee_XemNhanVienCungPhong
    @MaNV_Input VARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @MaPhong VARCHAR(10);
    SELECT @MaPhong = MaPhong FROM NHANVIEN WHERE MaNV = @MaNV_Input;

    SELECT nv.MaNV, nv.HoTen, nv.NgaySinh, nv.Email, nv.SoDienThoai, nv.GioiTinh,
           nv.DiaChi, nv.MaPhong, pb.TenPhong AS TenPhongBan, nv.ChucVu, nv.LoaiNhanVien, 
           nv.TrangThai, nv.NgayVaoLam, nv.AvatarUrl, tk.MaVaiTro, vt.TenVaiTro,
           tk.TrangThai AS TrangThaiTaiKhoan, CAST(CASE WHEN tk.TrangThai = 1 THEN 0 ELSE 1 END AS BIT) AS IsLocked
    FROM NHANVIEN nv
    LEFT JOIN PHONGBAN pb ON nv.MaPhong = pb.MaPhong
    LEFT JOIN TAIKHOAN tk ON nv.MaNV = tk.MaNV
    LEFT JOIN VAITRO vt ON tk.MaVaiTro = vt.MaVaiTro
    WHERE nv.MaPhong = @MaPhong AND nv.TrangThai = 'ACTIVE';
END;
GO

IF OBJECT_ID('dbo.sp_Manager_XemNhanVienCungPhong', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_Manager_XemNhanVienCungPhong;
GO
CREATE PROCEDURE dbo.sp_Manager_XemNhanVienCungPhong
    @MaNV_Input VARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @MaPhong VARCHAR(10);
    SELECT @MaPhong = MaPhong FROM NHANVIEN WHERE MaNV = @MaNV_Input;

    SELECT nv.MaNV, nv.HoTen, nv.NgaySinh, nv.Email, nv.SoDienThoai, nv.GioiTinh,
           nv.DiaChi, nv.CCCD, nv.MaSoThue, nv.MaPhong, pb.TenPhong AS TenPhongBan,
           nv.ChucVu, nv.LoaiNhanVien, nv.TrangThai, nv.NgayVaoLam, nv.AvatarUrl,
           nv.Luong, tk.MaVaiTro, vt.TenVaiTro, tk.TrangThai AS TrangThaiTaiKhoan,
           CAST(CASE WHEN tk.TrangThai = 1 THEN 0 ELSE 1 END AS BIT) AS IsLocked,
           nv.CreatedAt, nv.UpdatedAt
    FROM NHANVIEN nv
    LEFT JOIN PHONGBAN pb ON nv.MaPhong = pb.MaPhong
    LEFT JOIN TAIKHOAN tk ON nv.MaNV = tk.MaNV
    LEFT JOIN VAITRO vt ON tk.MaVaiTro = vt.MaVaiTro
    WHERE nv.MaPhong = @MaPhong;
END;
GO

-- 9.3 Ke toan (FIN)
IF OBJECT_ID('dbo.sp_Finance_XemLuongCongTy', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_Finance_XemLuongCongTy;
GO
CREATE PROCEDURE dbo.sp_Finance_XemLuongCongTy
    @MaNV_Input VARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @MaPhongFinance VARCHAR(10);
    SELECT @MaPhongFinance = MaPhong FROM NHANVIEN WHERE MaNV = @MaNV_Input;

    SELECT nv.MaNV,
           CASE WHEN nv.MaPhong = @MaPhongFinance THEN nv.HoTen ELSE NULL END AS HoTen,
           CASE WHEN nv.MaPhong = @MaPhongFinance THEN nv.NgaySinh ELSE NULL END AS NgaySinh,
           CASE WHEN nv.MaPhong = @MaPhongFinance THEN nv.Email ELSE NULL END AS Email,
           CASE WHEN nv.MaPhong = @MaPhongFinance THEN nv.SoDienThoai ELSE NULL END AS SoDienThoai,
           CASE WHEN nv.MaPhong = @MaPhongFinance THEN nv.MaPhong ELSE NULL END AS MaPhong,
           CASE WHEN nv.MaPhong = @MaPhongFinance THEN pb.TenPhong ELSE NULL END AS TenPhongBan,
           CASE WHEN nv.MaPhong = @MaPhongFinance THEN nv.ChucVu ELSE NULL END AS ChucVu,
           nv.Luong, nv.MaSoThue, nv.TrangThai, nv.LoaiNhanVien
    FROM NHANVIEN nv
    LEFT JOIN PHONGBAN pb ON nv.MaPhong = pb.MaPhong;
END;
GO

-- 9.4 Nhan su (HR & HRM)
IF OBJECT_ID('dbo.sp_HR_XemNhanVienNgoaiPhong', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_HR_XemNhanVienNgoaiPhong;
GO
CREATE PROCEDURE dbo.sp_HR_XemNhanVienNgoaiPhong
    @MaNV_Input VARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @MaPhongHR VARCHAR(10);
    SELECT @MaPhongHR = MaPhong FROM NHANVIEN WHERE MaNV = @MaNV_Input;

    SELECT nv.MaNV, nv.HoTen, nv.NgaySinh, nv.Email, nv.SoDienThoai, nv.GioiTinh,
           nv.DiaChi, nv.CCCD, nv.MaSoThue, nv.MaPhong, pb.TenPhong AS TenPhongBan,
           nv.ChucVu, nv.LoaiNhanVien, nv.TrangThai, nv.NgayVaoLam, nv.AvatarUrl,
           nv.Luong, tk.TenDangNhap, tk.MaVaiTro, vt.TenVaiTro, tk.TrangThai AS TrangThaiTaiKhoan,
           CAST(CASE WHEN tk.TrangThai = 1 THEN 0 ELSE 1 END AS BIT) AS IsLocked,
           nv.CreatedAt, nv.UpdatedAt
    FROM NHANVIEN nv
    LEFT JOIN PHONGBAN pb ON nv.MaPhong = pb.MaPhong
    LEFT JOIN TAIKHOAN tk ON nv.MaNV = tk.MaNV
    LEFT JOIN VAITRO vt ON tk.MaVaiTro = vt.MaVaiTro
    WHERE nv.MaPhong <> @MaPhongHR;
END;
GO

IF OBJECT_ID('dbo.sp_HRManager_XemTatCaNhanVien', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_HRManager_XemTatCaNhanVien;
GO
CREATE PROCEDURE dbo.sp_HRManager_XemTatCaNhanVien
AS
BEGIN
    SET NOCOUNT ON;
    SELECT nv.MaNV, nv.HoTen, nv.NgaySinh, nv.Email, nv.SoDienThoai, nv.GioiTinh,
           nv.DiaChi, nv.CCCD, nv.MaSoThue, nv.MaPhong, pb.TenPhong AS TenPhongBan,
           nv.ChucVu, nv.LoaiNhanVien, nv.TrangThai, nv.NgayVaoLam, nv.AvatarUrl,
           nv.Luong, tk.TenDangNhap, tk.MaVaiTro, vt.TenVaiTro, tk.TrangThai AS TrangThaiTaiKhoan,
           CAST(CASE WHEN tk.TrangThai = 1 THEN 0 ELSE 1 END AS BIT) AS IsLocked,
           tk.LastLogin, tk.FailedLoginAttempts, nv.CreatedAt, nv.UpdatedAt
    FROM NHANVIEN nv
    LEFT JOIN PHONGBAN pb ON nv.MaPhong = pb.MaPhong
    LEFT JOIN TAIKHOAN tk ON nv.MaNV = tk.MaNV
    LEFT JOIN VAITRO vt ON tk.MaVaiTro = vt.MaVaiTro;
END;
GO

IF OBJECT_ID('dbo.sp_HR_UpdateNhanVien', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_HR_UpdateNhanVien;
GO
CREATE PROCEDURE dbo.sp_HR_UpdateNhanVien
    @MaNV_Input    VARCHAR(10),
    @MaNV          VARCHAR(10),
    @HoTen         NVARCHAR(100) = NULL,
    @NgaySinh      DATE          = NULL,
    @Email         VARCHAR(100)  = NULL,
    @SoDienThoai   VARCHAR(15)   = NULL,
    @GioiTinh      VARCHAR(10)   = NULL,
    @DiaChi        NVARCHAR(255) = NULL,
    @CCCD          VARCHAR(20)   = NULL,
    @MaPhong       VARCHAR(10)   = NULL,
    @ChucVu        NVARCHAR(100) = NULL,
    @LoaiNhanVien  VARCHAR(20)   = NULL,
    @TrangThai     VARCHAR(20)   = NULL,
    @NgayVaoLam    DATE          = NULL,
    @Luong         DECIMAL(18,2) = NULL,
    @MaSoThue      VARCHAR(20)   = NULL,
    @AvatarUrl     NVARCHAR(500) = NULL
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
        HoTen = COALESCE(@HoTen, HoTen), NgaySinh = COALESCE(@NgaySinh, NgaySinh), Email = COALESCE(@Email, Email),
        SoDienThoai = COALESCE(@SoDienThoai, SoDienThoai), GioiTinh = COALESCE(@GioiTinh, GioiTinh),
        DiaChi = COALESCE(@DiaChi, DiaChi), CCCD = COALESCE(@CCCD, CCCD), MaPhong = COALESCE(@MaPhong, MaPhong),
        ChucVu = COALESCE(@ChucVu, ChucVu), LoaiNhanVien = COALESCE(@LoaiNhanVien, LoaiNhanVien),
        TrangThai = COALESCE(@TrangThai, TrangThai), NgayVaoLam = COALESCE(@NgayVaoLam, NgayVaoLam),
        Luong = COALESCE(@Luong, Luong), MaSoThue = COALESCE(@MaSoThue, MaSoThue),
        AvatarUrl = COALESCE(@AvatarUrl, AvatarUrl), UpdatedAt = GETDATE()
    WHERE MaNV = @MaNV;
END;
GO

IF OBJECT_ID('dbo.sp_HR_InsertNhanVien', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_HR_InsertNhanVien;
GO
CREATE PROCEDURE dbo.sp_HR_InsertNhanVien
    @MaNV_Input    VARCHAR(10),
    @MaNV          VARCHAR(10),
    @HoTen         NVARCHAR(100),
    @NgaySinh      DATE          = NULL,
    @Email         VARCHAR(100)  = NULL,
    @SoDienThoai   VARCHAR(15)   = NULL,
    @GioiTinh      VARCHAR(10)   = NULL,
    @DiaChi        NVARCHAR(255) = NULL,
    @CCCD          VARCHAR(20)   = NULL,
    @MaPhong       VARCHAR(10),
    @ChucVu        NVARCHAR(100) = NULL,
    @LoaiNhanVien  VARCHAR(20)   = 'FULLTIME',
    @TrangThai     VARCHAR(20)   = 'ACTIVE',
    @NgayVaoLam    DATE          = NULL,
    @Luong         DECIMAL(18,2) = NULL,
    @MaSoThue      VARCHAR(20)   = NULL,
    @AvatarUrl     NVARCHAR(500) = NULL,
    @TenDangNhap   VARCHAR(50),
    @MatKhau       VARCHAR(100)
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
        INSERT INTO NHANVIEN (MaNV, HoTen, NgaySinh, Email, SoDienThoai, GioiTinh, DiaChi, CCCD,
            MaPhong, ChucVu, LoaiNhanVien, TrangThai, NgayVaoLam, Luong, MaSoThue, AvatarUrl)
        VALUES (@MaNV, @HoTen, @NgaySinh, @Email, @SoDienThoai, @GioiTinh, @DiaChi, @CCCD,
            @MaPhong, @ChucVu, COALESCE(@LoaiNhanVien, 'FULLTIME'), COALESCE(@TrangThai, 'ACTIVE'),
            COALESCE(@NgayVaoLam, CAST(GETDATE() AS DATE)), @Luong, @MaSoThue, @AvatarUrl);

        INSERT INTO TAIKHOAN (TenDangNhap, MatKhauHash, MaNV, MaVaiTro, TrangThai)
        VALUES (@TenDangNhap, HASHBYTES('SHA2_256', @MatKhau), @MaNV, 'EMP', 1);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        DECLARE @Err NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@Err, 16, 1);
    END CATCH
END;
GO

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

IF OBJECT_ID('dbo.sp_HRManager_InsertNhanVien', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_HRManager_InsertNhanVien;
GO
CREATE PROCEDURE dbo.sp_HRManager_InsertNhanVien
    @MaNV          VARCHAR(10),
    @HoTen         NVARCHAR(100),
    @NgaySinh      DATE          = NULL,
    @Email         VARCHAR(100)  = NULL,
    @SoDienThoai   VARCHAR(15)   = NULL,
    @GioiTinh      VARCHAR(10)   = NULL,
    @DiaChi        NVARCHAR(255) = NULL,
    @CCCD          VARCHAR(20)   = NULL,
    @MaPhong       VARCHAR(10),
    @ChucVu        NVARCHAR(100) = NULL,
    @LoaiNhanVien  VARCHAR(20)   = 'FULLTIME',
    @TrangThai     VARCHAR(20)   = 'ACTIVE',
    @NgayVaoLam    DATE          = NULL,
    @Luong         DECIMAL(18,2) = NULL,
    @MaSoThue      VARCHAR(20)   = NULL,
    @AvatarUrl     NVARCHAR(500) = NULL,
    @TenDangNhap   VARCHAR(50),
    @MatKhau       VARCHAR(100),
    @MaVaiTro      VARCHAR(10)   = 'EMP'
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    BEGIN TRY
        INSERT INTO NHANVIEN (MaNV, HoTen, NgaySinh, Email, SoDienThoai, GioiTinh, DiaChi, CCCD,
            MaPhong, ChucVu, LoaiNhanVien, TrangThai, NgayVaoLam, Luong, MaSoThue, AvatarUrl)
        VALUES (@MaNV, @HoTen, @NgaySinh, @Email, @SoDienThoai, @GioiTinh, @DiaChi, @CCCD,
            @MaPhong, @ChucVu, COALESCE(@LoaiNhanVien, 'FULLTIME'), COALESCE(@TrangThai, 'ACTIVE'),
            COALESCE(@NgayVaoLam, CAST(GETDATE() AS DATE)), @Luong, @MaSoThue, @AvatarUrl);

        INSERT INTO TAIKHOAN (TenDangNhap, MatKhauHash, MaNV, MaVaiTro, TrangThai)
        VALUES (@TenDangNhap, HASHBYTES('SHA2_256', @MatKhau), @MaNV, @MaVaiTro, 1);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        DECLARE @Err NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@Err, 16, 1);
    END CATCH
END;
GO

IF OBJECT_ID('dbo.sp_HRManager_UpdateNhanVien', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_HRManager_UpdateNhanVien;
GO
CREATE PROCEDURE dbo.sp_HRManager_UpdateNhanVien
    @MaNV          VARCHAR(10),
    @HoTen         NVARCHAR(100) = NULL,
    @NgaySinh      DATE          = NULL,
    @Email         VARCHAR(100)  = NULL,
    @SoDienThoai   VARCHAR(15)   = NULL,
    @GioiTinh      VARCHAR(10)   = NULL,
    @DiaChi        NVARCHAR(255) = NULL,
    @CCCD          VARCHAR(20)   = NULL,
    @MaPhong       VARCHAR(10)   = NULL,
    @ChucVu        NVARCHAR(100) = NULL,
    @LoaiNhanVien  VARCHAR(20)   = NULL,
    @TrangThai     VARCHAR(20)   = NULL,
    @NgayVaoLam    DATE          = NULL,
    @Luong         DECIMAL(18,2) = NULL,
    @MaSoThue      VARCHAR(20)   = NULL,
    @AvatarUrl     NVARCHAR(500) = NULL,
    @MaVaiTro      VARCHAR(10)   = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE NHANVIEN SET
        HoTen = COALESCE(@HoTen, HoTen), NgaySinh = COALESCE(@NgaySinh, NgaySinh), Email = COALESCE(@Email, Email),
        SoDienThoai = COALESCE(@SoDienThoai, SoDienThoai), GioiTinh = COALESCE(@GioiTinh, GioiTinh),
        DiaChi = COALESCE(@DiaChi, DiaChi), CCCD = COALESCE(@CCCD, CCCD), MaPhong = COALESCE(@MaPhong, MaPhong),
        ChucVu = COALESCE(@ChucVu, ChucVu), LoaiNhanVien = COALESCE(@LoaiNhanVien, LoaiNhanVien),
        TrangThai = COALESCE(@TrangThai, TrangThai), NgayVaoLam = COALESCE(@NgayVaoLam, NgayVaoLam),
        Luong = COALESCE(@Luong, Luong), MaSoThue = COALESCE(@MaSoThue, MaSoThue),
        AvatarUrl = COALESCE(@AvatarUrl, AvatarUrl), UpdatedAt = GETDATE()
    WHERE MaNV = @MaNV;

    IF @MaVaiTro IS NOT NULL
        UPDATE TAIKHOAN SET MaVaiTro = @MaVaiTro WHERE MaNV = @MaNV;
END;
GO

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

IF OBJECT_ID('dbo.sp_HRManager_XemNhatKy', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_HRManager_XemNhatKy;
GO
CREATE PROCEDURE dbo.sp_HRManager_XemNhatKy
    @TuNgay  DATE = NULL,
    @DenNgay DATE = NULL,
    @MaNV    VARCHAR(10) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT nk.MaNK AS MaLog, nk.MaNV_ThucHien AS ActorId, nv.HoTen AS ActorName, tk.TenDangNhap,
           nk.HanhDong, nk.BangBiTacDong AS TableName, nk.HangBiThayDoi AS TargetId,
           nvTarget.HoTen AS TargetName, nk.CotBiThayDoi, nk.GiaTriCu, nk.GiaTriMoi,
           CONCAT(nk.HanhDong, N' ', nk.CotBiThayDoi, N' của ', nk.HangBiThayDoi) AS NoiDung,
           nk.ThoiGian
    FROM NHATKY nk
    LEFT JOIN NHANVIEN nv ON nk.MaNV_ThucHien = nv.MaNV
    LEFT JOIN TAIKHOAN tk ON nk.MaNV_ThucHien = tk.MaNV
    LEFT JOIN NHANVIEN nvTarget ON nk.HangBiThayDoi = nvTarget.MaNV
    WHERE (@TuNgay IS NULL OR CAST(nk.ThoiGian AS DATE) >= @TuNgay)
      AND (@DenNgay IS NULL OR CAST(nk.ThoiGian AS DATE) <= @DenNgay)
      AND (@MaNV IS NULL OR nk.MaNV_ThucHien = @MaNV)
    ORDER BY nk.ThoiGian DESC;
END;
GO

IF OBJECT_ID('dbo.sp_HRManager_XemTaiKhoan', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_HRManager_XemTaiKhoan;
GO
CREATE PROCEDURE dbo.sp_HRManager_XemTaiKhoan
AS
BEGIN
    SET NOCOUNT ON;
    SELECT tk.TenDangNhap, nv.MaNV, nv.HoTen, nv.Email, nv.SoDienThoai, nv.MaPhong,
           pb.TenPhong AS TenPhongBan, tk.MaVaiTro, vt.TenVaiTro, tk.TrangThai,
           CAST(CASE WHEN tk.TrangThai = 1 THEN 0 ELSE 1 END AS BIT) AS IsLocked,
           tk.CreatedAt, tk.LastLogin, tk.FailedLoginAttempts
    FROM TAIKHOAN tk
    JOIN NHANVIEN nv ON tk.MaNV = nv.MaNV
    LEFT JOIN PHONGBAN pb ON nv.MaPhong = pb.MaPhong
    LEFT JOIN VAITRO vt ON tk.MaVaiTro = vt.MaVaiTro
    ORDER BY tk.CreatedAt DESC;
END;
GO

IF OBJECT_ID('dbo.sp_HRManager_DoiTrangThaiTaiKhoan', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_HRManager_DoiTrangThaiTaiKhoan;
GO
CREATE PROCEDURE dbo.sp_HRManager_DoiTrangThaiTaiKhoan
    @TenDangNhap VARCHAR(50),
    @TrangThai   BIT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE TAIKHOAN SET TrangThai = @TrangThai WHERE TenDangNhap = @TenDangNhap;
END;
GO

IF OBJECT_ID('dbo.sp_HRManager_DoiVaiTro', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_HRManager_DoiVaiTro;
GO
CREATE PROCEDURE dbo.sp_HRManager_DoiVaiTro
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


-- ============================================================
-- BUOC 10: Trigger Audit Log
-- ============================================================
IF OBJECT_ID('dbo.trg_NhanVien_Update', 'TR') IS NOT NULL DROP TRIGGER dbo.trg_NhanVien_Update;
GO
CREATE TRIGGER dbo.trg_NhanVien_Update
ON dbo.NHANVIEN
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF UPDATE(HoTen)
        INSERT INTO NHATKY (MaNV_ThucHien, HanhDong, BangBiTacDong, HangBiThayDoi, CotBiThayDoi, GiaTriCu, GiaTriMoi)
        SELECT dbo.fn_GetCurrentMaNV(), 'UPDATE', 'NHANVIEN', i.MaNV, 'HoTen', d.HoTen, i.HoTen
        FROM inserted i JOIN deleted d ON i.MaNV = d.MaNV WHERE ISNULL(i.HoTen,'') <> ISNULL(d.HoTen,'');

    IF UPDATE(Email)
        INSERT INTO NHATKY (MaNV_ThucHien, HanhDong, BangBiTacDong, HangBiThayDoi, CotBiThayDoi, GiaTriCu, GiaTriMoi)
        SELECT dbo.fn_GetCurrentMaNV(), 'UPDATE', 'NHANVIEN', i.MaNV, 'Email', d.Email, i.Email
        FROM inserted i JOIN deleted d ON i.MaNV = d.MaNV WHERE ISNULL(i.Email,'') <> ISNULL(d.Email,'');

    IF UPDATE(SoDienThoai)
        INSERT INTO NHATKY (MaNV_ThucHien, HanhDong, BangBiTacDong, HangBiThayDoi, CotBiThayDoi, GiaTriCu, GiaTriMoi)
        SELECT dbo.fn_GetCurrentMaNV(), 'UPDATE', 'NHANVIEN', i.MaNV, 'SoDienThoai', d.SoDienThoai, i.SoDienThoai
        FROM inserted i JOIN deleted d ON i.MaNV = d.MaNV WHERE ISNULL(i.SoDienThoai,'') <> ISNULL(d.SoDienThoai,'');

    IF UPDATE(GioiTinh)
        INSERT INTO NHATKY (MaNV_ThucHien, HanhDong, BangBiTacDong, HangBiThayDoi, CotBiThayDoi, GiaTriCu, GiaTriMoi)
        SELECT dbo.fn_GetCurrentMaNV(), 'UPDATE', 'NHANVIEN', i.MaNV, 'GioiTinh', d.GioiTinh, i.GioiTinh
        FROM inserted i JOIN deleted d ON i.MaNV = d.MaNV WHERE ISNULL(i.GioiTinh,'') <> ISNULL(d.GioiTinh,'');

    IF UPDATE(DiaChi)
        INSERT INTO NHATKY (MaNV_ThucHien, HanhDong, BangBiTacDong, HangBiThayDoi, CotBiThayDoi, GiaTriCu, GiaTriMoi)
        SELECT dbo.fn_GetCurrentMaNV(), 'UPDATE', 'NHANVIEN', i.MaNV, 'DiaChi', d.DiaChi, i.DiaChi
        FROM inserted i JOIN deleted d ON i.MaNV = d.MaNV WHERE ISNULL(i.DiaChi,'') <> ISNULL(d.DiaChi,'');

    IF UPDATE(CCCD)
        INSERT INTO NHATKY (MaNV_ThucHien, HanhDong, BangBiTacDong, HangBiThayDoi, CotBiThayDoi, GiaTriCu, GiaTriMoi)
        SELECT dbo.fn_GetCurrentMaNV(), 'UPDATE', 'NHANVIEN', i.MaNV, 'CCCD', d.CCCD, i.CCCD
        FROM inserted i JOIN deleted d ON i.MaNV = d.MaNV WHERE ISNULL(i.CCCD,'') <> ISNULL(d.CCCD,'');

    IF UPDATE(MaPhong)
        INSERT INTO NHATKY (MaNV_ThucHien, HanhDong, BangBiTacDong, HangBiThayDoi, CotBiThayDoi, GiaTriCu, GiaTriMoi)
        SELECT dbo.fn_GetCurrentMaNV(), 'UPDATE', 'NHANVIEN', i.MaNV, 'MaPhong', d.MaPhong, i.MaPhong
        FROM inserted i JOIN deleted d ON i.MaNV = d.MaNV WHERE ISNULL(i.MaPhong,'') <> ISNULL(d.MaPhong,'');

    IF UPDATE(ChucVu)
        INSERT INTO NHATKY (MaNV_ThucHien, HanhDong, BangBiTacDong, HangBiThayDoi, CotBiThayDoi, GiaTriCu, GiaTriMoi)
        SELECT dbo.fn_GetCurrentMaNV(), 'UPDATE', 'NHANVIEN', i.MaNV, 'ChucVu', d.ChucVu, i.ChucVu
        FROM inserted i JOIN deleted d ON i.MaNV = d.MaNV WHERE ISNULL(i.ChucVu,'') <> ISNULL(d.ChucVu,'');

    IF UPDATE(LoaiNhanVien)
        INSERT INTO NHATKY (MaNV_ThucHien, HanhDong, BangBiTacDong, HangBiThayDoi, CotBiThayDoi, GiaTriCu, GiaTriMoi)
        SELECT dbo.fn_GetCurrentMaNV(), 'UPDATE', 'NHANVIEN', i.MaNV, 'LoaiNhanVien', d.LoaiNhanVien, i.LoaiNhanVien
        FROM inserted i JOIN deleted d ON i.MaNV = d.MaNV WHERE ISNULL(i.LoaiNhanVien,'') <> ISNULL(d.LoaiNhanVien,'');

    IF UPDATE(TrangThai)
        INSERT INTO NHATKY (MaNV_ThucHien, HanhDong, BangBiTacDong, HangBiThayDoi, CotBiThayDoi, GiaTriCu, GiaTriMoi)
        SELECT dbo.fn_GetCurrentMaNV(), 'UPDATE', 'NHANVIEN', i.MaNV, 'TrangThai', d.TrangThai, i.TrangThai
        FROM inserted i JOIN deleted d ON i.MaNV = d.MaNV WHERE ISNULL(i.TrangThai,'') <> ISNULL(d.TrangThai,'');

    IF UPDATE(NgayVaoLam)
        INSERT INTO NHATKY (MaNV_ThucHien, HanhDong, BangBiTacDong, HangBiThayDoi, CotBiThayDoi, GiaTriCu, GiaTriMoi)
        SELECT dbo.fn_GetCurrentMaNV(), 'UPDATE', 'NHANVIEN', i.MaNV, 'NgayVaoLam', CONVERT(NVARCHAR(30), d.NgayVaoLam), CONVERT(NVARCHAR(30), i.NgayVaoLam)
        FROM inserted i JOIN deleted d ON i.MaNV = d.MaNV WHERE ISNULL(CONVERT(NVARCHAR(30), i.NgayVaoLam),'') <> ISNULL(CONVERT(NVARCHAR(30), d.NgayVaoLam),'');

    IF UPDATE(Luong)
        INSERT INTO NHATKY (MaNV_ThucHien, HanhDong, BangBiTacDong, HangBiThayDoi, CotBiThayDoi, GiaTriCu, GiaTriMoi)
        SELECT dbo.fn_GetCurrentMaNV(), 'UPDATE', 'NHANVIEN', i.MaNV, 'Luong', CAST(d.Luong AS NVARCHAR), CAST(i.Luong AS NVARCHAR)
        FROM inserted i JOIN deleted d ON i.MaNV = d.MaNV WHERE ISNULL(i.Luong,0) <> ISNULL(d.Luong,0);

    IF UPDATE(MaSoThue)
        INSERT INTO NHATKY (MaNV_ThucHien, HanhDong, BangBiTacDong, HangBiThayDoi, CotBiThayDoi, GiaTriCu, GiaTriMoi)
        SELECT dbo.fn_GetCurrentMaNV(), 'UPDATE', 'NHANVIEN', i.MaNV, 'MaSoThue', d.MaSoThue, i.MaSoThue
        FROM inserted i JOIN deleted d ON i.MaNV = d.MaNV WHERE ISNULL(i.MaSoThue,'') <> ISNULL(d.MaSoThue,'');
END;
GO

IF OBJECT_ID('dbo.trg_NhanVien_Delete', 'TR') IS NOT NULL DROP TRIGGER dbo.trg_NhanVien_Delete;
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

IF OBJECT_ID('dbo.trg_NhanVien_Insert', 'TR') IS NOT NULL DROP TRIGGER dbo.trg_NhanVien_Insert;
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

IF OBJECT_ID('dbo.sp_Auth_DoiMatKhau', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_Auth_DoiMatKhau;
GO

-- Đổi mật khẩu
CREATE PROCEDURE dbo.sp_Auth_DoiMatKhau
    @MaNV VARCHAR(10),
    @MatKhauCu VARCHAR(100),
    @MatKhauMoi VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Kiểm tra mật khẩu cũ có khớp không
    IF EXISTS (
        SELECT 1 FROM TAIKHOAN 
        WHERE MaNV = @MaNV AND MatKhauHash = HASHBYTES('SHA2_256', @MatKhauCu)
    )
    BEGIN
        UPDATE TAIKHOAN 
        SET MatKhauHash = HASHBYTES('SHA2_256', @MatKhauMoi)
        WHERE MaNV = @MaNV;
        
        SELECT 'Success' AS Status;
    END
    ELSE
    BEGIN
        RAISERROR(N'Mật khẩu cũ không chính xác', 16, 1);
    END
END;
GO

-- ============================================================
-- BUOC 11: Cap quyen EXECUTE cho tung Role
-- ============================================================

-- Role_Employee
GRANT EXECUTE ON dbo.sp_Auth_Me                       TO Role_Employee;
GRANT EXECUTE ON dbo.sp_Employee_XemThongTinCaNhan    TO Role_Employee;
GRANT EXECUTE ON dbo.sp_Employee_XemNhanVienCungPhong TO Role_Employee;

-- Role_Manager 
GRANT EXECUTE ON dbo.sp_Auth_Me                       TO Role_Manager;
GRANT EXECUTE ON dbo.sp_Employee_XemThongTinCaNhan    TO Role_Manager;
GRANT EXECUTE ON dbo.sp_Manager_XemNhanVienCungPhong  TO Role_Manager;

-- Role_Finance 
GRANT EXECUTE ON dbo.sp_Auth_Me                       TO Role_Finance;
GRANT EXECUTE ON dbo.sp_Employee_XemThongTinCaNhan    TO Role_Finance;
GRANT EXECUTE ON dbo.sp_Employee_XemNhanVienCungPhong TO Role_Finance;
GRANT EXECUTE ON dbo.sp_Finance_XemLuongCongTy        TO Role_Finance;

-- Role_HR_Staff 
GRANT EXECUTE ON dbo.sp_Auth_Me                       TO Role_HR_Staff;
GRANT EXECUTE ON dbo.sp_Employee_XemThongTinCaNhan    TO Role_HR_Staff;
GRANT EXECUTE ON dbo.sp_HR_XemNhanVienNgoaiPhong      TO Role_HR_Staff;
GRANT EXECUTE ON dbo.sp_HR_InsertNhanVien             TO Role_HR_Staff;
GRANT EXECUTE ON dbo.sp_HR_UpdateNhanVien             TO Role_HR_Staff;
GRANT EXECUTE ON dbo.sp_HR_DeleteNhanVien             TO Role_HR_Staff;

-- Role_HR_Manager 
GRANT EXECUTE ON dbo.sp_Auth_Me                       TO Role_HR_Manager;
GRANT EXECUTE ON dbo.sp_Employee_XemThongTinCaNhan    TO Role_HR_Manager;
GRANT EXECUTE ON dbo.sp_HRManager_XemTatCaNhanVien    TO Role_HR_Manager;
GRANT EXECUTE ON dbo.sp_HRManager_InsertNhanVien      TO Role_HR_Manager;
GRANT EXECUTE ON dbo.sp_HRManager_UpdateNhanVien      TO Role_HR_Manager;
GRANT EXECUTE ON dbo.sp_HRManager_DeleteNhanVien      TO Role_HR_Manager;
GRANT EXECUTE ON dbo.sp_HRManager_XemNhatKy           TO Role_HR_Manager;
GRANT EXECUTE ON dbo.sp_HRManager_DoiTrangThaiTaiKhoan TO Role_HR_Manager;
GRANT EXECUTE ON dbo.sp_HRManager_DoiVaiTro           TO Role_HR_Manager;
GRANT EXECUTE ON dbo.sp_HRManager_XemTaiKhoan         TO Role_HR_Manager;
GO

-- Cấp quyền thực thi procedure cho tất cả các Role
GRANT EXECUTE ON dbo.sp_Auth_DoiMatKhau TO Role_Employee;
GRANT EXECUTE ON dbo.sp_Auth_DoiMatKhau TO Role_Manager;
GRANT EXECUTE ON dbo.sp_Auth_DoiMatKhau TO Role_Finance;
GRANT EXECUTE ON dbo.sp_Auth_DoiMatKhau TO Role_HR_Staff;
GRANT EXECUTE ON dbo.sp_Auth_DoiMatKhau TO Role_HR_Manager;

-- Quyen cho test_user (NodeJS connect)
GRANT EXECUTE ON dbo.sp_Auth_Login TO test_user;
GRANT EXECUTE ON dbo.sp_Auth_Me    TO test_user;
GRANT EXECUTE ON dbo.sp_Auth_DoiMatKhau TO test_user;
GO