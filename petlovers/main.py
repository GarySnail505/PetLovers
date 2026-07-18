from __future__ import annotations

from flask import Blueprint, current_app, send_from_directory


main_bp = Blueprint("main", __name__)


@main_bp.route("/", defaults={"path": ""})
@main_bp.route("/<path:path>")
def index(path: str):
    """Sirve el frontend compilado y conserva el enrutamiento de React."""
    dist = current_app.config["FRONTEND_DIST"]
    requested = dist / path
    if path and requested.is_file():
        return send_from_directory(dist, path)
    index_file = dist / "index.html"
    if index_file.is_file():
        return send_from_directory(dist, "index.html")
    return (
        "La interfaz todavía no está compilada. Ejecute .\\setup.ps1 una vez.",
        503,
        {"Content-Type": "text/plain; charset=utf-8"},
    )
