from __future__ import annotations

from dataclasses import dataclass, field


@dataclass(frozen=True)
class FieldDef:
    name: str
    label: str
    input_type: str = "text"
    required: bool = True
    max_length: int | None = None
    step: str | None = None
    help_text: str | None = None
    options_source: str | None = None
    readonly: bool = False


@dataclass(frozen=True)
class EntityDef:
    key: str
    singular: str
    plural: str
    description: str
    primary_key: str
    storage_strategy: str
    routing_label: str
    fields: list[FieldDef] = field(default_factory=list)
    list_columns: list[tuple[str, str]] = field(default_factory=list)


def entities_for_node(node_key: str) -> dict[str, EntityDef]:
    employee_fields = [
        FieldDef("Codigo_empleado", "Código", max_length=3, help_text="Identificador de 3 caracteres."),
        FieldDef("Nombre_empleado", "Nombre", max_length=50),
        FieldDef("Cargo", "Cargo", max_length=50),
        FieldDef("Codigo_sede", "Sede", input_type="select", options_source="sedes"),
    ]
    employee_columns = [
        ("Codigo_empleado", "Código"),
        ("Nombre_empleado", "Nombre"),
        ("Cargo", "Cargo"),
        ("Codigo_sede", "Sede"),
    ]
    if node_key == "inaquito":
        employee_fields.extend(
            [
                FieldDef("Cedula_empleado", "Cédula", max_length=10),
                FieldDef("Celular_empleado", "Celular", max_length=10),
                FieldDef("Correo_empleado", "Correo", input_type="email", max_length=100),
            ]
        )
        employee_columns.extend(
            [
                ("Cedula_empleado", "Cédula"),
                ("Celular_empleado", "Celular"),
                ("Correo_empleado", "Correo"),
            ]
        )

    return {
        "sedes": EntityDef(
            key="sedes",
            singular="sede",
            plural="Sedes",
            description="Información replicada de las ubicaciones de PetLovers.",
            primary_key="Codigo_sede",
            storage_strategy="publisher_local" if node_key == "inaquito" else "replicated_read_only",
            routing_label=(
                "Tabla local publicadora · cambios administrados en Iñaquito"
                if node_key == "inaquito"
                else "Réplica local unidireccional desde Iñaquito"
            ),
            fields=[
                FieldDef("Codigo_sede", "Código", max_length=3),
                FieldDef("Ubicacion", "Ubicación", max_length=50),
                FieldDef("Nombre_sede", "Nombre de la sede", max_length=50),
            ],
            list_columns=[
                ("Codigo_sede", "Código"),
                ("Ubicacion", "Ubicación"),
                ("Nombre_sede", "Nombre"),
            ],
        ),
        "clientes": EntityDef(
            key="clientes",
            singular="cliente",
            plural="Clientes",
            description="Datos compartidos y replicados entre ambas sedes.",
            primary_key="Cedula_cliente",
            storage_strategy="merge_replica_local",
            routing_label="Tabla local · replicación de mezcla entre nodos",
            fields=[
                FieldDef("Cedula_cliente", "Cédula", max_length=10),
                FieldDef("Nombre_Cliente", "Nombre", max_length=50),
                FieldDef("Celular_Cliente", "Celular", max_length=10),
                FieldDef("Correo_Cliente", "Correo", input_type="email", max_length=100),
            ],
            list_columns=[
                ("Cedula_cliente", "Cédula"),
                ("Nombre_Cliente", "Nombre"),
                ("Celular_Cliente", "Celular"),
                ("Correo_Cliente", "Correo"),
            ],
        ),
        "mascotas": EntityDef(
            key="mascotas",
            singular="mascota",
            plural="Mascotas",
            description="Mascotas replicadas para que puedan atenderse en cualquiera de los nodos.",
            primary_key="Id_mascota",
            storage_strategy="merge_replica_local",
            routing_label="Tabla local · replicación de mezcla entre nodos",
            fields=[
                FieldDef("Id_mascota", "Identificador", max_length=3),
                FieldDef("Nombre_mascota", "Nombre", max_length=50),
                FieldDef("Fecha_nacimiento", "Fecha de nacimiento", input_type="date"),
                FieldDef("Especie", "Especie", max_length=30),
                FieldDef("Raza", "Raza", max_length=50),
                FieldDef("Cedula_cliente", "Propietario", input_type="select", options_source="clientes"),
            ],
            list_columns=[
                ("Id_mascota", "ID"),
                ("Nombre_mascota", "Nombre"),
                ("Fecha_nacimiento", "Nacimiento"),
                ("Especie", "Especie"),
                ("Raza", "Raza"),
                ("Cliente", "Propietario"),
            ],
        ),
        "empleados": EntityDef(
            key="empleados",
            singular="empleado",
            plural="Empleados",
            description=(
                "Vista particionada global y datos de contacto almacenados en Iñaquito."
                if node_key == "inaquito"
                else "Vista particionada global; los datos de contacto pertenecen al nodo Iñaquito."
            ),
            primary_key="Codigo_empleado",
            storage_strategy="horizontal_vpa",
            routing_label="VPA global · Código de sede decide el fragmento",
            fields=employee_fields,
            list_columns=employee_columns,
        ),
        "servicios": EntityDef(
            key="servicios",
            singular="servicio",
            plural="Servicios",
            description="Vista particionada global de los servicios de ambas sedes.",
            primary_key="Codigo_servicio",
            storage_strategy="horizontal_vpa",
            routing_label="VPA global · Código de sede decide el fragmento",
            fields=[
                FieldDef("Codigo_servicio", "Código", max_length=3),
                FieldDef("Tipo_servicio", "Tipo de servicio", max_length=50),
                FieldDef("Costo_base", "Costo base", input_type="number", step="0.01"),
                FieldDef("Descripcion", "Descripción", input_type="textarea", max_length=100),
                FieldDef("Codigo_sede", "Sede", input_type="select", options_source="sedes"),
            ],
            list_columns=[
                ("Codigo_servicio", "Código"),
                ("Tipo_servicio", "Servicio"),
                ("Costo_base", "Costo base"),
                ("Descripcion", "Descripción"),
                ("Codigo_sede", "Sede"),
            ],
        ),
        "historiales": EntityDef(
            key="historiales",
            singular="atención",
            plural="Historial de atenciones",
            description="Vista particionada global de los historiales completos de ambas sedes.",
            primary_key="Id_historial",
            storage_strategy="horizontal_vpa",
            routing_label="V_Historial · Código de sede decide Historial001 o Historial002",
            fields=[
                FieldDef("Id_historial", "ID de historial", max_length=3),
                FieldDef("Id_mascota", "Mascota", input_type="select", options_source="mascotas"),
                FieldDef("Codigo_servicio", "Servicio", input_type="select", options_source="servicios"),
                FieldDef("Codigo_empleado", "Empleado responsable", input_type="select", options_source="empleados"),
                FieldDef(
                    "Codigo_sede",
                    "Nodo destino",
                    input_type="select",
                    options_source="sedes",
                    help_text="La VPA utiliza este código para elegir el fragmento 001 o 002.",
                ),
                FieldDef("Fecha_atencion", "Fecha de atención", input_type="date"),
                FieldDef("Pago", "Pago", input_type="number", step="0.01"),
            ],
            list_columns=[
                ("Id_historial", "ID"),
                ("Mascota", "Mascota"),
                ("Servicio", "Servicio"),
                ("Empleado", "Responsable"),
                ("Codigo_sede", "Sede"),
                ("Fecha_atencion", "Fecha"),
                ("Pago", "Pago"),
            ],
        ),
    }
