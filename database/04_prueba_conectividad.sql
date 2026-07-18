SELECT
    @@SERVERNAME AS Servidor,
    DB_NAME() AS BaseDatos,
    ORIGINAL_LOGIN() AS LoginSql,
    GETDATE() AS FechaServidor;
