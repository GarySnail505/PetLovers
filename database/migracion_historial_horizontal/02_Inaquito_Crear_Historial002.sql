/* MIGRACION LOCAL - NODO 002 INAQUITO
   Crea Historial002 y reconstruye cada fila a partir de los fragmentos
   verticales existentes. No elimina ni modifica las tablas antiguas. */

USE [PetLoversInaquito];
GO

SET XACT_ABORT ON;
GO

IF OBJECT_ID(N'dbo.Historial_Clinico002', N'U') IS NULL
    THROW 52001, 'No existe dbo.Historial_Clinico002.', 1;

IF OBJECT_ID(N'dbo.Historial_Pago002', N'U') IS NULL
    THROW 52002, 'No existe dbo.Historial_Pago002.', 1;

IF OBJECT_ID(N'dbo.Historial002', N'U') IS NOT NULL
    THROW 52003, 'dbo.Historial002 ya existe. No se realizo ningun cambio.', 1;

IF EXISTS
(
    SELECT c.Id_historial, c.Codigo_sede
    FROM dbo.Historial_Clinico002 AS c
    FULL OUTER JOIN dbo.Historial_Pago002 AS p
      ON p.Id_historial = c.Id_historial
     AND p.Codigo_sede = c.Codigo_sede
    WHERE c.Id_historial IS NULL OR p.Id_historial IS NULL
)
    THROW 52004, 'Existen historiales clinicos sin pago o pagos sin historial clinico.', 1;
GO

BEGIN TRY
    BEGIN TRANSACTION;

    CREATE TABLE dbo.Historial002
    (
        Id_historial char(3) NOT NULL,
        Id_mascota char(3) NOT NULL,
        Codigo_servicio char(3) NOT NULL,
        Codigo_empleado char(3) NOT NULL,
        Codigo_sede char(3) NOT NULL,
        Fecha_atencion date NOT NULL,
        Pago numeric(7,2) NOT NULL,
        CONSTRAINT pk_historial002
            PRIMARY KEY (Id_historial, Codigo_sede),
        CONSTRAINT fk_historial002_mascota
            FOREIGN KEY (Id_mascota)
            REFERENCES dbo.Mascota(Id_mascota),
        CONSTRAINT fk_historial002_servicio
            FOREIGN KEY (Codigo_servicio, Codigo_sede)
            REFERENCES dbo.Servicio002(Codigo_servicio, Codigo_sede),
        CONSTRAINT fk_historial002_empleado
            FOREIGN KEY (Codigo_empleado, Codigo_sede)
            REFERENCES dbo.Empleado_Op002(Codigo_empleado, Codigo_sede),
        CONSTRAINT c_historial002
            CHECK (Codigo_sede = '002')
    );

    INSERT INTO dbo.Historial002
    (
        Id_historial, Id_mascota, Codigo_servicio, Codigo_empleado,
        Codigo_sede, Fecha_atencion, Pago
    )
    SELECT
        c.Id_historial, c.Id_mascota, c.Codigo_servicio, c.Codigo_empleado,
        c.Codigo_sede, c.Fecha_atencion, p.Pago
    FROM dbo.Historial_Clinico002 AS c
    INNER JOIN dbo.Historial_Pago002 AS p
      ON p.Id_historial = c.Id_historial
     AND p.Codigo_sede = c.Codigo_sede;

    IF (SELECT COUNT_BIG(*) FROM dbo.Historial002)
       <> (SELECT COUNT_BIG(*) FROM dbo.Historial_Clinico002)
        THROW 52005, 'La cantidad migrada no coincide con Historial_Clinico002.', 1;

    ALTER TABLE dbo.Historial002 WITH CHECK CHECK CONSTRAINT c_historial002;

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO

SELECT COUNT(*) AS Registros_migrados FROM dbo.Historial002;
SELECT * FROM dbo.Historial002 ORDER BY Id_historial;

SELECT name, definition, is_disabled, is_not_trusted
FROM sys.check_constraints
WHERE parent_object_id = OBJECT_ID(N'dbo.Historial002');
GO
