USE [smartmarket_hrm];
GO
SET XACT_ABORT ON;
BEGIN TRY
    BEGIN TRANSACTION;
    DECLARE @definition nvarchar(max);
    SELECT @definition = definition
    FROM sys.check_constraints
    WHERE parent_object_id = OBJECT_ID(N'dbo.employees')
      AND name = N'CK_employees_login_provider';

    -- Keep the existing allowed values and additionally allow LOCAL accounts.
    IF @definition IS NOT NULL
       AND CHARINDEX(N'''LOCAL''', UPPER(@definition)) = 0
    BEGIN
        ALTER TABLE dbo.employees DROP CONSTRAINT CK_employees_login_provider;
        DECLARE @sql nvarchar(max) =
            N'ALTER TABLE dbo.employees WITH CHECK ADD CONSTRAINT CK_employees_login_provider CHECK (('
            + @definition + N') OR ([login_provider] = ''LOCAL''));';
        EXEC sys.sp_executesql @sql;
    END;
    COMMIT TRANSACTION;
    SELECT name, definition FROM sys.check_constraints
    WHERE parent_object_id = OBJECT_ID(N'dbo.employees')
      AND name = N'CK_employees_login_provider';
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO