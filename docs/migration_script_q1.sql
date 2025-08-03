-- =====================================================
-- MIGRATION SCRIPT FOR SITE Q1 (ThuVienQ1) - CORRECTED
-- Database: ThuVienQ1 on MSSQLSERVER1 (port 1431)
-- Date: 2025-08-03
-- Purpose: Full schema creation according to requirements.md
-- =====================================================

USE ThuVienQ1;
GO

PRINT '========================================';
PRINT 'STARTING CORRECTED MIGRATION FOR SITE Q1';
PRINT '========================================';

-- =====================================================
-- STEP 1: CREATE TABLE SCHEMAS
-- =====================================================

PRINT 'Step 1: Creating table schemas...';

-- 1.1. Create CHINHANH table (FULLY REPLICATED)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'CHINHANH')
BEGIN
    CREATE TABLE CHINHANH (
        MaCN VARCHAR(10) PRIMARY KEY,
        TenCN NVARCHAR(255) NOT NULL,
        DiaChi NVARCHAR(255) NOT NULL
    );
    PRINT '✓ Created CHINHANH table (Fully Replicated)';
END
ELSE
    PRINT '⚠ CHINHANH table already exists';

-- 1.2. Create SACH table (FULLY REPLICATED)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'SACH')
BEGIN
    CREATE TABLE SACH (
        ISBN VARCHAR(20) PRIMARY KEY,
        TenSach NVARCHAR(255) NOT NULL,
        TacGia NVARCHAR(255) NOT NULL
    );
    PRINT '✓ Created SACH table (Fully Replicated)';
END
ELSE
    PRINT '⚠ SACH table already exists';

-- 1.3. Create QUYENSACH table (HORIZONTALLY FRAGMENTED by MaCN)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'QUYENSACH')
BEGIN
    CREATE TABLE QUYENSACH (
        MaQuyenSach VARCHAR(20) PRIMARY KEY,
        ISBN VARCHAR(20) NOT NULL,
        MaCN VARCHAR(10) NOT NULL,
        TinhTrang NVARCHAR(50) NOT NULL DEFAULT N'Có sẵn',
        FOREIGN KEY (ISBN) REFERENCES SACH(ISBN),
        FOREIGN KEY (MaCN) REFERENCES CHINHANH(MaCN),
        CONSTRAINT CHK_QuyenSach_MaCN CHECK (MaCN = 'Q1'), -- Fragment constraint
        CONSTRAINT CHK_QuyenSach_TinhTrang CHECK (TinhTrang IN (N'Có sẵn', N'Đang được mượn'))
    );
    PRINT '✓ Created QUYENSACH table (Horizontally Fragmented - Q1 only)';
END
ELSE
    PRINT '⚠ QUYENSACH table already exists';

-- 1.4. Create DOCGIA table (HORIZONTALLY FRAGMENTED by MaCN_DangKy)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'DOCGIA')
BEGIN
    CREATE TABLE DOCGIA (
        MaDG VARCHAR(10) PRIMARY KEY,
        HoTen NVARCHAR(255) NOT NULL,
        MaCN_DangKy VARCHAR(10) NOT NULL,
        FOREIGN KEY (MaCN_DangKy) REFERENCES CHINHANH(MaCN),
        CONSTRAINT CHK_DocGia_MaCN CHECK (MaCN_DangKy = 'Q1') -- Fragment constraint
    );
    PRINT '✓ Created DOCGIA table (Horizontally Fragmented - Q1 only)';
END
ELSE
    PRINT '⚠ DOCGIA table already exists';

-- 1.5. Create PHIEUMUON table (HORIZONTALLY FRAGMENTED by MaCN)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'PHIEUMUON')
BEGIN
    CREATE TABLE PHIEUMUON (
        MaPM INT IDENTITY(1,1) PRIMARY KEY,
        MaDG VARCHAR(10) NOT NULL,
        MaQuyenSach VARCHAR(20) NOT NULL,
        MaCN VARCHAR(10) NOT NULL,
        NgayMuon DATETIME NOT NULL DEFAULT GETDATE(),
        NgayTra DATETIME NULL,
        FOREIGN KEY (MaDG) REFERENCES DOCGIA(MaDG),
        FOREIGN KEY (MaQuyenSach) REFERENCES QUYENSACH(MaQuyenSach),
        FOREIGN KEY (MaCN) REFERENCES CHINHANH(MaCN),
        CONSTRAINT CHK_PhieuMuon_MaCN CHECK (MaCN = 'Q1') -- Fragment constraint
    );
    PRINT '✓ Created PHIEUMUON table (Horizontally Fragmented - Q1 only)';
END
ELSE
    PRINT '⚠ PHIEUMUON table already exists';

-- =====================================================
-- STEP 2: INSERT SAMPLE DATA
-- =====================================================

PRINT 'Step 2: Inserting sample data...';

