/* VPA DE HISTORIAL - EJECUTAR EN INAQUITO
   Linked server de Cumbaya: CHIKORITA. */

USE [PetLoversInaquito];
GO

SET ANSI_NULLS ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET QUOTED_IDENTIFIER ON;
SET NUMERIC_ROUNDABORT OFF;
GO

IF OBJECT_ID(N'dbo.Historial002', N'U') IS NULL
    THROW 54001, 'No existe dbo.Historial002 en Inaquito.', 1;

IF NOT EXISTS
(
    SELECT 1
    FROM [CHIKORITA].PetLoversCumbaya.sys.tables AS t
    INNER JOIN [CHIKORITA].PetLoversCumbaya.sys.schemas AS s
      ON s.schema_id = t.schema_id
    WHERE s.name = N'dbo' AND t.name = N'Historial001'
)
    THROW 54002, 'No existe dbo.Historial001 en Cumbaya o el linked server no permite consultarla.', 1;

IF EXISTS
(
    SELECT RTRIM(i.Id_historial)
    FROM dbo.Historial002 AS i
    INNER JOIN [CHIKORITA].PetLoversCumbaya.dbo.Historial001 AS c
      ON c.Id_historial = i.Id_historial
)
    THROW 54003, 'Existen Id_historial duplicados entre Cumbaya e Inaquito.', 1;
GO

DECLARE @sql nvarchar(max);

IF OBJECT_ID(N'dbo.V_Historial', N'V') IS NULL
    SET @sql = N'CREATE VIEW dbo.V_Historial AS ';
ELSE
    SET @sql = N'ALTER VIEW dbo.V_Historial AS ';

SET @sql += N'
SELECT Id_historial, Id_mascota, Codigo_servicio, Codigo_empleado,
       Codigo_sede, Fecha_atencion, Pago
FROM [CHIKORITA].PetLoversCumbaya.dbo.Historial001
UNION ALL
SELECT Id_historial, Id_mascota, Codigo_servicio, Codigo_empleado,
       Codigo_sede, Fecha_atencion, Pago
FROM PetLoversInaquito.dbo.Historial002';

EXEC sys.sp_executesql @sql;
GO

IF USER_ID(N'pl_app_inaquito') IS NOT NULL
BEGIN
    GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.Historial002 TO pl_app_inaquito;
    GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.V_Historial TO pl_app_inaquito;
END;
GO

SELECT * FROM dbo.V_Historial
ORDER BY Codigo_sede, Id_historial;
GO
