USE master;
GO
-- drop database 
IF DB_ID('QL_NHANVIEN') IS NOT NULL
BEGIN
    ALTER DATABASE QL_NHANVIEN SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE QL_NHANVIEN;
END
GO
-- drop certificate
IF EXISTS (SELECT 1 FROM sys.certificates WHERE name = 'TDECer_QLNhanVien')
    DROP CERTIFICATE TDECer_QLNhanVien;
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
CREATE TABLE PHONGBAN (
    MaPhong        VARCHAR(10) PRIMARY KEY,
    TenPhong       NVARCHAR(100) NOT NULL,
    MaTruongPhong  VARCHAR(10) NULL
);
GO

CREATE TABLE VAITRO (
    MaVaiTro  VARCHAR(10) PRIMARY KEY,
    TenVaiTro NVARCHAR(50) NOT NULL
);
GO

CREATE TABLE NHANVIEN (
    MaNV           VARCHAR(10) PRIMARY KEY,
    HoTen          NVARCHAR(100) NOT NULL,
    NgaySinh       DATE NULL,
    Email          VARCHAR(100) NULL,
    SoDienThoai    VARCHAR(15) NULL,
    GioiTinh       VARCHAR(10) NULL,
    DiaChi         NVARCHAR(255) NULL,
    CCCD           VARCHAR(20) NULL,
    MaPhong        VARCHAR(10) NULL,
    ChucVu         NVARCHAR(100) NULL,
    LoaiNhanVien   VARCHAR(20) NOT NULL CONSTRAINT DF_NV_LoaiNhanVien DEFAULT 'FULLTIME',
    TrangThai      VARCHAR(20) NOT NULL CONSTRAINT DF_NV_TrangThai DEFAULT 'ACTIVE',
    NgayVaoLam     DATE NULL CONSTRAINT DF_NV_NgayVaoLam DEFAULT CAST(GETDATE() AS DATE),
    LuongEncrypted VARBINARY(MAX) NULL,
    MaSoThue       VARCHAR(20) NULL,
    AvatarUrl      NVARCHAR(500) NULL,
    CreatedAt      DATETIME NOT NULL CONSTRAINT DF_NV_CreatedAt DEFAULT GETDATE(),
    UpdatedAt      DATETIME NOT NULL CONSTRAINT DF_NV_UpdatedAt DEFAULT GETDATE(),

    CONSTRAINT FK_NV_PHONG FOREIGN KEY (MaPhong) REFERENCES PHONGBAN(MaPhong),
    CONSTRAINT CK_NV_GioiTinh CHECK (GioiTinh IS NULL OR GioiTinh IN ('NAM', 'NU', 'KHAC')),
    CONSTRAINT CK_NV_LoaiNhanVien CHECK (LoaiNhanVien IN ('FULLTIME', 'PARTTIME', 'INTERN')),
    CONSTRAINT CK_NV_TrangThai CHECK (TrangThai IN ('ACTIVE', 'INACTIVE'))
);
GO

-- Rang buoc duy nhat cho cac truong: email, so dien thoai, CCCD, ma so thue 
CREATE UNIQUE NONCLUSTERED INDEX IDX_NV_Email ON NHANVIEN(Email) WHERE Email IS NOT NULL;
CREATE UNIQUE NONCLUSTERED INDEX IDX_NV_SoDienThoai ON NHANVIEN(SoDienThoai) WHERE SoDienThoai IS NOT NULL;
CREATE UNIQUE NONCLUSTERED INDEX IDX_NV_CCCD ON NHANVIEN(CCCD) WHERE CCCD IS NOT NULL;
CREATE UNIQUE NONCLUSTERED INDEX IDX_NV_MaSoThue ON NHANVIEN(MaSoThue) WHERE MaSoThue IS NOT NULL;
GO

CREATE TABLE TAIKHOAN (
    TenDangNhap         VARCHAR(50) PRIMARY KEY,
    MatKhauHash         VARBINARY(256) NOT NULL,
    MaNV                VARCHAR(10) UNIQUE,
    MaVaiTro            VARCHAR(10),
    TrangThai           BIT DEFAULT 1,
    CreatedAt           DATETIME NOT NULL CONSTRAINT DF_TK_CreatedAt DEFAULT GETDATE(),
    LastLogin           DATETIME NULL,
    FailedLoginAttempts INT NOT NULL CONSTRAINT DF_TK_FailedLoginAttempts DEFAULT 0,

    CONSTRAINT FK_TK_NV FOREIGN KEY (MaNV) REFERENCES NHANVIEN(MaNV),
    CONSTRAINT FK_TK_VT FOREIGN KEY (MaVaiTro) REFERENCES VAITRO(MaVaiTro)
);
GO

CREATE TABLE NHATKY (
    MaNK           INT IDENTITY(1,1) PRIMARY KEY,
    MaNV_ThucHien  VARCHAR(10),
    HanhDong       NVARCHAR(50),
    BangBiTacDong  NVARCHAR(50),
    HangBiThayDoi  NVARCHAR(50),
    CotBiThayDoi   NVARCHAR(50),
    GiaTriCu       NVARCHAR(MAX),
    GiaTriMoi      NVARCHAR(MAX),
    ThoiGian       DATETIME2 DEFAULT SYSDATETIME(),

    CONSTRAINT FK_NK_NV FOREIGN KEY (MaNV_ThucHien) REFERENCES NHANVIEN(MaNV)
);
GO

ALTER TABLE PHONGBAN
ADD CONSTRAINT FK_PHONG_TRUONGPHONG
FOREIGN KEY (MaTruongPhong) REFERENCES NHANVIEN(MaNV);
GO

-- ============================================================
-- BUOC 5: Tao cac ham (SU DUNG SESSION_CONTEXT DE LOG DUOC USER)
-- ============================================================
-- 5.1 Ham lay MaNV hien tai tu Session Context
CREATE FUNCTION dbo.fn_GetCurrentMaNV()
RETURNS VARCHAR(10)
AS
BEGIN
    RETURN CAST(SESSION_CONTEXT(N'MaNV') AS VARCHAR(10));
END;
GO
-- 5.2 Ham lay MaVaiTro hien tai tu Session Context
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

-- tao key (ma hoa luong)
IF NOT EXISTS (SELECT 1 FROM sys.symmetric_keys WHERE name = '##MS_DatabaseMasterKey##')
BEGIN
    CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'StrongPassword@2026!';
END
GO

CREATE CERTIFICATE Cert_QuanLyLuong
WITH SUBJECT = 'Certificate bao ve khoa ma hoa luong nhan vien';
GO

CREATE PROCEDURE dbo.sp_CreateSalaryKeyForPhong
    @MaPhong VARCHAR(10)
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @KeyName SYSNAME = 'SymKey_' + @MaPhong;
    DECLARE @sql NVARCHAR(MAX);

    IF @MaPhong IS NULL OR NOT EXISTS (SELECT 1 FROM PHONGBAN WHERE MaPhong = @MaPhong)
    BEGIN
        RAISERROR(N'Ma phong khong hop le', 16, 1);
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM sys.symmetric_keys WHERE name = @KeyName)
    BEGIN
        SET @sql = N'CREATE SYMMETRIC KEY ' + QUOTENAME(@KeyName) +
                   N' WITH ALGORITHM = AES_256 ENCRYPTION BY CERTIFICATE Cert_QuanLyLuong;';
        EXEC sp_executesql @sql;
    END
END;
GO

