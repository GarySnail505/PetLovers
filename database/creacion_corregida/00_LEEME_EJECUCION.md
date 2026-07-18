# PETLOVERS - ORDEN DE EJECUCION

Los scripts conservan el formato general de los archivos originales:
`CREATE DATABASE`, `USE`, `CREATE TABLE`, `ALTER TABLE`,
`INSERT INTO ... SELECT` y consultas `SELECT` finales.

## NODO 002 - INAQUITO

1. Ejecutar `01_PetLovers_Central_Inaquito.sql`.
2. Ejecutar `03_PetLovers_Nodo002_Inaquito.sql`.
3. Configurar Iñaquito como publicador de las tablas `Sede`, `Cliente` y
   `Mascota`.

## REPLICACION HACIA CUMBAYA

4. Crear o seleccionar `PetLoversCumbaya` como base de datos de suscripcion.
5. Configurar Cumbayá como suscriptor de la publicación de Iñaquito.
6. Generar y aplicar la instantánea hasta comprobar que en Cumbayá ya existen:
   `Sede`, `Cliente` y `Mascota`.

## NODO 001 - CUMBAYA

7. Configurar el servidor vinculado hacia Iñaquito con el nombre
   `NODO_INAQUITO`.
8. Ejecutar `02_PetLovers_Nodo001_Cumbaya.sql`.

## ESQUEMA LOCAL RESULTANTE

| Relacion | Nodo 001 - Cumbaya | Nodo 002 - Inaquito |
|---|---|---|
| Sede | `Sede` replicada | `Sede` publicador |
| Cliente | `Cliente` replicada | `Cliente` publicador |
| Mascota | `Mascota` replicada | `Mascota` publicador |
| Empleado operativo | `Empleado_Op001` | `Empleado_Op002` |
| Empleado contacto | No se almacena | `Empleado_Contacto` |
| Servicio | `Servicio001` | `Servicio002` |
| Historial clinico | `Historial_Clinico001` | `Historial_Clinico002` |
| Historial pago | `Historial_Pago001` | `Historial_Pago002` |

## IMPORTANTE

- El script de Cumbayá no crea ni inserta datos en `Sede`, `Cliente` o
  `Mascota`. Estas tablas deben llegar mediante replicación.
- `Empleado_Op001` recupera solamente empleados con `Codigo_sede='001'`.
- `Empleado_Op002` recupera solamente empleados con `Codigo_sede='002'`.
- `Empleado_Contacto` recupera en Iñaquito los contactos de todos los
  empleados, porque ese nodo cumple la función administrativa.
- Los datos y el estilo de inserción se mantienen como en los scripts
  originales.
- Si el servidor vinculado tiene otro nombre, reemplazar
  `[NODO_INAQUITO]` en el script de Cumbayá.
- Los scripts están pensados para bases nuevas; no deben ejecutarse dos veces
  sobre las mismas tablas.
