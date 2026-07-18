/*--------------------- VISTAS PARTICIONADAS ------------------*/

/* IMPORTANTE:
El script se ejecuta por bloques en el nodo indicado.
El servidor vinculado desde Inaquito hacia Cumbaya se encuentra
configurado con el nombre [WIN-LO84K82LN7M]. */


/*--------------------- CUMBAYA ------------------*/

use PetLoversCumbaya
go

---- Empleado_Op001
-- 1) Confirmar que el campo de fragmentacion forma parte de la pk

exec sp_help N'dbo.Empleado_Op001'


-- 2) Incluir Codigo_sede en la pk de Empleado_Op001

if exists
(
    select 1 from Empleado_Op001
    where Codigo_sede <> '001'
)
begin
    select * from Empleado_Op001
    where Codigo_sede <> '001'

    raiserror('Empleado_Op001 contiene empleados que no pertenecen a la sede 001. Corregirlos antes de continuar.',16,1)
end
else
begin
    if exists (select 1 from sys.foreign_keys where name='fk_codigo_empleado_historial001')
        alter table Historial_Clinico001
        drop constraint fk_codigo_empleado_historial001

    if exists (select 1 from sys.foreign_keys where name='fk_codigo_empleado_sede_historial001')
        alter table Historial_Clinico001
        drop constraint fk_codigo_empleado_sede_historial001

    if exists (select 1 from sys.key_constraints where name='pk_codigo_empleado001')
        alter table Empleado_Op001
        drop constraint pk_codigo_empleado001

    if exists (select 1 from sys.key_constraints where name='pk_codigo_empleado_sede001')
        alter table Empleado_Op001
        drop constraint pk_codigo_empleado_sede001

    alter table Empleado_Op001 add constraint
    pk_codigo_empleado_sede001 primary key (Codigo_empleado,Codigo_sede)

    alter table Historial_Clinico001 add constraint
    fk_codigo_empleado_sede_historial001
    foreign key (Codigo_empleado,Codigo_sede)
    references Empleado_Op001(Codigo_empleado,Codigo_sede)
end
go


-- 3) Definir las restricciones CHECK del fragmento 001

if not exists (select 1 from sys.check_constraints where name='c_empleado_op001')
and not exists (select 1 from Empleado_Op001 where Codigo_sede <> '001')
    alter table Empleado_Op001 with check
    add constraint c_empleado_op001 check (Codigo_sede = '001')
go

if not exists (select 1 from sys.check_constraints where name='c_servicio001')
    alter table Servicio001 with check
    add constraint c_servicio001 check (Codigo_sede = '001')
go

if not exists (select 1 from sys.check_constraints where name='c_historial_clinico001')
    alter table Historial_Clinico001 with check
    add constraint c_historial_clinico001 check (Codigo_sede = '001')
go

if not exists (select 1 from sys.check_constraints where name='c_historial_pago001')
    alter table Historial_Pago001 with check
    add constraint c_historial_pago001 check (Codigo_sede = '001')
go

if exists (select 1 from sys.check_constraints where name='c_empleado_op001')
    alter table Empleado_Op001 with check check constraint c_empleado_op001

if exists (select 1 from sys.check_constraints where name='c_servicio001')
    alter table Servicio001 with check check constraint c_servicio001

if exists (select 1 from sys.check_constraints where name='c_historial_clinico001')
    alter table Historial_Clinico001 with check check constraint c_historial_clinico001

if exists (select 1 from sys.check_constraints where name='c_historial_pago001')
    alter table Historial_Pago001 with check check constraint c_historial_pago001
go


-- verificar

exec sp_help N'dbo.Empleado_Op001'
exec sp_help N'dbo.Servicio001'
exec sp_help N'dbo.Historial_Clinico001'
exec sp_help N'dbo.Historial_Pago001'

select * from Empleado_Op001
select * from Servicio001
select * from Historial_Clinico001
select * from Historial_Pago001


/*--------------------- INAQUITO ------------------*/

use PetLoversInaquito
go

---- Empleado_Op002
-- 1) Confirmar que el campo de fragmentacion forma parte de la pk

