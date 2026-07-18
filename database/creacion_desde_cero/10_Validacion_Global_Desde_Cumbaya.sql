/* VALIDACION SIN ESCRITURAS - EJECUTAR EN CUMBAYA. */

USE [PetLoversCumbaya];
GO

IF OBJECT_ID(N'dbo.V_Empleado_Op', N'V') IS NULL
   OR OBJECT_ID(N'dbo.V_Servicio', N'V') IS NULL
   OR OBJECT_ID(N'dbo.V_Historial', N'V') IS NULL
    THROW 69001, 'Falta una o mas VPA en Cumbaya.', 1;
GO

-- Todas estas consultas deben devolver cero filas.
SELECT * FROM dbo.Empleado_Op001 WHERE Codigo_sede <> '001';
SELECT * FROM dbo.Servicio001 WHERE Codigo_sede <> '001';
SELECT * FROM dbo.Historial001 WHERE Codigo_sede <> '001';

SELECT *
FROM [DESKTOP-Q40JF1K].PetLoversInaquito.dbo.Empleado_Op002
WHERE Codigo_sede <> '002';

SELECT *
FROM [DESKTOP-Q40JF1K].PetLoversInaquito.dbo.Servicio002
WHERE Codigo_sede <> '002';

SELECT *
FROM [DESKTOP-Q40JF1K].PetLoversInaquito.dbo.Historial002
WHERE Codigo_sede <> '002';
GO

-- Unicidad global de los identificadores que deben ser compartidos.
SELECT Codigo_empleado, COUNT(*) AS Repeticiones
FROM dbo.V_Empleado_Op
GROUP BY Codigo_empleado
HAVING COUNT(*) > 1;

SELECT Id_historial, COUNT(*) AS Repeticiones
FROM dbo.V_Historial
GROUP BY Id_historial
HAVING COUNT(*) > 1;
GO

-- La reconstruccion de Historial debe coincidir con la base central.
WITH Central AS
(
    SELECT
        h.Id_historial, h.Id_mascota, h.Codigo_servicio, h.Codigo_empleado,
        s.Codigo_sede, h.Fecha_atencion, h.Pago
    FROM [DESKTOP-Q40JF1K].PetLoversCentral.dbo.Historial AS h
    INNER JOIN [DESKTOP-Q40JF1K].PetLoversCentral.dbo.Servicio AS s
      ON s.Codigo_servicio = h.Codigo_servicio
)
SELECT * FROM Central
EXCEPT
SELECT Id_historial, Id_mascota, Codigo_servicio, Codigo_empleado,
       Codigo_sede, Fecha_atencion, Pago
FROM dbo.V_Historial;

WITH Central AS
(
    SELECT
        h.Id_historial, h.Id_mascota, h.Codigo_servicio, h.Codigo_empleado,
        s.Codigo_sede, h.Fecha_atencion, h.Pago
    FROM [DESKTOP-Q40JF1K].PetLoversCentral.dbo.Historial AS h
    INNER JOIN [DESKTOP-Q40JF1K].PetLoversCentral.dbo.Servicio AS s
      ON s.Codigo_servicio = h.Codigo_servicio
)
SELECT Id_historial, Id_mascota, Codigo_servicio, Codigo_empleado,
       Codigo_sede, Fecha_atencion, Pago
FROM dbo.V_Historial
EXCEPT
SELECT * FROM Central;
GO

SELECT Codigo_sede, COUNT(*) AS Empleados
FROM dbo.V_Empleado_Op GROUP BY Codigo_sede ORDER BY Codigo_sede;

SELECT Codigo_sede, COUNT(*) AS Servicios
FROM dbo.V_Servicio GROUP BY Codigo_sede ORDER BY Codigo_sede;

SELECT Codigo_sede, COUNT(*) AS Historiales
FROM dbo.V_Historial GROUP BY Codigo_sede ORDER BY Codigo_sede;
GO
