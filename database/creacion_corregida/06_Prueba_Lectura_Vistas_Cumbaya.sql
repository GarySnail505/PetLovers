/*--------------------- PRUEBA DE LECTURA DE LAS VPA ------------------*/

/* Ejecutar exclusivamente conectado al nodo de Cumbaya.

Servidor local: WIN-LO84K82LN7M
Base local: PetLoversCumbaya
Servidor vinculado de Inaquito: DESKTOP-Q40JF1K

Esta prueba no modifica ningun dato. */

use PetLoversCumbaya
go


-- 1) Confirmar que las cuatro vistas existen

select name,type_desc
from sys.views
where name in
(
    'V_Empleado_Op',
    'V_Servicio',
    'V_Historial_Clinico',
    'V_Historial_Pago'
)
order by name
go


-- 2) Consultar la reconstruccion completa

select * from V_Empleado_Op
order by Codigo_sede,Codigo_empleado

select * from V_Servicio
order by Codigo_sede,Codigo_servicio

select * from V_Historial_Clinico
order by Codigo_sede,Id_historial

select * from V_Historial_Pago
order by Codigo_sede,Id_historial
go


-- 3) Contar los registros recuperados de cada fragmento

select Codigo_sede,count(*) as Cantidad_empleados
from V_Empleado_Op
group by Codigo_sede
order by Codigo_sede

select Codigo_sede,count(*) as Cantidad_servicios
from V_Servicio
group by Codigo_sede
order by Codigo_sede

select Codigo_sede,count(*) as Cantidad_historiales_clinicos
from V_Historial_Clinico
group by Codigo_sede
order by Codigo_sede

select Codigo_sede,count(*) as Cantidad_historiales_pago
from V_Historial_Pago
group by Codigo_sede
order by Codigo_sede
go


-- 4) Confirmar que los datos se encuentran en el fragmento correcto
-- Todas las consultas siguientes deben devolver cero filas.

select * from PetLoversCumbaya.dbo.Empleado_Op001
where Codigo_sede <> '001'

select * from [DESKTOP-Q40JF1K].PetLoversInaquito.dbo.Empleado_Op002
where Codigo_sede <> '002'

select * from PetLoversCumbaya.dbo.Servicio001
where Codigo_sede <> '001'

select * from [DESKTOP-Q40JF1K].PetLoversInaquito.dbo.Servicio002
where Codigo_sede <> '002'

select * from PetLoversCumbaya.dbo.Historial_Clinico001
where Codigo_sede <> '001'

select * from [DESKTOP-Q40JF1K].PetLoversInaquito.dbo.Historial_Clinico002
where Codigo_sede <> '002'

select * from PetLoversCumbaya.dbo.Historial_Pago001
where Codigo_sede <> '001'

select * from [DESKTOP-Q40JF1K].PetLoversInaquito.dbo.Historial_Pago002
where Codigo_sede <> '002'
go


-- 5) Buscar claves duplicadas dentro de la reconstruccion
-- Todas las consultas siguientes deben devolver cero filas.

select Codigo_empleado,Codigo_sede,count(*) as Repeticiones
from V_Empleado_Op
group by Codigo_empleado,Codigo_sede
having count(*) > 1

select Codigo_servicio,Codigo_sede,count(*) as Repeticiones
from V_Servicio
group by Codigo_servicio,Codigo_sede
having count(*) > 1

select Id_historial,Codigo_sede,count(*) as Repeticiones
from V_Historial_Clinico
group by Id_historial,Codigo_sede
having count(*) > 1

select Id_historial,Codigo_sede,count(*) as Repeticiones
from V_Historial_Pago
group by Id_historial,Codigo_sede
having count(*) > 1
go
