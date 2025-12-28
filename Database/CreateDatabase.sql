-- =============================================
-- Script tạo Database Quản Lý Công Việc
-- Hệ thống quản lý công việc với kiến trúc 3 lớp
-- =============================================

-- Tạo Database với collation hỗ trợ tiếng Việt
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'QuanLyCongViec')
BEGIN
    CREATE DATABASE QuanLyCongViec
    COLLATE Vietnamese_CI_AS;
END
ELSE
BEGIN
    -- Nếu database đã tồn tại, đổi collation
    ALTER DATABASE QuanLyCongViec COLLATE Vietnamese_CI_AS;
END
GO

USE QuanLyCongViec;
GO

-- =============================================
-- 1. BẢNG USERS - Quản lý người dùng
-- =============================================
-- Xóa foreign key constraints trước khi drop table
IF OBJECT_ID('FK_Tasks_Users', 'F') IS NOT NULL
    ALTER TABLE Tasks DROP CONSTRAINT FK_Tasks_Users;
GO

IF OBJECT_ID('FK_TaskHistory_Tasks', 'F') IS NOT NULL
    ALTER TABLE TaskHistory DROP CONSTRAINT FK_TaskHistory_Tasks;
GO

IF OBJECT_ID('FK_TaskHistory_Users', 'F') IS NOT NULL
    ALTER TABLE TaskHistory DROP CONSTRAINT FK_TaskHistory_Users;
GO

-- Xóa index trước khi drop table
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Users_Username' AND object_id = OBJECT_ID('Users'))
    DROP INDEX IX_Users_Username ON Users;
GO

IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Users_Email' AND object_id = OBJECT_ID('Users'))
    DROP INDEX IX_Users_Email ON Users;
GO

IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Users_IsActive' AND object_id = OBJECT_ID('Users'))
    DROP INDEX IX_Users_IsActive ON Users;
GO

-- Xóa unique constraints
DECLARE @ConstraintName NVARCHAR(200);
SELECT TOP 1 @ConstraintName = name FROM sys.key_constraints 
WHERE parent_object_id = OBJECT_ID('Users') AND type = 'UQ' AND name LIKE '%Username%';
IF @ConstraintName IS NOT NULL
    EXEC('ALTER TABLE Users DROP CONSTRAINT ' + @ConstraintName);
GO

DECLARE @ConstraintName2 NVARCHAR(200);
SELECT TOP 1 @ConstraintName2 = name FROM sys.key_constraints 
WHERE parent_object_id = OBJECT_ID('Users') AND type = 'UQ' AND name LIKE '%Email%';
IF @ConstraintName2 IS NOT NULL
    EXEC('ALTER TABLE Users DROP CONSTRAINT ' + @ConstraintName2);
GO

-- Xóa CHECK constraints
IF OBJECT_ID('CK_Users_Email', 'C') IS NOT NULL
    ALTER TABLE Users DROP CONSTRAINT CK_Users_Email;
GO

IF OBJECT_ID('CK_Users_Username', 'C') IS NOT NULL
    ALTER TABLE Users DROP CONSTRAINT CK_Users_Username;
GO

-- Bây giờ mới drop table
IF OBJECT_ID('Users', 'U') IS NOT NULL
    DROP TABLE Users;
GO

CREATE TABLE Users
(
    Id INT IDENTITY(1,1) PRIMARY KEY,
    Username NVARCHAR(50) NOT NULL UNIQUE,
    PasswordHash NVARCHAR(255) NOT NULL,
    FullName NVARCHAR(100) NOT NULL,
    Email NVARCHAR(100) NOT NULL UNIQUE,
    CreatedDate DATETIME NOT NULL DEFAULT GETDATE(),
    LastLoginDate DATETIME NULL,
    IsActive BIT NOT NULL DEFAULT 1,
    
    -- Ràng buộc
    CONSTRAINT CK_Users_Email CHECK (Email LIKE '%@%.%'),
    CONSTRAINT CK_Users_Username CHECK (LEN(Username) >= 3)
);
GO

-- Index cho Username và Email để tối ưu tìm kiếm
CREATE INDEX IX_Users_Username ON Users(Username);
CREATE INDEX IX_Users_Email ON Users(Email);
CREATE INDEX IX_Users_IsActive ON Users(IsActive);
GO

-- =============================================
-- 2. BẢNG TASKS - Quản lý công việc
-- =============================================
-- Xóa foreign key constraints trước
IF OBJECT_ID('FK_TaskHistory_Tasks', 'F') IS NOT NULL
    ALTER TABLE TaskHistory DROP CONSTRAINT FK_TaskHistory_Tasks;
