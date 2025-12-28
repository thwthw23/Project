-- =============================================
-- Script tạo dữ liệu mẫu ngẫu nhiên
-- Tạo nhiều Users và Tasks để test ứng dụng
-- =============================================
-- ⚠️ QUAN TRỌNG: Phải chạy TOÀN BỘ script từ đầu đến cuối
-- Không được chạy từng phần hoặc chọn dòng giữa chừng
-- =============================================
-- Script này bao gồm:
-- 1. Sửa collation database để hỗ trợ tiếng Việt (Unicode)
-- 2. Cập nhật stored procedures (bỏ hash password)
-- 3. Cập nhật password cũ (nếu có) thành plain text
-- 4. Cập nhật dữ liệu cũ bị lỗi encoding (nếu có)
-- 5. Tạo dữ liệu mẫu mới
-- =============================================

USE master;
GO

-- =============================================
-- PHẦN 1: SỬA COLLATION DATABASE (HỖ TRỢ TIẾNG VIỆT)
-- =============================================
PRINT '========================================';
PRINT 'BƯỚC 1: SỬA COLLATION DATABASE';
PRINT '========================================';

USE QuanLyCongViec;
GO

-- Xóa các index và unique constraint trước khi đổi collation (vì chúng phụ thuộc vào collation)
PRINT 'Đang xóa các index và unique constraint...';

-- Xóa index trên bảng Users
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Users_Username' AND object_id = OBJECT_ID('Users'))
    DROP INDEX IX_Users_Username ON Users;
GO

IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Users_Email' AND object_id = OBJECT_ID('Users'))
    DROP INDEX IX_Users_Email ON Users;
GO

IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Users_IsActive' AND object_id = OBJECT_ID('Users'))
    DROP INDEX IX_Users_IsActive ON Users;
GO

-- Xóa unique constraint trên Username
DECLARE @ConstraintName NVARCHAR(200);
SELECT TOP 1 @ConstraintName = kc.name 
FROM sys.key_constraints kc
INNER JOIN sys.index_columns ic ON kc.parent_object_id = ic.object_id AND kc.unique_index_id = ic.index_id
INNER JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
WHERE kc.parent_object_id = OBJECT_ID('Users') 
    AND kc.type = 'UQ' 
    AND c.name = 'Username';
IF @ConstraintName IS NOT NULL
    EXEC('ALTER TABLE Users DROP CONSTRAINT ' + @ConstraintName);
GO

-- Xóa unique constraint trên Email
DECLARE @ConstraintName2 NVARCHAR(200);
SELECT TOP 1 @ConstraintName2 = kc.name 
FROM sys.key_constraints kc
INNER JOIN sys.index_columns ic ON kc.parent_object_id = ic.object_id AND kc.unique_index_id = ic.index_id
INNER JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
WHERE kc.parent_object_id = OBJECT_ID('Users') 
    AND kc.type = 'UQ' 
    AND c.name = 'Email';
IF @ConstraintName2 IS NOT NULL
    EXEC('ALTER TABLE Users DROP CONSTRAINT ' + @ConstraintName2);
GO

-- Xóa index trên bảng Tasks
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Tasks_UserId' AND object_id = OBJECT_ID('Tasks'))
    DROP INDEX IX_Tasks_UserId ON Tasks;
GO

IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Tasks_Status' AND object_id = OBJECT_ID('Tasks'))
    DROP INDEX IX_Tasks_Status ON Tasks;
GO

IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Tasks_Priority' AND object_id = OBJECT_ID('Tasks'))
    DROP INDEX IX_Tasks_Priority ON Tasks;
GO

IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Tasks_Category' AND object_id = OBJECT_ID('Tasks'))
    DROP INDEX IX_Tasks_Category ON Tasks;
GO

IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Tasks_DueDate' AND object_id = OBJECT_ID('Tasks'))
    DROP INDEX IX_Tasks_DueDate ON Tasks;
GO

IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Tasks_Status_DueDate' AND object_id = OBJECT_ID('Tasks'))
    DROP INDEX IX_Tasks_Status_DueDate ON Tasks;
GO

IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Tasks_IsDeleted' AND object_id = OBJECT_ID('Tasks'))
    DROP INDEX IX_Tasks_IsDeleted ON Tasks;
GO

IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Tasks_UserId_IsDeleted' AND object_id = OBJECT_ID('Tasks'))
    DROP INDEX IX_Tasks_UserId_IsDeleted ON Tasks;
GO

-- Xóa index trên bảng TaskHistory
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_TaskHistory_TaskId' AND object_id = OBJECT_ID('TaskHistory'))
    DROP INDEX IX_TaskHistory_TaskId ON TaskHistory;
GO

IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_TaskHistory_UserId' AND object_id = OBJECT_ID('TaskHistory'))
    DROP INDEX IX_TaskHistory_UserId ON TaskHistory;
GO

IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_TaskHistory_ActionDate' AND object_id = OBJECT_ID('TaskHistory'))
    DROP INDEX IX_TaskHistory_ActionDate ON TaskHistory;
GO