CREATE PROCEDURE dbo.sp_OpenSalaryKeyByPhong
    @MaPhong VARCHAR(10)
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @KeyName SYSNAME = 'SymKey_' + @MaPhong;
    DECLARE @sql NVARCHAR(MAX);

    IF NOT EXISTS (SELECT 1 FROM sys.symmetric_keys WHERE name = @KeyName)
    BEGIN
        RAISERROR(N'Chua co khoa ma hoa luong cho phong ban nay', 16, 1);
        RETURN;
    END

    IF NOT EXISTS (
        SELECT 1
        FROM sys.openkeys ok
        JOIN sys.symmetric_keys sk ON ok.key_id = sk.symmetric_key_id
        WHERE sk.name = @KeyName
    )
    BEGIN
        SET @sql = N'OPEN SYMMETRIC KEY ' + QUOTENAME(@KeyName) +
                   N' DECRYPTION BY CERTIFICATE Cert_QuanLyLuong;';
        EXEC sp_executesql @sql;
    END
END;
GO

CREATE PROCEDURE dbo.sp_CloseSalaryKeyByPhong
    @MaPhong VARCHAR(10)
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @KeyName SYSNAME = 'SymKey_' + @MaPhong;
    DECLARE @sql NVARCHAR(MAX);

    IF EXISTS (
        SELECT 1
        FROM sys.openkeys ok
        JOIN sys.symmetric_keys sk ON ok.key_id = sk.symmetric_key_id
        WHERE sk.name = @KeyName
    )
    BEGIN
        SET @sql = N'CLOSE SYMMETRIC KEY ' + QUOTENAME(@KeyName) + N';';
        EXEC sp_executesql @sql;
    END
END;
GO

CREATE PROCEDURE dbo.sp_OpenAllSalaryKeys
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @MaPhong VARCHAR(10);

    DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT MaPhong FROM PHONGBAN;

    OPEN cur;
    FETCH NEXT FROM cur INTO @MaPhong;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        EXEC dbo.sp_OpenSalaryKeyByPhong @MaPhong;
        FETCH NEXT FROM cur INTO @MaPhong;
    END

    CLOSE cur;
    DEALLOCATE cur;
END;
GO

CREATE PROCEDURE dbo.sp_CloseAllSalaryKeys
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @MaPhong VARCHAR(10);

    DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT MaPhong FROM PHONGBAN;

    OPEN cur;
    FETCH NEXT FROM cur INTO @MaPhong;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        EXEC dbo.sp_CloseSalaryKeyByPhong @MaPhong;
        FETCH NEXT FROM cur INTO @MaPhong;
    END

    CLOSE cur;
    DEALLOCATE cur;
END;
GO

-- 9.1 Dang nhap & Kiem tra token
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
        UPDATE TAIKHOAN
        SET LastLogin = GETDATE(), FailedLoginAttempts = 0
        WHERE TenDangNhap = @TenDangNhap;

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
        UPDATE TAIKHOAN
        SET FailedLoginAttempts = FailedLoginAttempts + 1
        WHERE TenDangNhap = @TenDangNhap;

        SELECT 'Fail' AS Status, NULL AS MaNV, NULL AS MaVaiTro;
    END
END;
GO

CREATE PROCEDURE dbo.sp_Auth_Me
    @MaNV_Input VARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT tk.TenDangNhap, nv.MaNV, nv.HoTen, nv.Email, nv.SoDienThoai, nv.MaPhong,
           pb.TenPhong AS TenPhongBan, tk.MaVaiTro, vt.TenVaiTro, tk.TrangThai AS TrangThaiTaiKhoan,
           CAST(CASE WHEN tk.TrangThai = 1 THEN 0 ELSE 1 END AS BIT) AS IsLocked,
           tk.LastLogin
    FROM NHANVIEN nv
    LEFT JOIN TAIKHOAN tk ON nv.MaNV = tk.MaNV
    LEFT JOIN PHONGBAN pb ON nv.MaPhong = pb.MaPhong
    LEFT JOIN VAITRO vt ON tk.MaVaiTro = vt.MaVaiTro
    WHERE nv.MaNV = @MaNV_Input;
END;
GO

-- 9.2 Ho so va Dong nghiep (EMP/MAN)
CREATE PROCEDURE dbo.sp_Employee_XemThongTinCaNhan
    @MaNV_Input VARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @MaPhong VARCHAR(10);
    SELECT @MaPhong = MaPhong FROM NHANVIEN WHERE MaNV = @MaNV_Input;

    IF @MaPhong IS NOT NULL EXEC dbo.sp_OpenSalaryKeyByPhong @MaPhong;

    SELECT nv.MaNV, nv.HoTen, nv.NgaySinh, nv.Email, nv.SoDienThoai, nv.GioiTinh,
           nv.DiaChi, nv.CCCD, nv.MaSoThue, nv.MaPhong, pb.TenPhong AS TenPhongBan,
           mgr.HoTen AS managerName,
           nv.ChucVu, nv.LoaiNhanVien, nv.TrangThai, nv.NgayVaoLam, nv.AvatarUrl,
           TRY_CONVERT(DECIMAL(18,2), CONVERT(VARCHAR(50), DecryptByKey(nv.LuongEncrypted, 1, CONVERT(VARCHAR(10), nv.MaNV)))) AS Luong,
           tk.TenDangNhap, tk.MaVaiTro, vt.TenVaiTro, tk.TrangThai AS TrangThaiTaiKhoan,
           CAST(CASE WHEN tk.TrangThai = 1 THEN 0 ELSE 1 END AS BIT) AS IsLocked,
           tk.LastLogin, nv.CreatedAt, nv.UpdatedAt
    FROM NHANVIEN nv
    LEFT JOIN PHONGBAN pb ON nv.MaPhong = pb.MaPhong
    LEFT JOIN NHANVIEN mgr ON pb.MaTruongPhong = mgr.MaNV
    LEFT JOIN TAIKHOAN tk ON nv.MaNV = tk.MaNV
    LEFT JOIN VAITRO vt ON tk.MaVaiTro = vt.MaVaiTro
    WHERE nv.MaNV = @MaNV_Input;

    IF @MaPhong IS NOT NULL EXEC dbo.sp_CloseSalaryKeyByPhong @MaPhong;
END;
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
           tk.TrangThai AS TrangThaiTaiKhoan,
           CAST(CASE WHEN tk.TrangThai = 1 THEN 0 ELSE 1 END AS BIT) AS IsLocked
    FROM NHANVIEN nv
    LEFT JOIN PHONGBAN pb ON nv.MaPhong = pb.MaPhong
    LEFT JOIN TAIKHOAN tk ON nv.MaNV = tk.MaNV
    LEFT JOIN VAITRO vt ON tk.MaVaiTro = vt.MaVaiTro
    WHERE nv.MaPhong = @MaPhong AND nv.TrangThai = 'ACTIVE';
END;
GO

CREATE PROCEDURE dbo.sp_Manager_XemNhanVienCungPhong
    @MaNV_Input VARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @MaPhong VARCHAR(10);
    SELECT @MaPhong = MaPhong FROM NHANVIEN WHERE MaNV = @MaNV_Input;

    IF @MaPhong IS NOT NULL EXEC dbo.sp_OpenSalaryKeyByPhong @MaPhong;

    SELECT nv.MaNV, nv.HoTen, nv.NgaySinh, nv.Email, nv.SoDienThoai, nv.GioiTinh,
           nv.DiaChi, nv.CCCD, nv.MaSoThue, nv.MaPhong, pb.TenPhong AS TenPhongBan,
           nv.ChucVu, nv.LoaiNhanVien, nv.TrangThai, nv.NgayVaoLam, nv.AvatarUrl,
           TRY_CONVERT(DECIMAL(18,2), CONVERT(VARCHAR(50), DecryptByKey(nv.LuongEncrypted, 1, CONVERT(VARCHAR(10), nv.MaNV)))) AS Luong,
           tk.MaVaiTro, vt.TenVaiTro, tk.TrangThai AS TrangThaiTaiKhoan,
           CAST(CASE WHEN tk.TrangThai = 1 THEN 0 ELSE 1 END AS BIT) AS IsLocked,
           nv.CreatedAt, nv.UpdatedAt
    FROM NHANVIEN nv
    LEFT JOIN PHONGBAN pb ON nv.MaPhong = pb.MaPhong
    LEFT JOIN TAIKHOAN tk ON nv.MaNV = tk.MaNV
    LEFT JOIN VAITRO vt ON tk.MaVaiTro = vt.MaVaiTro
    WHERE nv.MaPhong = @MaPhong;

    IF @MaPhong IS NOT NULL EXEC dbo.sp_CloseSalaryKeyByPhong @MaPhong;