GO

-- Xóa index trước khi drop table
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

-- Xóa CHECK constraints
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

-- Xóa foreign key constraint
IF OBJECT_ID('FK_Tasks_Users', 'F') IS NOT NULL
    ALTER TABLE Tasks DROP CONSTRAINT FK_Tasks_Users;
GO

-- Bây giờ mới drop table
IF OBJECT_ID('Tasks', 'U') IS NOT NULL
    DROP TABLE Tasks;
GO

CREATE TABLE Tasks
(
    Id INT IDENTITY(1,1) PRIMARY KEY,
    Title NVARCHAR(200) NOT NULL,
    Description NVARCHAR(MAX),
    UserId INT NOT NULL,
    Priority NVARCHAR(20) NOT NULL DEFAULT 'Medium',
    Status NVARCHAR(20) NOT NULL DEFAULT 'Todo',
    Category NVARCHAR(20) NOT NULL DEFAULT 'Work',
    DueDate DATETIME NOT NULL,
    CreatedDate DATETIME NOT NULL DEFAULT GETDATE(),
    CompletedDate DATETIME NULL,
    IsDeleted BIT NOT NULL DEFAULT 0,
    DeletedDate DATETIME NULL,
    
    -- Khóa ngoại
    CONSTRAINT FK_Tasks_Users FOREIGN KEY (UserId) REFERENCES Users(Id) ON DELETE CASCADE,
    
    -- Ràng buộc giá trị
    CONSTRAINT CK_Tasks_Priority CHECK (Priority IN ('High', 'Medium', 'Low')),
    CONSTRAINT CK_Tasks_Status CHECK (Status IN ('Todo', 'Doing', 'Done')),
    CONSTRAINT CK_Tasks_Category CHECK (Category IN ('Work', 'Personal', 'Study')),
    CONSTRAINT CK_Tasks_Title CHECK (LEN(TRIM(Title)) > 0)
);
GO

-- Index để tối ưu truy vấn
CREATE INDEX IX_Tasks_UserId ON Tasks(UserId);
CREATE INDEX IX_Tasks_Status ON Tasks(Status);
CREATE INDEX IX_Tasks_Priority ON Tasks(Priority);
CREATE INDEX IX_Tasks_Category ON Tasks(Category);
CREATE INDEX IX_Tasks_DueDate ON Tasks(DueDate);
CREATE INDEX IX_Tasks_Status_DueDate ON Tasks(Status, DueDate);
CREATE INDEX IX_Tasks_IsDeleted ON Tasks(IsDeleted);
CREATE INDEX IX_Tasks_UserId_IsDeleted ON Tasks(UserId, IsDeleted);
GO

-- =============================================
-- 3. BẢNG TASKHISTORY - Lịch sử thay đổi công việc
-- =============================================
-- Xóa index trước khi drop table
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_TaskHistory_TaskId' AND object_id = OBJECT_ID('TaskHistory'))
    DROP INDEX IX_TaskHistory_TaskId ON TaskHistory;
GO

IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_TaskHistory_UserId' AND object_id = OBJECT_ID('TaskHistory'))
    DROP INDEX IX_TaskHistory_UserId ON TaskHistory;
GO

IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_TaskHistory_ActionDate' AND object_id = OBJECT_ID('TaskHistory'))
    DROP INDEX IX_TaskHistory_ActionDate ON TaskHistory;
GO

-- Xóa foreign key constraints
IF OBJECT_ID('FK_TaskHistory_Tasks', 'F') IS NOT NULL
    ALTER TABLE TaskHistory DROP CONSTRAINT FK_TaskHistory_Tasks;
GO

IF OBJECT_ID('FK_TaskHistory_Users', 'F') IS NOT NULL
    ALTER TABLE TaskHistory DROP CONSTRAINT FK_TaskHistory_Users;
GO

-- Xóa CHECK constraints
IF OBJECT_ID('CK_TaskHistory_Action', 'C') IS NOT NULL
    ALTER TABLE TaskHistory DROP CONSTRAINT CK_TaskHistory_Action;
GO

-- Bây giờ mới drop table
IF OBJECT_ID('TaskHistory', 'U') IS NOT NULL
    DROP TABLE TaskHistory;
GO