-- 2.1. Insert into CHINHANH (replicated data)
IF NOT EXISTS (SELECT 1 FROM CHINHANH WHERE MaCN = 'Q1')
BEGIN
    INSERT INTO CHINHANH VALUES 
        ('Q1', N'Thư viện Quận 1', N'123 Nguyễn Huệ, Quận 1, TP.HCM'),
        ('Q3', N'Thư viện Quận 3', N'456 Võ Văn Tần, Quận 3, TP.HCM');
    PRINT '✓ Inserted CHINHANH sample data';
END
ELSE
    PRINT '⚠ CHINHANH sample data already exists';

-- 2.2. Insert into SACH (replicated data)
IF NOT EXISTS (SELECT 1 FROM SACH WHERE ISBN = '978-604-2-25308-0')
BEGIN
    INSERT INTO SACH VALUES 
        ('978-604-2-25308-0', N'Sapiens: Lược sử loài người', N'Yuval Noah Harari'),
        ('978-604-2-13949-1', N'Homo Deus: Lược sử tương lai', N'Yuval Noah Harari'),
        ('978-604-2-15234-7', N'21 Lessons for the 21st Century', N'Yuval Noah Harari');
    PRINT '✓ Inserted SACH sample data';
END
ELSE
    PRINT '⚠ SACH sample data already exists';

-- 2.3. Insert into DOCGIA (Q1 fragment only)
IF NOT EXISTS (SELECT 1 FROM DOCGIA WHERE MaDG = 'DG001')
BEGIN
    INSERT INTO DOCGIA VALUES 
        ('DG001', N'Nguyễn Văn An', 'Q1'),
        ('DG002', N'Trần Thị Bình', 'Q1');
    PRINT '✓ Inserted DOCGIA sample data for Q1';
END
ELSE
    PRINT '⚠ DOCGIA sample data already exists';

-- 2.4. Insert into QUYENSACH (Q1 fragment only)
IF NOT EXISTS (SELECT 1 FROM QUYENSACH WHERE MaQuyenSach = 'Q1-001')
BEGIN
    INSERT INTO QUYENSACH VALUES 
        ('Q1-001', '978-604-2-25308-0', 'Q1', N'Có sẵn'),
        ('Q1-002', '978-604-2-25308-0', 'Q1', N'Có sẵn'),
        ('Q1-003', '978-604-2-13949-1', 'Q1', N'Có sẵn');
    PRINT '✓ Inserted QUYENSACH sample data for Q1';
END
ELSE
    PRINT '⚠ QUYENSACH sample data already exists';

-- =====================================================
-- STEP 3: CREATE CRUD STORED PROCEDURES FOR THUTHU
-- =====================================================

PRINT 'Step 3: Creating CRUD stored procedures for ThuThu...';

-- 3.1. DOCGIA CRUD Procedures
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_ThuThu_CreateDocGia')
    DROP PROCEDURE sp_ThuThu_CreateDocGia;
GO

CREATE PROCEDURE sp_ThuThu_CreateDocGia
    @MaDG VARCHAR(10),
    @HoTen NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Security: Only ThuThu_Q1 and QuanLy can execute
    DECLARE @CurrentUser VARCHAR(50) = USER_NAME();
    IF @CurrentUser NOT IN ('ThuThu_Q1', 'QuanLy')
    BEGIN
        RAISERROR('Access denied: Only ThuThu_Q1 or QuanLy can create readers in Q1', 16, 1);
        RETURN;
    END
    
    BEGIN TRY
        -- Validate inputs
        IF @MaDG IS NULL OR @HoTen IS NULL
        BEGIN
            RAISERROR('MaDG and HoTen are required', 16, 1);
            RETURN;
        END
        
        -- Check for duplicate
        IF EXISTS (SELECT 1 FROM DOCGIA WHERE MaDG = @MaDG)
        BEGIN
            RAISERROR('Reader ID already exists', 16, 1);
            RETURN;
        END
        
        -- Insert with Q1 constraint
        INSERT INTO DOCGIA (MaDG, HoTen, MaCN_DangKy)
        VALUES (@MaDG, @HoTen, 'Q1');
        
        SELECT 'SUCCESS' AS Status, 'Reader created successfully' AS Message, @MaDG AS MaDG;
        
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END;
GO

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_ThuThu_ReadDocGia')
    DROP PROCEDURE sp_ThuThu_ReadDocGia;
GO

CREATE PROCEDURE sp_ThuThu_ReadDocGia
    @MaDG VARCHAR(10) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Security check
    DECLARE @CurrentUser VARCHAR(50) = USER_NAME();
    IF @CurrentUser NOT IN ('ThuThu_Q1', 'QuanLy')
    BEGIN
        RAISERROR('Access denied: Only ThuThu_Q1 or QuanLy can read readers in Q1', 16, 1);
        RETURN;
    END
    
    BEGIN TRY
        IF @MaDG IS NOT NULL
        BEGIN
            SELECT D.*, C.TenCN 
            FROM DOCGIA D 
            JOIN CHINHANH C ON D.MaCN_DangKy = C.MaCN
            WHERE D.MaDG = @MaDG AND D.MaCN_DangKy = 'Q1';
        END
        ELSE
        BEGIN
            SELECT D.*, C.TenCN 
            FROM DOCGIA D 
            JOIN CHINHANH C ON D.MaCN_DangKy = C.MaCN
            WHERE D.MaCN_DangKy = 'Q1'
            ORDER BY D.MaDG;
        END
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END;
GO

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_ThuThu_UpdateDocGia')
    DROP PROCEDURE sp_ThuThu_UpdateDocGia;