END;
GO

-- 9.3 Ke toan (FIN)
CREATE PROCEDURE dbo.sp_Finance_XemLuongCongTy
    @MaNV_Input VARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @MaPhongFinance VARCHAR(10);
    SELECT @MaPhongFinance = MaPhong FROM NHANVIEN WHERE MaNV = @MaNV_Input;

    EXEC dbo.sp_OpenAllSalaryKeys;

    SELECT nv.MaNV,
           nv.HoTen,
           CASE WHEN nv.MaPhong = @MaPhongFinance THEN nv.NgaySinh ELSE NULL END AS NgaySinh,
           CASE WHEN nv.MaPhong = @MaPhongFinance THEN nv.Email ELSE NULL END AS Email,
           CASE WHEN nv.MaPhong = @MaPhongFinance THEN nv.SoDienThoai ELSE NULL END AS SoDienThoai,
           CASE WHEN nv.MaPhong = @MaPhongFinance THEN nv.MaPhong ELSE NULL END AS MaPhong,
           CASE WHEN nv.MaPhong = @MaPhongFinance THEN pb.TenPhong ELSE NULL END AS TenPhongBan,
           CASE WHEN nv.MaPhong = @MaPhongFinance THEN nv.ChucVu ELSE NULL END AS ChucVu,
           TRY_CONVERT(DECIMAL(18,2), CONVERT(VARCHAR(50), DecryptByKey(nv.LuongEncrypted, 1, CONVERT(VARCHAR(10), nv.MaNV)))) AS Luong,
           nv.MaSoThue, nv.TrangThai, nv.LoaiNhanVien
    FROM NHANVIEN nv
    LEFT JOIN PHONGBAN pb ON nv.MaPhong = pb.MaPhong;

    EXEC dbo.sp_CloseAllSalaryKeys;
END;
GO

-- 9.4 Nhan su (HR & HRM)
CREATE PROCEDURE dbo.sp_HR_XemNhanVienNgoaiPhong
    @MaNV_Input VARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @MaPhongHR VARCHAR(10);
    SELECT @MaPhongHR = MaPhong FROM NHANVIEN WHERE MaNV = @MaNV_Input;

	EXEC dbo.sp_OpenAllSalaryKeys;

    SELECT nv.MaNV, nv.HoTen, nv.NgaySinh, nv.Email, nv.SoDienThoai, nv.GioiTinh,
           nv.DiaChi, nv.CCCD, nv.MaSoThue, nv.MaPhong, pb.TenPhong AS TenPhongBan,
           nv.ChucVu, nv.LoaiNhanVien, nv.TrangThai, nv.NgayVaoLam, nv.AvatarUrl,
           TRY_CONVERT(DECIMAL(18,2), CONVERT(VARCHAR(50), DecryptByKey(nv.LuongEncrypted, 1, CONVERT(VARCHAR(10), nv.MaNV)))) AS Luong,
           tk.TenDangNhap, tk.MaVaiTro, vt.TenVaiTro, tk.TrangThai AS TrangThaiTaiKhoan,
           CAST(CASE WHEN tk.TrangThai = 1 THEN 0 ELSE 1 END AS BIT) AS IsLocked,
           nv.CreatedAt, nv.UpdatedAt
    FROM NHANVIEN nv
    LEFT JOIN PHONGBAN pb ON nv.MaPhong = pb.MaPhong
    LEFT JOIN TAIKHOAN tk ON nv.MaNV = tk.MaNV
    LEFT JOIN VAITRO vt ON tk.MaVaiTro = vt.MaVaiTro
    WHERE nv.MaPhong <> @MaPhongHR;

	EXEC dbo.sp_CloseAllSalaryKeys;
END;
GO

CREATE PROCEDURE dbo.sp_HRManager_XemTatCaNhanVien
AS
BEGIN
    SET NOCOUNT ON;

    EXEC dbo.sp_OpenAllSalaryKeys;

    SELECT nv.MaNV, nv.HoTen, nv.NgaySinh, nv.Email, nv.SoDienThoai, nv.GioiTinh,
           nv.DiaChi, nv.CCCD, nv.MaSoThue, nv.MaPhong, pb.TenPhong AS TenPhongBan,
           nv.ChucVu, nv.LoaiNhanVien, nv.TrangThai, nv.NgayVaoLam, nv.AvatarUrl,
           TRY_CONVERT(DECIMAL(18,2), CONVERT(VARCHAR(50), DecryptByKey(nv.LuongEncrypted, 1, CONVERT(VARCHAR(10), nv.MaNV)))) AS Luong,
           tk.TenDangNhap, tk.MaVaiTro, vt.TenVaiTro, tk.TrangThai AS TrangThaiTaiKhoan,
           CAST(CASE WHEN tk.TrangThai = 1 THEN 0 ELSE 1 END AS BIT) AS IsLocked,
           tk.LastLogin, tk.FailedLoginAttempts, nv.CreatedAt, nv.UpdatedAt
    FROM NHANVIEN nv
    LEFT JOIN PHONGBAN pb ON nv.MaPhong = pb.MaPhong
    LEFT JOIN TAIKHOAN tk ON nv.MaNV = tk.MaNV
    LEFT JOIN VAITRO vt ON tk.MaVaiTro = vt.MaVaiTro;

    EXEC dbo.sp_CloseAllSalaryKeys;
END;
GO

