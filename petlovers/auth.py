from __future__ import annotations

import json
from functools import wraps
from pathlib import Path
from urllib.parse import urlparse

from flask import Blueprint, abort, current_app, flash, redirect, render_template, request, session, url_for

from .security import verify_password


auth_bp = Blueprint("auth", __name__)


def _load_users() -> dict:
    path: Path = current_app.config["USERS_FILE"]
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def current_user() -> dict | None:
    username = session.get("username")
    if not username:
        return None
    user = _load_users().get(username)
    if not user:
        session.clear()
        return None
    return {"username": username, **user}


def login_required(view):
    @wraps(view)
    def wrapped(*args, **kwargs):
        if not current_user():
            return redirect(url_for("auth.login", next=request.full_path))
        return view(*args, **kwargs)

    return wrapped


def require_node_access(node_key: str | None = None) -> dict:
    user = current_user()
    if not user:
        abort(403)
    target = node_key or session.get("active_node") or current_app.config["LOCAL_NODE"]
    if target != current_app.config["LOCAL_NODE"]:
        abort(403, description="Esta instalación solo permite utilizar su nodo local.")
    return user


def _safe_next(value: str | None) -> str | None:
    if not value:
        return None
    parsed = urlparse(value)
    if parsed.netloc or parsed.scheme:
        return None
    return value


@auth_bp.route("/login", methods=["GET", "POST"])
def login():
    if current_user():
        return redirect(url_for("main.index"))

    if request.method == "POST":
        username = request.form.get("username", "").strip().lower()
        password = request.form.get("password", "")
        user = _load_users().get(username)
        if not user or not verify_password(password, user.get("password_hash", "")):
            flash("Usuario o contraseña incorrectos.", "error")
            return render_template("login.html", username=username), 401

        session.clear()
        session["username"] = username
        session["active_node"] = current_app.config["LOCAL_NODE"]
        import secrets

        session["csrf_token"] = secrets.token_urlsafe(32)
        flash(f"Sesión iniciada como {user['display_name']}.", "success")
        return redirect(_safe_next(request.args.get("next")) or url_for("main.index"))

    return render_template("login.html")


@auth_bp.post("/logout")
@login_required
def logout():
    session.clear()
    flash("Sesión cerrada.", "info")
    return redirect(url_for("auth.login"))
