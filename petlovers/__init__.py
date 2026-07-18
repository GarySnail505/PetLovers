from __future__ import annotations

import secrets
from pathlib import Path

from dotenv import load_dotenv
from flask import Flask, jsonify, render_template, request, session

from .api import api_bp
from .auth import auth_bp, current_user
from .config import load_settings
from .main import main_bp


CSRF_EXEMPT_ENDPOINTS = {"auth.login", "api.api_login", "api.api_session", "api.api_health"}
CSRF_METHODS = {"POST", "PUT", "PATCH", "DELETE"}


def create_app() -> Flask:
    root = Path(__file__).resolve().parent.parent
    load_dotenv(root / ".env")

    app = Flask(__name__, template_folder="templates", static_folder="static")
    settings = load_settings(root)
    app.config.update(settings)

    app.register_blueprint(auth_bp)
    app.register_blueprint(main_bp)
    app.register_blueprint(api_bp)

    @app.before_request
    def protect_mutations_with_csrf():
        if request.method not in CSRF_METHODS:
            return None
        if request.endpoint in CSRF_EXEMPT_ENDPOINTS:
            return None
        expected = session.get("csrf_token")
        received = (
            request.form.get("csrf_token")
            or request.headers.get("X-CSRF-Token")
            or (request.get_json(silent=True) or {}).get("csrf_token")
        )
        if not expected or not received or not secrets.compare_digest(expected, received):
            from flask import abort

            abort(400, description="Token CSRF inválido o vencido.")
        return None

    @app.context_processor
    def inject_globals():
        if "csrf_token" not in session:
            session["csrf_token"] = secrets.token_urlsafe(32)
        user = current_user()
        active_node = app.config["LOCAL_NODE"]
        session["active_node"] = active_node
        node = app.config["NODES"].get(active_node) if active_node else None
        return {
            "csrf_token": session["csrf_token"],
            "current_user": user,
            "active_node": active_node,
            "active_node_config": node,
            "all_nodes": app.config["NODES"],
        }

    @app.template_filter("money")
    def money_filter(value):
        if value is None or value == "":
            return "—"
        try:
            return f"${float(value):,.2f}"
        except (TypeError, ValueError):
            return value

    @app.template_filter("date_iso")
    def date_iso_filter(value):
        if value is None or value == "":
            return "—"
        return value.isoformat() if hasattr(value, "isoformat") else str(value)

    def _wants_json() -> bool:
        return request.path.startswith("/api/") or request.accept_mimetypes.best == "application/json"

    @app.errorhandler(400)
    def bad_request(error):
        if _wants_json():
            return jsonify({"message": getattr(error, "description", str(error))}), 400
        return (
            render_template(
                "error.html",
                code=400,
                title="Solicitud inválida",
                message=getattr(error, "description", str(error)),
            ),
            400,
        )

    @app.errorhandler(403)
    def forbidden(error):
        if _wants_json():
            return jsonify({"message": getattr(error, "description", str(error))}), 403
        return (
            render_template(
                "error.html",
                code=403,
                title="Acceso denegado",
                message=getattr(error, "description", str(error)),
            ),
            403,
        )

    @app.errorhandler(404)
    def not_found(error):
        if _wants_json():
            return jsonify({"message": "El recurso solicitado no existe."}), 404
        return (
            render_template(
                "error.html",
                code=404,
                title="No encontrado",
                message="El recurso solicitado no existe.",
            ),
            404,
        )

    @app.errorhandler(500)
    def internal_error(error):
        if _wants_json():
            return jsonify({"message": "La operación no pudo completarse. Revise la consola del servidor."}), 500
        return (
            render_template(
                "error.html",
                code=500,
                title="Error interno",
                message="La operación no pudo completarse. Revise la consola del servidor.",
            ),
            500,
        )

    return app
