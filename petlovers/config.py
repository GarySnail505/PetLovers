from __future__ import annotations

import os
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class NodeConfig:
    key: str
    code: str
    name: str
    location: str
    server: str
    port: str
    database: str
    username: str
    password: str
    tables: dict[str, str | None]


NODE_IDENTITIES = {
    "cumbaya": {
        "code": "001",
        "name": "Nodo 001 · Cumbayá",
        "location": "Cumbayá",
        "database": "PetLoversCumbaya",
    },
    "inaquito": {
        "code": "002",
        "name": "Nodo 002 · Iñaquito",
        "location": "Iñaquito",
        "database": "PetLoversInaquito",
    },
}


def _bool(name: str, default: bool = False) -> bool:
    value = os.getenv(name)
    if value is None:
        return default
    return value.strip().lower() in {"1", "true", "yes", "si", "sí", "on"}


def load_settings(root: Path) -> dict:
    local_key = os.getenv("LOCAL_NODE", "inaquito").strip().lower()
    if local_key not in NODE_IDENTITIES:
        raise RuntimeError("LOCAL_NODE debe ser 'cumbaya' o 'inaquito'.")

    identity = NODE_IDENTITIES[local_key]
    local_node = NodeConfig(
        key=local_key,
        code=identity["code"],
        name=identity["name"],
        location=identity["location"],
        server=os.getenv("LOCAL_SQL_SERVER", "localhost"),
        port=os.getenv("LOCAL_SQL_PORT", "1433"),
        database=os.getenv("LOCAL_SQL_DATABASE", identity["database"]),
        username=os.getenv("LOCAL_SQL_USER", ""),
        password=os.getenv("LOCAL_SQL_PASSWORD", ""),
        tables={
            # Tablas locales/replicadas: la aplicación escribe directamente aquí.
            "sede": "Sede",
            "cliente": "Cliente",
            "mascota": "Mascota",
            "empleado_contacto": "Empleado_Contacto" if local_key == "inaquito" else None,
            # Fragmentación horizontal: todo el CRUD pasa por las VPA locales.
            "empleado_op": "V_Empleado_Op",
            "servicio": "V_Servicio",
            "historial": "V_Historial",
        },
    )

    return {
        "SECRET_KEY": os.getenv("FLASK_SECRET_KEY", "dev-only-change-me"),
        "DEBUG": _bool("FLASK_DEBUG", True),
        "HOST": os.getenv("HOST", "127.0.0.1"),
        "PORT": int(os.getenv("PORT", "5000")),
        "SQL_DRIVER": os.getenv("SQL_DRIVER", "ODBC Driver 18 for SQL Server"),
        "SQL_ENCRYPT": os.getenv("SQL_ENCRYPT", "no"),
        "SQL_TRUST_SERVER_CERTIFICATE": os.getenv("SQL_TRUST_SERVER_CERTIFICATE", "yes"),
        "SQL_CONNECTION_TIMEOUT": int(os.getenv("SQL_CONNECTION_TIMEOUT", "5")),
        "LOCAL_NODE": local_key,
        # NODES contiene deliberadamente un solo destino conectable.
        "NODES": {local_key: local_node},
        "USERS_FILE": root / "config" / "users.json",
        "TEMPLATES_AUTO_RELOAD": True,
        "FRONTEND_DIST": root / "frontend" / "dist",
    }
