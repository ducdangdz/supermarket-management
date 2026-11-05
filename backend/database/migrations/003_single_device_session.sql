/* Enforce one active local application session per employee. Apply after 001_account_auth.sql. */
USE smartmarket_hrm;
GO
SET XACT_ABORT ON;
BEGIN TRANSACTION;

/* Old sessions cannot be tied to an installation identifier, so revoke them. */
DELETE FROM dbo.auth_sessions;

IF COL_LENGTH('dbo.auth_sessions', 'device_id') IS NULL
    ALTER TABLE dbo.auth_sessions ADD device_id CHAR(32) NOT NULL;
IF COL_LENGTH('dbo.auth_sessions', 'last_seen_at') IS NULL
    ALTER TABLE dbo.auth_sessions ADD last_seen_at DATETIME2 NOT NULL CONSTRAINT DF_auth_sessions_last_seen_at DEFAULT SYSUTCDATETIME();
/* A unique employee_id index would also block manager/admin multi-device access. */
IF EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.auth_sessions') AND name = 'UX_auth_sessions_employee')
    DROP INDEX UX_auth_sessions_employee ON dbo.auth_sessions;

COMMIT;
GO