-- Xóa index trên bảng SystemSettings (nếu có)
IF OBJECT_ID('SystemSettings', 'U') IS NOT NULL
BEGIN
    IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Settings_SettingKey' AND object_id = OBJECT_ID('SystemSettings'))
        DROP INDEX IX_Settings_SettingKey ON SystemSettings;
    
    -- Xóa unique constraint trên SettingKey
    DECLARE @ConstraintName3 NVARCHAR(200);
    SELECT TOP 1 @ConstraintName3 = kc.name 
    FROM sys.key_constraints kc
    INNER JOIN sys.index_columns ic ON kc.parent_object_id = ic.object_id AND kc.unique_index_id = ic.index_id
    INNER JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
    WHERE kc.parent_object_id = OBJECT_ID('SystemSettings') 
        AND kc.type = 'UQ' 
        AND c.name = 'SettingKey';
    IF @ConstraintName3 IS NOT NULL
        EXEC('ALTER TABLE SystemSettings DROP CONSTRAINT ' + @ConstraintName3);
END
GO

PRINT 'Đã xóa các index và unique constraint';
PRINT '';

-- Xóa các CHECK constraints trước khi đổi collation (vì chúng phụ thuộc vào collation)
PRINT 'Đang xóa các CHECK constraints...';

IF OBJECT_ID('CK_Users_Email', 'C') IS NOT NULL
    ALTER TABLE Users DROP CONSTRAINT CK_Users_Email;
GO

IF OBJECT_ID('CK_Users_Username', 'C') IS NOT NULL
    ALTER TABLE Users DROP CONSTRAINT CK_Users_Username;
GO

IF OBJECT_ID('CK_Tasks_Priority', 'C') IS NOT NULL
    ALTER TABLE Tasks DROP CONSTRAINT CK_Tasks_Priority;
GO

IF OBJECT_ID('CK_Tasks_Status', 'C') IS NOT NULL
    ALTER TABLE Tasks DROP CONSTRAINT CK_Tasks_Status;
GO

IF OBJECT_ID('CK_Tasks_Category', 'C') IS NOT NULL
    ALTER TABLE Tasks DROP CONSTRAINT CK_Tasks_Category;
GO

IF OBJECT_ID('CK_Tasks_Title', 'C') IS NOT NULL
    ALTER TABLE Tasks DROP CONSTRAINT CK_Tasks_Title;
GO

IF OBJECT_ID('CK_TaskHistory_Action', 'C') IS NOT NULL
    ALTER TABLE TaskHistory DROP CONSTRAINT CK_TaskHistory_Action;
GO

PRINT 'Đã xóa các CHECK constraints';
PRINT '';

-- Đổi collation của database sang Vietnamese_CI_AS (hỗ trợ tiếng Việt)
USE master;
GO

ALTER DATABASE QuanLyCongViec COLLATE Vietnamese_CI_AS;
GO

USE QuanLyCongViec;
GO

PRINT 'Đã đổi collation database sang Vietnamese_CI_AS';
PRINT '';

-- Sửa collation cho bảng Users
IF OBJECT_ID('Users', 'U') IS NOT NULL
BEGIN
    ALTER TABLE Users
    ALTER COLUMN Username NVARCHAR(50) COLLATE Vietnamese_CI_AS NOT NULL;
    
    ALTER TABLE Users
    ALTER COLUMN PasswordHash NVARCHAR(255) COLLATE Vietnamese_CI_AS NOT NULL;
    
    ALTER TABLE Users
    ALTER COLUMN FullName NVARCHAR(100) COLLATE Vietnamese_CI_AS NOT NULL;
    
    ALTER TABLE Users
    ALTER COLUMN Email NVARCHAR(100) COLLATE Vietnamese_CI_AS NOT NULL;
END
GO

-- Sửa collation cho bảng Tasks
IF OBJECT_ID('Tasks', 'U') IS NOT NULL
BEGIN
    ALTER TABLE Tasks
    ALTER COLUMN Title NVARCHAR(200) COLLATE Vietnamese_CI_AS NOT NULL;
    
    ALTER TABLE Tasks
    ALTER COLUMN Description NVARCHAR(MAX) COLLATE Vietnamese_CI_AS;
    
    ALTER TABLE Tasks
    ALTER COLUMN Priority NVARCHAR(20) COLLATE Vietnamese_CI_AS NOT NULL;
    
    ALTER TABLE Tasks
    ALTER COLUMN Status NVARCHAR(20) COLLATE Vietnamese_CI_AS NOT NULL;
    
    ALTER TABLE Tasks
    ALTER COLUMN Category NVARCHAR(20) COLLATE Vietnamese_CI_AS NOT NULL;
END
GO

-- Sửa collation cho bảng TaskHistory
IF OBJECT_ID('TaskHistory', 'U') IS NOT NULL
BEGIN
    ALTER TABLE TaskHistory
    ALTER COLUMN Action NVARCHAR(50) COLLATE Vietnamese_CI_AS NOT NULL;
    
    ALTER TABLE TaskHistory
    ALTER COLUMN OldStatus NVARCHAR(20) COLLATE Vietnamese_CI_AS;
    
    ALTER TABLE TaskHistory
    ALTER COLUMN NewStatus NVARCHAR(20) COLLATE Vietnamese_CI_AS;
    
    ALTER TABLE TaskHistory
    ALTER COLUMN Notes NVARCHAR(500) COLLATE Vietnamese_CI_AS;
END
GO

-- Sửa collation cho bảng SystemSettings (nếu có)
IF OBJECT_ID('SystemSettings', 'U') IS NOT NULL
BEGIN
    ALTER TABLE SystemSettings
    ALTER COLUMN SettingKey NVARCHAR(100) COLLATE Vietnamese_CI_AS NOT NULL;
    
    ALTER TABLE SystemSettings
    ALTER COLUMN SettingValue NVARCHAR(255) COLLATE Vietnamese_CI_AS NOT NULL;
    
    ALTER TABLE SystemSettings
    ALTER COLUMN Description NVARCHAR(500) COLLATE Vietnamese_CI_AS;
