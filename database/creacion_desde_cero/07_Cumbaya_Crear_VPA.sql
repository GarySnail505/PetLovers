/* VISTAS PARTICIONADAS ACTUALIZABLES - NODO 001 CUMBAYA
   Linked server hacia Inaquito: DESKTOP-Q40JF1K. */

USE [master];
GO

IF NOT EXISTS (SELECT 1 FROM sys.servers WHERE name = N'DESKTOP-Q40JF1K' AND is_linked = 1)
    THROW 66001, 'No existe el linked server DESKTOP-Q40JF1K.', 1;

EXEC sys.sp_serveroption
    @server = N'DESKTOP-Q40JF1K',
    @optname = N'data access',
    @optvalue = N'true';
GO

SELECT TOP (1) *
FROM [DESKTOP-Q40JF1K].PetLoversInaquito.dbo.Empleado_Op002;
GO

USE [PetLoversCumbaya];
GO

SET ANSI_NULLS ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET QUOTED_IDENTIFIER ON;
SET NUMERIC_ROUNDABORT OFF;
GO

IF OBJECT_ID(N'dbo.Empleado_Op001', N'U') IS NULL
   OR OBJECT_ID(N'dbo.Servicio001', N'U') IS NULL
   OR OBJECT_ID(N'dbo.Historial001', N'U') IS NULL
    THROW 66002, 'Faltan fragmentos locales 001.', 1;

IF EXISTS
(
    SELECT 1
    FROM sys.check_constraints
    WHERE name IN (N'c_empleado_op001', N'c_servicio001', N'c_historial001')
      AND (is_disabled = 1 OR is_not_trusted = 1)
)
    THROW 66003, 'Los CHECK del fragmento 001 deben estar habilitados y validados.', 1;
GO

DECLARE @sql nvarchar(max);

IF OBJECT_ID(N'dbo.V_Empleado_Op', N'V') IS NULL
    SET @sql = N'CREATE VIEW dbo.V_Empleado_Op AS ';
ELSE
    SET @sql = N'ALTER VIEW dbo.V_Empleado_Op AS ';

SET @sql += N'
SELECT Codigo_empleado, Nombre_empleado, Cargo, Codigo_sede
FROM PetLoversCumbaya.dbo.Empleado_Op001
UNION ALL
SELECT Codigo_empleado, Nombre_empleado, Cargo, Codigo_sede
FROM [DESKTOP-Q40JF1K].PetLoversInaquito.dbo.Empleado_Op002';

EXEC sys.sp_executesql @sql;
GO

DECLARE @sql nvarchar(max);

IF OBJECT_ID(N'dbo.V_Servicio', N'V') IS NULL
    SET @sql = N'CREATE VIEW dbo.V_Servicio AS ';
ELSE
    SET @sql = N'ALTER VIEW dbo.V_Servicio AS ';

SET @sql += N'
SELECT Codigo_servicio, Tipo_servicio, Costo_base, Descripcion, Codigo_sede
FROM PetLoversCumbaya.dbo.Servicio001
UNION ALL
SELECT Codigo_servicio, Tipo_servicio, Costo_base, Descripcion, Codigo_sede
FROM [DESKTOP-Q40JF1K].PetLoversInaquito.dbo.Servicio002';

EXEC sys.sp_executesql @sql;
GO

DECLARE @sql nvarchar(max);

IF OBJECT_ID(N'dbo.V_Historial', N'V') IS NULL
    SET @sql = N'CREATE VIEW dbo.V_Historial AS ';
ELSE
    SET @sql = N'ALTER VIEW dbo.V_Historial AS ';

SET @sql += N'
SELECT Id_historial, Id_mascota, Codigo_servicio, Codigo_empleado,
       Codigo_sede, Fecha_atencion, Pago
FROM PetLoversCumbaya.dbo.Historial001
UNION ALL
SELECT Id_historial, Id_mascota, Codigo_servicio, Codigo_empleado,
       Codigo_sede, Fecha_atencion, Pago
FROM [DESKTOP-Q40JF1K].PetLoversInaquito.dbo.Historial002';

EXEC sys.sp_executesql @sql;
GO

SELECT Codigo_sede, COUNT(*) AS Empleados
FROM dbo.V_Empleado_Op GROUP BY Codigo_sede;

SELECT Codigo_sede, COUNT(*) AS Servicios
FROM dbo.V_Servicio GROUP BY Codigo_sede;

SELECT Codigo_sede, COUNT(*) AS Historiales
FROM dbo.V_Historial GROUP BY Codigo_sede;
GO
