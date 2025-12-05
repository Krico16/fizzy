@echo off
REM Fizzy Management Script for Windows

echo.
echo ========================================
echo         FIZZY MANAGEMENT
echo ========================================
echo.
echo [1] Start Development
echo [2] Start Production
echo [3] Stop Development
echo [4] Stop Production
echo [5] View Dev Logs
echo [6] View Prod Logs
echo [7] Status
echo [8] Cleanup All
echo [9] Exit
echo.
set /p choice="Select option: "

if "%choice%"=="1" goto dev_start
if "%choice%"=="2" goto prod_start
if "%choice%"=="3" goto dev_stop
if "%choice%"=="4" goto prod_stop
if "%choice%"=="5" goto dev_logs
if "%choice%"=="6" goto prod_logs
if "%choice%"=="7" goto status
if "%choice%"=="8" goto cleanup
if "%choice%"=="9" goto end

:dev_start
echo Starting Development Environment...
docker compose up -d
echo.
echo Development running at: http://localhost:3006
pause
goto end

:prod_start
if not exist .env.production (
    echo ERROR: .env.production not found!
    echo Create it from .env.production.example first
    pause
    goto end
)
echo Starting Production Environment...
docker compose -f docker-compose.prod.yml up -d
echo.
echo Production running at: http://localhost
pause
goto end

:dev_stop
echo Stopping Development...
docker compose down
pause
goto end

:prod_stop
echo Stopping Production...
docker compose -f docker-compose.prod.yml down
pause
goto end

:dev_logs
echo Development Logs (Ctrl+C to exit):
docker compose logs -f app
goto end

:prod_logs
echo Production Logs (Ctrl+C to exit):
docker compose -f docker-compose.prod.yml logs -f app
goto end

:status
echo.
echo === Container Status ===
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo.
echo === Images ===
docker images fizzy*
echo.
pause
goto end

:cleanup
echo.
echo WARNING: This will stop all containers and remove volumes!
set /p confirm="Are you sure? (yes/no): "
if not "%confirm%"=="yes" goto end
echo.
echo Stopping all containers...
docker compose down -v
docker compose -f docker-compose.prod.yml down -v
echo.
echo Cleaning up images...
docker image prune -f
echo.
echo Done!
pause
goto end

:end
