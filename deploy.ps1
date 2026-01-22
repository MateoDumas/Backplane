$ErrorActionPreference = "Continue"

Write-Host "Iniciando Despliegue a Produccion..." -ForegroundColor Green

Write-Host "Deteniendo entorno de desarrollo..."
docker-compose down

Write-Host "Construyendo y levantando servicios (PROD)..."
docker-compose -f docker-compose.prod.yml up -d --build

if ($LASTEXITCODE -eq 0) {
    Write-Host "Despliegue Exitoso!" -ForegroundColor Green
    Write-Host "Frontend disponible en: http://localhost"
    Write-Host "API Gateway disponible en: http://localhost:8080"
} else {
    Write-Host "Error en el despliegue." -ForegroundColor Red
}
