# Migracion de Historial a fragmentacion horizontal

Esta migracion reemplaza la fragmentacion mixta de `Historial` por dos
fragmentos horizontales completos:

- Cumbaya: `dbo.Historial001`.
- Inaquito: `dbo.Historial002`.

Las tablas y vistas antiguas no se eliminan. Permanecen como respaldo hasta
que la migracion y el aplicativo hayan sido validados.

## Orden obligatorio

1. Detener temporalmente el aplicativo en los dos equipos para evitar cambios
   mientras se copian los datos.
2. Crear un respaldo de `PetLoversCumbaya` y `PetLoversInaquito`.
3. En Cumbaya ejecutar `01_Cumbaya_Crear_Historial001.sql`.
4. En Inaquito ejecutar `02_Inaquito_Crear_Historial002.sql`.
5. En Cumbaya ejecutar `03_Cumbaya_Crear_V_Historial.sql`.
6. En Inaquito ejecutar `04_Inaquito_Crear_V_Historial.sql`.
7. Desde Cumbaya ejecutar `05_Prueba_CRUD_V_Historial_Cumbaya.sql`.
8. Desplegar el aplicativo actualizado en ambos equipos.

## Servidores vinculados utilizados

- Desde Cumbaya hacia Inaquito: `[DESKTOP-Q40JF1K]`.
- Desde Inaquito hacia Cumbaya: `[CHIKORITA]`.

Si alguno de esos aliases cambia, se debe reemplazar en los scripts 03, 04 y
05 antes de ejecutarlos.

## Objetos conservados como respaldo

- `Historial_Clinico001`, `Historial_Pago001`.
- `Historial_Clinico002`, `Historial_Pago002`.
- `V_Historial_Clinico`, `V_Historial_Pago` en ambos nodos.

No deben eliminarse hasta comprobar el CRUD desde las dos instalaciones.
