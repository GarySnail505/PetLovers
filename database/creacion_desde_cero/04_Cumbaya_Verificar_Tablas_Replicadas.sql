/* EJECUTAR DESPUES DE APLICAR LAS INSTANTANEAS DE REPLICACION. */

USE [PetLoversCumbaya];
GO

IF OBJECT_ID(N'dbo.Sede', N'U') IS NULL
    THROW 63001, 'La replicacion todavía no creo dbo.Sede.', 1;

IF OBJECT_ID(N'dbo.Cliente', N'U') IS NULL
    THROW 63002, 'La replicacion todavía no creo dbo.Cliente.', 1;

IF OBJECT_ID(N'dbo.Mascota', N'U') IS NULL
    THROW 63003, 'La replicacion todavía no creo dbo.Mascota.', 1;
GO

IF EXISTS
(
    SELECT 1
    FROM dbo.Mascota AS m
    LEFT JOIN dbo.Cliente AS c ON c.Cedula_cliente = m.Cedula_cliente
    WHERE c.Cedula_cliente IS NULL
)
    THROW 63004, 'Existen mascotas replicadas sin cliente.', 1;
GO

SELECT 'Sede' AS Entidad, COUNT(*) AS Cantidad FROM dbo.Sede
UNION ALL SELECT 'Cliente', COUNT(*) FROM dbo.Cliente
UNION ALL SELECT 'Mascota', COUNT(*) FROM dbo.Mascota;

SELECT
    t.name AS Tabla,
    c.name AS Columna_rowguid,
    c.is_rowguidcol
FROM sys.tables AS t
LEFT JOIN sys.columns AS c
  ON c.object_id = t.object_id
 AND c.is_rowguidcol = 1
WHERE t.name IN (N'Cliente', N'Mascota')
ORDER BY t.name;

SELECT
    name,
    is_disabled,
    is_not_trusted,
    is_not_for_replication
FROM sys.foreign_keys
WHERE parent_object_id = OBJECT_ID(N'dbo.Mascota');
GO