CREATE TABLE TaskHistory
(
    Id INT IDENTITY(1,1) PRIMARY KEY,
    TaskId INT NOT NULL,
    Action NVARCHAR(50) NOT NULL,
    OldStatus NVARCHAR(20) NULL,
    NewStatus NVARCHAR(20) NULL,
    Notes NVARCHAR(500) NULL,
    ActionDate DATETIME NOT NULL DEFAULT GETDATE(),
    UserId INT NOT NULL,
    
    -- Khóa ngoại
    CONSTRAINT FK_TaskHistory_Tasks FOREIGN KEY (TaskId) REFERENCES Tasks(Id) ON DELETE CASCADE,
    CONSTRAINT FK_TaskHistory_Users FOREIGN KEY (UserId) REFERENCES Users(Id) ON DELETE NO ACTION,
    
    -- Ràng buộc
    CONSTRAINT CK_TaskHistory_Action CHECK (Action IN ('Created', 'Updated', 'Completed', 'Deleted', 'StatusChanged'))
);
GO

-- Index để tối ưu truy vấn lịch sử
CREATE INDEX IX_TaskHistory_TaskId ON TaskHistory(TaskId);
CREATE INDEX IX_TaskHistory_UserId ON TaskHistory(UserId);
CREATE INDEX IX_TaskHistory_ActionDate ON TaskHistory(ActionDate DESC);
GO

-- =============================================
-- 4. BẢNG SETTINGS - Cấu hình hệ thống
-- =============================================
-- Xóa index và unique constraint trước
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Settings_SettingKey' AND object_id = OBJECT_ID('Settings'))
    DROP INDEX IX_Settings_SettingKey ON Settings;
GO

-- Xóa unique constraint trên SettingKey
DECLARE @ConstraintName3 NVARCHAR(200);
SELECT TOP 1 @ConstraintName3 = name FROM sys.key_constraints 
WHERE parent_object_id = OBJECT_ID('Settings') AND type = 'UQ';
IF @ConstraintName3 IS NOT NULL
    EXEC('ALTER TABLE Settings DROP CONSTRAINT ' + @ConstraintName3);
GO

-- Bây giờ mới drop table
IF OBJECT_ID('Settings', 'U') IS NOT NULL
    DROP TABLE Settings;
GO

CREATE TABLE Settings
(
    Id INT IDENTITY(1,1) PRIMARY KEY,
    SettingKey NVARCHAR(100) NOT NULL UNIQUE,
    SettingValue NVARCHAR(255) NOT NULL,
    Description NVARCHAR(500) NULL,
    CreatedDate DATETIME NOT NULL DEFAULT GETDATE(),
    UpdatedDate DATETIME NULL
);
GO

-- Insert các cấu hình mặc định
INSERT INTO Settings (SettingKey, SettingValue, Description)
VALUES 
    ('MAX_LOGIN_ATTEMPTS', '5', N'Số lần đăng nhập sai tối đa cho phép trước khi khóa tài khoản'),
    ('LOCKOUT_MINUTES', '15', N'Thời gian khóa tài khoản (tính bằng phút) sau khi đăng nhập sai quá nhiều lần'),
    ('ERROR_USERNAME_EXISTS', '-1', N'Mã lỗi từ stored procedure: Username đã tồn tại'),
    ('ERROR_EMAIL_EXISTS', '-2', N'Mã lỗi từ stored procedure: Email đã tồn tại');
GO

-- Index cho SettingKey để tối ưu tìm kiếm
CREATE INDEX IX_Settings_SettingKey ON Settings(SettingKey);
GO

-- =============================================
-- 5. VIEWS - Các view hỗ trợ báo cáo
-- =============================================

-- View: Thống kê theo trạng thái
IF OBJECT_ID('vw_StatusStats', 'V') IS NOT NULL
    DROP VIEW vw_StatusStats;
GO

CREATE VIEW vw_StatusStats
AS
SELECT 
    Status,
    COUNT(*) AS Count
FROM Tasks
WHERE IsDeleted = 0
GROUP BY Status;
GO

-- View: Thống kê theo độ ưu tiên
IF OBJECT_ID('vw_PriorityStats', 'V') IS NOT NULL
    DROP VIEW vw_PriorityStats;
GO

CREATE VIEW vw_PriorityStats
AS
SELECT 
    Priority,
    COUNT(*) AS Count
FROM Tasks
WHERE IsDeleted = 0
GROUP BY Priority;
GO

-- View: Thống kê theo phân loại
IF OBJECT_ID('vw_CategoryStats', 'V') IS NOT NULL
    DROP VIEW vw_CategoryStats;
GO

CREATE VIEW vw_CategoryStats
AS
SELECT 
    Category,
    COUNT(*) AS Count
FROM Tasks
WHERE IsDeleted = 0
GROUP BY Category;
GO

