from __future__ import annotations

from datetime import date
from decimal import Decimal, InvalidOperation
import re

from flask import current_app

from .config import NodeConfig
from .db import fetch_all, fetch_one, scalar, transaction


_EMAIL = re.compile(r"^[^\s@]+@[^\s@]+\.[^\s@]+$")


class ValidationError(ValueError):
    def __init__(self, errors: dict[str, str]):
        super().__init__("Datos inválidos")
        self.errors = errors


class NodeRepository:
    DISTRIBUTED_ENTITIES = {"empleados", "servicios", "historiales"}

    def __init__(self, node_key: str):
        self.node_key = node_key
        self.node: NodeConfig = current_app.config["NODES"][node_key]
        self.t = self.node.tables

    @staticmethod
    def _table(name: str | None) -> str:
        if not name or not re.fullmatch(r"[A-Za-z0-9_]+", name):
            raise RuntimeError("Nombre de tabla no válido en la configuración.")
        return f"dbo.[{name}]"

    @staticmethod
    def _trim(value):
        return value.strip() if isinstance(value, str) else value

    @staticmethod
    def _split_key(entity: str, key: str) -> tuple[str, str | None]:
        if entity not in NodeRepository.DISTRIBUTED_ENTITIES:
            return key, None
        identifier, separator, site = key.partition("|")
        if not separator or site not in {"001", "002"}:
            raise ValidationError({"Codigo_sede": "La clave del registro no contiene una sede válida."})
        return identifier, site

    def counts(self) -> dict[str, int]:
        result = {
            "Sedes": scalar(self.node_key, f"SELECT COUNT(*) FROM {self._table(self.t['sede'])}"),
            "Clientes": scalar(self.node_key, f"SELECT COUNT(*) FROM {self._table(self.t['cliente'])}"),
            "Mascotas": scalar(self.node_key, f"SELECT COUNT(*) FROM {self._table(self.t['mascota'])}"),
            "Empleados": scalar(self.node_key, f"SELECT COUNT(*) FROM {self._table(self.t['empleado_op'])}"),
            "Servicios": scalar(self.node_key, f"SELECT COUNT(*) FROM {self._table(self.t['servicio'])}"),
            "Atenciones": scalar(self.node_key, f"SELECT COUNT(*) FROM {self._table(self.t['historial'])}"),
        }
        return {key: int(value or 0) for key, value in result.items()}

    def list(self, entity: str) -> list[dict]:
        methods = {
            "sedes": self._list_sedes,
            "clientes": self._list_clientes,
            "mascotas": self._list_mascotas,
            "empleados": self._list_empleados,
            "servicios": self._list_servicios,
            "historiales": self._list_historiales,
        }
        rows = methods[entity]()
        primary_keys = {
            "sedes": "Codigo_sede",
            "clientes": "Cedula_cliente",
            "mascotas": "Id_mascota",
            "empleados": "Codigo_empleado",
            "servicios": "Codigo_servicio",
            "historiales": "Id_historial",
        }
        for row in rows:
            for key, value in list(row.items()):
                row[key] = self._trim(value)
            row["_key"] = str(row[primary_keys[entity]])
            if entity in self.DISTRIBUTED_ENTITIES:
                row["_key"] += f"|{row['Codigo_sede']}"
        return rows

    def get(self, entity: str, key: str) -> dict | None:
        methods = {
            "sedes": self._get_sede,
            "clientes": self._get_cliente,
            "mascotas": self._get_mascota,
            "empleados": self._get_empleado,
            "servicios": self._get_servicio,
            "historiales": self._get_historial,
        }
        row = methods[entity](key)
        if row:
            row = {k: self._trim(v) for k, v in row.items()}
        return row

    def create(self, entity: str, data: dict) -> None:
        cleaned = self.validate(entity, data, editing=False)
        getattr(self, f"_create_{entity}")(cleaned)

    def update(self, entity: str, key: str, data: dict) -> None:
        identifier, _ = self._split_key(entity, key)
        cleaned = self.validate(entity, data, editing=True, original_key=identifier)
        getattr(self, f"_update_{entity}")(key, cleaned)

    def delete(self, entity: str, key: str) -> None:
        getattr(self, f"_delete_{entity}")(key)

    def options(self, source: str, site: str | None = None) -> list[tuple[str, str]]:
        site_filter = site if site in {"001", "002"} else None
        if source == "clientes":
            return [
                (self._trim(r["Cedula_cliente"]), f"{self._trim(r['Cedula_cliente'])} · {r['Nombre_Cliente']}")
                for r in fetch_all(
                    self.node_key,
                    f"SELECT Cedula_cliente, Nombre_Cliente FROM {self._table(self.t['cliente'])} ORDER BY Nombre_Cliente",
                )
            ]
        if source == "mascotas":
            return [
                (self._trim(r["Id_mascota"]), f"{self._trim(r['Id_mascota'])} · {r['Nombre_mascota']}")
                for r in fetch_all(
                    self.node_key,
                    f"SELECT Id_mascota, Nombre_mascota FROM {self._table(self.t['mascota'])} ORDER BY Nombre_mascota",
                )
            ]
        if source == "servicios":
            where = " WHERE RTRIM(Codigo_sede)=?" if site_filter else ""
            params = (site_filter,) if site_filter else ()
            return [
                (self._trim(r["Codigo_servicio"]), f"{self._trim(r['Codigo_servicio'])} · {r['Tipo_servicio']} · sede {self._trim(r['Codigo_sede'])}")
                for r in fetch_all(
                    self.node_key,
                    f"SELECT Codigo_servicio, Tipo_servicio, Codigo_sede FROM {self._table(self.t['servicio'])}"
                    f"{where} "
                    "ORDER BY Codigo_sede, Tipo_servicio",
                    params,
                )
            ]
        if source == "empleados":
            where = " WHERE RTRIM(Codigo_sede)=?" if site_filter else ""
            params = (site_filter,) if site_filter else ()
            return [
                (self._trim(r["Codigo_empleado"]), f"{self._trim(r['Codigo_empleado'])} · {r['Nombre_empleado']} · sede {self._trim(r['Codigo_sede'])}")
                for r in fetch_all(
                    self.node_key,
                    f"SELECT Codigo_empleado, Nombre_empleado, Codigo_sede FROM {self._table(self.t['empleado_op'])}"
                    f"{where} "
                    "ORDER BY Codigo_sede, Nombre_empleado",
                    params,
                )
            ]
        if source == "sedes":
            return [
                (self._trim(r["Codigo_sede"]), f"{self._trim(r['Codigo_sede'])} · {r['Nombre_sede']}")
                for r in fetch_all(
                    self.node_key,
                    f"SELECT Codigo_sede, Nombre_sede FROM {self._table(self.t['sede'])} ORDER BY Codigo_sede",
                )
            ]
        return []

    def validate(self, entity: str, data: dict, *, editing: bool, original_key: str | None = None) -> dict:
        cleaned = {key: (value.strip() if isinstance(value, str) else value) for key, value in data.items()}
        errors: dict[str, str] = {}

        required_by_entity = {
            "sedes": ["Codigo_sede", "Ubicacion", "Nombre_sede"],
            "clientes": ["Cedula_cliente", "Nombre_Cliente", "Celular_Cliente", "Correo_Cliente"],
            "mascotas": ["Id_mascota", "Nombre_mascota", "Fecha_nacimiento", "Especie", "Raza", "Cedula_cliente"],
            "empleados": ["Codigo_empleado", "Nombre_empleado", "Cargo", "Codigo_sede"],
            "servicios": ["Codigo_servicio", "Tipo_servicio", "Costo_base", "Descripcion", "Codigo_sede"],
            "historiales": ["Id_historial", "Id_mascota", "Codigo_servicio", "Codigo_empleado", "Codigo_sede", "Fecha_atencion", "Pago"],
        }
        if entity == "empleados" and self.node_key == "inaquito":
            required_by_entity[entity] += ["Cedula_empleado", "Celular_empleado", "Correo_empleado"]

        for name in required_by_entity[entity]:
            if cleaned.get(name) in (None, ""):
                errors[name] = "Este campo es obligatorio."

        lengths = {
            "Codigo_sede": 3,
            "Cedula_cliente": 10,
            "Celular_Cliente": 10,
            "Correo_Cliente": 100,
            "Id_mascota": 3,
            "Nombre_mascota": 50,
            "Especie": 30,
            "Raza": 50,
            "Codigo_empleado": 3,
            "Nombre_empleado": 50,
            "Cargo": 50,
            "Cedula_empleado": 10,
            "Celular_empleado": 10,
            "Correo_empleado": 100,
            "Codigo_servicio": 3,
            "Tipo_servicio": 50,
            "Descripcion": 100,
            "Ubicacion": 50,
            "Nombre_sede": 50,
            "Nombre_Cliente": 50,
            "Id_historial": 3,
        }
        for name, maximum in lengths.items():
            value = cleaned.get(name)
            if value and len(str(value)) > maximum:
                errors[name] = f"Máximo {maximum} caracteres."

        for name in ["Cedula_cliente", "Celular_Cliente", "Cedula_empleado", "Celular_empleado"]:
            value = cleaned.get(name)
            if value and (len(value) != 10 or not value.isdigit()):
                errors[name] = "Debe contener exactamente 10 dígitos."

        for name in ["Correo_Cliente", "Correo_empleado"]:
            value = cleaned.get(name)
            if value and not _EMAIL.match(value):
                errors[name] = "Ingrese un correo válido."

        for name in ["Fecha_nacimiento", "Fecha_atencion"]:
            value = cleaned.get(name)
            if value:
                try:
                    parsed = date.fromisoformat(value)
                    cleaned[name] = parsed
                except ValueError:
                    errors[name] = "Ingrese una fecha válida."

        for name in ["Costo_base", "Pago"]:
            if name in cleaned and cleaned.get(name) not in (None, ""):
                try:
                    amount = Decimal(str(cleaned[name]))
                    if amount < 0 or amount > Decimal("99999.99"):
                        raise InvalidOperation
                    cleaned[name] = amount.quantize(Decimal("0.01"))
                except (InvalidOperation, ValueError):
                    errors[name] = "Ingrese un valor entre 0 y 99999.99."

        if entity in self.DISTRIBUTED_ENTITIES and cleaned.get("Codigo_sede") not in {"001", "002"}:
            errors["Codigo_sede"] = "Seleccione la sede 001 o 002."

        if entity == "historiales" and not errors:
            site = cleaned["Codigo_sede"]
            if not editing:
                history_exists = scalar(
                    self.node_key,
                    f"SELECT COUNT(*) FROM {self._table(self.t['historial'])} "
                    "WHERE Id_historial=?",
                    (cleaned["Id_historial"],),
                )
                if history_exists:
                    errors["Id_historial"] = "El identificador ya existe en uno de los dos nodos."
            service_exists = scalar(
                self.node_key,
                f"SELECT COUNT(*) FROM {self._table(self.t['servicio'])} "
                "WHERE Codigo_servicio=? AND RTRIM(Codigo_sede)=?",
                (cleaned["Codigo_servicio"], site),
            )
            employee_exists = scalar(
                self.node_key,
                f"SELECT COUNT(*) FROM {self._table(self.t['empleado_op'])} "
                "WHERE Codigo_empleado=? AND RTRIM(Codigo_sede)=?",
                (cleaned["Codigo_empleado"], site),
            )
            if not service_exists:
                errors["Codigo_servicio"] = "El servicio no pertenece a la sede seleccionada."
            if not employee_exists:
                errors["Codigo_empleado"] = "El empleado no pertenece a la sede seleccionada."

        if editing and original_key:
            key_names = {
                "sedes": "Codigo_sede",
                "clientes": "Cedula_cliente",
                "mascotas": "Id_mascota",
                "empleados": "Codigo_empleado",
                "servicios": "Codigo_servicio",
                "historiales": "Id_historial",
            }
            cleaned[key_names[entity]] = original_key

        if errors:
            raise ValidationError(errors)
        return cleaned

    # ----- Lectura -----
    def _list_sedes(self):
        return fetch_all(
            self.node_key,
            f"SELECT Codigo_sede, Ubicacion, Nombre_sede FROM {self._table(self.t['sede'])} ORDER BY Codigo_sede",
        )

    def _list_clientes(self):
        return fetch_all(
            self.node_key,
            f"SELECT Cedula_cliente, Nombre_Cliente, Celular_Cliente, Correo_Cliente "
            f"FROM {self._table(self.t['cliente'])} ORDER BY Nombre_Cliente",
        )

    def _list_mascotas(self):
        return fetch_all(
            self.node_key,
            f"SELECT m.Id_mascota, m.Nombre_mascota, m.Fecha_nacimiento, m.Especie, m.Raza, "
            f"m.Cedula_cliente, c.Nombre_Cliente AS Cliente "
            f"FROM {self._table(self.t['mascota'])} m "
            f"LEFT JOIN {self._table(self.t['cliente'])} c ON c.Cedula_cliente=m.Cedula_cliente "
            "ORDER BY m.Nombre_mascota",
        )

    def _list_empleados(self):
        op = self._table(self.t["empleado_op"])
        contact_name = self.t["empleado_contacto"]
        if contact_name:
            contact = self._table(contact_name)
            return fetch_all(
                self.node_key,
                f"SELECT op.Codigo_empleado, op.Nombre_empleado, op.Cargo, op.Codigo_sede, "
                "ct.Cedula_empleado, ct.Celular_empleado, ct.Correo_empleado "
                f"FROM {op} op LEFT JOIN {contact} ct ON ct.Codigo_empleado=op.Codigo_empleado "
                "ORDER BY op.Codigo_sede, op.Nombre_empleado",
            )
        return fetch_all(
            self.node_key,
            f"SELECT Codigo_empleado, Nombre_empleado, Cargo, Codigo_sede FROM {op} "
            "ORDER BY Codigo_sede, Nombre_empleado",
        )

    def _list_servicios(self):
        return fetch_all(
            self.node_key,
            f"SELECT Codigo_servicio, Tipo_servicio, Costo_base, Descripcion, Codigo_sede "
            f"FROM {self._table(self.t['servicio'])} ORDER BY Codigo_sede, Tipo_servicio",
        )

    def _list_historiales(self):
        history = self._table(self.t["historial"])
        return fetch_all(
            self.node_key,
            f"SELECT h.Id_historial, h.Id_mascota, m.Nombre_mascota AS Mascota, "
            "h.Codigo_servicio, s.Tipo_servicio AS Servicio, h.Codigo_empleado, "
            "e.Nombre_empleado AS Empleado, h.Codigo_sede, h.Fecha_atencion, h.Pago "
            f"FROM {history} h "
            f"LEFT JOIN {self._table(self.t['mascota'])} m ON m.Id_mascota=h.Id_mascota "
            f"LEFT JOIN {self._table(self.t['servicio'])} s ON s.Codigo_servicio=h.Codigo_servicio "
            "AND s.Codigo_sede=h.Codigo_sede "
            f"LEFT JOIN {self._table(self.t['empleado_op'])} e ON e.Codigo_empleado=h.Codigo_empleado "
            "AND e.Codigo_sede=h.Codigo_sede "
            "ORDER BY h.Fecha_atencion DESC, h.Codigo_sede, h.Id_historial DESC",
        )

    def _get_sede(self, key):
        return fetch_one(
            self.node_key,
            f"SELECT Codigo_sede, Ubicacion, Nombre_sede FROM {self._table(self.t['sede'])} WHERE Codigo_sede=?",
            (key,),
        )

    def _get_cliente(self, key):
        return fetch_one(
            self.node_key,
            f"SELECT Cedula_cliente, Nombre_Cliente, Celular_Cliente, Correo_Cliente "
            f"FROM {self._table(self.t['cliente'])} WHERE Cedula_cliente=?",
            (key,),
        )

    def _get_mascota(self, key):
        return fetch_one(
            self.node_key,
            f"SELECT Id_mascota, Nombre_mascota, Fecha_nacimiento, Especie, Raza, Cedula_cliente "
            f"FROM {self._table(self.t['mascota'])} WHERE Id_mascota=?",
            (key,),
        )

    def _get_empleado(self, key):
        identifier, site = self._split_key("empleados", key)
        op = self._table(self.t["empleado_op"])
        if self.t["empleado_contacto"]:
            contact = self._table(self.t["empleado_contacto"])
            return fetch_one(
                self.node_key,
                f"SELECT op.Codigo_empleado, op.Nombre_empleado, op.Cargo, op.Codigo_sede, "
                "ct.Cedula_empleado, ct.Celular_empleado, ct.Correo_empleado "
                f"FROM {op} op LEFT JOIN {contact} ct ON ct.Codigo_empleado=op.Codigo_empleado "
                "WHERE op.Codigo_empleado=? AND RTRIM(op.Codigo_sede)=?",
                (identifier, site),
            )
        return fetch_one(
            self.node_key,
            f"SELECT Codigo_empleado, Nombre_empleado, Cargo, Codigo_sede FROM {op} "
            "WHERE Codigo_empleado=? AND RTRIM(Codigo_sede)=?",
            (identifier, site),
        )

    def _get_servicio(self, key):
        identifier, site = self._split_key("servicios", key)
        return fetch_one(
            self.node_key,
            f"SELECT Codigo_servicio, Tipo_servicio, Costo_base, Descripcion, Codigo_sede "
            f"FROM {self._table(self.t['servicio'])} WHERE Codigo_servicio=? AND RTRIM(Codigo_sede)=?",
            (identifier, site),
        )

    def _get_historial(self, key):
        identifier, site = self._split_key("historiales", key)
        return fetch_one(
            self.node_key,
            f"SELECT h.Id_historial, h.Id_mascota, h.Codigo_servicio, h.Codigo_empleado, "
            "h.Codigo_sede, h.Fecha_atencion, h.Pago "
            f"FROM {self._table(self.t['historial'])} h "
            "WHERE h.Id_historial=? AND RTRIM(h.Codigo_sede)=?",
            (identifier, site),
        )

    # ----- Escritura: sedes -----
    def _create_sedes(self, d):
        with transaction(self.node_key) as cn:
            cn.execute(
                f"INSERT INTO {self._table(self.t['sede'])} (Codigo_sede, Ubicacion, Nombre_sede) VALUES (?,?,?)",
                d["Codigo_sede"], d["Ubicacion"], d["Nombre_sede"],
            )

    def _update_sedes(self, key, d):
        with transaction(self.node_key) as cn:
            cn.execute(
                f"UPDATE {self._table(self.t['sede'])} SET Ubicacion=?, Nombre_sede=? WHERE Codigo_sede=?",
                d["Ubicacion"], d["Nombre_sede"], key,
            )

    def _delete_sedes(self, key):
        with transaction(self.node_key) as cn:
            cn.execute(f"DELETE FROM {self._table(self.t['sede'])} WHERE Codigo_sede=?", key)

    # ----- Escritura: clientes -----
    def _create_clientes(self, d):
        with transaction(self.node_key) as cn:
            cn.execute(
                f"INSERT INTO {self._table(self.t['cliente'])} "
                "(Cedula_cliente, Nombre_Cliente, Celular_Cliente, Correo_Cliente) VALUES (?,?,?,?)",
                d["Cedula_cliente"], d["Nombre_Cliente"], d["Celular_Cliente"], d["Correo_Cliente"],
            )

    def _update_clientes(self, key, d):
        with transaction(self.node_key) as cn:
            cn.execute(
                f"UPDATE {self._table(self.t['cliente'])} SET Nombre_Cliente=?, Celular_Cliente=?, "
                "Correo_Cliente=? WHERE Cedula_cliente=?",
                d["Nombre_Cliente"], d["Celular_Cliente"], d["Correo_Cliente"], key,
            )

    def _delete_clientes(self, key):
        with transaction(self.node_key) as cn:
            cn.execute(f"DELETE FROM {self._table(self.t['cliente'])} WHERE Cedula_cliente=?", key)

    # ----- Escritura: mascotas -----
    def _create_mascotas(self, d):
        with transaction(self.node_key) as cn:
            cn.execute(
                f"INSERT INTO {self._table(self.t['mascota'])} "
                "(Id_mascota, Nombre_mascota, Fecha_nacimiento, Especie, Raza, Cedula_cliente) "
                "VALUES (?,?,?,?,?,?)",
                d["Id_mascota"], d["Nombre_mascota"], d["Fecha_nacimiento"], d["Especie"], d["Raza"], d["Cedula_cliente"],
            )

    def _update_mascotas(self, key, d):
        with transaction(self.node_key) as cn:
            cn.execute(
                f"UPDATE {self._table(self.t['mascota'])} SET Nombre_mascota=?, Fecha_nacimiento=?, "
                "Especie=?, Raza=?, Cedula_cliente=? WHERE Id_mascota=?",
                d["Nombre_mascota"], d["Fecha_nacimiento"], d["Especie"], d["Raza"], d["Cedula_cliente"], key,
            )

    def _delete_mascotas(self, key):
        with transaction(self.node_key) as cn:
            cn.execute(f"DELETE FROM {self._table(self.t['mascota'])} WHERE Id_mascota=?", key)

    # ----- Escritura: empleados -----
    def _create_empleados(self, d):
        with transaction(self.node_key) as cn:
            cn.execute(
                f"INSERT INTO {self._table(self.t['empleado_op'])} "
                "(Codigo_empleado, Nombre_empleado, Cargo, Codigo_sede) VALUES (?,?,?,?)",
                d["Codigo_empleado"], d["Nombre_empleado"], d["Cargo"], d["Codigo_sede"],
            )
            if self.t["empleado_contacto"]:
                cn.execute(
                    f"INSERT INTO {self._table(self.t['empleado_contacto'])} "
                    "(Codigo_empleado, Cedula_empleado, Celular_empleado, Correo_empleado) VALUES (?,?,?,?)",
                    d["Codigo_empleado"], d["Cedula_empleado"], d["Celular_empleado"], d["Correo_empleado"],
                )

    def _update_empleados(self, key, d):
        identifier, site = self._split_key("empleados", key)
        with transaction(self.node_key) as cn:
            cn.execute(
                f"UPDATE {self._table(self.t['empleado_op'])} SET Nombre_empleado=?, Cargo=? "
                "WHERE Codigo_empleado=? AND RTRIM(Codigo_sede)=?",
                d["Nombre_empleado"], d["Cargo"], identifier, site,
            )
            if self.t["empleado_contacto"]:
                cursor = cn.execute(
                    f"UPDATE {self._table(self.t['empleado_contacto'])} SET Cedula_empleado=?, "
                    "Celular_empleado=?, Correo_empleado=? WHERE Codigo_empleado=?",
                    d["Cedula_empleado"], d["Celular_empleado"], d["Correo_empleado"], identifier,
                )
                if cursor.rowcount == 0:
                    cn.execute(
                        f"INSERT INTO {self._table(self.t['empleado_contacto'])} "
                        "(Codigo_empleado, Cedula_empleado, Celular_empleado, Correo_empleado) VALUES (?,?,?,?)",
                        identifier, d["Cedula_empleado"], d["Celular_empleado"], d["Correo_empleado"],
                    )

    def _delete_empleados(self, key):
        identifier, site = self._split_key("empleados", key)
        with transaction(self.node_key) as cn:
            if self.t["empleado_contacto"]:
                cn.execute(f"DELETE FROM {self._table(self.t['empleado_contacto'])} WHERE Codigo_empleado=?", identifier)
            cn.execute(
                f"DELETE FROM {self._table(self.t['empleado_op'])} WHERE Codigo_empleado=? AND RTRIM(Codigo_sede)=?",
                identifier, site,
            )

    # ----- Escritura: servicios -----
    def _create_servicios(self, d):
        with transaction(self.node_key) as cn:
            cn.execute(
                f"INSERT INTO {self._table(self.t['servicio'])} "
                "(Codigo_servicio, Tipo_servicio, Costo_base, Descripcion, Codigo_sede) VALUES (?,?,?,?,?)",
                d["Codigo_servicio"], d["Tipo_servicio"], d["Costo_base"], d["Descripcion"], d["Codigo_sede"],
            )

    def _update_servicios(self, key, d):
        identifier, site = self._split_key("servicios", key)
        with transaction(self.node_key) as cn:
            cn.execute(
                f"UPDATE {self._table(self.t['servicio'])} SET Tipo_servicio=?, Costo_base=?, Descripcion=? "
                "WHERE Codigo_servicio=? AND RTRIM(Codigo_sede)=?",
                d["Tipo_servicio"], d["Costo_base"], d["Descripcion"], identifier, site,
            )

    def _delete_servicios(self, key):
        identifier, site = self._split_key("servicios", key)
        with transaction(self.node_key) as cn:
            cn.execute(
                f"DELETE FROM {self._table(self.t['servicio'])} WHERE Codigo_servicio=? AND RTRIM(Codigo_sede)=?",
                identifier, site,
            )

    # ----- Escritura: historiales -----
    def _create_historiales(self, d):
        with transaction(self.node_key) as cn:
            cn.execute(
                f"INSERT INTO {self._table(self.t['historial'])} "
                "(Id_historial, Id_mascota, Codigo_servicio, Codigo_empleado, "
                "Codigo_sede, Fecha_atencion, Pago) VALUES (?,?,?,?,?,?,?)",
                d["Id_historial"], d["Id_mascota"], d["Codigo_servicio"],
                d["Codigo_empleado"], d["Codigo_sede"], d["Fecha_atencion"], d["Pago"],
            )

    def _update_historiales(self, key, d):
        identifier, site = self._split_key("historiales", key)
        with transaction(self.node_key) as cn:
            cn.execute(
                f"UPDATE {self._table(self.t['historial'])} SET Id_mascota=?, Codigo_servicio=?, "
                "Codigo_empleado=?, Fecha_atencion=?, Pago=? "
                "WHERE Id_historial=? AND RTRIM(Codigo_sede)=?",
                d["Id_mascota"], d["Codigo_servicio"], d["Codigo_empleado"],
                d["Fecha_atencion"], d["Pago"], identifier, site,
            )

    def _delete_historiales(self, key):
        identifier, site = self._split_key("historiales", key)
        with transaction(self.node_key) as cn:
            cn.execute(
                f"DELETE FROM {self._table(self.t['historial'])} WHERE Id_historial=? AND RTRIM(Codigo_sede)=?",
                identifier, site,
            )

    # ----- Comparación de réplicas -----
    def shared_keys(self, entity: str) -> set[str]:
        definitions = {
            "Sede": (self.t["sede"], "Codigo_sede"),
            "Cliente": (self.t["cliente"], "Cedula_cliente"),
            "Mascota": (self.t["mascota"], "Id_mascota"),
        }
        table, column = definitions[entity]
        rows = fetch_all(self.node_key, f"SELECT {column} AS ItemKey FROM {self._table(table)}")
        return {str(self._trim(row["ItemKey"])) for row in rows}