IF OBJECT_ID('dbo.sp_HRManager_InsertNhanVien', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_HRManager_InsertNhanVien;
GO
CREATE PROCEDURE dbo.sp_HRManager_InsertNhanVien
    @MaNV          VARCHAR(10),
    @HoTen         NVARCHAR(100),
    @NgaySinh      DATE = NULL,
    @Email         VARCHAR(100) = NULL,
    @SoDienThoai   VARCHAR(15) = NULL,
    @GioiTinh      VARCHAR(10) = NULL,
    @DiaChi        NVARCHAR(255) = NULL,
    @CCCD          VARCHAR(20) = NULL,
    @MaPhong       VARCHAR(10),
    @ChucVu        NVARCHAR(100) = NULL,
    @LoaiNhanVien  VARCHAR(20) = 'FULLTIME',
    @TrangThai     VARCHAR(20) = 'ACTIVE',
    @NgayVaoLam    DATE = NULL,
    @Luong         DECIMAL(18,2) = NULL,
    @MaSoThue      VARCHAR(20) = NULL,
    @AvatarUrl     NVARCHAR(500) = NULL,
    @TenDangNhap   VARCHAR(50),
    @MatKhau       VARCHAR(100),
    @MaVaiTro      VARCHAR(10) = 'EMP'
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;

    IF @MaVaiTro = 'HRM' AND EXISTS (SELECT 1 FROM TAIKHOAN WHERE MaVaiTro = 'HRM' AND TrangThai = 1)
    BEGIN RAISERROR(N'Thất bại: Hệ thống chỉ cho phép tồn tại duy nhất một Trưởng phòng Nhân sự hoạt động.', 16, 1); RETURN; END

    IF @MaVaiTro IN ('MAN', 'HRM') AND EXISTS (
        SELECT 1 FROM TAIKHOAN tk JOIN NHANVIEN nv_check ON tk.MaNV = nv_check.MaNV
        WHERE nv_check.MaPhong = @MaPhong AND tk.MaVaiTro IN ('MAN', 'HRM') AND tk.TrangThai = 1
    )
    BEGIN RAISERROR(N'Thất bại: Phòng ban chỉ định hiện tại đã có Quản lý hoặc Trưởng phòng hoạt động.', 16, 1); RETURN; END

    DECLARE @LuongEncrypted VARBINARY(MAX) = NULL;
    BEGIN TRANSACTION;
    BEGIN TRY
        IF @Luong IS NOT NULL
        BEGIN
            EXEC dbo.sp_OpenSalaryKeyByPhong @MaPhong;
            SET @LuongEncrypted = EncryptByKey(Key_GUID('SymKey_' + @MaPhong), CONVERT(VARCHAR(50), @Luong), 1, CONVERT(VARCHAR(10), @MaNV));
            EXEC dbo.sp_CloseSalaryKeyByPhong @MaPhong;
        END

        INSERT INTO NHANVIEN (MaNV, HoTen, NgaySinh, Email, SoDienThoai, GioiTinh, DiaChi, CCCD, MaPhong, ChucVu, LoaiNhanVien, TrangThai, NgayVaoLam, LuongEncrypted, MaSoThue, AvatarUrl)
        VALUES (@MaNV, @HoTen, @NgaySinh, @Email, @SoDienThoai, @GioiTinh, @DiaChi, @CCCD, @MaPhong, @ChucVu, COALESCE(@LoaiNhanVien, 'FULLTIME'), COALESCE(@TrangThai, 'ACTIVE'), COALESCE(@NgayVaoLam, CAST(GETDATE() AS DATE)), @LuongEncrypted, @MaSoThue, @AvatarUrl);

        INSERT INTO TAIKHOAN (TenDangNhap, MatKhauHash, MaNV, MaVaiTro, TrangThai)
        VALUES (@TenDangNhap, HASHBYTES('SHA2_256', @MatKhau), @MaNV, @MaVaiTro, 1);

        IF @MaVaiTro IN ('MAN', 'HRM')
            UPDATE PHONGBAN SET MaTruongPhong = @MaNV WHERE MaPhong = @MaPhong;

        IF @Luong IS NOT NULL
        BEGIN
            INSERT INTO NHATKY (MaNV_ThucHien, HanhDong, BangBiTacDong, HangBiThayDoi, CotBiThayDoi, GiaTriCu, GiaTriMoi)
            VALUES (dbo.fn_GetCurrentMaNV(), 'INSERT', 'NHANVIEN', @MaNV, 'Luong', NULL, FORMAT(@Luong, 'N0', 'vi-VN') + N' đ');
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
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
    @NgaySinh      DATE = NULL,
    @Email         VARCHAR(100) = NULL,
    @SoDienThoai   VARCHAR(15) = NULL,
    @GioiTinh      VARCHAR(10) = NULL,
    @DiaChi        NVARCHAR(255) = NULL,
    @CCCD          VARCHAR(20) = NULL,
    @MaPhong       VARCHAR(10) = NULL,
    @ChucVu        NVARCHAR(100) = NULL,
    @LoaiNhanVien  VARCHAR(20) = NULL,
    @TrangThai     VARCHAR(20) = NULL,
    @NgayVaoLam    DATE = NULL,
    @Luong         DECIMAL(18,2) = NULL,
    @MaSoThue      VARCHAR(20) = NULL,
    @AvatarUrl     NVARCHAR(500) = NULL,
    @MaVaiTro      VARCHAR(10) = NULL
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @OldMaPhong VARCHAR(10), @NewMaPhong VARCHAR(10), @CurrentRole VARCHAR(10), @OldTrangThai VARCHAR(20);
    SELECT @OldMaPhong = MaPhong, @OldTrangThai = TrangThai FROM NHANVIEN WHERE MaNV = @MaNV;
    SELECT @CurrentRole = MaVaiTro FROM TAIKHOAN WHERE MaNV = @MaNV;
    
    SET @NewMaPhong = COALESCE(@MaPhong, @OldMaPhong);
    DECLARE @FinalRole VARCHAR(10) = COALESCE(@MaVaiTro, @CurrentRole);
    DECLARE @FinalTrangThai VARCHAR(20) = COALESCE(@TrangThai, @OldTrangThai);

    IF @FinalTrangThai = 'INACTIVE' AND @CurrentRole = 'HRM' AND (
        SELECT COUNT(*) FROM TAIKHOAN tk JOIN NHANVIEN nv ON tk.MaNV = nv.MaNV 
        WHERE tk.MaVaiTro = 'HRM' AND tk.TrangThai = 1 AND nv.TrangThai = 'ACTIVE'
    ) <= 1
    BEGIN RAISERROR(N'Thất bại: Cơ chế tự động bảo vệ hệ thống chặn hành vi đình chỉ công tác Trưởng phòng Nhân sự duy nhất.', 16, 1); RETURN; END

    IF @CurrentRole = 'HRM' AND @FinalRole <> 'HRM' AND (SELECT COUNT(*) FROM TAIKHOAN WHERE MaVaiTro = 'HRM' AND TrangThai = 1) <= 1
    BEGIN RAISERROR(N'Thất bại: Hệ thống yêu cầu tối thiểu một tài khoản có vai trò Trưởng phòng Nhân sự hoạt động.', 16, 1); RETURN; END

    IF @FinalRole = 'HRM' AND EXISTS (SELECT 1 FROM TAIKHOAN WHERE MaVaiTro = 'HRM' AND TrangThai = 1 AND MaNV <> @MaNV)
    BEGIN RAISERROR(N'Thất bại: Toàn hệ thống chỉ cho phép tồn tại duy nhất một Trưởng phòng Nhân sự hoạt động.', 16, 1); RETURN; END

    IF @FinalRole IN ('MAN', 'HRM') AND EXISTS (
        SELECT 1 FROM TAIKHOAN tk JOIN NHANVIEN nv ON tk.MaNV = nv.MaNV 
        WHERE nv.MaPhong = @NewMaPhong AND tk.MaVaiTro IN ('MAN', 'HRM') AND tk.TrangThai = 1 AND tk.MaNV <> @MaNV
    )
    BEGIN RAISERROR(N'Thất bại: Không thể chuyển giao vai trò, phòng ban chỉ định đã thiết lập cơ cấu Trưởng phòng.', 16, 1); RETURN; END

    BEGIN TRANSACTION;
    BEGIN TRY
        DECLARE @LuongEncrypted VARBINARY(MAX) = NULL;
        DECLARE @CurrentLuong DECIMAL(18,2) = NULL;

        IF @OldMaPhong IS NOT NULL 
        BEGIN
            EXEC dbo.sp_OpenSalaryKeyByPhong @OldMaPhong;
            SELECT @CurrentLuong = TRY_CONVERT(DECIMAL(18,2), CONVERT(VARCHAR(50), DecryptByKey(LuongEncrypted, 1, CONVERT(VARCHAR(10), @MaNV)))) FROM NHANVIEN WHERE MaNV = @MaNV;
            EXEC dbo.sp_CloseSalaryKeyByPhong @OldMaPhong;
        END

        DECLARE @LuongLuu DECIMAL(18,2) = COALESCE(@Luong, @CurrentLuong);
        IF @LuongLuu IS NOT NULL
        BEGIN
            EXEC dbo.sp_OpenSalaryKeyByPhong @NewMaPhong;
            SET @LuongEncrypted = EncryptByKey(Key_GUID('SymKey_' + @NewMaPhong), CONVERT(VARCHAR(50), @LuongLuu), 1, CONVERT(VARCHAR(10), @MaNV));
            EXEC dbo.sp_CloseSalaryKeyByPhong @NewMaPhong;
        END

        UPDATE NHANVIEN 
        SET HoTen = COALESCE(@HoTen, HoTen), NgaySinh = COALESCE(@NgaySinh, NgaySinh), Email = COALESCE(@Email, Email), SoDienThoai = COALESCE(@SoDienThoai, SoDienThoai), GioiTinh = COALESCE(@GioiTinh, GioiTinh), DiaChi = COALESCE(@DiaChi, DiaChi), CCCD = COALESCE(@CCCD, CCCD), MaPhong = @NewMaPhong, ChucVu = COALESCE(@ChucVu, ChucVu), LoaiNhanVien = COALESCE(@LoaiNhanVien, LoaiNhanVien), TrangThai = @FinalTrangThai, NgayVaoLam = COALESCE(@NgayVaoLam, NgayVaoLam), LuongEncrypted = COALESCE(@LuongEncrypted, LuongEncrypted), MaSoThue = COALESCE(@MaSoThue, MaSoThue), AvatarUrl = COALESCE(@AvatarUrl, AvatarUrl), UpdatedAt = GETDATE() 
        WHERE MaNV = @MaNV;

        IF @MaVaiTro IS NOT NULL UPDATE TAIKHOAN SET MaVaiTro = @MaVaiTro WHERE MaNV = @MaNV;

        IF @FinalTrangThai = 'INACTIVE' UPDATE TAIKHOAN SET TrangThai = 0 WHERE MaNV = @MaNV;
        IF @FinalTrangThai = 'ACTIVE' UPDATE TAIKHOAN SET TrangThai = 1 WHERE MaNV = @MaNV;

        UPDATE PHONGBAN SET MaTruongPhong = NULL WHERE MaTruongPhong = @MaNV;
        IF @FinalRole IN ('MAN', 'HRM') AND @FinalTrangThai = 'ACTIVE'
            UPDATE PHONGBAN SET MaTruongPhong = @MaNV WHERE MaPhong = @NewMaPhong;

        IF @Luong IS NOT NULL AND ISNULL(@CurrentLuong, -1) <> ISNULL(@LuongLuu, -1)
        BEGIN
            INSERT INTO NHATKY (MaNV_ThucHien, HanhDong, BangBiTacDong, HangBiThayDoi, CotBiThayDoi, GiaTriCu, GiaTriMoi)
            VALUES (
                dbo.fn_GetCurrentMaNV(),
                'UPDATE',
                'NHANVIEN',
                @MaNV,
                'Luong',
                CASE WHEN @CurrentLuong IS NULL THEN N'Chưa có dữ liệu' ELSE FORMAT(@CurrentLuong, 'N0', 'vi-VN') + N' đ' END,
                FORMAT(@LuongLuu, 'N0', 'vi-VN') + N' đ'
            );
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        DECLARE @Err NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@Err, 16, 1);
    END CATCH