-- View: Công việc quá hạn và sắp đến hạn
IF OBJECT_ID('vw_TaskOverdueAndDueSoon', 'V') IS NOT NULL
    DROP VIEW vw_TaskOverdueAndDueSoon;
GO

CREATE VIEW vw_TaskOverdueAndDueSoon
AS
SELECT 
    t.*,
    CASE 
        WHEN t.Status != 'Done' AND t.DueDate < CAST(GETDATE() AS DATE) THEN 1 
        ELSE 0 
    END AS IsOverdue,
    CASE 
        WHEN t.Status != 'Done' AND t.DueDate <= DATEADD(DAY, 3, CAST(GETDATE() AS DATE)) THEN 1 
        ELSE 0 
    END AS IsDueSoon
FROM Tasks t
WHERE t.IsDeleted = 0;
GO

-- View: Tổng quan thống kê theo người dùng
IF OBJECT_ID('vw_UserTaskSummary', 'V') IS NOT NULL
    DROP VIEW vw_UserTaskSummary;
GO

CREATE VIEW vw_UserTaskSummary
AS
SELECT 
    u.Id AS UserId,
    u.Username,
    u.FullName,
    COUNT(t.Id) AS TotalTasks,
    SUM(CASE WHEN t.Status = 'Done' THEN 1 ELSE 0 END) AS CompletedTasks,
    SUM(CASE WHEN t.Status != 'Done' AND t.DueDate < CAST(GETDATE() AS DATE) THEN 1 ELSE 0 END) AS OverdueTasks,
    SUM(CASE WHEN t.Status != 'Done' AND t.DueDate <= DATEADD(DAY, 3, CAST(GETDATE() AS DATE)) THEN 1 ELSE 0 END) AS DueSoonTasks,
    CASE 
        WHEN COUNT(t.Id) > 0 
        THEN CAST(SUM(CASE WHEN t.Status = 'Done' THEN 1 ELSE 0 END) * 100.0 / COUNT(t.Id) AS DECIMAL(5,2))
        ELSE 0 
    END AS CompletionRate
FROM Users u
LEFT JOIN Tasks t ON u.Id = t.UserId AND t.IsDeleted = 0
WHERE u.IsActive = 1
GROUP BY u.Id, u.Username, u.FullName;
GO

-- =============================================
-- 5. STORED PROCEDURES - Các thủ tục lưu trữ
-- =============================================

-- SP: Lấy dữ liệu báo cáo cho người dùng
IF OBJECT_ID('sp_GetReportData', 'P') IS NOT NULL
    DROP PROCEDURE sp_GetReportData;
GO

CREATE PROCEDURE sp_GetReportData
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Thống kê tổng quan
    SELECT 
        COUNT(*) AS TotalTasks,
        SUM(CASE WHEN Status = 'Done' THEN 1 ELSE 0 END) AS CompletedTasks,
        SUM(CASE WHEN Status != 'Done' AND DueDate < CAST(GETDATE() AS DATE) THEN 1 ELSE 0 END) AS OverdueTasks,
        SUM(CASE WHEN Status != 'Done' AND DueDate <= DATEADD(DAY, 3, CAST(GETDATE() AS DATE)) THEN 1 ELSE 0 END) AS DueSoonTasks,
        CASE 
            WHEN COUNT(*) > 0 
            THEN CAST(SUM(CASE WHEN Status = 'Done' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2))
            ELSE 0 
        END AS CompletionRate
    FROM Tasks
    WHERE UserId = @UserId AND IsDeleted = 0;
    
    -- Thống kê theo trạng thái
    SELECT Status, COUNT(*) AS Count
    FROM Tasks
    WHERE UserId = @UserId AND IsDeleted = 0
    GROUP BY Status;
    
    -- Thống kê theo độ ưu tiên
    SELECT Priority, COUNT(*) AS Count
    FROM Tasks
    WHERE UserId = @UserId AND IsDeleted = 0
    GROUP BY Priority;
    
    -- Thống kê theo phân loại
    SELECT Category, COUNT(*) AS Count
    FROM Tasks
    WHERE UserId = @UserId AND IsDeleted = 0
    GROUP BY Category;
END;
GO

-- SP: Tự động ghi lịch sử khi thay đổi trạng thái
IF OBJECT_ID('sp_LogTaskStatusChange', 'P') IS NOT NULL
    DROP PROCEDURE sp_LogTaskStatusChange;
GO

