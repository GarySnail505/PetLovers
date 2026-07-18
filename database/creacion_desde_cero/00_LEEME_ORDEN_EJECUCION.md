# PetLovers - creación completa desde cero

Este paquete crea una instalación nueva con el diseño definitivo:

- `Sede`: replicación unidireccional desde Iñaquito hacia Cumbayá.
- `Cliente` y `Mascota`: replicación de mezcla bidireccional.
- `Empleado_Op`: fragmentación horizontal sobre el fragmento vertical
  operativo; `Empleado_Contacto` permanece en Iñaquito.
- `Servicio`: fragmentación horizontal primaria.
- `Historial`: únicamente fragmentación horizontal derivada, sin separar pago
  y datos clínicos.
- VPA en ambos nodos: `V_Empleado_Op`, `V_Servicio` y `V_Historial`.

Los scripts se niegan a crear una base si ya existe. No contienen `DROP
DATABASE`, por lo que no deben usarse como scripts de migración sobre las bases
actuales.

## Nombres utilizados

| Elemento | Valor |
|---|---|
| Nodo 001 Cumbayá | `CHIKORITA` |
| Nodo 002 Iñaquito | `DESKTOP-Q40JF1K` |
| Base central | `PetLoversCentral` |
| Base Cumbayá | `PetLoversCumbaya` |
| Base Iñaquito | `PetLoversInaquito` |
| Linked server Iñaquito -> Cumbayá | `CHIKORITA` |
| Linked server Cumbayá -> Iñaquito | `DESKTOP-Q40JF1K` |

Si cambia un alias de linked server, hay que reemplazarlo antes de ejecutar los
scripts 05, 06, 07, 10 y 11.

## Orden obligatorio

1. En Iñaquito ejecutar `01_Central_Inaquito.sql`.
2. En Iñaquito ejecutar `02_Inaquito_Esquema_Local.sql`.
3. En Cumbayá ejecutar `03_Cumbaya_Crear_Base_Suscripcion.sql`.
4. Configurar en SQL Server la replicación:
   - Publicación de mezcla de `Cliente` y `Mascota`, con Iñaquito como
     publicador y Cumbayá como suscriptor editable.
   - Publicación unidireccional de `Sede`, desde Iñaquito hacia Cumbayá.
   - Generar y aplicar las instantáneas hasta que las tres tablas existan en
     `PetLoversCumbaya`.
5. En Cumbayá ejecutar `04_Cumbaya_Verificar_Tablas_Replicadas.sql`.
6. En Cumbayá ejecutar `05_Cumbaya_Esquema_Local.sql`.
7. Configurar los linked servers con los aliases indicados y habilitar `DATA
   ACCESS` y DTC en ambos equipos.
8. En Iñaquito ejecutar `06_Inaquito_Crear_VPA.sql`.
9. En Cumbayá ejecutar `07_Cumbaya_Crear_VPA.sql`.
10. Ejecutar los scripts de permisos 08 y 09 si se usarán los usuarios
    `pl_app_inaquito` y `pl_app_cumbaya`.
11. Ejecutar `10_Validacion_Global_Desde_Cumbaya.sql`.
12. Ejecutar `11_Prueba_CRUD_VPA_Desde_Cumbaya.sql`. La prueba termina con
    `ROLLBACK` y no conserva datos.

## Replicación

La creación de publicaciones, agentes y suscripciones no se incluye como un
script ciego porque requiere cuentas de servicio, contraseña del distribuidor,
ruta de instantáneas y modalidad push/pull propias de cada instalación. Después
de configurarla en SSMS conviene usar `Replication > Generate Scripts` para
guardar el script exacto del entorno junto a este paquete.
