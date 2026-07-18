/* PRUEBA CRUD DE V_HISTORIAL - EJECUTAR EN CUMBAYA
   Verifica el enrutamiento hacia Historial001 e Historial002.
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

IF EXISTS (SELECT 1 FROM dbo.V_Historial WHERE Id_historial IN ('X71','X72'))
    THROW 70001, 'Los identificadores temporales X71 o X72 ya estan ocupados.', 1;
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

    INSERT INTO dbo.V_Historial
    VALUES ('X71',@Mascota,NULL,NULL,'001',CAST(GETDATE() AS date),10.00);

    INSERT INTO dbo.V_Historial
    VALUES ('X72',@Mascota,NULL,NULL,'002',CAST(GETDATE() AS date),20.00);

    IF NOT EXISTS
       (
           SELECT 1 FROM dbo.Historial001
           WHERE Id_historial = 'X71' AND Codigo_sede = '001'
       )
        THROW 70003, 'El INSERT de Cumbaya no llego a Historial001.', 1;

    IF NOT EXISTS
       (
           SELECT 1
           FROM [DESKTOP-Q40JF1K].PetLoversInaquito.dbo.Historial002
           WHERE Id_historial = 'X72' AND Codigo_sede = '002'
       )
        THROW 70004, 'El INSERT de Inaquito no llego a Historial002.', 1;

    UPDATE dbo.V_Historial
    SET Pago = Pago + 5.00
    WHERE Id_historial IN ('X71','X72');

    IF (SELECT SUM(Pago) FROM dbo.V_Historial WHERE Id_historial IN ('X71','X72')) <> 40.00
        THROW 70005, 'La actualizacion no se aplico a los dos fragmentos.', 1;

    DELETE FROM dbo.V_Historial WHERE Id_historial IN ('X71','X72');

    IF EXISTS (SELECT 1 FROM dbo.V_Historial WHERE Id_historial IN ('X71','X72'))
        THROW 70006, 'La eliminacion dejo registros temporales.', 1;

    PRINT 'PRUEBA CORRECTA: V_Historial enruta el CRUD hacia 001 y 002.';
    ROLLBACK TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO

SELECT * FROM dbo.V_Historial WHERE Id_historial IN ('X71','X72');
GO
