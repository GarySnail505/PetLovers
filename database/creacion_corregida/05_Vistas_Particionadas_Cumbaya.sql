/*--------------------- VISTAS PARTICIONADAS CUMBAYA ------------------*/

/* IMPORTANTE:
Este script se ejecuta exclusivamente conectado al nodo de Cumbaya.

Servidor local: WIN-LO84K82LN7M
Base local: PetLoversCumbaya
Servidor vinculado de Inaquito: DESKTOP-Q40JF1K

Antes de crear las vistas, las restricciones CHECK y las PK de los
fragmentos 001 y 002 deben estar creadas correctamente. */


/*--------------------- HABILITAR DATA ACCESS ------------------*/

use master
go

exec sp_serveroption
@server='DESKTOP-Q40JF1K',
@optname='data access',
@optvalue='true'
go

-- verificar

select name,is_linked,is_data_access_enabled
from sys.servers
where name='DESKTOP-Q40JF1K'
go


/*--------------------- VERIFICAR LOS FRAGMENTOS ------------------*/

use PetLoversCumbaya
go

-- el resultado debe ser cero filas

select * from Empleado_Op001
where Codigo_sede <> '001'

select * from Servicio001
where Codigo_sede <> '001'

select * from Historial_Clinico001
where Codigo_sede <> '001'

select * from Historial_Pago001
where Codigo_sede <> '001'
go

-- verificar la lectura del fragmento remoto de Inaquito

select *
from [DESKTOP-Q40JF1K].PetLoversInaquito.dbo.Empleado_Op002
go


/*--------------------- CREAR LAS VPA EN CUMBAYA ------------------*/

use PetLoversCumbaya
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

declare @sql_empleado nvarchar(max)

if object_id('V_Empleado_Op','V') is null
    set @sql_empleado='create view V_Empleado_Op as '
else
    set @sql_empleado='alter view V_Empleado_Op as '

set @sql_empleado=@sql_empleado+'
select Codigo_empleado,Nombre_empleado,Cargo,Codigo_sede
from PetLoversCumbaya.dbo.Empleado_Op001
union all
select Codigo_empleado,Nombre_empleado,Cargo,Codigo_sede
from [DESKTOP-Q40JF1K].PetLoversInaquito.dbo.Empleado_Op002'

exec sp_executesql @sql_empleado
go

select * from V_Empleado_Op


---- VPA de Servicio - Fragmentacion horizontal primaria

declare @sql_servicio nvarchar(max)

if object_id('V_Servicio','V') is null
    set @sql_servicio='create view V_Servicio as '
else
    set @sql_servicio='alter view V_Servicio as '

set @sql_servicio=@sql_servicio+'
select Codigo_servicio,Tipo_servicio,Costo_base,Descripcion,Codigo_sede
from PetLoversCumbaya.dbo.Servicio001
union all
select Codigo_servicio,Tipo_servicio,Costo_base,Descripcion,Codigo_sede
from [DESKTOP-Q40JF1K].PetLoversInaquito.dbo.Servicio002'

exec sp_executesql @sql_servicio
go

select * from V_Servicio


---- VPA de Historial_Clinico - Fragmentacion horizontal derivada

declare @sql_historial_clinico nvarchar(max)

if object_id('V_Historial_Clinico','V') is null
    set @sql_historial_clinico='create view V_Historial_Clinico as '
else
    set @sql_historial_clinico='alter view V_Historial_Clinico as '

set @sql_historial_clinico=@sql_historial_clinico+'
select Id_historial,Id_mascota,Codigo_servicio,Codigo_empleado,Codigo_sede,Fecha_atencion
from PetLoversCumbaya.dbo.Historial_Clinico001
union all
select Id_historial,Id_mascota,Codigo_servicio,Codigo_empleado,Codigo_sede,Fecha_atencion
from [DESKTOP-Q40JF1K].PetLoversInaquito.dbo.Historial_Clinico002'

exec sp_executesql @sql_historial_clinico
go

select * from V_Historial_Clinico


---- VPA de Historial_Pago - Fragmentacion horizontal derivada

declare @sql_historial_pago nvarchar(max)

if object_id('V_Historial_Pago','V') is null
    set @sql_historial_pago='create view V_Historial_Pago as '
else
    set @sql_historial_pago='alter view V_Historial_Pago as '

set @sql_historial_pago=@sql_historial_pago+'
select Id_historial,Codigo_sede,Pago
from PetLoversCumbaya.dbo.Historial_Pago001
union all
select Id_historial,Codigo_sede,Pago
from [DESKTOP-Q40JF1K].PetLoversInaquito.dbo.Historial_Pago002'

exec sp_executesql @sql_historial_pago
go

select * from V_Historial_Pago


/*--------------------- EJEMPLO CRUD ------------------*/

/* Ejecutar despues de activar y configurar DTC en los dos nodos. */

/*
-- la siguiente linea se ejecuta una sola vez por sesion
set XACT_ABORT on

begin distributed transaction
insert into V_Empleado_Op
values ('099','Empleado de prueba','Auxiliar','002')
commit transaction
*/
