/* PRUEBA CRUD DISTRIBUIDA - EJECUTAR EN CUMBAYA
   Prueba las tres VPA y el acceso directo remoto a Empleado_Contacto.
   Siempre termina con ROLLBACK. */

USE [PetLoversCumbaya];
GO

SET ANSI_NULLS ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET QUOTED_IDENTIFIER ON;
SET NUMERIC_ROUNDABORT OFF;
SET XACT_ABORT ON;
GO

IF EXISTS (SELECT 1 FROM dbo.V_Empleado_Op WHERE Codigo_empleado IN ('X91','X92'))
   OR EXISTS (SELECT 1 FROM dbo.V_Servicio WHERE Codigo_servicio IN ('X81','X82'))
   OR EXISTS (SELECT 1 FROM dbo.V_Historial WHERE Id_historial IN ('X71','X72'))
   OR EXISTS
      (
          SELECT 1
          FROM [DESKTOP-Q40JF1K].PetLoversInaquito.dbo.Empleado_Contacto
          WHERE Codigo_empleado IN ('X91','X92')
      )
    THROW 70001, 'Los identificadores temporales ya estan ocupados.', 1;
GO

DECLARE @Mascota char(3);

SELECT TOP (1) @Mascota = c.Id_mascota
FROM dbo.Mascota AS c
WHERE EXISTS
(
    SELECT 1
    FROM [DESKTOP-Q40JF1K].PetLoversInaquito.dbo.Mascota AS i
    WHERE i.Id_mascota = c.Id_mascota
)
ORDER BY c.Id_mascota;

IF @Mascota IS NULL
    THROW 70002, 'No existe una mascota sincronizada para realizar la prueba.', 1;

BEGIN TRY
    BEGIN DISTRIBUTED TRANSACTION;

    -- Empleado operativo por VPA y contacto directo en Inaquito.
    INSERT INTO dbo.V_Empleado_Op
    VALUES ('X91','Empleado prueba Cumbaya','Auxiliar temporal','001');

    INSERT INTO dbo.V_Empleado_Op
    VALUES ('X92','Empleado prueba Inaquito','Auxiliar temporal','002');

    INSERT INTO [DESKTOP-Q40JF1K].PetLoversInaquito.dbo.Empleado_Contacto
    VALUES ('X91','1799999991','0999999991','x91@petlovers.test');

    INSERT INTO [DESKTOP-Q40JF1K].PetLoversInaquito.dbo.Empleado_Contacto
    VALUES ('X92','1799999992','0999999992','x92@petlovers.test');

    -- Servicio por VPA.
    INSERT INTO dbo.V_Servicio
    VALUES ('X81','Servicio prueba 001',10.00,'Temporal Cumbaya','001');

    INSERT INTO dbo.V_Servicio
    VALUES ('X82','Servicio prueba 002',20.00,'Temporal Inaquito','002');

    -- Historial horizontal completo por VPA.
    INSERT INTO dbo.V_Historial
    VALUES ('X71',@Mascota,'X81','X91','001',CAST(GETDATE() AS date),10.00);

    INSERT INTO dbo.V_Historial
    VALUES ('X72',@Mascota,'X82','X92','002',CAST(GETDATE() AS date),20.00);

    IF (SELECT COUNT(*) FROM dbo.V_Historial WHERE Id_historial IN ('X71','X72')) <> 2
        THROW 70003, 'La prueba INSERT no reconstruyo los dos nodos.', 1;

    UPDATE dbo.V_Empleado_Op
    SET Cargo = 'Cargo actualizado por VPA'
    WHERE Codigo_empleado IN ('X91','X92');

    UPDATE dbo.V_Servicio
    SET Costo_base = Costo_base + 5.00
    WHERE Codigo_servicio IN ('X81','X82');

    UPDATE dbo.V_Historial
    SET Pago = Pago + 5.00
    WHERE Id_historial IN ('X71','X72');

    UPDATE [DESKTOP-Q40JF1K].PetLoversInaquito.dbo.Empleado_Contacto
    SET Correo_empleado = CONCAT(Codigo_empleado, '@actualizado.test')
    WHERE Codigo_empleado IN ('X91','X92');

    DELETE FROM dbo.V_Historial WHERE Id_historial IN ('X71','X72');
    DELETE FROM dbo.V_Servicio WHERE Codigo_servicio IN ('X81','X82');
    DELETE FROM [DESKTOP-Q40JF1K].PetLoversInaquito.dbo.Empleado_Contacto
    WHERE Codigo_empleado IN ('X91','X92');
    DELETE FROM dbo.V_Empleado_Op WHERE Codigo_empleado IN ('X91','X92');

    IF EXISTS (SELECT 1 FROM dbo.V_Historial WHERE Id_historial IN ('X71','X72'))
       OR EXISTS (SELECT 1 FROM dbo.V_Servicio WHERE Codigo_servicio IN ('X81','X82'))
       OR EXISTS (SELECT 1 FROM dbo.V_Empleado_Op WHERE Codigo_empleado IN ('X91','X92'))
        THROW 70004, 'La prueba DELETE dejo registros temporales.', 1;

    PRINT 'PRUEBA CORRECTA: CRUD distribuido en 001 y 002.';
    ROLLBACK TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO

SELECT * FROM dbo.V_Empleado_Op WHERE Codigo_empleado IN ('X91','X92');
SELECT * FROM dbo.V_Servicio WHERE Codigo_servicio IN ('X81','X82');
SELECT * FROM dbo.V_Historial WHERE Id_historial IN ('X71','X72');
GO
