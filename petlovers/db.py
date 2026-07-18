from __future__ import annotations

from contextlib import contextmanager

import pyodbc
from flask import current_app

from .config import NodeConfig


def _server_value(node: NodeConfig) -> str:
    server = node.server.strip()
    port = node.port.strip()
    if not server:
        raise RuntimeError(f"No se configuró el servidor SQL del nodo {node.name}.")
    if "\\" in server or not port:
        return server
    return f"{server},{port}"


def connection_string(node_key: str) -> str:
    if node_key != current_app.config["LOCAL_NODE"]:
        raise RuntimeError("La aplicación solo puede conectarse al nodo SQL Server local.")
    node: NodeConfig = current_app.config["NODES"][node_key]
    driver = current_app.config["SQL_DRIVER"]
    timeout = current_app.config["SQL_CONNECTION_TIMEOUT"]
    encrypt = current_app.config["SQL_ENCRYPT"]
    trust = current_app.config["SQL_TRUST_SERVER_CERTIFICATE"]
    return (
        f"DRIVER={{{driver}}};"
        f"SERVER={_server_value(node)};"
        f"DATABASE={node.database};"
        f"UID={node.username};PWD={node.password};"
        f"Encrypt={encrypt};TrustServerCertificate={trust};"
        f"Connection Timeout={timeout};"
    )


def connect(node_key: str, *, autocommit: bool = False):
    return pyodbc.connect(connection_string(node_key), autocommit=autocommit)


def _dict_rows(cursor) -> list[dict]:
    columns = [column[0] for column in cursor.description] if cursor.description else []
    return [dict(zip(columns, row)) for row in cursor.fetchall()]


def fetch_all(node_key: str, sql: str, params: tuple | list = ()) -> list[dict]:
    with connect(node_key) as connection:
        cursor = connection.cursor()
        cursor.execute(sql, *params)
        return _dict_rows(cursor)


def fetch_one(node_key: str, sql: str, params: tuple | list = ()) -> dict | None:
    rows = fetch_all(node_key, sql, params)
    return rows[0] if rows else None


def scalar(node_key: str, sql: str, params: tuple | list = ()):
    with connect(node_key) as connection:
        cursor = connection.cursor()
        cursor.execute(sql, *params)
        row = cursor.fetchone()
        return None if row is None else row[0]


@contextmanager
def transaction(node_key: str):
    connection = connect(node_key, autocommit=False)
    try:
        # Requerido para escrituras que SQL Server promueve a transacción
        # distribuida al atravesar una vista particionada.
        connection.execute("SET XACT_ABORT ON")
        yield connection
        connection.commit()
    except Exception:
        connection.rollback()
        raise
    finally:
        connection.close()


def ping(node_key: str) -> tuple[bool, str]:
    try:
        value = scalar(node_key, "SELECT DB_NAME()")
        return True, str(value)
    except Exception as error:
        return False, friendly_db_error(error)


def friendly_db_error(error: Exception) -> str:
    text = str(error)
    mappings = {
        "2627": "Ya existe un registro con esa clave primaria.",
        "2601": "Ya existe un registro con un valor que debe ser único.",
        "547": "La operación viola una relación entre tablas. Revise los registros relacionados.",
        "8152": "Uno de los valores supera la longitud permitida por la columna.",
        "22001": "Uno de los valores supera la longitud permitida por la columna.",
        "18456": "SQL Server rechazó el usuario o la contraseña configurados.",
        "08001": "No fue posible conectarse con SQL Server. Revise IP, puerto, firewall e instancia.",
        "HYT00": "La conexión con SQL Server agotó el tiempo de espera.",
    }
    for code, message in mappings.items():
        if code in text:
            return message
    if len(text) > 280:
        return text[:277] + "..."
    return text
