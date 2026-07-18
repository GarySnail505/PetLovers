/*--------------------- CUMBAYA ------------------*/

-- Esquema de replicacion.
/* Las tablas Sede, Cliente y Mascota NO se crean en este script.
Cumbaya es el suscriptor y estas tablas deben existir por la
replicacion realizada desde el nodo de Inaquito. */

/*--------------------------------------------*/

/* La base PetLoversCumbaya debe crearse como base de suscripcion
durante la configuracion de la replicacion. */
use PetLoversCumbaya
go

/* IMPORTANTE:
Antes de continuar, configurar la suscripcion desde Inaquito y comprobar
que las tablas Sede, Cliente y Mascota ya se encuentren en Cumbaya. */

select * from Sede
select * from Cliente
select * from Mascota

/*--------------------------------------------*/
/* Creacion de la tabla Empleado_Op001 - Fragmentacion mixta */
/*--------------------------------------------*/

create table Empleado_Op001
(
Codigo_empleado char(3) not null,
Nombre_empleado varchar(50) not null,
Cargo varchar(50) not null,
Codigo_sede char(3) not null
)

/*--------------------------------------------*/
-- FRAGMENTACION HORIZONTAL PRIMARIA
-- Anadir el campo de fragmentacion
-- A la PK de la tabla
/*--------------------------------------------*/

create table Servicio001
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

create table Historial_Clinico001
(
Id_historial char(3) not null,
Id_mascota char(3) not null,
Codigo_servicio char(3) not null,
Codigo_empleado char(3) not null,
Codigo_sede char(3) not null, -- esto es anadido
Fecha_atencion date not null
)

create table Historial_Pago001
(
Id_historial char(3) not null,
Codigo_sede char(3) not null, -- esto es anadido
Pago numeric(7,2) not null
)

/*--------------------------------------------*/
-- Creacion de PKs
/*--------------------------------------------*/

-- Sede, Cliente y Mascota conservan las claves creadas por la replicacion.

-- Empleado operativo Cumbaya
alter table Empleado_Op001 add constraint
pk_codigo_empleado_sede001 primary key (Codigo_empleado,Codigo_sede)

alter table Empleado_Op001 add constraint
fk_codigo_sede_empleado001 foreign key (Codigo_sede)
references Sede(Codigo_sede)

-- Servicio Cumbaya
alter table Servicio001 add constraint
pk_codigo_servicio_sede001 primary key (Codigo_servicio,Codigo_sede)

alter table Servicio001 add constraint
fk_codigo_sede_servicio001 foreign key (Codigo_sede)
references Sede(Codigo_sede)

-- Historial clinico Cumbaya -- Fragm. horiz. derivada y vertical
alter table Historial_Clinico001 add constraint
pk_id_historial_sede_clinico001 primary key (Id_historial,Codigo_sede)

alter table Historial_Clinico001 add constraint
fk_id_mascota_historial001 foreign key (Id_mascota)
references Mascota(Id_mascota)

alter table Historial_Clinico001 add constraint
fk_codigo_servicio_sede001 foreign key (Codigo_servicio,Codigo_sede)
references Servicio001(Codigo_servicio,Codigo_sede)

alter table Historial_Clinico001 add constraint
fk_codigo_empleado_sede_historial001 foreign key (Codigo_empleado,Codigo_sede)
references Empleado_Op001(Codigo_empleado,Codigo_sede)

-- Historial pago Cumbaya -- Fragm. vertical
alter table Historial_Pago001 add constraint
pk_id_historial_sede_pago001 primary key (Id_historial,Codigo_sede)

alter table Historial_Pago001 add constraint
fk_historial_clinico_pago001 foreign key (Id_historial,Codigo_sede)
references Historial_Clinico001(Id_historial,Codigo_sede)

/*--------------------------------------------*/
-- Restricciones de fragmentacion
/*--------------------------------------------*/

alter table Empleado_Op001 add constraint
c_empleado_op001 check (Codigo_sede='001')

alter table Servicio001 add constraint
c_servicio001 check (Codigo_sede='001')

alter table Historial_Clinico001 add constraint
c_historial_clinico001 check (Codigo_sede='001')

alter table Historial_Pago001 add constraint
c_historial_pago001 check (Codigo_sede='001')


/*--------------------------------------------*/
------ RECUPERAR DATOS DE CUMBAYA --------
/*--------------------------------------------*/

/* IMPORTANTE:
NODO_INAQUITO es el nombre del servidor vinculado configurado
hacia el equipo donde se encuentra PetLoversCentral. */

-- Sede, Cliente y Mascota no se insertan manualmente.
-- Sus datos llegan a Cumbaya mediante la replicacion.

-- tabla Empleado_Op001
insert into PetLoversCumbaya.dbo.Empleado_Op001
select Codigo_empleado,Nombre_empleado,Cargo,Codigo_sede
from [NODO_INAQUITO].PetLoversCentral.dbo.Empleado
where Codigo_sede='001'

select * from Empleado_Op001

-- tabla Servicio001
insert into PetLoversCumbaya.dbo.Servicio001
select *
from [NODO_INAQUITO].PetLoversCentral.dbo.Servicio
where Codigo_sede='001'

select * from Servicio001

-- tabla Historial_Clinico001
insert into PetLoversCumbaya.dbo.Historial_Clinico001
select Id_historial,Id_mascota,Codigo_servicio,Codigo_empleado,'001',Fecha_atencion
from [NODO_INAQUITO].PetLoversCentral.dbo.Historial hcentral
where
(select Codigo_sede
from [NODO_INAQUITO].PetLoversCentral.dbo.Servicio scentral
where hcentral.Codigo_servicio=scentral.Codigo_servicio)='001'

select * from Historial_Clinico001

-- tabla Historial_Pago001
insert into PetLoversCumbaya.dbo.Historial_Pago001
select Id_historial,'001',Pago
from [NODO_INAQUITO].PetLoversCentral.dbo.Historial hcentral
where
(select Codigo_sede
from [NODO_INAQUITO].PetLoversCentral.dbo.Servicio scentral
where hcentral.Codigo_servicio=scentral.Codigo_servicio)='001'

select * from Historial_Pago001


/*--------------------------------------------*/
--- LISTO TODOS LOS REGISTROS
/*--------------------------------------------*/

select * from Sede
select * from Cliente
select * from Mascota
select * from Empleado_Op001
select * from Servicio001
select * from Historial_Clinico001
select * from Historial_Pago001
