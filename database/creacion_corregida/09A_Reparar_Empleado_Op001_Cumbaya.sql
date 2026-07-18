/*--------------------- REPARAR PK EN CUMBAYA ------------------*/

/* Ejecutar exclusivamente conectado al nodo de Cumbaya.
Este script corrige una base que ya fue creada con la PK antigua. */

use PetLoversCumbaya
go


-- 1) Confirmar que solo existan empleados de la sede 001

if exists
(
    select 1 from Empleado_Op001
    where Codigo_sede <> '001'
)
begin
    select * from Empleado_Op001
    where Codigo_sede <> '001'

    raiserror('Empleado_Op001 contiene empleados de otra sede. Corregirlos antes de cambiar la PK.',16,1)
    return
end


-- 2) Eliminar la FK que utiliza la PK antigua

if exists
(
    select 1 from sys.foreign_keys
    where name='fk_codigo_empleado_historial001'
)
    alter table Historial_Clinico001
    drop constraint fk_codigo_empleado_historial001

if exists
(
    select 1 from sys.foreign_keys
    where name='fk_codigo_empleado_sede_historial001'
)
    alter table Historial_Clinico001
    drop constraint fk_codigo_empleado_sede_historial001


-- 3) Reemplazar la PK antigua por la PK compuesta

if exists
(
    select 1 from sys.key_constraints
    where name='pk_codigo_empleado001'
)
    alter table Empleado_Op001
    drop constraint pk_codigo_empleado001

if exists
(
    select 1 from sys.key_constraints
    where name='pk_codigo_empleado_sede001'
)
    alter table Empleado_Op001
    drop constraint pk_codigo_empleado_sede001

alter table Empleado_Op001 add constraint
pk_codigo_empleado_sede001 primary key (Codigo_empleado,Codigo_sede)


-- 4) Crear nuevamente la FK con los dos atributos

alter table Historial_Clinico001 add constraint
fk_codigo_empleado_sede_historial001
foreign key (Codigo_empleado,Codigo_sede)
references Empleado_Op001(Codigo_empleado,Codigo_sede)


-- 5) Crear y validar la restriccion CHECK

if exists
(
    select 1 from sys.check_constraints
    where name='c_empleado_op001'
)
    alter table Empleado_Op001
    drop constraint c_empleado_op001

alter table Empleado_Op001 with check add constraint
c_empleado_op001 check (Codigo_sede='001')

alter table Empleado_Op001 with check
check constraint c_empleado_op001
go


-- 6) Verificar el resultado

exec sp_help N'dbo.Empleado_Op001'

select name,definition,is_disabled,is_not_trusted
from sys.check_constraints
where parent_object_id=object_id('dbo.Empleado_Op001')
go