END
GO

PRINT 'Đã sửa collation các cột sang Vietnamese_CI_AS';
PRINT '';

-- Tạo lại các index và unique constraint sau khi đổi collation
PRINT 'Đang tạo lại các index và unique constraint...';

-- Tạo lại index và unique constraint cho bảng Users
IF OBJECT_ID('Users', 'U') IS NOT NULL
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Users_Username' AND object_id = OBJECT_ID('Users'))
        CREATE INDEX IX_Users_Username ON Users(Username);
    
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Users_Email' AND object_id = OBJECT_ID('Users'))
        CREATE INDEX IX_Users_Email ON Users(Email);
    
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Users_IsActive' AND object_id = OBJECT_ID('Users'))
        CREATE INDEX IX_Users_IsActive ON Users(IsActive);
    
    -- Tạo lại unique constraint trên Username
    IF NOT EXISTS (
        SELECT 1 FROM sys.key_constraints kc
        INNER JOIN sys.index_columns ic ON kc.parent_object_id = ic.object_id AND kc.unique_index_id = ic.index_id
        INNER JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
        WHERE kc.parent_object_id = OBJECT_ID('Users') AND kc.type = 'UQ' AND c.name = 'Username'
    )
        ALTER TABLE Users ADD CONSTRAINT UQ_Users_Username UNIQUE (Username);
    
    -- Tạo lại unique constraint trên Email
    IF NOT EXISTS (
        SELECT 1 FROM sys.key_constraints kc
        INNER JOIN sys.index_columns ic ON kc.parent_object_id = ic.object_id AND kc.unique_index_id = ic.index_id
        INNER JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
        WHERE kc.parent_object_id = OBJECT_ID('Users') AND kc.type = 'UQ' AND c.name = 'Email'
    )
        ALTER TABLE Users ADD CONSTRAINT UQ_Users_Email UNIQUE (Email);
END
GO

-- Tạo lại index cho bảng Tasks
IF OBJECT_ID('Tasks', 'U') IS NOT NULL
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Tasks_UserId' AND object_id = OBJECT_ID('Tasks'))
        CREATE INDEX IX_Tasks_UserId ON Tasks(UserId);
    
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Tasks_Status' AND object_id = OBJECT_ID('Tasks'))
        CREATE INDEX IX_Tasks_Status ON Tasks(Status);
    
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Tasks_Priority' AND object_id = OBJECT_ID('Tasks'))
        CREATE INDEX IX_Tasks_Priority ON Tasks(Priority);
    
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Tasks_Category' AND object_id = OBJECT_ID('Tasks'))
        CREATE INDEX IX_Tasks_Category ON Tasks(Category);
    
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Tasks_DueDate' AND object_id = OBJECT_ID('Tasks'))
        CREATE INDEX IX_Tasks_DueDate ON Tasks(DueDate);
    
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Tasks_Status_DueDate' AND object_id = OBJECT_ID('Tasks'))
        CREATE INDEX IX_Tasks_Status_DueDate ON Tasks(Status, DueDate);
    
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Tasks_IsDeleted' AND object_id = OBJECT_ID('Tasks'))
        CREATE INDEX IX_Tasks_IsDeleted ON Tasks(IsDeleted);
    
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Tasks_UserId_IsDeleted' AND object_id = OBJECT_ID('Tasks'))
        CREATE INDEX IX_Tasks_UserId_IsDeleted ON Tasks(UserId, IsDeleted);
END
GO

-- Tạo lại index cho bảng TaskHistory
IF OBJECT_ID('TaskHistory', 'U') IS NOT NULL
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_TaskHistory_TaskId' AND object_id = OBJECT_ID('TaskHistory'))
        CREATE INDEX IX_TaskHistory_TaskId ON TaskHistory(TaskId);
    
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_TaskHistory_UserId' AND object_id = OBJECT_ID('TaskHistory'))
        CREATE INDEX IX_TaskHistory_UserId ON TaskHistory(UserId);
    
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_TaskHistory_ActionDate' AND object_id = OBJECT_ID('TaskHistory'))
        CREATE INDEX IX_TaskHistory_ActionDate ON TaskHistory(ActionDate DESC);
END
GO

-- Tạo lại index và unique constraint cho bảng SystemSettings (nếu có)
IF OBJECT_ID('SystemSettings', 'U') IS NOT NULL
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Settings_SettingKey' AND object_id = OBJECT_ID('SystemSettings'))
        CREATE INDEX IX_Settings_SettingKey ON SystemSettings(SettingKey);
    
    -- Tạo lại unique constraint trên SettingKey
    IF NOT EXISTS (
        SELECT 1 FROM sys.key_constraints kc
        INNER JOIN sys.index_columns ic ON kc.parent_object_id = ic.object_id AND kc.unique_index_id = ic.index_id
        INNER JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
        WHERE kc.parent_object_id = OBJECT_ID('SystemSettings') AND kc.type = 'UQ' AND c.name = 'SettingKey'
    )
        ALTER TABLE SystemSettings ADD CONSTRAINT UQ_Settings_SettingKey UNIQUE (SettingKey);
END
GO

PRINT 'Đã tạo lại các index và unique constraint';
PRINT '';

-- Tạo lại các CHECK constraints sau khi đổi collation
PRINT 'Đang tạo lại các CHECK constraints...';

