# Contribuir a PetLovers

## Preparación

1. Clone el repositorio.
2. Copie `.env.example` como `.env` y configure el nodo local.
3. Ejecute `setup.ps1` una vez.
4. Ejecute `run.ps1` para iniciar el aplicativo.

Nunca agregue `.env`, contraseñas, respaldos `.bak` ni archivos de bases de
datos al repositorio.

## Flujo recomendado

La rama estable es `main`. Cada cambio se desarrolla en una rama corta:

```powershell
git switch main
git pull
git switch -c feature/nombre-del-cambio
```

Antes de confirmar cambios:

```powershell
.\.venv\Scripts\python.exe -m unittest discover -s tests -v
Set-Location frontend
npm.cmd run build
Set-Location ..
```

Después:

```powershell
git status
git add .
git commit -m "feat: descripción breve del cambio"
git push -u origin feature/nombre-del-cambio
```

Abra un pull request hacia `main` y confirme que la validación automática
finaliza correctamente.

## Convención de commits

- `feat:` funcionalidad nueva.
- `fix:` corrección de error.
- `db:` cambios de esquema, VPA o replicación.
- `docs:` documentación.
- `test:` pruebas.
- `chore:` mantenimiento del proyecto.

## Cambios de base de datos

- No modifique scripts de migración que ya se hayan ejecutado en un entorno.
- Agregue un script nuevo, numerado y con el nodo de ejecución indicado.
- Incluya verificaciones previas y, cuando sea posible, una transacción.
- No incluya `DROP DATABASE` ni eliminaciones irreversibles sin un script de
  validación y respaldo explícito.
- Documente el orden de ejecución en el archivo `00_LEEME` correspondiente.
