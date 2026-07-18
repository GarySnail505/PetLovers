/* ESQUEMA LOCAL - NODO 002 INAQUITO
   Requiere PetLoversCentral en esta misma instancia. */

USE [master];
GO

IF DB_ID(N'PetLoversCentral') IS NULL
    THROW 61001, 'Primero debe crearse PetLoversCentral.', 1;

IF DB_ID(N'PetLoversInaquito') IS NOT NULL
    THROW 61002, 'PetLoversInaquito ya existe. No se realizo ningun cambio.', 1;
GO

CREATE DATABASE PetLoversInaquito COLLATE Modern_Spanish_CI_AS;
GO

USE [PetLoversInaquito];
GO

CREATE TABLE dbo.Sede
(
    Codigo_sede char(3) NOT NULL,
    Ubicacion varchar(50) NOT NULL,
    Nombre_sede varchar(50) NOT NULL,
    CONSTRAINT pk_sede002 PRIMARY KEY (Codigo_sede)
);

CREATE TABLE dbo.Cliente
(
    Cedula_cliente char(10) NOT NULL,
    Nombre_Cliente varchar(50) NOT NULL,
    Celular_Cliente char(10) NOT NULL,
    Correo_Cliente varchar(100) NOT NULL,
    CONSTRAINT pk_cliente002 PRIMARY KEY (Cedula_cliente)
);

CREATE TABLE dbo.Mascota
(
    Id_mascota char(3) NOT NULL,
    Nombre_mascota varchar(50) NOT NULL,
    Fecha_nacimiento date NOT NULL,
    Especie varchar(30) NOT NULL,
    Raza varchar(50) NOT NULL,
    Cedula_cliente char(10) NOT NULL,
    CONSTRAINT pk_mascota002 PRIMARY KEY (Id_mascota),
    CONSTRAINT fk_mascota_cliente002 FOREIGN KEY (Cedula_cliente)
        REFERENCES dbo.Cliente(Cedula_cliente)
);

CREATE TABLE dbo.Empleado_Op002
(
    Codigo_empleado char(3) NOT NULL,
    Nombre_empleado varchar(50) NOT NULL,
    Cargo varchar(50) NOT NULL,
    Codigo_sede char(3) NOT NULL,
    CONSTRAINT pk_empleado_op002 PRIMARY KEY (Codigo_empleado, Codigo_sede),
    CONSTRAINT fk_empleado_op_sede002 FOREIGN KEY (Codigo_sede)
        REFERENCES dbo.Sede(Codigo_sede),
    CONSTRAINT c_empleado_op002 CHECK (Codigo_sede = '002')
);

CREATE TABLE dbo.Empleado_Contacto
(
    Codigo_empleado char(3) NOT NULL,
    Cedula_empleado char(10) NOT NULL,
    Celular_empleado char(10) NOT NULL,
    Correo_empleado varchar(100) NOT NULL,
    CONSTRAINT pk_empleado_contacto PRIMARY KEY (Codigo_empleado),
    CONSTRAINT uq_empleado_contacto_cedula UNIQUE (Cedula_empleado)
);

CREATE TABLE dbo.Servicio002
(
    Codigo_servicio char(3) NOT NULL,
    Tipo_servicio varchar(50) NOT NULL,
    Costo_base numeric(7,2) NOT NULL,
    Descripcion varchar(100) NOT NULL,
    Codigo_sede char(3) NOT NULL,
    CONSTRAINT pk_servicio002 PRIMARY KEY (Codigo_servicio, Codigo_sede),
    CONSTRAINT fk_servicio_sede002 FOREIGN KEY (Codigo_sede)
        REFERENCES dbo.Sede(Codigo_sede),
    CONSTRAINT c_servicio002 CHECK (Codigo_sede = '002')
);

