# Quick Start - Production Test

Para probar rápidamente el deployment de producción en tu máquina local:

## 1. Generar Claves (Una sola vez)

```powershell
# Generar SECRET_KEY_BASE
docker run --rm ruby:3.4.7-slim ruby -r securerandom -e "puts SecureRandom.hex(64)"

# Copiar el output y guardarlo
```

## 2. Crear Archivo .env.production

Crea el archivo `.env.production` con este contenido mínimo:

```env
# Reemplaza estos valores con los que generaste
SECRET_KEY_BASE=tu-secret-key-base-aqui
RAILS_MASTER_KEY=00000000000000000000000000000000

# Configuración básica
SINGLE_TENANT=true
ALLOWED_HOST_DOMAINS=localhost,127.0.0.1
RAILS_LOG_LEVEL=info

# SMTP (opcional para pruebas locales)
SMTP_HOST=smtp.example.com
SMTP_PORT=587
SMTP_USERNAME=user
SMTP_PASSWORD=pass
```

## 3. Deploy

### Windows:
```cmd
bin\deploy-production.bat
```

### Linux/Mac:
```bash
chmod +x bin/deploy-production
./bin/deploy-production
```

### O manualmente:
```bash
docker compose -f docker-compose.prod.yml build
docker compose -f docker-compose.prod.yml up -d
```

## 4. Acceder

1. Ve a: **http://localhost**
2. Email: **dev@localhost**
3. Obtén el magic link:
   ```bash
   docker compose -f docker-compose.prod.yml logs app | findstr magic
   ```

## 5. Monitoreo

```bash
# Ver logs
docker compose -f docker-compose.prod.yml logs -f

# Ver estado
docker compose -f docker-compose.prod.yml ps

# Detener
docker compose -f docker-compose.prod.yml down
```

## Diferencias Dev vs Prod

| Característica | Dev | Prod |
|----------------|-----|------|
| Puerto | 3006 | 80 |
| Hot reload | ✅ Sí | ❌ No |
| Assets precompilados | ❌ No | ✅ Sí |
| Jemalloc | ❌ No | ✅ Sí |
| Thruster | ✅ Sí | ✅ Sí |
| Optimización | Baja | Alta |

## Troubleshooting

### Puerto 80 en uso
Modifica en `docker-compose.prod.yml`:
```yaml
ports:
  - "8080:80"
```

### Ver errores de build
```bash
docker compose -f docker-compose.prod.yml build --progress=plain
```

### Resetear todo
```bash
docker compose -f docker-compose.prod.yml down -v
docker system prune -af
```