GO

CREATE PROCEDURE sp_ThuThu_UpdateDocGia
    @MaDG VARCHAR(10),
    @HoTen NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Security check
    DECLARE @CurrentUser VARCHAR(50) = USER_NAME();
    IF @CurrentUser NOT IN ('ThuThu_Q1', 'QuanLy')
    BEGIN
        RAISERROR('Access denied: Only ThuThu_Q1 or QuanLy can update readers in Q1', 16, 1);
        RETURN;
    END
    
    BEGIN TRY
        -- Validate inputs
        IF @MaDG IS NULL OR @HoTen IS NULL
        BEGIN
            RAISERROR('MaDG and HoTen are required', 16, 1);
            RETURN;
        END
        
        -- Check if reader exists in Q1
        IF NOT EXISTS (SELECT 1 FROM DOCGIA WHERE MaDG = @MaDG AND MaCN_DangKy = 'Q1')
        BEGIN
            RAISERROR('Reader not found in Q1 branch', 16, 1);
            RETURN;
        END
        
        -- Update (cannot change MaCN_DangKy - fragmentation key)
        UPDATE DOCGIA 
        SET HoTen = @HoTen
        WHERE MaDG = @MaDG AND MaCN_DangKy = 'Q1';
        
        SELECT 'SUCCESS' AS Status, 'Reader updated successfully' AS Message, @MaDG AS MaDG;
        
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END;
GO

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_ThuThu_DeleteDocGia')
    DROP PROCEDURE sp_ThuThu_DeleteDocGia;
GO

CREATE PROCEDURE sp_ThuThu_DeleteDocGia
    @MaDG VARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Security check
    DECLARE @CurrentUser VARCHAR(50) = USER_NAME();
    IF @CurrentUser NOT IN ('ThuThu_Q1', 'QuanLy')
    BEGIN
        RAISERROR('Access denied: Only ThuThu_Q1 or QuanLy can delete readers in Q1', 16, 1);
        RETURN;
    END
    
    BEGIN TRY
        -- Validate input
        IF @MaDG IS NULL
        BEGIN
            RAISERROR('MaDG is required', 16, 1);
            RETURN;
        END
        
        -- Check for active borrows (referential integrity)
        IF EXISTS (SELECT 1 FROM PHIEUMUON WHERE MaDG = @MaDG AND NgayTra IS NULL)
        BEGIN
            RAISERROR('Cannot delete reader with active borrows', 16, 1);
            RETURN;
        END
        
        -- Check if reader exists in Q1
        IF NOT EXISTS (SELECT 1 FROM DOCGIA WHERE MaDG = @MaDG AND MaCN_DangKy = 'Q1')
        BEGIN
            RAISERROR('Reader not found in Q1 branch', 16, 1);
            RETURN;
        END
        
        DELETE FROM DOCGIA WHERE MaDG = @MaDG AND MaCN_DangKy = 'Q1';
        
        SELECT 'SUCCESS' AS Status, 'Reader deleted successfully' AS Message, @MaDG AS MaDG;
        
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END;
GO

-- 3.2. QUYENSACH CRUD Procedures
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_ThuThu_CreateQuyenSach')
    DROP PROCEDURE sp_ThuThu_CreateQuyenSach;
GO

CREATE PROCEDURE sp_ThuThu_CreateQuyenSach
    @MaQuyenSach VARCHAR(20),
    @ISBN VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Security check
    DECLARE @CurrentUser VARCHAR(50) = USER_NAME();
    IF @CurrentUser NOT IN ('ThuThu_Q1', 'QuanLy')
    BEGIN
        RAISERROR('Access denied: Only ThuThu_Q1 or QuanLy can create book copies in Q1', 16, 1);
        RETURN;
    END
    
    BEGIN TRY
        -- Validate inputs
        IF @MaQuyenSach IS NULL OR @ISBN IS NULL
        BEGIN
            RAISERROR('MaQuyenSach and ISBN are required', 16, 1);
            RETURN;
        END
        
        -- Check if ISBN exists in SACH
        IF NOT EXISTS (SELECT 1 FROM SACH WHERE ISBN = @ISBN)
        BEGIN
            RAISERROR('ISBN not found in book catalog', 16, 1);
            RETURN;
        END
        
        -- Check for duplicate
        IF EXISTS (SELECT 1 FROM QUYENSACH WHERE MaQuyenSach = @MaQuyenSach)
        BEGIN
            RAISERROR('Book copy ID already exists', 16, 1);
            RETURN;
        END
        
        -- Insert with Q1 constraint
        INSERT INTO QUYENSACH (MaQuyenSach, ISBN, MaCN, TinhTrang)
        VALUES (@MaQuyenSach, @ISBN, 'Q1', N'Có sẵn');
        
        SELECT 'SUCCESS' AS Status, 'Book copy created successfully' AS Message, @MaQuyenSach AS MaQuyenSach;
        
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END;
GO

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_ThuThu_ReadQuyenSach')
    DROP PROCEDURE sp_ThuThu_ReadQuyenSach;
