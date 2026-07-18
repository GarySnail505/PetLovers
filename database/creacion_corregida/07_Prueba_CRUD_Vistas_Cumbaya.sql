/*--------------------- PRUEBA CRUD DE LAS VPA ------------------*/

/* Ejecutar exclusivamente conectado al nodo de Cumbaya.

La prueba utiliza los codigos Z91 y Z92 y termina con ROLLBACK.
Por tanto, no deja registros de prueba en ninguno de los nodos.

Antes de ejecutarla deben estar habilitados:
- DATA ACCESS para el servidor vinculado DESKTOP-Q40JF1K.
- DTC en Cumbaya e Inaquito.
- Las operaciones distribuidas a traves del firewall. */

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
go


-- 1) Confirmar que los codigos de prueba se encuentran disponibles

if exists
(
    select 1 from V_Empleado_Op where Codigo_empleado in ('Z91','Z92')
    union all
    select 1 from V_Servicio where Codigo_servicio in ('Z91','Z92')
    union all
    select 1 from V_Historial_Clinico where Id_historial in ('Z91','Z92')
    union all
    select 1 from V_Historial_Pago where Id_historial in ('Z91','Z92')
)
begin
    raiserror('Los codigos Z91 o Z92 ya existen. Cambiar los codigos antes de ejecutar la prueba.',16,1)
    return
end
go


-- 2) Ejecutar INSERT, SELECT, UPDATE y DELETE mediante las vistas

declare @Id_mascota char(3)

select top 1 @Id_mascota=c.Id_mascota
from PetLoversCumbaya.dbo.Mascota c
where exists
(
    select 1
    from [DESKTOP-Q40JF1K].PetLoversInaquito.dbo.Mascota i
    where i.Id_mascota=c.Id_mascota
)
order by c.Id_mascota

if @Id_mascota is null
begin
    raiserror('No existe una mascota comun en los dos nodos para realizar la prueba.',16,1)
    return
end

begin try

    begin distributed transaction

    ---- INSERCION

    -- empleado Z91 debe dirigirse a Cumbaya
    insert into V_Empleado_Op
    values ('Z91','Prueba Cumbaya','Auxiliar de prueba','001')

    -- empleado Z92 debe dirigirse a Inaquito
    insert into V_Empleado_Op
    values ('Z92','Prueba Inaquito','Auxiliar de prueba','002')

    insert into V_Servicio
    values ('Z91','Servicio prueba 001',10.00,'Prueba temporal Cumbaya','001')

    insert into V_Servicio
    values ('Z92','Servicio prueba 002',20.00,'Prueba temporal Inaquito','002')

    insert into V_Historial_Clinico
    values ('Z91',@Id_mascota,'Z91','Z91','001',getdate())

    insert into V_Historial_Clinico
    values ('Z92',@Id_mascota,'Z92','Z92','002',getdate())

    insert into V_Historial_Pago
    values ('Z91','001',10.00)

    insert into V_Historial_Pago
    values ('Z92','002',20.00)


    ---- VERIFICAR LA INSERCION Y EL ENRUTAMIENTO

    select * from V_Empleado_Op
    where Codigo_empleado in ('Z91','Z92')

    select 'Cumbaya' as Nodo,*
    from PetLoversCumbaya.dbo.Empleado_Op001
    where Codigo_empleado in ('Z91','Z92')

    select 'Inaquito' as Nodo,*
    from [DESKTOP-Q40JF1K].PetLoversInaquito.dbo.Empleado_Op002
    where Codigo_empleado in ('Z91','Z92')


    ---- ACTUALIZACION

    update V_Empleado_Op
    set Cargo='Cargo actualizado'
    where Codigo_empleado in ('Z91','Z92')

    update V_Servicio
    set Costo_base=Costo_base+5
    where Codigo_servicio in ('Z91','Z92')

    update V_Historial_Clinico
    set Fecha_atencion=dateadd(day,1,Fecha_atencion)
    where Id_historial in ('Z91','Z92')

    update V_Historial_Pago
    set Pago=Pago+5
    where Id_historial in ('Z91','Z92')


    ---- VERIFICAR LA ACTUALIZACION

    select * from V_Empleado_Op
    where Codigo_empleado in ('Z91','Z92')

    select * from V_Servicio
    where Codigo_servicio in ('Z91','Z92')

    select * from V_Historial_Clinico
    where Id_historial in ('Z91','Z92')

    select * from V_Historial_Pago
    where Id_historial in ('Z91','Z92')


    ---- ELIMINACION
    -- Se eliminan primero las tablas dependientes.

    delete from V_Historial_Pago
    where Id_historial in ('Z91','Z92')

    delete from V_Historial_Clinico
    where Id_historial in ('Z91','Z92')

    delete from V_Servicio
    where Codigo_servicio in ('Z91','Z92')

    delete from V_Empleado_Op
    where Codigo_empleado in ('Z91','Z92')


    ---- VERIFICAR LA ELIMINACION

    if exists
    (
        select 1 from V_Empleado_Op where Codigo_empleado in ('Z91','Z92')
        union all
        select 1 from V_Servicio where Codigo_servicio in ('Z91','Z92')
        union all
        select 1 from V_Historial_Clinico where Id_historial in ('Z91','Z92')
        union all
        select 1 from V_Historial_Pago where Id_historial in ('Z91','Z92')
    )
    begin
        raiserror('La prueba DELETE no elimino todos los registros temporales.',16,1)
    end

    print 'PRUEBA CORRECTA: INSERT, SELECT, UPDATE y DELETE funcionaron en los dos nodos.'

    -- La prueba no conserva ningun cambio.
    rollback transaction

end try
begin catch

    if @@TRANCOUNT > 0
        rollback transaction

    declare @Mensaje_error nvarchar(4000)
    select @Mensaje_error=error_message()
    raiserror(@Mensaje_error,16,1)

end catch
go


-- 3) Verificacion final despues del ROLLBACK
-- Todas las consultas deben devolver cero filas.

select * from V_Empleado_Op
where Codigo_empleado in ('Z91','Z92')

select * from V_Servicio
where Codigo_servicio in ('Z91','Z92')

select * from V_Historial_Clinico
where Id_historial in ('Z91','Z92')

select * from V_Historial_Pago
where Id_historial in ('Z91','Z92')
go
