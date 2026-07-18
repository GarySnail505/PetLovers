/* Ejecutar en cada base para confirmar los nombres y columnas usados por el aplicativo. */
SELECT
    DB_NAME() AS BaseDatos,
    t.name AS Tabla,
    c.column_id AS Orden,
    c.name AS Columna,
    ty.name AS Tipo,
    c.max_length AS LongitudBytes,
    c.precision AS Precision,
    c.scale AS Escala,
    c.is_nullable AS PermiteNulos,
    dc.definition AS ValorPredeterminado,
    c.is_rowguidcol AS EsRowGuid
FROM sys.tables t
INNER JOIN sys.columns c ON c.object_id = t.object_id
INNER JOIN sys.types ty ON ty.user_type_id = c.user_type_id
LEFT JOIN sys.default_constraints dc ON dc.parent_object_id = c.object_id AND dc.parent_column_id = c.column_id
WHERE t.name IN (
    'Sede', 'Cliente', 'Mascota', 'Empleado_Op', 'Empleado_Contacto',
    'Servicio001', 'Servicio002',
    'Historial001', 'Historial002',
    'Historial_Clinico001', 'Historial_Clinico002',
    'Historial_Pago001', 'Historial_Pago002'
)
ORDER BY t.name, c.column_id;
