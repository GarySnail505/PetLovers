/*--------------------- REPARAR PK EN INAQUITO ------------------*/

/* Ejecutar exclusivamente conectado al nodo de Inaquito.
Este script corrige una base que ya fue creada con la PK antigua. */

use PetLoversInaquito
go


-- 1) Empleado_Contacto contiene contactos de las dos sedes
-- y no debe referenciar solamente al fragmento Empleado_Op002.

if exists
(
    select 1 from sys.foreign_keys
    where name='fk_codigo_empleado_contacto002'
)
    alter table Empleado_Contacto
    drop constraint fk_codigo_empleado_contacto002


-- 2) Confirmar que solo existan empleados de la sede 002

if exists
(
    select 1 from Empleado_Op002
    where Codigo_sede <> '002'
)
begin
    select * from Empleado_Op002
    where Codigo_sede <> '002'

    raiserror('Empleado_Op002 contiene empleados de otra sede. Corregirlos antes de cambiar la PK.',16,1)
    return
end


-- 3) Eliminar la FK que utiliza la PK antigua

if exists
(
    select 1 from sys.foreign_keys
    where name='fk_codigo_empleado_historial002'
)
    alter table Historial_Clinico002
    drop constraint fk_codigo_empleado_historial002

if exists
(
    select 1 from sys.foreign_keys
    where name='fk_codigo_empleado_sede_historial002'
)
    alter table Historial_Clinico002
    drop constraint fk_codigo_empleado_sede_historial002


-- 4) Reemplazar la PK antigua por la PK compuesta

if exists
(
    select 1 from sys.key_constraints
    where name='pk_codigo_empleado002'
)
    alter table Empleado_Op002
    drop constraint pk_codigo_empleado002

if exists
(
    select 1 from sys.key_constraints
    where name='pk_codigo_empleado_sede002'
)
    alter table Empleado_Op002
    drop constraint pk_codigo_empleado_sede002

alter table Empleado_Op002 add constraint
pk_codigo_empleado_sede002 primary key (Codigo_empleado,Codigo_sede)


-- 5) Crear nuevamente la FK con los dos atributos

alter table Historial_Clinico002 add constraint
fk_codigo_empleado_sede_historial002
foreign key (Codigo_empleado,Codigo_sede)
references Empleado_Op002(Codigo_empleado,Codigo_sede)


-- 6) Crear y validar la restriccion CHECK

if exists
(
    select 1 from sys.check_constraints
    where name='c_empleado_op002'
)
    alter table Empleado_Op002
    drop constraint c_empleado_op002

alter table Empleado_Op002 with check add constraint
c_empleado_op002 check (Codigo_sede='002')

alter table Empleado_Op002 with check
check constraint c_empleado_op002
go


-- 7) Verificar el resultado

exec sp_help N'dbo.Empleado_Op002'

select name,definition,is_disabled,is_not_trusted
from sys.check_constraints
where parent_object_id=object_id('dbo.Empleado_Op002')
go
