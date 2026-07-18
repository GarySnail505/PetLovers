/* ESQUEMA LOCAL - NODO 001 CUMBAYA
   Requiere Sede, Cliente y Mascota creadas por replicacion y el linked server
   DESKTOP-Q40JF1K hacia Inaquito. */

USE [PetLoversCumbaya];
GO

IF OBJECT_ID(N'dbo.Sede', N'U') IS NULL
   OR OBJECT_ID(N'dbo.Cliente', N'U') IS NULL
   OR OBJECT_ID(N'dbo.Mascota', N'U') IS NULL
    THROW 64001, 'Primero deben sincronizarse Sede, Cliente y Mascota.', 1;

IF OBJECT_ID(N'dbo.Empleado_Op001', N'U') IS NOT NULL
    THROW 64002, 'Los fragmentos locales de Cumbaya ya existen.', 1;
GO

CREATE TABLE dbo.Empleado_Op001
(
    Codigo_empleado char(3) NOT NULL,
    Nombre_empleado varchar(50) NOT NULL,
    Cargo varchar(50) NOT NULL,
    Codigo_sede char(3) NOT NULL,
    CONSTRAINT pk_empleado_op001 PRIMARY KEY (Codigo_empleado, Codigo_sede),
    CONSTRAINT fk_empleado_op_sede001 FOREIGN KEY (Codigo_sede)
        REFERENCES dbo.Sede(Codigo_sede),
    CONSTRAINT c_empleado_op001 CHECK (Codigo_sede = '001')
);

CREATE TABLE dbo.Servicio001
(
    Codigo_servicio char(3) NOT NULL,
    Tipo_servicio varchar(50) NOT NULL,
    Costo_base numeric(7,2) NOT NULL,
    Descripcion varchar(100) NOT NULL,
    Codigo_sede char(3) NOT NULL,
    CONSTRAINT pk_servicio001 PRIMARY KEY (Codigo_servicio, Codigo_sede),
    CONSTRAINT fk_servicio_sede001 FOREIGN KEY (Codigo_sede)
        REFERENCES dbo.Sede(Codigo_sede),
    CONSTRAINT c_servicio001 CHECK (Codigo_sede = '001')
);

CREATE TABLE dbo.Historial001
(
    Id_historial char(3) NOT NULL,
    Id_mascota char(3) NOT NULL,
    Codigo_servicio char(3) NOT NULL,
    Codigo_empleado char(3) NOT NULL,
    Codigo_sede char(3) NOT NULL,
    Fecha_atencion date NOT NULL,
    Pago numeric(7,2) NOT NULL,
    CONSTRAINT pk_historial001 PRIMARY KEY (Id_historial, Codigo_sede),
    CONSTRAINT fk_historial_mascota001 FOREIGN KEY (Id_mascota)
        REFERENCES dbo.Mascota(Id_mascota),
    CONSTRAINT fk_historial_servicio001 FOREIGN KEY (Codigo_servicio, Codigo_sede)
        REFERENCES dbo.Servicio001(Codigo_servicio, Codigo_sede),
    CONSTRAINT fk_historial_empleado001 FOREIGN KEY (Codigo_empleado, Codigo_sede)
        REFERENCES dbo.Empleado_Op001(Codigo_empleado, Codigo_sede),
    CONSTRAINT c_historial001 CHECK (Codigo_sede = '001')
);
GO

INSERT INTO dbo.Empleado_Op001
SELECT Codigo_empleado, Nombre_empleado, Cargo, Codigo_sede
FROM [DESKTOP-Q40JF1K].PetLoversCentral.dbo.Empleado
WHERE Codigo_sede = '001';

INSERT INTO dbo.Servicio001
SELECT Codigo_servicio, Tipo_servicio, Costo_base, Descripcion, Codigo_sede
FROM [DESKTOP-Q40JF1K].PetLoversCentral.dbo.Servicio
WHERE Codigo_sede = '001';

INSERT INTO dbo.Historial001
(
    Id_historial, Id_mascota, Codigo_servicio, Codigo_empleado,
    Codigo_sede, Fecha_atencion, Pago
)
SELECT
    h.Id_historial, h.Id_mascota, h.Codigo_servicio, h.Codigo_empleado,
    s.Codigo_sede, h.Fecha_atencion, h.Pago
FROM [DESKTOP-Q40JF1K].PetLoversCentral.dbo.Historial AS h
INNER JOIN [DESKTOP-Q40JF1K].PetLoversCentral.dbo.Servicio AS s
  ON s.Codigo_servicio = h.Codigo_servicio
WHERE s.Codigo_sede = '001';
GO

ALTER TABLE dbo.Empleado_Op001 WITH CHECK CHECK CONSTRAINT c_empleado_op001;
ALTER TABLE dbo.Servicio001 WITH CHECK CHECK CONSTRAINT c_servicio001;
ALTER TABLE dbo.Historial001 WITH CHECK CHECK CONSTRAINT c_historial001;
GO

SELECT 'Empleado_Op001' AS Entidad, COUNT(*) AS Cantidad FROM dbo.Empleado_Op001
UNION ALL SELECT 'Servicio001', COUNT(*) FROM dbo.Servicio001
UNION ALL SELECT 'Historial001', COUNT(*) FROM dbo.Historial001;
GO
