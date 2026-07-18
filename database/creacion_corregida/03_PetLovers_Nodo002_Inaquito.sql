/*--------------------- INAQUITO ------------------*/

-- Esquema de replicacion.
/* Las tablas Sede, Cliente y Mascota se crean en el nodo
Inaquito porque este nodo sera el publicador de la replicacion. */

/*--------------------------------------------*/

create database PetLoversInaquito COLLATE Modern_Spanish_CI_AS
go
use PetLoversInaquito
go

create table Sede
(
Codigo_sede char(3) not null,
Ubicacion varchar(50) not null,
Nombre_sede varchar(50) not null
)

create table Cliente
(
Cedula_cliente char(10) not null,
Nombre_Cliente varchar(50) not null,
Celular_Cliente char(10) not null,
Correo_Cliente varchar(100) not null
)

create table Mascota
(
Id_mascota char(3) not null,
Nombre_mascota varchar(50) not null,
Fecha_nacimiento date not null,
Especie varchar(30) not null,
Raza varchar(50) not null,
Cedula_cliente char(10) not null
)

/*--------------------------------------------*/
/* Creacion de las tablas de Empleado - Fragmentacion mixta y vertical */
/*--------------------------------------------*/

create table Empleado_Op002
(
Codigo_empleado char(3) not null,
Nombre_empleado varchar(50) not null,
Cargo varchar(50) not null,
Codigo_sede char(3) not null
)

create table Empleado_Contacto
(
Codigo_empleado char(3) not null,
Cedula_empleado char(10) not null,
Celular_empleado char(10) not null,
Correo_empleado varchar(100) not null
)

/*--------------------------------------------*/
-- FRAGMENTACION HORIZONTAL PRIMARIA
-- Anadir el campo de fragmentacion
-- A la PK de la tabla
/*--------------------------------------------*/

create table Servicio002
(
Codigo_servicio char(3) not null,
Tipo_servicio varchar(50) not null,
Costo_base numeric(7,2) not null,
Descripcion varchar(100) not null,
Codigo_sede char(3) not null
)

/*--------------------------------------------*/
-- FRAGMENTACION HORIZONTAL DERIVADA Y MIXTA
-- Anadimos el campo de fragmentacion
-- a las tablas y se anade ese campo
-- a la PK de las tablas
/*--------------------------------------------*/

create table Historial_Clinico002
(
Id_historial char(3) not null,
Id_mascota char(3) not null,
Codigo_servicio char(3) not null,
Codigo_empleado char(3) not null,
Codigo_sede char(3) not null, -- esto es anadido
Fecha_atencion date not null
)

create table Historial_Pago002
(
Id_historial char(3) not null,
Codigo_sede char(3) not null, -- esto es anadido
Pago numeric(7,2) not null
)

/*--------------------------------------------*/
-- Creacion de PKs
/*--------------------------------------------*/

-- Sede
alter table Sede add constraint
pk_codigo_sede002 primary key (Codigo_sede)

-- Cliente
alter table Cliente add constraint
pk_cedula_cliente002 primary key (Cedula_cliente)

-- Mascota
alter table Mascota add constraint
pk_id_mascota002 primary key (Id_mascota)

alter table Mascota add constraint
fk_cedula_cliente002 foreign key (Cedula_cliente)
references Cliente(Cedula_cliente)

-- Empleado operativo Inaquito
alter table Empleado_Op002 add constraint
pk_codigo_empleado_sede002 primary key (Codigo_empleado,Codigo_sede)

alter table Empleado_Op002 add constraint
fk_codigo_sede_empleado002 foreign key (Codigo_sede)
references Sede(Codigo_sede)

-- Empleado contacto
alter table Empleado_Contacto add constraint
pk_codigo_empleado_contacto002 primary key (Codigo_empleado)

/* Empleado_Contacto conserva los contactos de todos los empleados.
No se crea una FK hacia Empleado_Op002 porque esa tabla contiene
unicamente los empleados operativos de la sede 002. */

-- Servicio Inaquito
alter table Servicio002 add constraint
pk_codigo_servicio_sede002 primary key (Codigo_servicio,Codigo_sede)

alter table Servicio002 add constraint
fk_codigo_sede_servicio002 foreign key (Codigo_sede)
references Sede(Codigo_sede)

