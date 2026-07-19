# PetLovers Distributed Manager

Aplicación Flask + React para el proyecto de Bases de Datos Distribuidas. Cada instalación se conecta **exclusivamente a su SQL Server local**. SQL Server resuelve el acceso al otro fragmento mediante los servidores vinculados y las vistas particionadas.

Para construir las tres bases y las VPA en una instalación completamente
nueva, consulte
[`database/creacion_desde_cero/00_LEEME_ORDEN_EJECUCION.md`](database/creacion_desde_cero/00_LEEME_ORDEN_EJECUCION.md).

## Arquitectura

| Instalación actual | Nodo | Equipo | Base local | Servidor vinculado |
|---|---|---|---|---|
| Host | Iñaquito (`002`) | `DESKTOP-Q40JF1K` | `PetLoversInaquito` | `WIN-LO84K82LN7M` |
| VM | Cumbayá (`001`) | `WIN-LO84K82LN7M` | `PetLoversCumbaya` | `DESKTOP-Q40JF1K` |

La aplicación del host no abre una conexión con Cumbayá y la aplicación de la VM no abre una conexión con Iñaquito. Cada una usa `localhost`; las vistas de SQL Server son las que consultan o modifican el fragmento remoto.

## Objetos utilizados por el CRUD

| Información | Objeto SQL utilizado |
|---|---|
| Empleado operativo | Vista `V_Empleado_Op` |
| Servicio | Vista `V_Servicio` |
| Historial de atención | Vista `V_Historial` |
| Cliente | Tabla local/replicada `Cliente` |
| Mascota | Tabla local/replicada `Mascota` |
| Sede | Tabla local/replicada `Sede` |
| Contacto del empleado | Tabla `Empleado_Contacto` de Iñaquito |

Las tablas físicas horizontales se llaman:

- Cumbayá: `Empleado_Op001`, `Servicio001` e `Historial001`.
- Iñaquito: `Empleado_Op002`, `Servicio002` e `Historial002`.

El aplicativo no escribe directamente en esas tablas. Las tres vistas globales usan `UNION ALL` y las restricciones `CHECK` dirigen cada fila según `Codigo_sede`.

## Instalación inicial

Requisitos:

- Python 3.11 o posterior.
- Node.js 20 o posterior (solo para instalar/compilar la interfaz).
- ODBC Driver 18 for SQL Server.
- SQL Server, servidores vinculados y DTC configurados.

En PowerShell, desde la carpeta del proyecto:

```powershell
.\setup.ps1
```

Este comando crea el entorno Python, instala las dependencias de ambas partes y compila React para que Flask pueda servirlo.

## Configuración del host de Iñaquito

El archivo `.env` debe contener:

```env
LOCAL_NODE=inaquito
LOCAL_SQL_SERVER=localhost
LOCAL_SQL_PORT=1433
LOCAL_SQL_DATABASE=PetLoversInaquito
LOCAL_SQL_USER=pl_app_inaquito
LOCAL_SQL_PASSWORD=CONTRASENA_LOCAL
```

Si SQL Server usa una instancia con nombre, se puede usar, por ejemplo, `LOCAL_SQL_SERVER=localhost\SQLEXPRESS` y dejar `LOCAL_SQL_PORT` vacío.

## Configuración de la VM de Cumbayá

```env
LOCAL_NODE=cumbaya
LOCAL_SQL_SERVER=localhost
LOCAL_SQL_PORT=1433
LOCAL_SQL_DATABASE=PetLoversCumbaya
LOCAL_SQL_USER=pl_app_cumbaya
LOCAL_SQL_PASSWORD=CONTRASENA_LOCAL
```

## Ejecución cotidiana

Después de la instalación inicial solo se ejecuta:

```powershell
.\run.ps1
```

La interfaz y la API quedan disponibles juntas en:

```text
http://127.0.0.1:5000
```

Ya no es necesario mantener una consola para Flask y otra para Vite.

## Uso en dos computadoras físicas con RadminVPN

1. Copiar el mismo proyecto a ambos computadores.
2. En cada copia, ejecutar `setup.ps1` una vez.
3. Configurar `LOCAL_NODE` y las credenciales de la base local correspondiente.
4. Mantener `LOCAL_SQL_SERVER=localhost` en ambos aplicativos.
5. Cambiar únicamente la configuración de los **servidores vinculados de SQL Server** para que usen los nombres o direcciones RadminVPN del otro equipo.
6. Verificar DTC, `DATA ACCESS` y las tres VPA en ambos nodos.
7. Ejecutar `run.ps1` en cada computador.

El cambio de red doméstica a la universidad no requiere modificar el aplicativo. Si cambia la conectividad entre bases, solamente debe revisarse RadminVPN y los servidores vinculados de SQL Server.

## Comportamiento de la interfaz

- Empleados, Servicios e Historiales muestran datos de ambas sedes mediante las vistas globales.
- Al crear un registro distribuido se selecciona por defecto la sede de la instalación local.
- El usuario puede escoger la otra sede cuando la operación lo requiera.
- Al editar o eliminar se utiliza la combinación de identificador y sede para seleccionar una sola fila.
- Cliente y Mascota se escriben una vez en la tabla local; la replicación bidireccional queda a cargo de SQL Server.

## Desarrollo con Git y GitHub

El repositorio usa la rama estable `main`, conserva los archivos de
configuración del proyecto y valida automáticamente el backend y el frontend
en cada push o pull request. Consulte [CONTRIBUTING.md](CONTRIBUTING.md) para
crear ramas, ejecutar pruebas y publicar cambios sin incluir dependencias,
cachés ni respaldos de SQL Server.
