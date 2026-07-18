from __future__ import annotations

from dataclasses import asdict
from datetime import date, datetime
from decimal import Decimal
import secrets

from flask import Blueprint, abort, current_app, jsonify, request, session

from .auth import current_user
from .db import friendly_db_error, ping
from .metadata import entities_for_node
from .repository import NodeRepository, ValidationError


api_bp = Blueprint("api", __name__, url_prefix="/api")


def _local_node_key() -> str:
    return current_app.config["LOCAL_NODE"]


def _node_summary() -> dict:
    node = current_app.config["NODES"][_local_node_key()]
    return {
        "key": node.key,
        "code": node.code,
        "name": node.name,
        "location": node.location,
        "database": node.database,
        "server": node.server,
    }


def _json_value(value):
    if isinstance(value, (date, datetime)):
        return value.isoformat()
    if isinstance(value, Decimal):
        return format(value, ".2f")
    return value


def _serialize_row(row: dict | None):
    if row is None:
        return None
    return {
        key: value.strip() if isinstance(value, str) else _json_value(value)
        for key, value in row.items()
    }


def _entity_definitions() -> dict:
    return {
        key: asdict(entity)
        for key, entity in entities_for_node(_local_node_key()).items()
    }


def _user_payload(user: dict) -> dict:
    local = _local_node_key()
    return {
        "username": user["username"],
        "display_name": user["display_name"],
        "role": user["role"],
        "allowed_nodes": [local],
        "default_node": local,
    }


def _session_payload(user: dict) -> dict:
    node = _node_summary()
    return {
        "authenticated": True,
        "csrf_token": session["csrf_token"],
        "user": _user_payload(user),
        "active_node": node,
        "nodes": {node["key"]: node},
        "entities": _entity_definitions(),
    }


def _require_user() -> dict:
    user = current_user()
    if not user:
        abort(401, description="Sesión no autenticada.")
    return user


@api_bp.get("/auth/session")
def api_session():
    user = current_user()
    if "csrf_token" not in session:
        session["csrf_token"] = secrets.token_urlsafe(32)
    if not user:
        return jsonify({"authenticated": False, "csrf_token": session["csrf_token"]})
    session["active_node"] = _local_node_key()
    return jsonify(_session_payload(user))


@api_bp.post("/auth/login")
def api_login():
    from .auth import _load_users
    from .security import verify_password

    payload = request.get_json(silent=True) or request.form
    username = (payload.get("username") or "").strip().lower()
    password = payload.get("password") or ""
    user = _load_users().get(username)
    if not user or not verify_password(password, user.get("password_hash", "")):
        return jsonify({"ok": False, "message": "Usuario o contraseña incorrectos."}), 401

    session.clear()
    session["username"] = username
    session["active_node"] = _local_node_key()
    session["csrf_token"] = secrets.token_urlsafe(32)
    return jsonify({"ok": True, **_session_payload({"username": username, **user})})


@api_bp.post("/auth/logout")
def api_logout():
    session.clear()
    return jsonify({"ok": True, "message": "Sesión cerrada."})


@api_bp.get("/meta")
def api_meta():
    _require_user()
    node = _node_summary()
    return jsonify({
        "active_node": node,
        "entities": _entity_definitions(),
        "nodes": {node["key"]: node},
        "allowed_nodes": [node["key"]],
    })


@api_bp.get("/dashboard")
def api_dashboard():
    _require_user()
    local = _local_node_key()
    status = ping(local)
    node = _node_summary()
    return jsonify({
        "node": node,
        "counts": NodeRepository(local).counts(),
        "current_status": {"ok": status[0], "message": status[1]},
        "node_statuses": {
            local: {"ok": status[0], "message": status[1], "node": node}
        },
    })


@api_bp.get("/options/<source>")
def api_options(source: str):
    _require_user()
    items = NodeRepository(_local_node_key()).options(source, request.args.get("site"))
    return jsonify({"items": [{"value": value, "label": label} for value, label in items]})


@api_bp.get("/entities/<entity_key>")
def api_entity_list(entity_key: str):
    _require_user()
    entities = entities_for_node(_local_node_key())
    if entity_key not in entities:
        abort(404)
    rows = NodeRepository(_local_node_key()).list(entity_key)
    return jsonify({
        "entity": asdict(entities[entity_key]),
        "rows": [_serialize_row(row) for row in rows],
    })


@api_bp.get("/entities/<entity_key>/<path:key>")
def api_entity_get(entity_key: str, key: str):
    _require_user()
    entities = entities_for_node(_local_node_key())
    if entity_key not in entities:
        abort(404)
    row = NodeRepository(_local_node_key()).get(entity_key, key)
    if not row:
        abort(404)
    return jsonify({"entity": asdict(entities[entity_key]), "row": _serialize_row(row)})


@api_bp.post("/entities/<entity_key>")
def api_entity_create(entity_key: str):
    _require_user()
    entities = entities_for_node(_local_node_key())
    if entity_key not in entities:
        abort(404)
    NodeRepository(_local_node_key()).create(
        entity_key, request.get_json(silent=True) or request.form.to_dict()
    )
    return jsonify({
        "ok": True,
        "message": f"{entities[entity_key].singular.capitalize()} creada correctamente.",
    }), 201


@api_bp.put("/entities/<entity_key>/<path:key>")
def api_entity_update(entity_key: str, key: str):
    _require_user()
    entities = entities_for_node(_local_node_key())
    if entity_key not in entities:
        abort(404)
    NodeRepository(_local_node_key()).update(
        entity_key, key, request.get_json(silent=True) or request.form.to_dict()
    )
    return jsonify({
        "ok": True,
        "message": f"{entities[entity_key].singular.capitalize()} actualizada correctamente.",
    })


@api_bp.delete("/entities/<entity_key>/<path:key>")
def api_entity_delete(entity_key: str, key: str):
    _require_user()
    entities = entities_for_node(_local_node_key())
    if entity_key not in entities:
        abort(404)
    NodeRepository(_local_node_key()).delete(entity_key, key)
    return jsonify({
        "ok": True,
        "message": f"{entities[entity_key].singular.capitalize()} eliminada correctamente.",
    })


@api_bp.get("/replication")
def api_replication():
    _require_user()
    return jsonify({
        "message": (
            "La aplicación no compara nodos mediante conexiones directas. "
            "La replicación se administra y supervisa desde SQL Server."
        )
    }), 410


@api_bp.get("/health")
def api_health():
    local = _local_node_key()
    ok, message = ping(local)
    return jsonify({
        "application": "PetLovers Distribuida",
        "local_node": local,
        "database": {"ok": ok, "message": message},
    }), 200 if ok else 503


@api_bp.errorhandler(ValidationError)
def handle_validation(error: ValidationError):
    return jsonify({"message": "Validación fallida.", "errors": error.errors}), 400


@api_bp.errorhandler(Exception)
def handle_api_exception(error: Exception):
    from werkzeug.exceptions import HTTPException

    if isinstance(error, HTTPException):
        return jsonify({"message": error.description or error.name}), error.code
    return jsonify({"message": friendly_db_error(error)}), 500