exec sp_help N'dbo.Empleado_Op002'


-- 2) Incluir Codigo_sede en la pk de Empleado_Op002

/* Empleado_Contacto contiene contactos de las dos sedes, por eso
no debe tener una fk hacia el fragmento local Empleado_Op002. */

if exists (select 1 from sys.foreign_keys where name='fk_codigo_empleado_contacto002')
    alter table Empleado_Contacto
    drop constraint fk_codigo_empleado_contacto002
go

if exists
(
    select 1 from Empleado_Op002
    where Codigo_sede <> '002'
)
begin
    select * from Empleado_Op002
    where Codigo_sede <> '002'

    raiserror('Empleado_Op002 contiene empleados que no pertenecen a la sede 002. Moverlos a Cumbaya antes de continuar.',16,1)
end
else
begin
    if exists (select 1 from sys.foreign_keys where name='fk_codigo_empleado_historial002')
        alter table Historial_Clinico002
        drop constraint fk_codigo_empleado_historial002

    if exists (select 1 from sys.foreign_keys where name='fk_codigo_empleado_sede_historial002')
        alter table Historial_Clinico002
        drop constraint fk_codigo_empleado_sede_historial002

    if exists (select 1 from sys.key_constraints where name='pk_codigo_empleado002')
        alter table Empleado_Op002
        drop constraint pk_codigo_empleado002

    if exists (select 1 from sys.key_constraints where name='pk_codigo_empleado_sede002')
        alter table Empleado_Op002
        drop constraint pk_codigo_empleado_sede002

    alter table Empleado_Op002 add constraint
    pk_codigo_empleado_sede002 primary key (Codigo_empleado,Codigo_sede)

    alter table Historial_Clinico002 add constraint
    fk_codigo_empleado_sede_historial002
    foreign key (Codigo_empleado,Codigo_sede)
    references Empleado_Op002(Codigo_empleado,Codigo_sede)
end
go


-- 3) Definir las restricciones CHECK del fragmento 002

if not exists (select 1 from sys.check_constraints where name='c_empleado_op002')
and not exists (select 1 from Empleado_Op002 where Codigo_sede <> '002')
    alter table Empleado_Op002 with check
    add constraint c_empleado_op002 check (Codigo_sede = '002')
go

if not exists (select 1 from sys.check_constraints where name='c_servicio002')
    alter table Servicio002 with check
    add constraint c_servicio002 check (Codigo_sede = '002')
go

if not exists (select 1 from sys.check_constraints where name='c_historial_clinico002')
    alter table Historial_Clinico002 with check
    add constraint c_historial_clinico002 check (Codigo_sede = '002')
go

if not exists (select 1 from sys.check_constraints where name='c_historial_pago002')
    alter table Historial_Pago002 with check
    add constraint c_historial_pago002 check (Codigo_sede = '002')
go

if exists (select 1 from sys.check_constraints where name='c_empleado_op002')
    alter table Empleado_Op002 with check check constraint c_empleado_op002

if exists (select 1 from sys.check_constraints where name='c_servicio002')
    alter table Servicio002 with check check constraint c_servicio002

if exists (select 1 from sys.check_constraints where name='c_historial_clinico002')
    alter table Historial_Clinico002 with check check constraint c_historial_clinico002

if exists (select 1 from sys.check_constraints where name='c_historial_pago002')
    alter table Historial_Pago002 with check check constraint c_historial_pago002
go


-- verificar

exec sp_help N'dbo.Empleado_Op002'
exec sp_help N'dbo.Servicio002'
exec sp_help N'dbo.Historial_Clinico002'
exec sp_help N'dbo.Historial_Pago002'

select * from Empleado_Op002
select * from Servicio002
select * from Historial_Clinico002
select * from Historial_Pago002


/*--------------------- CREAR LAS VPA ------------------*/

/* Este bloque se ejecuta en Inaquito.
Abrir una conexion nueva a DESKTOP-Q40JF1K antes de ejecutarlo.
No ejecutar este bloque conectado al servidor de Cumbaya.
Las opciones SET se ejecutan una vez en la sesion antes de crear
y utilizar las vistas particionadas. */