CREATE PROCEDURE sp_LogTaskStatusChange
    @TaskId INT,
    @OldStatus NVARCHAR(20),
    @NewStatus NVARCHAR(20),
    @UserId INT,
    @Notes NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO TaskHistory (TaskId, Action, OldStatus, NewStatus, Notes, UserId)
    VALUES (@TaskId, 'StatusChanged', @OldStatus, @NewStatus, @Notes, @UserId);
END;
GO

-- SP: Lấy công việc gần đây
IF OBJECT_ID('sp_GetRecentTasks', 'P') IS NOT NULL
    DROP PROCEDURE sp_GetRecentTasks;
GO

CREATE PROCEDURE sp_GetRecentTasks
    @UserId INT,
    @TopCount INT = 10
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT TOP (@TopCount)
        t.*,
        u.FullName AS UserFullName
    FROM Tasks t
    INNER JOIN Users u ON t.UserId = u.Id
    WHERE t.UserId = @UserId AND t.IsDeleted = 0
    ORDER BY t.CreatedDate DESC;
END;
GO

-- SP: Lấy công việc quan trọng (ưu tiên cao và sắp đến hạn)
IF OBJECT_ID('sp_GetUrgentTasks', 'P') IS NOT NULL
    DROP PROCEDURE sp_GetUrgentTasks;
GO

CREATE PROCEDURE sp_GetUrgentTasks
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        t.*,
        u.FullName AS UserFullName
    FROM Tasks t
    INNER JOIN Users u ON t.UserId = u.Id
    WHERE t.UserId = @UserId
        AND t.Status != 'Done'
        AND t.IsDeleted = 0
        AND (
            t.Priority = 'High' 
            OR t.DueDate <= DATEADD(DAY, 3, CAST(GETDATE() AS DATE))
        )
    ORDER BY 
        CASE WHEN t.Priority = 'High' THEN 1 ELSE 2 END,
        t.DueDate ASC;
END;
GO

-- =============================================
-- 6. TRIGGERS - Tự động ghi lịch sử
-- =============================================

-- Trigger: Tự động ghi lịch sử khi tạo công việc mới
IF OBJECT_ID('tr_Tasks_Insert', 'TR') IS NOT NULL
    DROP TRIGGER tr_Tasks_Insert;
GO

CREATE TRIGGER tr_Tasks_Insert
ON Tasks
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO TaskHistory (TaskId, Action, OldStatus, NewStatus, Notes, UserId)
    SELECT 
        Id,
        'Created',
        NULL,
        Status,
        N'Công việc được tạo mới',
        UserId
    FROM inserted;
END;
GO

-- Trigger: Tự động ghi lịch sử khi cập nhật trạng thái
IF OBJECT_ID('tr_Tasks_Update', 'TR') IS NOT NULL
    DROP TRIGGER tr_Tasks_Update;
GO

CREATE TRIGGER tr_Tasks_Update
ON Tasks
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Ghi lịch sử khi trạng thái thay đổi
    INSERT INTO TaskHistory (TaskId, Action, OldStatus, NewStatus, Notes, UserId)
    SELECT 
        i.Id,
        CASE 
            WHEN i.Status = 'Done' AND d.Status != 'Done' THEN 'Completed'
            WHEN i.Status != d.Status THEN 'StatusChanged'
            ELSE 'Updated'
        END,
        d.Status,
        i.Status,
        N'Công việc được cập nhật',
        i.UserId
    FROM inserted i
    INNER JOIN deleted d ON i.Id = d.Id
    WHERE (i.Status != d.Status OR i.Status = 'Done')
        AND i.IsDeleted = 0;
    
    -- Tự động cập nhật CompletedDate khi status = 'Done'
    UPDATE Tasks
    SET CompletedDate = GETDATE()
    FROM Tasks t
    INNER JOIN inserted i ON t.Id = i.Id
    INNER JOIN deleted d ON t.Id = d.Id
    WHERE t.Status = 'Done' 
        AND (d.Status != 'Done' OR d.Status IS NULL)
        AND t.CompletedDate IS NULL;
END;
GO

PRINT 'Database QuanLyCongViec đã được tạo thành công!';
PRINT 'Các bảng: Users, Tasks, TaskHistory';
PRINT 'Các Views: vw_StatusStats, vw_PriorityStats, vw_CategoryStats, vw_TaskOverdueAndDueSoon, vw_UserTaskSummary';
PRINT 'Các Stored Procedures: sp_GetReportData, sp_LogTaskStatusChange, sp_GetRecentTasks, sp_GetUrgentTasks';
PRINT 'Các Triggers: tr_Tasks_Insert, tr_Tasks_Update';
GO

