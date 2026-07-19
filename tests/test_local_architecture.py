from pathlib import Path
from unittest import TestCase
from unittest.mock import MagicMock, patch

from flask import Flask

from petlovers.config import load_settings
from petlovers.db import connection_string
from petlovers.metadata import entities_for_node
from petlovers.repository import NodeRepository, ValidationError


ROOT = Path(__file__).resolve().parents[1]


class LocalArchitectureTests(TestCase):
    def settings(self, local_node: str):
        with patch.dict(
            "os.environ",
            {
                "LOCAL_NODE": local_node,
                "LOCAL_SQL_SERVER": "localhost",
                "LOCAL_SQL_USER": "local_user",
                "LOCAL_SQL_PASSWORD": "local_password",
            },
            clear=True,
        ):
            return load_settings(ROOT)

    def test_only_local_node_is_connectable(self):
        settings = self.settings("inaquito")
        self.assertEqual("inaquito", settings["LOCAL_NODE"])
        self.assertEqual(["inaquito"], list(settings["NODES"]))

        app = Flask(__name__)
        app.config.update(settings)
        with app.app_context():
            self.assertIn("SERVER=localhost,1433", connection_string("inaquito"))
            with self.assertRaisesRegex(RuntimeError, "nodo SQL Server local"):
                connection_string("cumbaya")

    def test_horizontal_fragments_use_partitioned_views(self):
        for local_node in ("cumbaya", "inaquito"):
            node = self.settings(local_node)["NODES"][local_node]
            self.assertEqual("V_Empleado_Op", node.tables["empleado_op"])
            self.assertEqual("Empleado_Contacto", node.tables["empleado_contacto"])
            self.assertEqual("V_Servicio", node.tables["servicio"])
            self.assertEqual("V_Historial", node.tables["historial"])

    def test_cumbaya_routes_employee_contact_directly_to_inaquito(self):
        settings = self.settings("cumbaya")
        app = Flask(__name__)
        app.config.update(settings)
        with app.app_context():
            repository = NodeRepository("cumbaya")
            self.assertEqual(
                "[DESKTOP-Q40JF1K].[PetLoversInaquito].[dbo].[Empleado_Contacto]",
                repository._employee_contact_table(),
            )

    def test_inaquito_uses_its_local_employee_contact_table(self):
        settings = self.settings("inaquito")
        app = Flask(__name__)
        app.config.update(settings)
        with app.app_context():
            repository = NodeRepository("inaquito")
            self.assertEqual("dbo.[Empleado_Contacto]", repository._employee_contact_table())

    def test_cumbaya_employee_insert_uses_vpa_and_direct_contact_table(self):
        settings = self.settings("cumbaya")
        app = Flask(__name__)
        app.config.update(settings)
        connection = MagicMock()
        context = MagicMock()
        context.__enter__.return_value = connection

        with app.app_context(), patch("petlovers.repository.transaction", return_value=context):
            NodeRepository("cumbaya")._create_empleados(
                {
                    "Codigo_empleado": "X91",
                    "Nombre_empleado": "Empleado prueba",
                    "Cargo": "Auxiliar",
                    "Codigo_sede": "001",
                    "Cedula_empleado": "1799999991",
                    "Celular_empleado": "0999999991",
                    "Correo_empleado": "x91@petlovers.test",
                }
            )

        statements = [call.args[0] for call in connection.execute.call_args_list]
        self.assertIn("INSERT INTO dbo.[V_Empleado_Op]", statements[0])
        self.assertIn(
            "INSERT INTO [DESKTOP-Q40JF1K].[PetLoversInaquito].[dbo].[Empleado_Contacto]",
            statements[1],
        )

    def test_distributed_key_contains_identifier_and_site(self):
        self.assertEqual(("099", "002"), NodeRepository._split_key("empleados", "099|002"))
        with self.assertRaises(ValidationError):
            NodeRepository._split_key("servicios", "001")

    def test_local_site_is_selectable_not_forced(self):
        for local_node in ("cumbaya", "inaquito"):
            entities = entities_for_node(local_node)
            for entity_key in ("empleados", "servicios", "historiales"):
                site = next(field for field in entities[entity_key].fields if field.name == "Codigo_sede")
                self.assertEqual("sedes", site.options_source)
                self.assertFalse(site.readonly)

    def test_employee_contact_fields_are_available_on_both_nodes(self):
        for local_node in ("cumbaya", "inaquito"):
            names = {field.name for field in entities_for_node(local_node)["empleados"].fields}
            self.assertTrue({"Cedula_empleado", "Celular_empleado", "Correo_empleado"} <= names)


if __name__ == "__main__":
    import unittest

    unittest.main()