END;
GO

CREATE PROCEDURE dbo.sp_HR_InsertNhanVien
    @MaNV_Input    VARCHAR(10),
    @MaNV          VARCHAR(10),
    @HoTen         NVARCHAR(100),
    @NgaySinh      DATE = NULL,
    @Email         VARCHAR(100) = NULL,
    @SoDienThoai   VARCHAR(15) = NULL,
    @GioiTinh      VARCHAR(10) = NULL,
    @DiaChi        NVARCHAR(255) = NULL,
    @CCCD          VARCHAR(20) = NULL,
    @MaPhong       VARCHAR(10),
    @ChucVu        NVARCHAR(100) = NULL,
    @LoaiNhanVien  VARCHAR(20) = 'FULLTIME',
    @TrangThai     VARCHAR(20) = 'ACTIVE',
    @NgayVaoLam    DATE = NULL,
    @Luong         DECIMAL(18,2) = NULL,
    @MaSoThue      VARCHAR(20) = NULL,
    @AvatarUrl     NVARCHAR(500) = NULL,
    @TenDangNhap   VARCHAR(50),
    @MatKhau       VARCHAR(100)
WITH EXECUTE AS OWNER
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

    EXEC dbo.sp_HRManager_InsertNhanVien
        @MaNV, @HoTen, @NgaySinh, @Email, @SoDienThoai, @GioiTinh, @DiaChi, @CCCD,
        @MaPhong, @ChucVu, @LoaiNhanVien, @TrangThai, @NgayVaoLam, @Luong,
        @MaSoThue, @AvatarUrl, @TenDangNhap, @MatKhau, 'EMP';
END;
GO

CREATE PROCEDURE dbo.sp_HR_UpdateNhanVien
    @MaNV_Input    VARCHAR(10),
    @MaNV          VARCHAR(10),
    @HoTen         NVARCHAR(100) = NULL,
    @NgaySinh      DATE = NULL,
    @Email         VARCHAR(100) = NULL,
    @SoDienThoai   VARCHAR(15) = NULL,
    @GioiTinh      VARCHAR(10) = NULL,
    @DiaChi        NVARCHAR(255) = NULL,
    @CCCD          VARCHAR(20) = NULL,
    @MaPhong       VARCHAR(10) = NULL,
    @ChucVu        NVARCHAR(100) = NULL,
    @LoaiNhanVien  VARCHAR(20) = NULL,
    @TrangThai     VARCHAR(20) = NULL,
    @NgayVaoLam    DATE = NULL,
    @Luong         DECIMAL(18,2) = NULL,
    @MaSoThue      VARCHAR(20) = NULL,
    @AvatarUrl     NVARCHAR(500) = NULL
WITH EXECUTE AS OWNER
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

    EXEC dbo.sp_HRManager_UpdateNhanVien
        @MaNV, @HoTen, @NgaySinh, @Email, @SoDienThoai, @GioiTinh, @DiaChi, @CCCD,
        @MaPhong, @ChucVu, @LoaiNhanVien, @TrangThai, @NgayVaoLam, @Luong,
        @MaSoThue, @AvatarUrl, NULL;
END;
GO

IF OBJECT_ID('dbo.sp_HRManager_DeleteNhanVien', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_HRManager_DeleteNhanVien;
GO

CREATE PROCEDURE dbo.sp_HRManager_DeleteNhanVien
    @MaNV VARCHAR(10)
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @MaVaiTro VARCHAR(10);
    DECLARE @MaPhong VARCHAR(10);

    SELECT
        @MaVaiTro = tk.MaVaiTro,
        @MaPhong = nv.MaPhong
    FROM NHANVIEN nv
    LEFT JOIN TAIKHOAN tk ON nv.MaNV = tk.MaNV
    WHERE nv.MaNV = @MaNV;

    IF @MaVaiTro IS NULL
    BEGIN
        RAISERROR(N'Nhân viên hoặc tài khoản không tồn tại.', 16, 1);
        RETURN;
    END

    IF @MaVaiTro = 'HRM'
       AND (
            SELECT COUNT(*)
            FROM TAIKHOAN
            WHERE MaVaiTro = 'HRM'
              AND TrangThai = 1
       ) <= 1
    BEGIN
        RAISERROR(N'Thất bại: Không thể xóa Trưởng phòng Nhân sự duy nhất đang hoạt động của hệ thống!', 16, 1);
        RETURN;
    END

    BEGIN TRANSACTION;
    BEGIN TRY
        UPDATE PHONGBAN
        SET MaTruongPhong = NULL
        WHERE MaTruongPhong = @MaNV;

        DELETE FROM TAIKHOAN
        WHERE MaNV = @MaNV;

        DELETE FROM NHANVIEN
        WHERE MaNV = @MaNV;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;

        DECLARE @Err NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@Err, 16, 1);
    END CATCH