IF OBJECT_ID('Users', 'U') IS NOT NULL
BEGIN
    IF OBJECT_ID('CK_Users_Email', 'C') IS NULL
        ALTER TABLE Users ADD CONSTRAINT CK_Users_Email CHECK (Email LIKE '%@%.%');
    
    IF OBJECT_ID('CK_Users_Username', 'C') IS NULL
        ALTER TABLE Users ADD CONSTRAINT CK_Users_Username CHECK (LEN(Username) >= 3);
END
GO

IF OBJECT_ID('Tasks', 'U') IS NOT NULL
BEGIN
    IF OBJECT_ID('CK_Tasks_Priority', 'C') IS NULL
        ALTER TABLE Tasks ADD CONSTRAINT CK_Tasks_Priority CHECK (Priority IN (N'High', N'Medium', N'Low'));
    
    IF OBJECT_ID('CK_Tasks_Status', 'C') IS NULL
        ALTER TABLE Tasks ADD CONSTRAINT CK_Tasks_Status CHECK (Status IN (N'Todo', N'Doing', N'Done'));
    
    IF OBJECT_ID('CK_Tasks_Category', 'C') IS NULL
        ALTER TABLE Tasks ADD CONSTRAINT CK_Tasks_Category CHECK (Category IN (N'Work', N'Personal', N'Study'));
    
    IF OBJECT_ID('CK_Tasks_Title', 'C') IS NULL
        ALTER TABLE Tasks ADD CONSTRAINT CK_Tasks_Title CHECK (LEN(TRIM(Title)) > 0);
END
GO

IF OBJECT_ID('TaskHistory', 'U') IS NOT NULL
BEGIN
    IF OBJECT_ID('CK_TaskHistory_Action', 'C') IS NULL
        ALTER TABLE TaskHistory ADD CONSTRAINT CK_TaskHistory_Action CHECK (Action IN (N'Created', N'Updated', N'Completed', N'Deleted', N'StatusChanged'));
END
GO

PRINT 'Đã tạo lại các CHECK constraints';
PRINT '';

-- =============================================
-- PHẦN 2: CẬP NHẬT STORED PROCEDURES
-- =============================================
PRINT '========================================';
PRINT 'BƯỚC 2: CẬP NHẬT STORED PROCEDURES';
PRINT '========================================';

-- Cập nhật sp_UserLogin
IF OBJECT_ID('sp_UserLogin', 'P') IS NOT NULL
    DROP PROCEDURE sp_UserLogin;
GO

CREATE PROCEDURE sp_UserLogin
    @Username NVARCHAR(50),
    @Password NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @UserId INT;
    
    SELECT 
        @UserId = Id
    FROM Users
    WHERE Username = @Username 
        AND PasswordHash = @Password
        AND IsActive = 1;
    
    IF @UserId IS NOT NULL
    BEGIN
        -- Cập nhật LastLoginDate
        UPDATE Users SET LastLoginDate = GETDATE() WHERE Id = @UserId;
        
        SELECT 
            Id,
            Username,
            FullName,
            Email,
            CreatedDate
        FROM Users
        WHERE Id = @UserId;
        
        RETURN 1;
    END
    ELSE
    BEGIN
        RETURN 0;
    END
END;
GO

-- Cập nhật sp_UserRegister
IF OBJECT_ID('sp_UserRegister', 'P') IS NOT NULL
    DROP PROCEDURE sp_UserRegister;
GO

CREATE PROCEDURE sp_UserRegister
    @Username NVARCHAR(50),
    @Password NVARCHAR(255),
    @FullName NVARCHAR(100),
    @Email NVARCHAR(100),
    @UserId INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    IF EXISTS (SELECT 1 FROM Users WHERE Username = @Username)
    BEGIN
        SET @UserId = -1;
        RETURN;
    END
    
    IF EXISTS (SELECT 1 FROM Users WHERE Email = @Email)
    BEGIN
        SET @UserId = -2;
        RETURN;
    END
    
    INSERT INTO Users (Username, PasswordHash, FullName, Email, CreatedDate)
    VALUES (@Username, @Password, @FullName, @Email, GETDATE());
    
    SET @UserId = SCOPE_IDENTITY();
END;
GO

-- Cập nhật sp_ChangePassword
IF OBJECT_ID('sp_ChangePassword', 'P') IS NOT NULL
    DROP PROCEDURE sp_ChangePassword;
GO

CREATE PROCEDURE sp_ChangePassword
    @UserId INT,
    @OldPassword NVARCHAR(255),
    @NewPassword NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
    
    IF NOT EXISTS (SELECT 1 FROM Users WHERE Id = @UserId AND PasswordHash = @OldPassword)
    BEGIN
        RAISERROR(N'Mật khẩu cũ không đúng', 16, 1);
        RETURN;
    END
    
    UPDATE Users SET PasswordHash = @NewPassword WHERE Id = @UserId;
END;
GO

PRINT 'Đã cập nhật stored procedures:';
PRINT '- sp_UserLogin: Sử dụng @Password';
PRINT '- sp_UserRegister: Sử dụng @Password';
PRINT '- sp_ChangePassword: Sử dụng @OldPassword và @NewPassword';
PRINT '';

-- =============================================
-- PHẦN 3: CẬP NHẬT PASSWORD CŨ (NẾU CÓ)
-- =============================================
PRINT '========================================';
PRINT 'BƯỚC 3: CẬP NHẬT PASSWORD CŨ';
PRINT '========================================';

-- Cập nhật tất cả password cũ thành "123456" (plain text)
-- Chỉ cập nhật nếu password không phải là "123456" (có thể là hash cũ)
UPDATE Users
SET PasswordHash = '123456'
WHERE PasswordHash != '123456' OR PasswordHash IS NULL;