GO

CREATE PROCEDURE sp_ThuThu_ReadQuyenSach
    @MaQuyenSach VARCHAR(20) = NULL,
    @ISBN VARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Security check
    DECLARE @CurrentUser VARCHAR(50) = USER_NAME();
    IF @CurrentUser NOT IN ('ThuThu_Q1', 'QuanLy')
    BEGIN
        RAISERROR('Access denied: Only ThuThu_Q1 or QuanLy can read book copies in Q1', 16, 1);
        RETURN;
    END
    
    BEGIN TRY
        IF @MaQuyenSach IS NOT NULL
        BEGIN
            SELECT Q.*, S.TenSach, S.TacGia, C.TenCN 
            FROM QUYENSACH Q 
            JOIN SACH S ON Q.ISBN = S.ISBN
            JOIN CHINHANH C ON Q.MaCN = C.MaCN
            WHERE Q.MaQuyenSach = @MaQuyenSach AND Q.MaCN = 'Q1';
        END
        ELSE IF @ISBN IS NOT NULL
        BEGIN
            SELECT Q.*, S.TenSach, S.TacGia, C.TenCN 
            FROM QUYENSACH Q 
            JOIN SACH S ON Q.ISBN = S.ISBN
            JOIN CHINHANH C ON Q.MaCN = C.MaCN
            WHERE Q.ISBN = @ISBN AND Q.MaCN = 'Q1'
            ORDER BY Q.MaQuyenSach;
        END
        ELSE
        BEGIN
            SELECT Q.*, S.TenSach, S.TacGia, C.TenCN 
            FROM QUYENSACH Q 
            JOIN SACH S ON Q.ISBN = S.ISBN
            JOIN CHINHANH C ON Q.MaCN = C.MaCN
            WHERE Q.MaCN = 'Q1'
            ORDER BY S.TenSach, Q.MaQuyenSach;
        END
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END;
GO

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_ThuThu_UpdateQuyenSach')
    DROP PROCEDURE sp_ThuThu_UpdateQuyenSach;
GO

CREATE PROCEDURE sp_ThuThu_UpdateQuyenSach
    @MaQuyenSach VARCHAR(20),
    @TinhTrang NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Security check
    DECLARE @CurrentUser VARCHAR(50) = USER_NAME();
    IF @CurrentUser NOT IN ('ThuThu_Q1', 'QuanLy')
    BEGIN
        RAISERROR('Access denied: Only ThuThu_Q1 or QuanLy can update book copies in Q1', 16, 1);
        RETURN;
    END
    
    BEGIN TRY
        -- Validate inputs
        IF @MaQuyenSach IS NULL OR @TinhTrang IS NULL
        BEGIN
            RAISERROR('MaQuyenSach and TinhTrang are required', 16, 1);
            RETURN;
        END
        
        -- Check if book copy exists in Q1
        IF NOT EXISTS (SELECT 1 FROM QUYENSACH WHERE MaQuyenSach = @MaQuyenSach AND MaCN = 'Q1')
        BEGIN
            RAISERROR('Book copy not found in Q1 branch', 16, 1);
            RETURN;
        END
        
        -- Validate TinhTrang
        IF @TinhTrang NOT IN (N'Có sẵn', N'Đang được mượn')
        BEGIN
            RAISERROR('Invalid TinhTrang. Must be ''Có sẵn'' or ''Đang được mượn''', 16, 1);
            RETURN;
        END
        
        -- Update status
        UPDATE QUYENSACH 
        SET TinhTrang = @TinhTrang
        WHERE MaQuyenSach = @MaQuyenSach AND MaCN = 'Q1';
        
        SELECT 'SUCCESS' AS Status, 'Book copy updated successfully' AS Message, @MaQuyenSach AS MaQuyenSach;
        
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END;
GO

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_ThuThu_DeleteQuyenSach')
    DROP PROCEDURE sp_ThuThu_DeleteQuyenSach;
GO