-- Historial clinico Inaquito -- Fragm. horiz. derivada y vertical
alter table Historial_Clinico002 add constraint
pk_id_historial_sede_clinico002 primary key (Id_historial,Codigo_sede)

alter table Historial_Clinico002 add constraint
fk_id_mascota_historial002 foreign key (Id_mascota)
references Mascota(Id_mascota)

alter table Historial_Clinico002 add constraint
fk_codigo_servicio_sede002 foreign key (Codigo_servicio,Codigo_sede)
references Servicio002(Codigo_servicio,Codigo_sede)

alter table Historial_Clinico002 add constraint
fk_codigo_empleado_sede_historial002 foreign key (Codigo_empleado,Codigo_sede)
references Empleado_Op002(Codigo_empleado,Codigo_sede)

-- Historial pago Inaquito -- Fragm. vertical
alter table Historial_Pago002 add constraint
pk_id_historial_sede_pago002 primary key (Id_historial,Codigo_sede)

alter table Historial_Pago002 add constraint
fk_historial_clinico_pago002 foreign key (Id_historial,Codigo_sede)
references Historial_Clinico002(Id_historial,Codigo_sede)

/*--------------------------------------------*/
-- Restricciones de fragmentacion
/*--------------------------------------------*/

alter table Empleado_Op002 add constraint
c_empleado_op002 check (Codigo_sede='002')

alter table Servicio002 add constraint
c_servicio002 check (Codigo_sede='002')

alter table Historial_Clinico002 add constraint
c_historial_clinico002 check (Codigo_sede='002')

alter table Historial_Pago002 add constraint
c_historial_pago002 check (Codigo_sede='002')


/*--------------------------------------------*/
------ RECUPERAR DATOS DE INAQUITO --------
/*--------------------------------------------*/

-- tabla Sede
insert into PetLoversInaquito.dbo.Sede
select * from PetLoversCentral.dbo.Sede

select * from Sede

-- tabla Cliente
insert into PetLoversInaquito.dbo.Cliente
select * from PetLoversCentral.dbo.Cliente

select * from Cliente

-- tabla Mascota
insert into PetLoversInaquito.dbo.Mascota
select * from PetLoversCentral.dbo.Mascota

select * from Mascota

-- tabla Empleado_Op002
insert into PetLoversInaquito.dbo.Empleado_Op002
select Codigo_empleado,Nombre_empleado,Cargo,Codigo_sede
from PetLoversCentral.dbo.Empleado
where Codigo_sede='002'

select * from Empleado_Op002

-- tabla Empleado_Contacto
insert into PetLoversInaquito.dbo.Empleado_Contacto
select Codigo_empleado,Cedula_empleado,Celular_empleado,Correo_empleado
from PetLoversCentral.dbo.Empleado

select * from Empleado_Contacto

-- tabla Servicio002
insert into PetLoversInaquito.dbo.Servicio002
select *
from PetLoversCentral.dbo.Servicio
where Codigo_sede='002'

select * from Servicio002

-- tabla Historial_Clinico002
insert into PetLoversInaquito.dbo.Historial_Clinico002
select Id_historial,Id_mascota,Codigo_servicio,Codigo_empleado,'002',Fecha_atencion
from PetLoversCentral.dbo.Historial hcentral
where
(select Codigo_sede
from PetLoversCentral.dbo.Servicio scentral
where hcentral.Codigo_servicio=scentral.Codigo_servicio)='002'

select * from Historial_Clinico002

-- tabla Historial_Pago002
insert into PetLoversInaquito.dbo.Historial_Pago002
select Id_historial,'002',Pago
from PetLoversCentral.dbo.Historial hcentral
where
(select Codigo_sede
from PetLoversCentral.dbo.Servicio scentral
where hcentral.Codigo_servicio=scentral.Codigo_servicio)='002'

select * from Historial_Pago002


/*--------------------------------------------*/
--- LISTO TODOS LOS REGISTROS
/*--------------------------------------------*/

select * from Sede
select * from Cliente
select * from Mascota
select * from Empleado_Op002
select * from Empleado_Contacto
select * from Servicio002
select * from Historial_Clinico002
select * from Historial_Pago002