DECLARE @SoLuongUsersDaCapNhat INT = @@ROWCOUNT;
IF @SoLuongUsersDaCapNhat > 0
BEGIN
    PRINT 'Đã cập nhật ' + CAST(@SoLuongUsersDaCapNhat AS VARCHAR(10)) + ' password cũ thành plain text';
END
ELSE
BEGIN
    PRINT 'Không có password cũ cần cập nhật';
END
PRINT '';

-- =============================================
-- PHẦN 4: CẬP NHẬT DỮ LIỆU CŨ (NẾU CÓ)
-- =============================================
PRINT '========================================';
PRINT 'BƯỚC 4: CẬP NHẬT DỮ LIỆU CŨ';
PRINT '========================================';

-- Cập nhật dữ liệu cũ có ký tự bị lỗi (chứa ?)
PRINT 'Đang kiểm tra và cập nhật dữ liệu cũ...';

-- Cập nhật FullName trong bảng Users
UPDATE Users
SET FullName = CASE 
    WHEN FullName LIKE '%?%' AND Username = 'admin' THEN N'Quản trị viên'
    WHEN FullName LIKE '%?%' AND Username LIKE 'user%' THEN 
        -- Tạo lại tên từ danh sách có sẵn
        CASE (CAST(SUBSTRING(Username, 5, LEN(Username)) AS INT) - 1) % 20
            WHEN 0 THEN N'Nguyễn Văn An'
            WHEN 1 THEN N'Trần Thị Bình'
            WHEN 2 THEN N'Lê Văn Cường'
            WHEN 3 THEN N'Phạm Thị Dung'
            WHEN 4 THEN N'Hoàng Văn Đức'
            WHEN 5 THEN N'Ngô Thị Hương'
            WHEN 6 THEN N'Vũ Văn Hùng'
            WHEN 7 THEN N'Đỗ Thị Lan'
            WHEN 8 THEN N'Bùi Văn Minh'
            WHEN 9 THEN N'Lý Thị Nga'
            WHEN 10 THEN N'Đinh Văn Phong'
            WHEN 11 THEN N'Mai Thị Quỳnh'
            WHEN 12 THEN N'Tạ Văn Sơn'
            WHEN 13 THEN N'Võ Thị Trang'
            WHEN 14 THEN N'Phan Văn Tuấn'
            WHEN 15 THEN N'Hồ Thị Uyên'
            WHEN 16 THEN N'Dương Văn Việt'
            WHEN 17 THEN N'Lưu Thị Yến'
            WHEN 18 THEN N'Chu Văn Bảo'
            WHEN 19 THEN N'Trịnh Thị Châu'
            ELSE FullName
        END
    ELSE FullName
END
WHERE FullName LIKE '%?%';

DECLARE @UsersUpdated INT = @@ROWCOUNT;
IF @UsersUpdated > 0
    PRINT 'Đã cập nhật ' + CAST(@UsersUpdated AS VARCHAR(10)) + ' records trong bảng Users';
ELSE
    PRINT 'Không có dữ liệu Users cần cập nhật';
GO

-- Cập nhật Title và Description trong bảng Tasks (thay thế các ký tự bị lỗi)
UPDATE Tasks
SET Title = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
    Title,
    'C?ng', N'Công'),
    'vi?c', N'việc'),
    'h?c', N'học'),
    't?p', N'tập'),
    'kh?m', N'khám'),
    's?c', N'sức'),
    'kho?', N'khỏe'),
    'l?p', N'lập'),
    'trình', N'trình'),
    '?', N'ộ')
WHERE Title LIKE '%?%';

UPDATE Tasks
SET Description = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
    Description,
    'C?ng', N'Công'),
    'vi?c', N'việc'),
    'h?c', N'học'),
    't?p', N'tập'),
    'kh?m', N'khám'),
    's?c', N'sức'),
    'kho?', N'khỏe'),
    'l?p', N'lập'),
    'trình', N'trình'),
    '?', N'ộ')
WHERE Description LIKE '%?%';

DECLARE @TasksUpdated INT = @@ROWCOUNT;
IF @TasksUpdated > 0
    PRINT 'Đã cập nhật ' + CAST(@TasksUpdated AS VARCHAR(10)) + ' records trong bảng Tasks';
ELSE
    PRINT 'Không có dữ liệu Tasks cần cập nhật';
GO

-- Cập nhật Notes trong bảng TaskHistory
PRINT 'Đang kiểm tra và cập nhật dữ liệu TaskHistory...';

UPDATE TaskHistory
SET Notes = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
    Notes,
    'C?ng', N'Công'),
    'vi?c', N'việc'),
    'h?c', N'học'),
    't?p', N'tập'),
    'kh?m', N'khám'),
    's?c', N'sức'),
    'kho?', N'khỏe'),
    'l?p', N'lập'),
    'trình', N'trình'),
    '?ng', N'ộng')
WHERE Notes LIKE '%?%';

UPDATE TaskHistory
SET Notes = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
    Notes,
    '?n', N'ơn'),
    '?i', N'ời'),
    '?a', N'ưa'),
    '?u', N'ưu'),
    '?o', N'ộ'),
    '?e', N'ế'),
    '?y', N'ấy'),
    '?t', N'ất'),
    '?', N'ộ')
WHERE Notes LIKE '%?%';