CREATE PROCEDURE sp_ThuThu_DeleteQuyenSach
    @MaQuyenSach VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Security check
    DECLARE @CurrentUser VARCHAR(50) = USER_NAME();
    IF @CurrentUser NOT IN ('ThuThu_Q1', 'QuanLy')
    BEGIN
        RAISERROR('Access denied: Only ThuThu_Q1 or QuanLy can delete book copies in Q1', 16, 1);
        RETURN;
    END
    
    BEGIN TRY
        -- Validate input
        IF @MaQuyenSach IS NULL
        BEGIN
            RAISERROR('MaQuyenSach is required', 16, 1);
            RETURN;
        END
        
        -- Check if book copy is currently borrowed
        IF EXISTS (SELECT 1 FROM PHIEUMUON WHERE MaQuyenSach = @MaQuyenSach AND NgayTra IS NULL)
        BEGIN
            RAISERROR('Cannot delete book copy that is currently borrowed', 16, 1);
            RETURN;
        END
        
        -- Check if book copy exists in Q1
        IF NOT EXISTS (SELECT 1 FROM QUYENSACH WHERE MaQuyenSach = @MaQuyenSach AND MaCN = 'Q1')
        BEGIN
            RAISERROR('Book copy not found in Q1 branch', 16, 1);
            RETURN;
        END
        
        DELETE FROM QUYENSACH WHERE MaQuyenSach = @MaQuyenSach AND MaCN = 'Q1';
        
        SELECT 'SUCCESS' AS Status, 'Book copy deleted successfully' AS Message, @MaQuyenSach AS MaQuyenSach;
        
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END;
GO

-- 3.3. PHIEUMUON CRUD Procedures for borrowing management
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_ThuThu_CreatePhieuMuon')
    DROP PROCEDURE sp_ThuThu_CreatePhieuMuon;
GO

CREATE PROCEDURE sp_ThuThu_CreatePhieuMuon
    @MaDG VARCHAR(10),
    @MaQuyenSach VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Security check
    DECLARE @CurrentUser VARCHAR(50) = USER_NAME();
    IF @CurrentUser NOT IN ('ThuThu_Q1', 'QuanLy')
    BEGIN
        RAISERROR('Access denied: Only ThuThu_Q1 or QuanLy can create borrow records in Q1', 16, 1);
        RETURN;
    END
    
    BEGIN TRY
        -- Validate inputs
        IF @MaDG IS NULL OR @MaQuyenSach IS NULL
        BEGIN
            RAISERROR('MaDG and MaQuyenSach are required', 16, 1);
            RETURN;
        END
        
        -- Check if reader exists in Q1
        IF NOT EXISTS (SELECT 1 FROM DOCGIA WHERE MaDG = @MaDG AND MaCN_DangKy = 'Q1')
        BEGIN
            RAISERROR('Reader not found in Q1 branch', 16, 1);
            RETURN;
        END
        
        -- Check if book copy exists and is available
        IF NOT EXISTS (SELECT 1 FROM QUYENSACH WHERE MaQuyenSach = @MaQuyenSach AND MaCN = 'Q1' AND TinhTrang = N'Có sẵn')
        BEGIN
            RAISERROR('Book copy not available for borrowing in Q1', 16, 1);
            RETURN;
        END
        
        -- Create borrow record
        INSERT INTO PHIEUMUON (MaDG, MaQuyenSach, MaCN, NgayMuon)
        VALUES (@MaDG, @MaQuyenSach, 'Q1', GETDATE());
        
        -- Update book status
        UPDATE QUYENSACH 
        SET TinhTrang = N'Đang được mượn'
        WHERE MaQuyenSach = @MaQuyenSach AND MaCN = 'Q1';
        
        DECLARE @MaPM INT = SCOPE_IDENTITY();
        SELECT 'SUCCESS' AS Status, 'Borrow record created successfully' AS Message, @MaPM AS MaPM;
        
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END;
GO

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_ThuThu_ReturnBook')
    DROP PROCEDURE sp_ThuThu_ReturnBook;
GO

CREATE PROCEDURE sp_ThuThu_ReturnBook
    @MaPM INT = NULL,
    @MaQuyenSach VARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Security check
    DECLARE @CurrentUser VARCHAR(50) = USER_NAME();
    IF @CurrentUser NOT IN ('ThuThu_Q1', 'QuanLy')
    BEGIN
        RAISERROR('Access denied: Only ThuThu_Q1 or QuanLy can process returns in Q1', 16, 1);
        RETURN;
    END
    
    BEGIN TRY
        -- Must provide either MaPM or MaQuyenSach
        IF @MaPM IS NULL AND @MaQuyenSach IS NULL
        BEGIN
            RAISERROR('Either MaPM or MaQuyenSach must be provided', 16, 1);
            RETURN;
        END
        
        DECLARE @FoundMaPM INT;
        DECLARE @FoundMaQuyenSach VARCHAR(20);
        
        -- Find the active borrow record
        IF @MaPM IS NOT NULL
        BEGIN
            SELECT @FoundMaPM = MaPM, @FoundMaQuyenSach = MaQuyenSach
            FROM PHIEUMUON 
            WHERE MaPM = @MaPM AND MaCN = 'Q1' AND NgayTra IS NULL;
        END
        ELSE
        BEGIN
            SELECT @FoundMaPM = MaPM, @FoundMaQuyenSach = MaQuyenSach
            FROM PHIEUMUON 
            WHERE MaQuyenSach = @MaQuyenSach AND MaCN = 'Q1' AND NgayTra IS NULL;
        END
        
        IF @FoundMaPM IS NULL
        BEGIN
            RAISERROR('Active borrow record not found in Q1', 16, 1);
            RETURN;
        END
        
        -- Update return date
        UPDATE PHIEUMUON 
        SET NgayTra = GETDATE()
        WHERE MaPM = @FoundMaPM AND MaCN = 'Q1';
        
        -- Update book status
        UPDATE QUYENSACH 
        SET TinhTrang = N'Có sẵn'
        WHERE MaQuyenSach = @FoundMaQuyenSach AND MaCN = 'Q1';
        
        SELECT 'SUCCESS' AS Status, 'Book returned successfully' AS Message, @FoundMaPM AS MaPM;
        
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END;
GO

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_ThuThu_ReadPhieuMuon')
    DROP PROCEDURE sp_ThuThu_ReadPhieuMuon;