CREATE TABLE dbo.Historial002
(
    Id_historial char(3) NOT NULL,
    Id_mascota char(3) NOT NULL,
    Codigo_servicio char(3) NOT NULL,
    Codigo_empleado char(3) NOT NULL,
    Codigo_sede char(3) NOT NULL,
    Fecha_atencion date NOT NULL,
    Pago numeric(7,2) NOT NULL,
    CONSTRAINT pk_historial002 PRIMARY KEY (Id_historial, Codigo_sede),
    CONSTRAINT fk_historial_mascota002 FOREIGN KEY (Id_mascota)
        REFERENCES dbo.Mascota(Id_mascota),
    CONSTRAINT fk_historial_servicio002 FOREIGN KEY (Codigo_servicio, Codigo_sede)
        REFERENCES dbo.Servicio002(Codigo_servicio, Codigo_sede),
    CONSTRAINT fk_historial_empleado002 FOREIGN KEY (Codigo_empleado, Codigo_sede)
        REFERENCES dbo.Empleado_Op002(Codigo_empleado, Codigo_sede),
    CONSTRAINT c_historial002 CHECK (Codigo_sede = '002')
);
GO

INSERT INTO dbo.Sede
SELECT Codigo_sede, Ubicacion, Nombre_sede
FROM PetLoversCentral.dbo.Sede;

INSERT INTO dbo.Cliente
SELECT Cedula_cliente, Nombre_Cliente, Celular_Cliente, Correo_Cliente
FROM PetLoversCentral.dbo.Cliente;

INSERT INTO dbo.Mascota
SELECT Id_mascota, Nombre_mascota, Fecha_nacimiento, Especie, Raza, Cedula_cliente
FROM PetLoversCentral.dbo.Mascota;

INSERT INTO dbo.Empleado_Op002
SELECT Codigo_empleado, Nombre_empleado, Cargo, Codigo_sede
FROM PetLoversCentral.dbo.Empleado
WHERE Codigo_sede = '002';

INSERT INTO dbo.Empleado_Contacto
SELECT Codigo_empleado, Cedula_empleado, Celular_empleado, Correo_empleado
FROM PetLoversCentral.dbo.Empleado;

INSERT INTO dbo.Servicio002
SELECT Codigo_servicio, Tipo_servicio, Costo_base, Descripcion, Codigo_sede
FROM PetLoversCentral.dbo.Servicio
WHERE Codigo_sede = '002';

INSERT INTO dbo.Historial002
(
    Id_historial, Id_mascota, Codigo_servicio, Codigo_empleado,
    Codigo_sede, Fecha_atencion, Pago
)
SELECT
    h.Id_historial, h.Id_mascota, h.Codigo_servicio, h.Codigo_empleado,
    s.Codigo_sede, h.Fecha_atencion, h.Pago
FROM PetLoversCentral.dbo.Historial AS h
INNER JOIN PetLoversCentral.dbo.Servicio AS s
  ON s.Codigo_servicio = h.Codigo_servicio
WHERE s.Codigo_sede = '002';
GO

ALTER TABLE dbo.Empleado_Op002 WITH CHECK CHECK CONSTRAINT c_empleado_op002;
ALTER TABLE dbo.Servicio002 WITH CHECK CHECK CONSTRAINT c_servicio002;
ALTER TABLE dbo.Historial002 WITH CHECK CHECK CONSTRAINT c_historial002;
GO

SELECT 'Sede' AS Entidad, COUNT(*) AS Cantidad FROM dbo.Sede
UNION ALL SELECT 'Cliente', COUNT(*) FROM dbo.Cliente
UNION ALL SELECT 'Mascota', COUNT(*) FROM dbo.Mascota
UNION ALL SELECT 'Empleado_Op002', COUNT(*) FROM dbo.Empleado_Op002
UNION ALL SELECT 'Empleado_Contacto', COUNT(*) FROM dbo.Empleado_Contacto
UNION ALL SELECT 'Servicio002', COUNT(*) FROM dbo.Servicio002
UNION ALL SELECT 'Historial002', COUNT(*) FROM dbo.Historial002;
GO
