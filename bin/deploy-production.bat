@echo off
REM Windows deployment script for Fizzy

echo.
echo ========================================
echo    Fizzy Production Deployment
echo ========================================
echo.

REM Check if .env.production exists
if not exist .env.production (
    echo ERROR: .env.production file not found!
    echo Please create .env.production from .env.production.example
    exit /b 1
)

echo [*] Building production image...
docker compose -f docker-compose.prod.yml build --no-cache

if errorlevel 1 (
    echo ERROR: Build failed!
    exit /b 1
)

echo.
echo [*] Stopping existing containers...
docker compose -f docker-compose.prod.yml down

echo.
echo [*] Starting production containers...
docker compose -f docker-compose.prod.yml up -d

echo.
echo [*] Waiting for application to start...
timeout /t 10 /nobreak > nul

echo.
echo ========================================
echo    Deployment Complete!
echo ========================================
echo.
echo Application URL: http://localhost
echo View logs: docker compose -f docker-compose.prod.yml logs -f
echo Stop app: docker compose -f docker-compose.prod.yml down
echo.