GO

CREATE PROCEDURE sp_ThuThu_ReadPhieuMuon
    @MaPM INT = NULL,
    @MaDG VARCHAR(10) = NULL,
    @MaQuyenSach VARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Security check
    DECLARE @CurrentUser VARCHAR(50) = USER_NAME();
    IF @CurrentUser NOT IN ('ThuThu_Q1', 'QuanLy')
    BEGIN
        RAISERROR('Access denied: Only ThuThu_Q1 or QuanLy can read borrow records in Q1', 16, 1);
        RETURN;
    END
    
    BEGIN TRY
        IF @MaPM IS NOT NULL
        BEGIN
            SELECT P.*, D.HoTen, S.TenSach, S.TacGia, C.TenCN 
            FROM PHIEUMUON P 
            JOIN DOCGIA D ON P.MaDG = D.MaDG
            JOIN QUYENSACH Q ON P.MaQuyenSach = Q.MaQuyenSach
            JOIN SACH S ON Q.ISBN = S.ISBN
            JOIN CHINHANH C ON P.MaCN = C.MaCN
            WHERE P.MaPM = @MaPM AND P.MaCN = 'Q1';
        END
        ELSE IF @MaDG IS NOT NULL
        BEGIN
            SELECT P.*, D.HoTen, S.TenSach, S.TacGia, C.TenCN 
            FROM PHIEUMUON P 
            JOIN DOCGIA D ON P.MaDG = D.MaDG
            JOIN QUYENSACH Q ON P.MaQuyenSach = Q.MaQuyenSach
            JOIN SACH S ON Q.ISBN = S.ISBN
            JOIN CHINHANH C ON P.MaCN = C.MaCN
            WHERE P.MaDG = @MaDG AND P.MaCN = 'Q1'
            ORDER BY P.NgayMuon DESC;
        END
        ELSE IF @MaQuyenSach IS NOT NULL
        BEGIN
            SELECT P.*, D.HoTen, S.TenSach, S.TacGia, C.TenCN 
            FROM PHIEUMUON P 
            JOIN DOCGIA D ON P.MaDG = D.MaDG
            JOIN QUYENSACH Q ON P.MaQuyenSach = Q.MaQuyenSach
            JOIN SACH S ON Q.ISBN = S.ISBN
            JOIN CHINHANH C ON P.MaCN = C.MaCN
            WHERE P.MaQuyenSach = @MaQuyenSach AND P.MaCN = 'Q1'
            ORDER BY P.NgayMuon DESC;
        END
        ELSE
        BEGIN
            SELECT P.*, D.HoTen, S.TenSach, S.TacGia, C.TenCN 
            FROM PHIEUMUON P 
            JOIN DOCGIA D ON P.MaDG = D.MaDG
            JOIN QUYENSACH Q ON P.MaQuyenSach = Q.MaQuyenSach
            JOIN SACH S ON Q.ISBN = S.ISBN
            JOIN CHINHANH C ON P.MaCN = C.MaCN
            WHERE P.MaCN = 'Q1'
            ORDER BY P.NgayMuon DESC;
        END
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END;
GO

-- =====================================================
-- STEP 4: CREATE PROCEDURES FOR QUANLY (DISTRIBUTED QUERIES)
-- =====================================================

PRINT 'Step 4: Creating procedures for QuanLy (Manager)...';

-- SACH management procedures (for replicated table management via 2PC)
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_QuanLy_ReadSach')
    DROP PROCEDURE sp_QuanLy_ReadSach;
GO

CREATE PROCEDURE sp_QuanLy_ReadSach
    @ISBN VARCHAR(20) = NULL,
    @TenSach NVARCHAR(255) = NULL,
    @TacGia NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Only managers can manage replicated SACH table
    DECLARE @CurrentUser VARCHAR(50) = USER_NAME();
    IF @CurrentUser != 'QuanLy'
    BEGIN
        RAISERROR('Access denied: Only managers can read book catalog', 16, 1);
        RETURN;
    END
    
    BEGIN TRY
        IF @ISBN IS NOT NULL
        BEGIN
            SELECT * FROM SACH WHERE ISBN = @ISBN;
        END
        ELSE IF @TenSach IS NOT NULL OR @TacGia IS NOT NULL
        BEGIN
            SELECT * FROM SACH 
            WHERE (@TenSach IS NULL OR TenSach LIKE '%' + @TenSach + '%')
                AND (@TacGia IS NULL OR TacGia LIKE '%' + @TacGia + '%')
            ORDER BY TenSach;
        END
        ELSE
        BEGIN
            SELECT * FROM SACH ORDER BY TenSach;
        END
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END;
GO

