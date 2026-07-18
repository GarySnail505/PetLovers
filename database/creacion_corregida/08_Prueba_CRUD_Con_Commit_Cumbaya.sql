/*--------------------- PRUEBA CRUD CON COMMIT ------------------*/

/* Ejecutar exclusivamente conectado al nodo de Cumbaya.

Esta prueba SI modifica los datos de ambos nodos.
Ejecutar cada paso por separado para observar los cambios.

Z93 corresponde al fragmento 001 de Cumbaya.
Z94 corresponde al fragmento 002 de Inaquito. */

use PetLoversCumbaya
go

set ansi_nulls on
set ansi_padding on
set ansi_warnings on
set arithabort on
set concat_null_yields_null on
set quoted_identifier on
set numeric_roundabort off
set XACT_ABORT on
set lock_timeout 15000
go


/*--------------------- PASO 1 - VERIFICAR ------------------*/

-- Debe devolver cero filas antes de realizar la insercion.

select * from V_Empleado_Op
where Codigo_empleado in ('Z93','Z94')
go


/*--------------------- PASO 2 - CREATE / INSERT ------------------*/

begin distributed transaction

insert into V_Empleado_Op
(Codigo_empleado,Nombre_empleado,Cargo,Codigo_sede)
values ('Z93','Prueba CRUD Cumbaya','Auxiliar temporal','001')

insert into V_Empleado_Op
(Codigo_empleado,Nombre_empleado,Cargo,Codigo_sede)
values ('Z94','Prueba CRUD Inaquito','Auxiliar temporal','002')

commit transaction
go


/*--------------------- PASO 3 - READ / SELECT ------------------*/

-- La vista debe mostrar los dos empleados.

select * from V_Empleado_Op
where Codigo_empleado in ('Z93','Z94')
order by Codigo_sede,Codigo_empleado

-- Z93 debe aparecer solamente en la tabla local de Cumbaya.

select 'Cumbaya' as Nodo,*
from PetLoversCumbaya.dbo.Empleado_Op001
where Codigo_empleado in ('Z93','Z94')

-- Z94 debe aparecer solamente en la tabla remota de Inaquito.

select 'Inaquito' as Nodo,*
from [DESKTOP-Q40JF1K].PetLoversInaquito.dbo.Empleado_Op002
where Codigo_empleado in ('Z93','Z94')
go


/*--------------------- PASO 4 - UPDATE ------------------*/

begin distributed transaction

update V_Empleado_Op
set Cargo='Cargo actualizado mediante VPA'
where Codigo_empleado in ('Z93','Z94')

commit transaction
go


/*--------------------- PASO 5 - VERIFICAR UPDATE ------------------*/

select * from V_Empleado_Op
where Codigo_empleado in ('Z93','Z94')
order by Codigo_sede,Codigo_empleado
go


/*--------------------- PASO 6 - DELETE ------------------*/

/* Ejecutar este paso cuando se haya terminado de revisar
la insercion y la actualizacion. */

begin distributed transaction

delete from V_Empleado_Op
where Codigo_empleado in ('Z93','Z94')

commit transaction
go


/*--------------------- PASO 7 - VERIFICAR DELETE ------------------*/

-- Las tres consultas deben devolver cero filas.

select * from V_Empleado_Op
where Codigo_empleado in ('Z93','Z94')

select * from PetLoversCumbaya.dbo.Empleado_Op001
where Codigo_empleado in ('Z93','Z94')

select * from [DESKTOP-Q40JF1K].PetLoversInaquito.dbo.Empleado_Op002
where Codigo_empleado in ('Z93','Z94')
go