---- Habilitar la lectura del servidor vinculado de Cumbaya

use master
go

exec sp_serveroption
@server='WIN-LO84K82LN7M',
@optname='data access',
@optvalue='true'
go

-- verificar que DATA ACCESS se encuentre habilitado

select name,is_linked,is_data_access_enabled
from sys.servers
where name='WIN-LO84K82LN7M'
go

-- verificar la lectura de la tabla remota antes de crear las vistas

select *
from [WIN-LO84K82LN7M].PetLoversCumbaya.dbo.Empleado_Op001
go

use PetLoversInaquito
go

set ansi_nulls on
set ansi_padding on
set ansi_warnings on
set arithabort on
set concat_null_yields_null on
set quoted_identifier on
set numeric_roundabort off
go


---- VPA de Empleado_Op

if object_id('V_Empleado_Op','V') is not null
drop view V_Empleado_Op
go

create view V_Empleado_Op
as
select Codigo_empleado,Nombre_empleado,Cargo,Codigo_sede
from [WIN-LO84K82LN7M].PetLoversCumbaya.dbo.Empleado_Op001
union all
select Codigo_empleado,Nombre_empleado,Cargo,Codigo_sede
from PetLoversInaquito.dbo.Empleado_Op002
go

select * from V_Empleado_Op


---- VPA de Servicio - Fragmentacion horizontal primaria

if object_id('V_Servicio','V') is not null
drop view V_Servicio
go

create view V_Servicio
as
select Codigo_servicio,Tipo_servicio,Costo_base,Descripcion,Codigo_sede
from [WIN-LO84K82LN7M].PetLoversCumbaya.dbo.Servicio001
union all
select Codigo_servicio,Tipo_servicio,Costo_base,Descripcion,Codigo_sede
from PetLoversInaquito.dbo.Servicio002
go

select * from V_Servicio


---- VPA de Historial_Clinico - Fragmentacion horizontal derivada

if object_id('V_Historial_Clinico','V') is not null
drop view V_Historial_Clinico
go

create view V_Historial_Clinico
as
select Id_historial,Id_mascota,Codigo_servicio,Codigo_empleado,Codigo_sede,Fecha_atencion
from [WIN-LO84K82LN7M].PetLoversCumbaya.dbo.Historial_Clinico001
union all
select Id_historial,Id_mascota,Codigo_servicio,Codigo_empleado,Codigo_sede,Fecha_atencion
from PetLoversInaquito.dbo.Historial_Clinico002
go

select * from V_Historial_Clinico


---- VPA de Historial_Pago - Fragmentacion horizontal derivada

if object_id('V_Historial_Pago','V') is not null
drop view V_Historial_Pago
go

create view V_Historial_Pago
as
select Id_historial,Codigo_sede,Pago
from [WIN-LO84K82LN7M].PetLoversCumbaya.dbo.Historial_Pago001
union all
select Id_historial,Codigo_sede,Pago
from PetLoversInaquito.dbo.Historial_Pago002
go

select * from V_Historial_Pago


/*--------------------- EJEMPLO CRUD ------------------*/

/* Ejecutar este bloque despues de activar y configurar DTC
en los dos nodos. Las sentencias quedan comentadas para no
modificar los datos durante la creacion de las vistas. */

/*
-- la siguiente linea se ejecuta una sola vez por sesion
set XACT_ABORT on

-- INSERCION
-- Codigo_sede='001' hace que la fila se inserte en Cumbaya

begin distributed transaction
insert into V_Empleado_Op
values ('099','Empleado de prueba','Auxiliar','001')
commit transaction


-- ACTUALIZACION

begin distributed transaction
update V_Empleado_Op
set Cargo='Asistente'
where Codigo_empleado='099' and Codigo_sede='001'
commit transaction


-- ELIMINACION

begin distributed transaction
delete from V_Empleado_Op
where Codigo_empleado='099' and Codigo_sede='001'
commit transaction
*/