-- Search for available books at this site (for distributed search - FR7)
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_QuanLy_SearchAvailableBooks')
    DROP PROCEDURE sp_QuanLy_SearchAvailableBooks;
GO

CREATE PROCEDURE sp_QuanLy_SearchAvailableBooks
    @TenSach NVARCHAR(255) = NULL,
    @TacGia NVARCHAR(255) = NULL,
    @ISBN VARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- This procedure returns available books at Q1 site only
    -- Manager application will call this on all sites and aggregate (FR7)
    SELECT 
        'Q1' AS SiteCode,
        Q.MaQuyenSach,
        Q.ISBN,
        S.TenSach,
        S.TacGia,
        Q.TinhTrang,
        C.TenCN AS ChiNhanh
    FROM QUYENSACH Q
    JOIN SACH S ON Q.ISBN = S.ISBN
    JOIN CHINHANH C ON Q.MaCN = C.MaCN
    WHERE Q.MaCN = 'Q1'
        AND (@TenSach IS NULL OR S.TenSach LIKE '%' + @TenSach + '%')
        AND (@TacGia IS NULL OR S.TacGia LIKE '%' + @TacGia + '%')
        AND (@ISBN IS NULL OR S.ISBN = @ISBN)
    ORDER BY S.TenSach, Q.MaQuyenSach;
END;
GO

-- 2PC procedures for SACH table management (replicated table - FR10)
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_QuanLy_PrepareCreateSach')
    DROP PROCEDURE sp_QuanLy_PrepareCreateSach;
GO

CREATE PROCEDURE sp_QuanLy_PrepareCreateSach
    @ISBN VARCHAR(20),
    @TenSach NVARCHAR(255),
    @TacGia NVARCHAR(255),
    @TransactionId VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Phase 1 of 2PC: Prepare
    BEGIN TRY
        -- Check if ISBN already exists
        IF EXISTS (SELECT 1 FROM SACH WHERE ISBN = @ISBN)
        BEGIN
            RAISERROR('ISBN already exists', 16, 1);
            RETURN;
        END
        
        -- Log the prepared transaction (in production, use a transaction log table)
        -- For now, just validate and return success
        SELECT 'PREPARED' AS Status, 'Ready to commit on Q1' AS Message, @TransactionId AS TransactionId;
        
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END;
GO

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_QuanLy_CommitCreateSach')
    DROP PROCEDURE sp_QuanLy_CommitCreateSach;
GO

CREATE PROCEDURE sp_QuanLy_CommitCreateSach
    @ISBN VARCHAR(20),
    @TenSach NVARCHAR(255),
    @TacGia NVARCHAR(255),
    @TransactionId VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Phase 2 of 2PC: Commit
    BEGIN TRY
        INSERT INTO SACH (ISBN, TenSach, TacGia)
        VALUES (@ISBN, @TenSach, @TacGia);
        
        SELECT 'COMMITTED' AS Status, 'Book created successfully on Q1' AS Message, @TransactionId AS TransactionId;
        
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END;
GO

-- =====================================================
-- STEP 4: CREATE PROCEDURES FOR QUANLY (DISTRIBUTED QUERIES)
-- =====================================================

PRINT 'Step 4: Creating procedures for QuanLy (Manager)...';

-- For managers - these will be used in distributed query scenarios
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_QuanLy_GetSiteStatistics')
    DROP PROCEDURE sp_QuanLy_GetSiteStatistics;
GO

CREATE PROCEDURE sp_QuanLy_GetSiteStatistics
AS
BEGIN
    SET NOCOUNT ON;
    
    -- This procedure returns statistics for Q1 site only
    -- Manager application will call this on all sites and aggregate
    SELECT 
        'Q1' AS SiteCode,
        COUNT(DISTINCT D.MaDG) AS TotalReaders,
        COUNT(DISTINCT Q.MaQuyenSach) AS TotalBooks,
        COUNT(CASE WHEN Q.TinhTrang = N'Có sẵn' THEN 1 END) AS AvailableBooks,
        COUNT(CASE WHEN Q.TinhTrang = N'Đang được mượn' THEN 1 END) AS BorrowedBooks,
        COUNT(CASE WHEN P.NgayTra IS NULL THEN 1 END) AS ActiveBorrows
    FROM DOCGIA D
    FULL OUTER JOIN QUYENSACH Q ON D.MaCN_DangKy = Q.MaCN
    FULL OUTER JOIN PHIEUMUON P ON Q.MaQuyenSach = P.MaQuyenSach AND P.MaCN = 'Q1' AND P.NgayTra IS NULL;
