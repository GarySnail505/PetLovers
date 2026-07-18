/* BASE VACIA DE SUSCRIPCION - EJECUTAR EN CUMBAYA
   Sede, Cliente y Mascota deben ser creadas después por las publicaciones. */

USE [master];
GO

IF DB_ID(N'PetLoversCumbaya') IS NOT NULL
    THROW 62001, 'PetLoversCumbaya ya existe. No se realizo ningun cambio.', 1;
GO

CREATE DATABASE PetLoversCumbaya COLLATE Modern_Spanish_CI_AS;
GO

SELECT name, collation_name, state_desc
FROM sys.databases
WHERE name = N'PetLoversCumbaya';
GO
