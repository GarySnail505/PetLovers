/* Ejecutar conectado a la instancia SQL Server del NODO 001 - CUMBAYÁ. */
USE [master];
GO

IF NOT EXISTS (SELECT 1 FROM sys.sql_logins WHERE name = N'pl_app_cumbaya')
BEGIN
    CREATE LOGIN [pl_app_cumbaya]
    WITH PASSWORD = N'CAMBIAR-ANTES-DE-EJECUTAR-CUMBAYA#2026!',
         CHECK_POLICY = ON,
         CHECK_EXPIRATION = OFF;
END;
GO

USE [PetLoversCumbaya];
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'pl_app_cumbaya')
    CREATE USER [pl_app_cumbaya] FOR LOGIN [pl_app_cumbaya];
GO

GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.[Sede] TO [pl_app_cumbaya];
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.[Cliente] TO [pl_app_cumbaya];
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.[Mascota] TO [pl_app_cumbaya];
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.[Empleado_Op] TO [pl_app_cumbaya];
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.[Servicio001] TO [pl_app_cumbaya];
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.[Historial_Clinico001] TO [pl_app_cumbaya];
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.[Historial_Pago001] TO [pl_app_cumbaya];
GO