-- Sửa các cụm từ phổ biến trong Notes
UPDATE TaskHistory
SET Notes = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
    Notes,
    'Công vi?c', N'Công việc'),
    't?o m?i', N'tạo mới'),
    'c?p nh?t', N'cập nhật'),
    'thay ??i', N'thay đổi'),
    'tr?ng thái', N'trạng thái'),
    '??u tiên', N'ưu tiên'),
    'm? t?', N'mô tả'),
    'ngày t?o', N'ngày tạo'),
    'ngày hoàn thành', N'ngày hoàn thành'),
    '?ã', N'đã')
WHERE Notes LIKE '%?%';

DECLARE @TaskHistoryUpdated INT = @@ROWCOUNT;
IF @TaskHistoryUpdated > 0
    PRINT 'Đã cập nhật ' + CAST(@TaskHistoryUpdated AS VARCHAR(10)) + ' records trong bảng TaskHistory';
ELSE
    PRINT 'Không có dữ liệu TaskHistory cần cập nhật';
GO

PRINT '';

-- =============================================
-- PHẦN 5: TẠO DỮ LIỆU MẪU
-- =============================================
PRINT '========================================';
PRINT 'BƯỚC 5: TẠO DỮ LIỆU MẪU';
PRINT '========================================';

-- =============================================
-- KHAI BÁO CÁC BIẾN
-- =============================================
-- Lưu password dạng plain text (không hash)
DECLARE @Password NVARCHAR(255) = '123456';

-- CẤU HÌNH SỐ LƯỢNG - Có thể thay đổi các giá trị này
DECLARE @SoLuongUsers INT = 15;        -- Số lượng users muốn tạo (tối đa 20)
DECLARE @SoLuongTasksPerUser INT = 12; -- Số lượng tasks mỗi user

-- =============================================
-- XÓA DỮ LIỆU CŨ (NẾU MUỐN)
-- =============================================
-- Bỏ comment nếu muốn xóa dữ liệu cũ trước khi chèn mới
-- DELETE FROM TaskHistory;
-- DELETE FROM Tasks;
-- DELETE FROM Users WHERE Username != 'admin'; -- Giữ lại user admin
-- DBCC CHECKIDENT ('Users', RESEED, 0);
-- DBCC CHECKIDENT ('Tasks', RESEED, 0);
-- DBCC CHECKIDENT ('TaskHistory', RESEED, 0);

PRINT '========================================';
PRINT 'BẮT ĐẦU TẠO DỮ LIỆU MẪU';
PRINT '========================================';
PRINT 'Số lượng Users: ' + CAST(@SoLuongUsers AS VARCHAR(10));
PRINT 'Số lượng Tasks mỗi User: ' + CAST(@SoLuongTasksPerUser AS VARCHAR(10));
PRINT '========================================';

-- =============================================
-- TẠO DANH SÁCH TÊN MẪU
-- =============================================
-- Tạo bảng tạm chứa danh sách tên
CREATE TABLE #TempNames (
    FirstName NVARCHAR(50),
    LastName NVARCHAR(50)
);

INSERT INTO #TempNames VALUES
(N'Nguyễn Văn', N'An'), (N'Trần Thị', N'Bình'), (N'Lê Văn', N'Cường'), (N'Phạm Thị', N'Dung'),
(N'Hoàng Văn', N'Đức'), (N'Ngô Thị', N'Hương'), (N'Vũ Văn', N'Hùng'), (N'Đỗ Thị', N'Lan'),
(N'Bùi Văn', N'Minh'), (N'Lý Thị', N'Nga'), (N'Đinh Văn', N'Phong'), (N'Mai Thị', N'Quỳnh'),
(N'Tạ Văn', N'Sơn'), (N'Võ Thị', N'Trang'), (N'Phan Văn', N'Tuấn'), (N'Hồ Thị', N'Uyên'),
(N'Dương Văn', N'Việt'), (N'Lưu Thị', N'Yến'), (N'Chu Văn', N'Bảo'), (N'Trịnh Thị', N'Châu');

-- =============================================
-- TẠO DANH SÁCH TÊN CÔNG VIỆC MẪU
-- =============================================
CREATE TABLE #TempTaskTitles (
    Title NVARCHAR(200),
    Category NVARCHAR(20)
);

INSERT INTO #TempTaskTitles VALUES
-- Công việc Work
(N'Phân tích yêu cầu hệ thống', N'Work'), (N'Thiết kế database', N'Work'), (N'Lập trình module đăng nhập', N'Work'),
(N'Lập trình module quản lý user', N'Work'), (N'Thiết kế giao diện người dùng', N'Work'), (N'Lập trình API backend', N'Work'),
(N'Viết unit test', N'Work'), (N'Code review', N'Work'), (N'Tối ưu hóa hiệu suất', N'Work'), (N'Deploy lên server', N'Work'),
(N'Sửa lỗi bug', N'Work'), (N'Cập nhật tài liệu', N'Work'), (N'Họp với khách hàng', N'Work'), (N'Báo cáo tiến độ', N'Work'),
(N'Đào tạo nhân viên mới', N'Work'), (N'Nghiên cứu công nghệ mới', N'Work'), (N'Tối ưu database', N'Work'), (N'Backup dữ liệu', N'Work'),
-- Công việc Personal
(N'Mua sắm đồ dùng cá nhân', N'Personal'), (N'Đi khám sức khỏe', N'Personal'), (N'Gặp bạn bè', N'Personal'),
(N'Tập thể dục', N'Personal'), (N'Đọc sách', N'Personal'), (N'Học ngoại ngữ', N'Personal'), (N'Dọn dẹp nhà cửa', N'Personal'),
(N'Nấu ăn', N'Personal'), (N'Xem phim', N'Personal'), (N'Du lịch', N'Personal'),
-- Công việc Study
(N'Học lập trình C#', N'Study'), (N'Làm bài tập toán', N'Study'), (N'Ôn thi cuối kỳ', N'Study'),
(N'Viết báo cáo đồ án', N'Study'), (N'Thuyết trình', N'Study'), (N'Nghiên cứu tài liệu', N'Study'),
(N'Làm project nhóm', N'Study'), (N'Học tiếng Anh', N'Study'), (N'Chuẩn bị bài mới', N'Study'), (N'Làm bài kiểm tra', N'Study');

