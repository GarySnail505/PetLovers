$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

if (-not (Test-Path ".venv")) {
    py -m venv .venv
}

& .\.venv\Scripts\python.exe -m pip install --upgrade pip
& .\.venv\Scripts\python.exe -m pip install -r requirements.txt

Push-Location frontend
try {
    npm install
    npm run build
}
finally {
    Pop-Location
}

if (-not (Test-Path ".env")) {
    Copy-Item ".env.example" ".env"
    Write-Host "Se creó .env. Configure la identidad y credenciales del nodo local." -ForegroundColor Yellow
}

Write-Host "Instalación completada." -ForegroundColor Green
Write-Host "Para iniciar PetLovers ejecute: .\run.ps1"
