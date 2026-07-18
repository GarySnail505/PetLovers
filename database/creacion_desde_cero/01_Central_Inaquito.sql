/* BASE GLOBAL DE ORIGEN - EJECUTAR EN INAQUITO
   Este script es solamente para una instalación nueva. */

USE [master];
GO

IF DB_ID(N'PetLoversCentral') IS NOT NULL
    THROW 60001, 'PetLoversCentral ya existe. No se realizo ningun cambio.', 1;
GO

CREATE DATABASE PetLoversCentral COLLATE Modern_Spanish_CI_AS;
GO

USE [PetLoversCentral];
GO

CREATE TABLE dbo.Sede
(
    Codigo_sede char(3) NOT NULL,
    Ubicacion varchar(50) NOT NULL,
    Nombre_sede varchar(50) NOT NULL,
    CONSTRAINT pk_sede_central PRIMARY KEY (Codigo_sede)
);

CREATE TABLE dbo.Empleado
(
    Codigo_empleado char(3) NOT NULL,
    Cedula_empleado char(10) NOT NULL,
    Nombre_empleado varchar(50) NOT NULL,
    Celular_empleado char(10) NOT NULL,
    Correo_empleado varchar(100) NOT NULL,
    Cargo varchar(50) NOT NULL,
    Codigo_sede char(3) NOT NULL,
    CONSTRAINT pk_empleado_central PRIMARY KEY (Codigo_empleado),
    CONSTRAINT fk_empleado_sede_central FOREIGN KEY (Codigo_sede)
        REFERENCES dbo.Sede(Codigo_sede)
);

CREATE TABLE dbo.Cliente
(
    Cedula_cliente char(10) NOT NULL,
    Nombre_Cliente varchar(50) NOT NULL,
    Celular_Cliente char(10) NOT NULL,
    Correo_Cliente varchar(100) NOT NULL,
    CONSTRAINT pk_cliente_central PRIMARY KEY (Cedula_cliente)
);

CREATE TABLE dbo.Servicio
(
    Codigo_servicio char(3) NOT NULL,
    Tipo_servicio varchar(50) NOT NULL,
    Costo_base numeric(7,2) NOT NULL,
    Descripcion varchar(100) NOT NULL,
    Codigo_sede char(3) NOT NULL,
    CONSTRAINT pk_servicio_central PRIMARY KEY (Codigo_servicio),
    CONSTRAINT fk_servicio_sede_central FOREIGN KEY (Codigo_sede)
        REFERENCES dbo.Sede(Codigo_sede)
);

CREATE TABLE dbo.Mascota
(
    Id_mascota char(3) NOT NULL,
    Nombre_mascota varchar(50) NOT NULL,
    Fecha_nacimiento date NOT NULL,
    Especie varchar(30) NOT NULL,
    Raza varchar(50) NOT NULL,
    Cedula_cliente char(10) NOT NULL,
    CONSTRAINT pk_mascota_central PRIMARY KEY (Id_mascota),
    CONSTRAINT fk_mascota_cliente_central FOREIGN KEY (Cedula_cliente)
        REFERENCES dbo.Cliente(Cedula_cliente)
);

CREATE TABLE dbo.Historial
(
    Id_historial char(3) NOT NULL,
    Id_mascota char(3) NOT NULL,
    Codigo_servicio char(3) NOT NULL,
    Codigo_empleado char(3) NOT NULL,
    Fecha_atencion date NOT NULL,
    Pago numeric(7,2) NOT NULL,
    CONSTRAINT pk_historial_central PRIMARY KEY (Id_historial),
    CONSTRAINT fk_historial_mascota_central FOREIGN KEY (Id_mascota)
        REFERENCES dbo.Mascota(Id_mascota),
    CONSTRAINT fk_historial_servicio_central FOREIGN KEY (Codigo_servicio)
        REFERENCES dbo.Servicio(Codigo_servicio),
    CONSTRAINT fk_historial_empleado_central FOREIGN KEY (Codigo_empleado)
        REFERENCES dbo.Empleado(Codigo_empleado)
);
GO