-- =============================================
-- TẠO USERS
-- =============================================
DECLARE @Counter INT = 1;
DECLARE @Username NVARCHAR(50);
DECLARE @FullName NVARCHAR(100);
DECLARE @Email NVARCHAR(100);
DECLARE @FirstName NVARCHAR(50);
DECLARE @LastName NVARCHAR(50);
DECLARE @UserId INT;

WHILE @Counter <= @SoLuongUsers
BEGIN
    -- Chọn tên ngẫu nhiên
    SELECT TOP 1 @FirstName = FirstName, @LastName = LastName
    FROM #TempNames
    ORDER BY NEWID();
    
    -- Tạo username và email
    SET @Username = 'user' + CAST(@Counter AS VARCHAR(10));
    SET @FullName = @FirstName + ' ' + @LastName;
    SET @Email = @Username + '@example.com';
    
    -- Kiểm tra username đã tồn tại chưa
    IF NOT EXISTS (SELECT 1 FROM Users WHERE Username = @Username)
    BEGIN
        -- Insert user
        INSERT INTO Users (Username, PasswordHash, FullName, Email, CreatedDate, IsActive)
        VALUES (@Username, @Password, @FullName, @Email, DATEADD(DAY, -RAND() * 30, GETDATE()), 1);
        
        SET @UserId = SCOPE_IDENTITY();
        
        PRINT 'Đã tạo user: ' + @Username + ' - ' + @FullName;
    END
    ELSE
    BEGIN
        -- Lấy UserId nếu đã tồn tại
        SELECT @UserId = Id FROM Users WHERE Username = @Username;
        PRINT 'User đã tồn tại: ' + @Username;
    END
    
    -- Tạo Tasks cho user này
    IF @UserId IS NOT NULL
    BEGIN
        DECLARE @TaskCounter INT = 1;
        DECLARE @TaskTitle NVARCHAR(200);
        DECLARE @TaskCategory NVARCHAR(20);
        DECLARE @TaskPriority NVARCHAR(20);
        DECLARE @TaskStatus NVARCHAR(20);
        DECLARE @TaskDueDate DATETIME;
        DECLARE @TaskCreatedDate DATETIME;
        DECLARE @TaskDescription NVARCHAR(MAX);
        DECLARE @RandomValue FLOAT;
        
        WHILE @TaskCounter <= @SoLuongTasksPerUser
        BEGIN
            -- Chọn tiêu đề công việc ngẫu nhiên
            SELECT TOP 1 @TaskTitle = Title, @TaskCategory = Category
            FROM #TempTaskTitles
            ORDER BY NEWID();
            
            -- Random Priority (đảm bảo random mỗi lần khác nhau)
            SET @RandomValue = RAND(CHECKSUM(NEWID()));
            SET @TaskPriority = CASE 
                WHEN @RandomValue < 0.33 THEN 'High'
                WHEN @RandomValue < 0.66 THEN 'Medium'
                ELSE 'Low'
            END;
            
            -- Random Status
            SET @RandomValue = RAND(CHECKSUM(NEWID()));
            SET @TaskStatus = CASE 
                WHEN @RandomValue < 0.4 THEN 'Todo'
                WHEN @RandomValue < 0.75 THEN 'Doing'
                ELSE 'Done'
            END;
            
            -- Random DueDate (từ 30 ngày trước đến 30 ngày sau)
            SET @RandomValue = RAND(CHECKSUM(NEWID()));
            SET @TaskDueDate = DATEADD(DAY, CAST(@RandomValue * 60 - 30 AS INT), GETDATE());
            
            -- Random CreatedDate (từ 60 ngày trước đến hiện tại)
            SET @RandomValue = RAND(CHECKSUM(NEWID()));
            SET @TaskCreatedDate = DATEADD(DAY, -CAST(@RandomValue * 60 AS INT), GETDATE());
            
            -- Tạo Description
            SET @RandomValue = RAND(CHECKSUM(NEWID()));
            SET @TaskDescription = @TaskTitle + N'. Thời gian dự kiến: ' + CAST(CAST(@RandomValue * 40 + 10 AS INT) AS VARCHAR(10)) + N' giờ.';
            
            -- Insert Task
            INSERT INTO Tasks (Title, Description, UserId, Priority, Status, Category, DueDate, CreatedDate, CompletedDate, IsDeleted)
            VALUES (
                @TaskTitle,
                @TaskDescription,
                @UserId,
                @TaskPriority,
                @TaskStatus,
                @TaskCategory,
                @TaskDueDate,
                @TaskCreatedDate,
                CASE WHEN @TaskStatus = 'Done' THEN DATEADD(DAY, CAST(RAND(CHECKSUM(NEWID())) * 10 AS INT), @TaskCreatedDate) ELSE NULL END,
                0
            );
            
            SET @TaskCounter = @TaskCounter + 1;
        END
    END
    
    SET @Counter = @Counter + 1;
END

