from pathlib import Path
from unittest import TestCase
from unittest.mock import patch

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
            self.assertEqual("V_Servicio", node.tables["servicio"])
            self.assertEqual("V_Historial", node.tables["historial"])

    def test_distributed_key_contains_identifier_and_site(self):
        self.assertEqual(("099", "002"), NodeRepository._split_key("empleados", "099|002"))
        with self.assertRaises(ValidationError):
            NodeRepository._split_key("servicios", "001")

    def test_local_site_is_selectable_not_forced(self):
        entities = entities_for_node("inaquito")
        for entity_key in ("empleados", "servicios", "historiales"):
            site = next(field for field in entities[entity_key].fields if field.name == "Codigo_sede")
            self.assertEqual("sedes", site.options_source)
            self.assertFalse(site.readonly)


if __name__ == "__main__":
    import unittest

    unittest.main()