INSERT INTO dbo.Sede VALUES
('001','Cumbaya','PetLovers Cumbaya'),
('002','Inaquito','PetLovers Inaquito');

INSERT INTO dbo.Empleado VALUES
('E01','1711111111','Ana Torres','0991111111','ana.torres@petlovers.ec','Veterinaria general','001'),
('E02','1722222222','Carlos Mena','0992222222','carlos.mena@petlovers.ec','Estilista canino','001'),
('E03','1733333333','Lucia Paz','0993333333','lucia.paz@petlovers.ec','Auxiliar veterinaria','001'),
('E04','1744444444','Miguel Leon','0994444444','miguel.leon@petlovers.ec','Cirujano veterinario','002'),
('E05','1755555555','Sofia Ruiz','0995555555','sofia.ruiz@petlovers.ec','Traumatologa veterinaria','002'),
('E06','1766666666','Diego Mora','0996666666','diego.mora@petlovers.ec','Administrador','002');

INSERT INTO dbo.Cliente VALUES
('1712345678','Juan Perez','0981111111','juan.perez@email.com'),
('1723456789','Maria Lopez','0982222222','maria.lopez@email.com'),
('1734567890','Pedro Gomez','0983333333','pedro.gomez@email.com'),
('1745678901','Carla Vega','0984444444','carla.vega@email.com'),
('1756789012','Andres Luna','0985555555','andres.luna@email.com'),
('1767890123','Diana Castro','0986666666','diana.castro@email.com');

INSERT INTO dbo.Servicio VALUES
('S01','Consulta general',35.00,'Consulta veterinaria de rutina','001'),
('S02','Vacunacion',25.00,'Aplicacion de vacunas','001'),
('S03','Bano',20.00,'Bano y limpieza de mascota','001'),
('S04','Peluqueria',30.00,'Corte y arreglo estetico','001'),
('S05','Traumatologia',60.00,'Evaluacion traumatologica especializada','002'),
('S06','Cirugia',250.00,'Procedimiento quirurgico veterinario','002'),
('S07','Radiografia',50.00,'Estudio radiografico','002'),
('S08','Hospitalizacion',80.00,'Hospitalizacion y monitoreo diario','002');

INSERT INTO dbo.Mascota VALUES
('M01','Max','20210315','Perro','Labrador','1712345678'),
('M02','Luna','20220710','Gato','Siames','1723456789'),
('M03','Rocky','20201105','Perro','Pastor aleman','1734567890'),
('M04','Mia','20230120','Gato','Persa','1745678901'),
('M05','Toby','20190812','Perro','Beagle','1756789012'),
('M06','Nala','20210630','Gato','Mestizo','1767890123'),
('M07','Bruno','20220214','Perro','Pug','1712345678'),
('M08','Kira','20200925','Perro','Husky','1723456789');

INSERT INTO dbo.Historial VALUES
('H01','M01','S01','E01','20260502',35.00),
('H02','M02','S02','E01','20260504',25.00),
('H03','M03','S03','E02','20260506',20.00),
('H04','M04','S04','E02','20260508',30.00),
('H05','M05','S01','E03','20260510',35.00),
('H06','M01','S05','E05','20260512',60.00),
('H07','M03','S06','E04','20260515',250.00),
('H08','M06','S07','E05','20260518',50.00),
('H09','M07','S08','E04','20260520',80.00),
('H10','M08','S05','E05','20260522',60.00);
GO

SELECT 'Sede' AS Entidad, COUNT(*) AS Cantidad FROM dbo.Sede
UNION ALL SELECT 'Empleado', COUNT(*) FROM dbo.Empleado
UNION ALL SELECT 'Cliente', COUNT(*) FROM dbo.Cliente
UNION ALL SELECT 'Servicio', COUNT(*) FROM dbo.Servicio
UNION ALL SELECT 'Mascota', COUNT(*) FROM dbo.Mascota
UNION ALL SELECT 'Historial', COUNT(*) FROM dbo.Historial;
GO