END;
GO


IF OBJECT_ID('dbo.sp_HR_DeleteNhanVien', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_HR_DeleteNhanVien;
GO

CREATE PROCEDURE dbo.sp_HR_DeleteNhanVien
    @MaNV_Input VARCHAR(10),
    @MaNV       VARCHAR(10)
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @MaPhongHR VARCHAR(10);
    DECLARE @MaPhongTarget VARCHAR(10);
    DECLARE @RoleTarget VARCHAR(10);

    SELECT @MaPhongHR = MaPhong
    FROM NHANVIEN
    WHERE MaNV = @MaNV_Input;

    SELECT 
        @MaPhongTarget = nv.MaPhong,
        @RoleTarget = tk.MaVaiTro
    FROM NHANVIEN nv
    LEFT JOIN TAIKHOAN tk ON nv.MaNV = tk.MaNV
    WHERE nv.MaNV = @MaNV;

    IF @MaPhongTarget IS NULL
    BEGIN
        RAISERROR(N'Nhân viên cần xóa không tồn tại.', 16, 1);
        RETURN;
    END

    IF @MaPhongTarget = @MaPhongHR
    BEGIN
        RAISERROR(N'Không được xóa nhân viên cùng phòng HR.', 16, 1);
        RETURN;
    END

    IF @RoleTarget IN ('MAN', 'HRM')
    BEGIN
        RAISERROR(N'HR Staff không được xóa Quản lý / Trưởng phòng. Vui lòng liên hệ Trưởng phòng Nhân sự.', 16, 1);
        RETURN;
    END

    EXEC dbo.sp_HRManager_DeleteNhanVien @MaNV;
END;
GO

CREATE PROCEDURE dbo.sp_HRManager_XemNhatKy
    @TuNgay DATE = NULL,
    @DenNgay DATE = NULL,
    @MaNV VARCHAR(10) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        nk.MaNK AS MaLog, 
        nk.MaNV_ThucHien AS ActorId, 
        nv.HoTen AS ActorName,
        tk.TenDangNhap, 
        nk.HanhDong, 
        nk.BangBiTacDong AS TableName,
        nk.HangBiThayDoi AS TargetId, 

        COALESCE(
            nvTarget.HoTen, 
            CASE 
                WHEN nk.HanhDong = 'DELETE' AND nk.GiaTriCu IS NOT NULL 
                THEN SUBSTRING(nk.GiaTriCu, 1, ISNULL(NULLIF(CHARINDEX(' |', nk.GiaTriCu), 0) - 1, LEN(nk.GiaTriCu)))
                ELSE N'Hệ thống / Đã xóa' 
            END
        ) AS TargetName,

        nk.CotBiThayDoi, 
        nk.GiaTriCu, 
        nk.GiaTriMoi,
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
           pb.TenPhong AS TenPhongBan, tk.MaVaiTro, vt.TenVaiTro,

           CAST(CASE 
               WHEN tk.TrangThai = 1 AND nv.TrangThai = 'ACTIVE' THEN 1 
               ELSE 0 
           END AS BIT) AS TrangThai,

           CAST(CASE 
               WHEN tk.TrangThai = 1 AND nv.TrangThai = 'ACTIVE' THEN 0 
               ELSE 1 
           END AS BIT) AS IsLocked,

           nv.TrangThai AS TrangThaiNhanVien,
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
    @TrangThai BIT
AS
BEGIN
    SET NOCOUNT ON;

    IF @TrangThai = 0 
    BEGIN
        DECLARE @RoleCheck VARCHAR(10);
        SELECT @RoleCheck = MaVaiTro FROM TAIKHOAN WHERE TenDangNhap = @TenDangNhap;
        
        IF @RoleCheck = 'HRM' 
           AND (SELECT COUNT(*) FROM TAIKHOAN WHERE MaVaiTro = 'HRM' AND TrangThai = 1) <= 1
        BEGIN
            RAISERROR(N'Thất bại: Không thể khóa tài khoản Trưởng phòng Nhân sự duy nhất của hệ thống!', 16, 1);
            RETURN;
        END
    END

    UPDATE TAIKHOAN SET TrangThai = @TrangThai WHERE TenDangNhap = @TenDangNhap;
END;
GO

IF OBJECT_ID('dbo.sp_HRManager_DoiVaiTro', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_HRManager_DoiVaiTro;
GO
CREATE PROCEDURE dbo.sp_HRManager_DoiVaiTro
    @TenDangNhap VARCHAR(50),
    @MaVaiTroMoi VARCHAR(10)
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @MaNV VARCHAR(10), @MaPhong VARCHAR(10), @OldRole VARCHAR(10);

    SELECT @MaNV = tk.MaNV, @MaPhong = nv.MaPhong, @OldRole = tk.MaVaiTro 
    FROM TAIKHOAN tk JOIN NHANVIEN nv ON tk.MaNV = nv.MaNV WHERE tk.TenDangNhap = @TenDangNhap;

    IF @MaNV IS NULL BEGIN RAISERROR(N'Tài khoản không tồn tại.', 16, 1); RETURN; END
    IF NOT EXISTS (SELECT 1 FROM VAITRO WHERE MaVaiTro = @MaVaiTroMoi) BEGIN RAISERROR(N'Mã vai trò không tồn tại.', 16, 1); RETURN; END

    IF @MaVaiTroMoi = 'HRM' AND EXISTS (SELECT 1 FROM TAIKHOAN WHERE MaVaiTro = 'HRM' AND TrangThai = 1 AND MaNV <> @MaNV)
    BEGIN RAISERROR(N'Thất bại: Hệ thống chỉ được có 1 Trưởng phòng Nhân sự (HRM) đang hoạt động.', 16, 1); RETURN; END

    IF @OldRole = 'HRM' AND @MaVaiTroMoi <> 'HRM' AND (SELECT COUNT(*) FROM TAIKHOAN WHERE MaVaiTro = 'HRM' AND TrangThai = 1) <= 1
    BEGIN RAISERROR(N'Thất bại: Không thể giáng chức Trưởng phòng Nhân sự duy nhất.', 16, 1); RETURN; END

    IF @MaVaiTroMoi IN ('MAN', 'HRM') AND EXISTS (
        SELECT 1 FROM TAIKHOAN tk JOIN NHANVIEN nv ON tk.MaNV = nv.MaNV 
        WHERE nv.MaPhong = @MaPhong AND tk.MaVaiTro IN ('MAN', 'HRM') AND tk.TrangThai = 1 AND tk.MaNV <> @MaNV
    )
    BEGIN RAISERROR(N'Thất bại: Phòng ban này đã có Trưởng phòng.', 16, 1); RETURN; END

    BEGIN TRANSACTION;
    BEGIN TRY
        UPDATE TAIKHOAN SET MaVaiTro = @MaVaiTroMoi WHERE TenDangNhap = @TenDangNhap;

        UPDATE PHONGBAN SET MaTruongPhong = NULL WHERE MaTruongPhong = @MaNV;
        IF @MaVaiTroMoi IN ('MAN', 'HRM') UPDATE PHONGBAN SET MaTruongPhong = @MaNV WHERE MaPhong = @MaPhong;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        DECLARE @Err NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@Err, 16, 1);
    END CATCH
END;
GO

IF OBJECT_ID('dbo.sp_Auth_DoiMatKhau', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_Auth_DoiMatKhau;
GO

CREATE PROCEDURE dbo.sp_Auth_DoiMatKhau
    @MaNV        VARCHAR(10),
    @MatKhauCu   VARCHAR(100),
    @MatKhauMoi  VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (
        SELECT 1
        FROM TAIKHOAN tk
        JOIN NHANVIEN nv ON tk.MaNV = nv.MaNV
        WHERE tk.MaNV = @MaNV
          AND tk.MatKhauHash = HASHBYTES('SHA2_256', @MatKhauCu)
          AND tk.TrangThai = 1
          AND nv.TrangThai = 'ACTIVE'
    )
    BEGIN
        RAISERROR(N'Mật khẩu cũ không chính xác hoặc tài khoản không còn hoạt động', 16, 1);
        RETURN;
    END

    UPDATE TAIKHOAN
    SET MatKhauHash = HASHBYTES('SHA2_256', @MatKhauMoi),
        FailedLoginAttempts = 0
    WHERE MaNV = @MaNV;

    SELECT 'Success' AS Status,
           N'Đổi mật khẩu thành công' AS Message;
END;
GO


-- 1. SP XEM DANH SÁCH PHÒNG BAN 
IF OBJECT_ID('dbo.sp_HRManager_XemDanhSachPhongBan', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_HRManager_XemDanhSachPhongBan;
GO
CREATE PROCEDURE dbo.sp_HRManager_XemDanhSachPhongBan
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SELECT pb.MaPhong, pb.TenPhong, pb.MaTruongPhong, nv.HoTen AS TenTruongPhong
    FROM PHONGBAN pb
    LEFT JOIN NHANVIEN nv ON pb.MaTruongPhong = nv.MaNV;
END;
GO

-- 2. SP THÊM PHÒNG BAN MỚI
IF OBJECT_ID('dbo.sp_HRManager_ThemPhongBan', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_HRManager_ThemPhongBan;
GO
CREATE PROCEDURE dbo.sp_HRManager_ThemPhongBan
    @MaPhong VARCHAR(10),
    @TenPhong NVARCHAR(100)
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM PHONGBAN WHERE MaPhong = @MaPhong)
    BEGIN
        RAISERROR(N'Thất bại: Mã phòng ban này đã tồn tại trên hệ thống.', 16, 1);
        RETURN;
    END;

    INSERT INTO PHONGBAN (MaPhong, TenPhong, MaTruongPhong) 
    VALUES (@MaPhong, @TenPhong, NULL);
    
    INSERT INTO NHATKY (MaNV_ThucHien, HanhDong, BangBiTacDong, HangBiThayDoi, CotBiThayDoi, GiaTriCu, GiaTriMoi)
    VALUES (dbo.fn_GetCurrentMaNV(), 'INSERT', 'PHONGBAN', @MaPhong, 'ALL', NULL, @TenPhong);
END;
GO

-- 3. SP CẬP NHẬT PHÒNG BAN (Đổi tên hoặc Bổ nhiệm/Thay đổi Trưởng phòng)
IF OBJECT_ID('dbo.sp_HRManager_CapNhatPhongBan', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_HRManager_CapNhatPhongBan;
GO
CREATE PROCEDURE dbo.sp_HRManager_CapNhatPhongBan
    @MaPhong        VARCHAR(10),
    @TenPhong       NVARCHAR(100) = NULL,
    @MaTruongPhong  VARCHAR(10) = NULL
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @OldTen NVARCHAR(100), @OldTP VARCHAR(10);
    SELECT @OldTen = TenPhong, @OldTP = MaTruongPhong FROM PHONGBAN WHERE MaPhong = @MaPhong;

    IF @MaTruongPhong IS NOT NULL AND NOT EXISTS (SELECT 1 FROM NHANVIEN WHERE MaNV = @MaTruongPhong AND MaPhong = @MaPhong)
    BEGIN
        RAISERROR(N'Thất bại: Nhân viên được bổ nhiệm làm Trưởng phòng phải thuộc biên chế của phòng ban này.', 16, 1);
        RETURN;
    END;

    BEGIN TRANSACTION;
    BEGIN TRY
        UPDATE PHONGBAN 
        SET TenPhong = COALESCE(@TenPhong, TenPhong), 
            MaTruongPhong = @MaTruongPhong
        WHERE MaPhong = @MaPhong;

        IF @MaTruongPhong IS NOT NULL AND ISNULL(@OldTP, '') <> @MaTruongPhong
            UPDATE TAIKHOAN SET MaVaiTro = 'MAN' WHERE MaNV = @MaTruongPhong;

        IF @TenPhong IS NOT NULL AND @OldTen <> @TenPhong
            INSERT INTO NHATKY (MaNV_ThucHien, HanhDong, BangBiTacDong, HangBiThayDoi, CotBiThayDoi, GiaTriCu, GiaTriMoi)
            VALUES (dbo.fn_GetCurrentMaNV(), 'UPDATE', 'PHONGBAN', @MaPhong, 'TenPhong', @OldTen, @TenPhong);

        IF ISNULL(@OldTP, '') <> ISNULL(@MaTruongPhong, '')
            INSERT INTO NHATKY (MaNV_ThucHien, HanhDong, BangBiTacDong, HangBiThayDoi, CotBiThayDoi, GiaTriCu, GiaTriMoi)
            VALUES (dbo.fn_GetCurrentMaNV(), 'UPDATE', 'PHONGBAN', @MaPhong, 'MaTruongPhong', ISNULL(@OldTP, 'None'), ISNULL(@MaTruongPhong, 'None'));

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        DECLARE @Err NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@Err, 16, 1);
    END CATCH
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

    IF UPDATE(TrangThai)
        INSERT INTO NHATKY (MaNV_ThucHien, HanhDong, BangBiTacDong, HangBiThayDoi, CotBiThayDoi, GiaTriCu, GiaTriMoi)
        SELECT dbo.fn_GetCurrentMaNV(), 'UPDATE', 'NHANVIEN', i.MaNV, 'TrangThai', d.TrangThai, i.TrangThai
        FROM inserted i JOIN deleted d ON i.MaNV = d.MaNV WHERE ISNULL(i.TrangThai,'') <> ISNULL(d.TrangThai,'');
END;
GO

-- 3. Trigger xoa và them 
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
    SELECT
        dbo.fn_GetCurrentMaNV(),
        'INSERT',
        'NHANVIEN',
        i.MaNV,
        'ALL',
        NULL,
        CONCAT(
            N'Mã NV: ', i.MaNV,
            N' | Họ tên: ', i.HoTen,
            N' | Ngày sinh: ', ISNULL(CONVERT(NVARCHAR(20), i.NgaySinh, 103), N'Chưa cập nhật'),
            N' | Email: ', ISNULL(i.Email, N'Chưa cập nhật'),
            N' | SĐT: ', ISNULL(i.SoDienThoai, N'Chưa cập nhật'),
            N' | Giới tính: ', ISNULL(i.GioiTinh, N'Chưa cập nhật'),
            N' | Địa chỉ: ', ISNULL(i.DiaChi, N'Chưa cập nhật'),
            N' | CCCD: ', ISNULL(i.CCCD, N'Chưa cập nhật'),
            N' | Phòng: ', ISNULL(i.MaPhong, N'Chưa cập nhật'),
            N' | Chức vụ: ', ISNULL(i.ChucVu, N'Chưa cập nhật'),
            N' | Loại NV: ', ISNULL(i.LoaiNhanVien, N'Chưa cập nhật'),
            N' | Trạng thái: ', ISNULL(i.TrangThai, N'Chưa cập nhật'),
            N' | Ngày vào làm: ', ISNULL(CONVERT(NVARCHAR(20), i.NgayVaoLam, 103), N'Chưa cập nhật'),
            N' | MST: ', ISNULL(i.MaSoThue, N'Chưa cập nhật')
        )
    FROM inserted i;
END;
GO

-- 4. trigger khoa/mo tk 
IF OBJECT_ID('TRG_Audit_TaiKhoan', 'TR') IS NOT NULL DROP TRIGGER TRG_Audit_TaiKhoan;
GO

CREATE TRIGGER TRG_Audit_TaiKhoan
ON TAIKHOAN
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @MaNV_ThucHien VARCHAR(10) = CAST(SESSION_CONTEXT(N'MaNV') AS VARCHAR(10));

    IF UPDATE(MaVaiTro)
    BEGIN
        INSERT INTO NHATKY (MaNV_ThucHien, HanhDong, BangBiTacDong, HangBiThayDoi, CotBiThayDoi, GiaTriCu, GiaTriMoi)
        SELECT 
            @MaNV_ThucHien, 
            'ROLE', 
            'TAIKHOAN', 
            i.MaNV, 
            'MaVaiTro', 
            d.MaVaiTro, 
            i.MaVaiTro
        FROM inserted i
        JOIN deleted d ON i.TenDangNhap = d.TenDangNhap
        WHERE i.MaVaiTro <> d.MaVaiTro; 
    END

    IF UPDATE(TrangThai)
    BEGIN
        INSERT INTO NHATKY (MaNV_ThucHien, HanhDong, BangBiTacDong, HangBiThayDoi, CotBiThayDoi, GiaTriCu, GiaTriMoi)
        SELECT 
            @MaNV_ThucHien, 
            CASE WHEN i.TrangThai = 0 THEN 'LOCK_ACCOUNT' ELSE 'UPDATE' END, 
            'TAIKHOAN', 
            i.MaNV, 
            'TrangThai', 
            CAST(d.TrangThai AS VARCHAR(5)), 
            CAST(i.TrangThai AS VARCHAR(5))
        FROM inserted i
        JOIN deleted d ON i.TenDangNhap = d.TenDangNhap
        WHERE i.TrangThai <> d.TrangThai;
    END
END;
GO

-- CHẶN TOÀN BỘ QUYỀN TRUY CẬP TRỰC TIẾP VÀO BẢNG VẬT LÝ NHẬT KÝ HỆ THỐNG
DENY SELECT, INSERT, UPDATE, DELETE ON dbo.NHATKY TO PUBLIC;
GO

REVOKE EXECUTE ON dbo.sp_HRManager_XemNhatKy FROM PUBLIC; 
GRANT EXECUTE ON dbo.sp_HRManager_XemNhatKy TO Role_HR_Manager;
GO

-- ============================================================
-- BUOC 11: Cap quyen EXECUTE cho tung Role
-- ============================================================
-- Role_Employee
GRANT EXECUTE ON dbo.sp_Auth_Me TO Role_Employee;
GRANT EXECUTE ON dbo.sp_Employee_XemThongTinCaNhan TO Role_Employee;
GRANT EXECUTE ON dbo.sp_Employee_XemNhanVienCungPhong TO Role_Employee;

-- Role_Manager 
GRANT EXECUTE ON dbo.sp_Auth_Me TO Role_Manager;
GRANT EXECUTE ON dbo.sp_Employee_XemThongTinCaNhan TO Role_Manager;
GRANT EXECUTE ON dbo.sp_Manager_XemNhanVienCungPhong TO Role_Manager;

-- Role_Finance 
GRANT EXECUTE ON dbo.sp_Auth_Me TO Role_Finance;
GRANT EXECUTE ON dbo.sp_Employee_XemThongTinCaNhan TO Role_Finance;
GRANT EXECUTE ON dbo.sp_Employee_XemNhanVienCungPhong TO Role_Finance;
GRANT EXECUTE ON dbo.sp_Finance_XemLuongCongTy TO Role_Finance;

-- Role_HR_Staff 
GRANT EXECUTE ON dbo.sp_Auth_Me TO Role_HR_Staff;
GRANT EXECUTE ON dbo.sp_Employee_XemThongTinCaNhan TO Role_HR_Staff;
GRANT EXECUTE ON dbo.sp_HR_XemNhanVienNgoaiPhong TO Role_HR_Staff;
GRANT EXECUTE ON dbo.sp_HR_InsertNhanVien TO Role_HR_Staff;
GRANT EXECUTE ON dbo.sp_HR_UpdateNhanVien TO Role_HR_Staff;
GRANT EXECUTE ON dbo.sp_HR_DeleteNhanVien TO Role_HR_Staff;

-- Role_HR_Manager 
GRANT EXECUTE ON dbo.sp_Auth_Me TO Role_HR_Manager;
GRANT EXECUTE ON dbo.sp_Employee_XemThongTinCaNhan TO Role_HR_Manager;
GRANT EXECUTE ON dbo.sp_HRManager_XemTatCaNhanVien TO Role_HR_Manager;
GRANT EXECUTE ON dbo.sp_HRManager_InsertNhanVien TO Role_HR_Manager;
GRANT EXECUTE ON dbo.sp_HRManager_UpdateNhanVien TO Role_HR_Manager;
GRANT EXECUTE ON dbo.sp_HRManager_DeleteNhanVien TO Role_HR_Manager;
GRANT EXECUTE ON dbo.sp_HRManager_XemNhatKy TO Role_HR_Manager;
GRANT EXECUTE ON dbo.sp_HRManager_DoiTrangThaiTaiKhoan TO Role_HR_Manager;
GRANT EXECUTE ON dbo.sp_HRManager_DoiVaiTro TO Role_HR_Manager;
GRANT EXECUTE ON dbo.sp_HRManager_XemTaiKhoan TO Role_HR_Manager;

-- Cấp quyền thực thi procedure cho tất cả các Role
GRANT EXECUTE ON dbo.sp_Auth_DoiMatKhau TO Role_Employee;
GRANT EXECUTE ON dbo.sp_Auth_DoiMatKhau TO Role_Manager;
GRANT EXECUTE ON dbo.sp_Auth_DoiMatKhau TO Role_Finance;
GRANT EXECUTE ON dbo.sp_Auth_DoiMatKhau TO Role_HR_Staff;
GRANT EXECUTE ON dbo.sp_Auth_DoiMatKhau TO Role_HR_Manager;

-- Quyen cho test_user (NodeJS connect)
GRANT EXECUTE ON dbo.sp_Auth_Login TO test_user;
GRANT EXECUTE ON dbo.sp_Auth_Me TO test_user;
GRANT EXECUTE ON dbo.sp_Auth_DoiMatKhau TO test_user;
GO

GRANT EXECUTE ON dbo.sp_OpenSalaryKeyByPhong TO Role_Manager;
GRANT EXECUTE ON dbo.sp_CloseSalaryKeyByPhong TO Role_Manager;
GRANT EXECUTE ON dbo.sp_OpenAllSalaryKeys TO Role_Finance;
GRANT EXECUTE ON dbo.sp_CloseAllSalaryKeys TO Role_Finance;
GRANT EXECUTE ON dbo.sp_OpenAllSalaryKeys TO Role_HR_Manager;
GRANT EXECUTE ON dbo.sp_CloseAllSalaryKeys TO Role_HR_Manager;

DENY SELECT, INSERT, UPDATE, DELETE ON dbo.PHONGBAN TO PUBLIC;
GO
GRANT EXECUTE ON dbo.sp_HRManager_XemDanhSachPhongBan TO Role_HR_Manager;
GRANT EXECUTE ON dbo.sp_HRManager_ThemPhongBan TO Role_HR_Manager;
GRANT EXECUTE ON dbo.sp_HRManager_CapNhatPhongBan TO Role_HR_Manager;
GO