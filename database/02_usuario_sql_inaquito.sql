/* Ejecutar conectado a la instancia SQL Server del NODO 002 - IÑAQUITO. */
USE [master];
GO

IF NOT EXISTS (SELECT 1 FROM sys.sql_logins WHERE name = N'pl_app_inaquito')
BEGIN
    CREATE LOGIN [pl_app_inaquito]
    WITH PASSWORD = N'CAMBIAR-ANTES-DE-EJECUTAR-INAQUITO#2026!',
         CHECK_POLICY = ON,
         CHECK_EXPIRATION = OFF;
END;
GO

USE [PetLoversInaquito];
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'pl_app_inaquito')
    CREATE USER [pl_app_inaquito] FOR LOGIN [pl_app_inaquito];
GO

GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.[Sede] TO [pl_app_inaquito];
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.[Cliente] TO [pl_app_inaquito];
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.[Mascota] TO [pl_app_inaquito];
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.[Empleado_Op] TO [pl_app_inaquito];
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.[Empleado_Contacto] TO [pl_app_inaquito];
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.[Servicio002] TO [pl_app_inaquito];
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.[Historial_Clinico002] TO [pl_app_inaquito];
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.[Historial_Pago002] TO [pl_app_inaquito];
GO
