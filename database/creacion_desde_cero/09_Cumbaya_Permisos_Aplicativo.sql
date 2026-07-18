/* PERMISOS DEL APLICATIVO - EJECUTAR EN CUMBAYA
   El login y el usuario pl_app_cumbaya deben crearse previamente con una
   contraseña administrada fuera de este archivo. */

USE [PetLoversCumbaya];
GO

IF USER_ID(N'pl_app_cumbaya') IS NULL
    THROW 68001, 'No existe el usuario de base pl_app_cumbaya.', 1;
GO

GRANT SELECT ON dbo.Sede TO pl_app_cumbaya;
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.Cliente TO pl_app_cumbaya;
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.Mascota TO pl_app_cumbaya;
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.V_Empleado_Op TO pl_app_cumbaya;
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.V_Servicio TO pl_app_cumbaya;
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.V_Historial TO pl_app_cumbaya;
GO

/* El mapeo de seguridad del linked server DESKTOP-Q40JF1K debe usar en
   Inaquito una identidad con CRUD sobre Empleado_Op002, Servicio002,
   Historial002 y Empleado_Contacto. */
