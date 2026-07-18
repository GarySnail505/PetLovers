/*--------------------- DIAGNOSTICO DE INSERCION VPA ------------------*/

/* Ejecutar conectado al nodo de Cumbaya.
Este script no inserta, actualiza ni elimina datos. */

use PetLoversCumbaya
go


/*--------------------- PASO 1 - LIMPIAR LA SESION ------------------*/

/* Ejecutar despues de cancelar una consulta que se quedo esperando.
Evita que la ventana conserve bloqueos de una transaccion incompleta. */

select @@SPID as Sesion_actual,@@TRANCOUNT as Transacciones_abiertas

if @@TRANCOUNT > 0
begin
    rollback transaction
    print 'Se revirtio la transaccion que habia quedado abierta.'
end
go


/*--------------------- PASO 2 - PROBAR LA LECTURA REMOTA ------------------*/

select top 1 *
from [DESKTOP-Q40JF1K].PetLoversInaquito.dbo.Empleado_Op002
go


/*--------------------- PASO 3 - PROBAR DTC SIN MODIFICAR DATOS ------------------*/

set XACT_ABORT on
go

begin try

    begin distributed transaction

    select top 1 *
    from PetLoversCumbaya.dbo.Empleado_Op001

    select top 1 *
    from [DESKTOP-Q40JF1K].PetLoversInaquito.dbo.Empleado_Op002

    rollback transaction

    print 'PRUEBA DTC CORRECTA: los dos nodos participaron en la transaccion.'

end try
begin catch

    if @@TRANCOUNT > 0
        rollback transaction

    select
        error_number() as Numero_error,
        error_message() as Mensaje_error

end catch
go


/*--------------------- PASO 4 - DETECTAR BLOQUEOS ------------------*/

/* Ejecutar este bloque desde una segunda ventana mientras la primera
se encuentra esperando. Requiere permiso VIEW SERVER STATE. */

select
    r.session_id,
    r.status,
    r.command,
    r.blocking_session_id,
    r.wait_type,
    r.wait_time,
    r.wait_resource,
    r.open_transaction_count,
    db_name(r.database_id) as Base_datos,
    t.text as Sentencia
from sys.dm_exec_requests r
cross apply sys.dm_exec_sql_text(r.sql_handle) t
where r.session_id <> @@SPID
and
(
    r.database_id=db_id('PetLoversCumbaya')
    or r.blocking_session_id <> 0
)
order by r.blocking_session_id desc,r.session_id
go
