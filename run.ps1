$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

if (-not (Test-Path ".venv\Scripts\python.exe")) {
    throw "Falta la instalación inicial. Ejecute .\setup.ps1 una vez."
}

if (-not (Test-Path "frontend\dist\index.html")) {
    throw "Falta compilar la interfaz. Ejecute .\setup.ps1 una vez."
}

Write-Host "PetLovers disponible en http://127.0.0.1:5000" -ForegroundColor Green
Write-Host "Presione Ctrl+C para detenerlo."
& .\.venv\Scripts\python.exe run.py