-- =============================================
-- TẠO TÀI KHOẢN ADMIN (nếu chưa có)
-- =============================================
IF NOT EXISTS (SELECT 1 FROM Users WHERE Username = 'admin')
BEGIN
    INSERT INTO Users (Username, PasswordHash, FullName, Email, CreatedDate, IsActive)
    VALUES (N'admin', @Password, N'Quản trị viên', N'admin@example.com', GETDATE(), 1);
    
    DECLARE @AdminUserId INT = SCOPE_IDENTITY();
    
    -- Tạo một số tasks cho admin
    DECLARE @AdminTaskCounter INT = 1;
    DECLARE @AdminTaskTitle NVARCHAR(200);
    DECLARE @AdminTaskCategory NVARCHAR(20);
    DECLARE @AdminTaskPriority NVARCHAR(20);
    DECLARE @AdminTaskStatus NVARCHAR(20);
    DECLARE @AdminTaskDueDate DATETIME;
    DECLARE @AdminTaskCreatedDate DATETIME;
    DECLARE @AdminTaskDescription NVARCHAR(MAX);
    DECLARE @AdminRandomValue FLOAT;
    
    WHILE @AdminTaskCounter <= 5
    BEGIN
        -- Chọn tiêu đề công việc ngẫu nhiên từ bảng tạm
        SELECT TOP 1 @AdminTaskTitle = Title, @AdminTaskCategory = Category
        FROM #TempTaskTitles
        ORDER BY NEWID();
        
        SET @AdminRandomValue = RAND(CHECKSUM(NEWID()));
        SET @AdminTaskPriority = CASE WHEN @AdminRandomValue < 0.5 THEN 'High' ELSE 'Medium' END;
        
        SET @AdminRandomValue = RAND(CHECKSUM(NEWID()));
        SET @AdminTaskStatus = CASE WHEN @AdminRandomValue < 0.5 THEN 'Todo' ELSE 'Doing' END;
        
        SET @AdminRandomValue = RAND(CHECKSUM(NEWID()));
        SET @AdminTaskDueDate = DATEADD(DAY, CAST(@AdminRandomValue * 30 AS INT), GETDATE());
        
        SET @AdminRandomValue = RAND(CHECKSUM(NEWID()));
        SET @AdminTaskCreatedDate = DATEADD(DAY, -CAST(@AdminRandomValue * 15 AS INT), GETDATE());
        
        SET @AdminTaskDescription = @AdminTaskTitle + N'. Công việc quản trị.';
        
        INSERT INTO Tasks (Title, Description, UserId, Priority, Status, Category, DueDate, CreatedDate, IsDeleted)
        VALUES (@AdminTaskTitle, @AdminTaskDescription, @AdminUserId, @AdminTaskPriority, @AdminTaskStatus, @AdminTaskCategory, @AdminTaskDueDate, @AdminTaskCreatedDate, 0);
        
        SET @AdminTaskCounter = @AdminTaskCounter + 1;
    END
    
    PRINT 'Đã tạo tài khoản admin';
END

-- =============================================
-- DỌN DẸP BẢNG TẠM
-- =============================================
DROP TABLE #TempNames;
DROP TABLE #TempTaskTitles;

PRINT '========================================';
PRINT 'HOÀN THÀNH TẤT CẢ CÁC BƯỚC';
PRINT '========================================';
PRINT '✅ Đã sửa collation database (hỗ trợ tiếng Việt)';
PRINT '✅ Đã cập nhật stored procedures';
PRINT '✅ Đã cập nhật password cũ (nếu có)';
PRINT '✅ Đã cập nhật dữ liệu cũ bị lỗi encoding (nếu có)';
PRINT '✅ Đã tạo dữ liệu mẫu';
PRINT '';
PRINT 'LƯU Ý:';
PRINT '- Nếu vẫn thấy ký tự bị lỗi, có thể do dữ liệu đã được lưu sai từ trước';
PRINT '- Chạy lại script UpdateExistingData_ToUnicode.sql để sửa chi tiết hơn';
PRINT '- Hoặc xóa dữ liệu cũ và chạy lại script này';
PRINT '========================================';

-- Hiển thị thống kê
SELECT 
    'Tổng số Users' AS ThongKe,
    COUNT(*) AS SoLuong
FROM Users
WHERE IsActive = 1

UNION ALL

SELECT 
    'Tổng số Tasks' AS ThongKe,
    COUNT(*) AS SoLuong
FROM Tasks
WHERE IsDeleted = 0

UNION ALL

SELECT 
    'Số Tasks Todo' AS ThongKe,
    COUNT(*) AS SoLuong
FROM Tasks
WHERE Status = 'Todo' AND IsDeleted = 0

UNION ALL

SELECT 
    'Số Tasks Doing' AS ThongKe,
    COUNT(*) AS SoLuong
FROM Tasks
WHERE Status = 'Doing' AND IsDeleted = 0

UNION ALL

SELECT 
    'Số Tasks Done' AS ThongKe,
    COUNT(*) AS SoLuong
FROM Tasks
WHERE Status = 'Done' AND IsDeleted = 0

UNION ALL

SELECT 
    'Số Tasks Quá Hạn' AS ThongKe,
    COUNT(*) AS SoLuong
FROM Tasks
WHERE Status != 'Done' AND DueDate < CAST(GETDATE() AS DATE) AND IsDeleted = 0;

GO

PRINT '';
PRINT '========================================';
PRINT 'THÔNG TIN ĐĂNG NHẬP';
PRINT '========================================';
PRINT 'Username: admin (hoặc user1, user2, ...)';
PRINT 'Password: 123456 (lưu dạng plain text)';
PRINT '========================================';
GO

