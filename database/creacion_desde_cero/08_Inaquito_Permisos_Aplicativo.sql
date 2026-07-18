/* PERMISOS DEL APLICATIVO - EJECUTAR EN INAQUITO
   El login y el usuario pl_app_inaquito deben crearse previamente con una
   contraseña administrada fuera de este archivo. */

USE [PetLoversInaquito];
GO

IF USER_ID(N'pl_app_inaquito') IS NULL
    THROW 67001, 'No existe el usuario de base pl_app_inaquito.', 1;
GO

GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.Sede TO pl_app_inaquito;
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.Cliente TO pl_app_inaquito;
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.Mascota TO pl_app_inaquito;
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.Empleado_Contacto TO pl_app_inaquito;
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.V_Empleado_Op TO pl_app_inaquito;
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.V_Servicio TO pl_app_inaquito;
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.V_Historial TO pl_app_inaquito;
GO

/* El mapeo del linked server CHIKORITA debe usar en Cumbaya una identidad con
   permisos de CRUD sobre Empleado_Op001, Servicio001 e Historial001. */