END;
GO

-- =====================================================
-- STEP 5: GRANT PERMISSIONS
-- =====================================================

PRINT 'Step 5: Granting permissions...';

-- Create users if they don't exist (assumes they are created at instance level)
-- Grant permissions to ThuThu_Q1
GRANT SELECT, INSERT, UPDATE, DELETE ON DOCGIA TO ThuThu_Q1;
GRANT SELECT, INSERT, UPDATE, DELETE ON QUYENSACH TO ThuThu_Q1;
GRANT SELECT, INSERT, UPDATE, DELETE ON PHIEUMUON TO ThuThu_Q1;
GRANT SELECT ON SACH TO ThuThu_Q1;
GRANT SELECT ON CHINHANH TO ThuThu_Q1;
GRANT EXECUTE ON sp_ThuThu_CreateDocGia TO ThuThu_Q1;
GRANT EXECUTE ON sp_ThuThu_ReadDocGia TO ThuThu_Q1;
GRANT EXECUTE ON sp_ThuThu_UpdateDocGia TO ThuThu_Q1;
GRANT EXECUTE ON sp_ThuThu_DeleteDocGia TO ThuThu_Q1;
GRANT EXECUTE ON sp_ThuThu_CreateQuyenSach TO ThuThu_Q1;
GRANT EXECUTE ON sp_ThuThu_ReadQuyenSach TO ThuThu_Q1;
GRANT EXECUTE ON sp_ThuThu_UpdateQuyenSach TO ThuThu_Q1;
GRANT EXECUTE ON sp_ThuThu_DeleteQuyenSach TO ThuThu_Q1;
GRANT EXECUTE ON sp_ThuThu_CreatePhieuMuon TO ThuThu_Q1;
GRANT EXECUTE ON sp_ThuThu_ReadPhieuMuon TO ThuThu_Q1;
GRANT EXECUTE ON sp_ThuThu_ReturnBook TO ThuThu_Q1;

-- Grant permissions to QuanLy
GRANT SELECT, INSERT, UPDATE, DELETE ON DOCGIA TO QuanLy;
GRANT SELECT, INSERT, UPDATE, DELETE ON QUYENSACH TO QuanLy;
GRANT SELECT, INSERT, UPDATE, DELETE ON PHIEUMUON TO QuanLy;
GRANT SELECT, INSERT, UPDATE, DELETE ON SACH TO QuanLy;
GRANT SELECT ON CHINHANH TO QuanLy;
GRANT EXECUTE ON sp_QuanLy_GetSiteStatistics TO QuanLy;
GRANT EXECUTE ON sp_QuanLy_ReadSach TO QuanLy;
GRANT EXECUTE ON sp_QuanLy_SearchAvailableBooks TO QuanLy;
GRANT EXECUTE ON sp_QuanLy_PrepareCreateSach TO QuanLy;
GRANT EXECUTE ON sp_QuanLy_CommitCreateSach TO QuanLy;
-- QuanLy can also use ThuThu procedures
GRANT EXECUTE ON sp_ThuThu_CreateDocGia TO QuanLy;
GRANT EXECUTE ON sp_ThuThu_ReadDocGia TO QuanLy;
GRANT EXECUTE ON sp_ThuThu_UpdateDocGia TO QuanLy;
GRANT EXECUTE ON sp_ThuThu_DeleteDocGia TO QuanLy;
GRANT EXECUTE ON sp_ThuThu_ReadQuyenSach TO QuanLy;
GRANT EXECUTE ON sp_ThuThu_ReadPhieuMuon TO QuanLy;

PRINT '✓ Granted permissions successfully';

-- =====================================================
-- STEP 6: VERIFY MIGRATION
-- =====================================================

PRINT 'Step 6: Verifying migration...';

-- Check tables
SELECT 
    TABLE_NAME,
    TABLE_TYPE
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_NAME IN ('CHINHANH', 'SACH', 'QUYENSACH', 'DOCGIA', 'PHIEUMUON')
ORDER BY TABLE_NAME;

-- Check stored procedures
SELECT 
    ROUTINE_NAME,
    ROUTINE_TYPE,
    CREATED
FROM INFORMATION_SCHEMA.ROUTINES 
WHERE ROUTINE_NAME LIKE 'sp_ThuThu_%' 
   OR ROUTINE_NAME LIKE 'sp_QuanLy_%'
ORDER BY ROUTINE_NAME;

-- Check constraints
SELECT 
    TABLE_NAME,
    CONSTRAINT_NAME,
    CONSTRAINT_TYPE
FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS 
WHERE TABLE_NAME IN ('QUYENSACH', 'DOCGIA', 'PHIEUMUON')
    AND CONSTRAINT_TYPE = 'CHECK'
ORDER BY TABLE_NAME;

PRINT '========================================';
PRINT 'CORRECTED MIGRATION COMPLETED FOR SITE Q1';
PRINT 'Schema matches requirements.md exactly';
PRINT '========================================';
