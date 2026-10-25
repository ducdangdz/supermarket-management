/* Apply after the base schema. Preserves existing employees and Google login. */
USE smartmarket_hrm;
GO
SET XACT_ABORT ON;
BEGIN TRANSACTION;
-- SQL Server unfiltered UNIQUE allows only one NULL; local accounts have no Google sub.
IF EXISTS (SELECT 1 FROM sys.key_constraints WHERE name = 'UK_employees_google_sub' AND parent_object_id = OBJECT_ID('dbo.employees'))
    ALTER TABLE dbo.employees DROP CONSTRAINT UK_employees_google_sub;
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.employees') AND name = 'UX_employees_google_sub_not_null')
    CREATE UNIQUE INDEX UX_employees_google_sub_not_null ON dbo.employees(google_sub) WHERE google_sub IS NOT NULL;
IF OBJECT_ID('dbo.auth_challenges', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.auth_challenges (
        challenge_id UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
        email VARCHAR(150) NOT NULL,
        purpose VARCHAR(16) NOT NULL CHECK (purpose IN ('REGISTER', 'RESET')),
        code_hash VARCHAR(255) NOT NULL,
        full_name NVARCHAR(150) NULL,
        password_hash VARCHAR(255) NULL,
        expires_at DATETIME2 NOT NULL,
        attempts INT NOT NULL DEFAULT 0,
        consumed BIT NOT NULL DEFAULT 0,
        created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
    );
    CREATE INDEX IX_auth_challenges_email ON dbo.auth_challenges(email, created_at);
END;
IF OBJECT_ID('dbo.auth_sessions', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.auth_sessions (
        token_hash CHAR(64) NOT NULL PRIMARY KEY,
        employee_id BIGINT NOT NULL REFERENCES dbo.employees(employee_id),
        expires_at DATETIME2 NOT NULL,
        created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
    );
    CREATE INDEX IX_auth_sessions_employee ON dbo.auth_sessions(employee_id);
END;
COMMIT;
GO
