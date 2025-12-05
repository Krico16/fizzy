# Fizzy - Production Deployment Guide

Esta guía te ayudará a desplegar Fizzy en modo producción usando Docker.

## 📋 Requisitos Previos

- Docker Engine 20.10+
- Docker Compose V2
- Puerto 80 disponible (o modificar en `docker-compose.prod.yml`)
- Al menos 2GB de RAM libre
- 10GB de espacio en disco

## 🚀 Pasos para el Deployment

### 1. Generar Claves de Seguridad

Primero necesitas generar las claves secretas:

```bash
# Generar SECRET_KEY_BASE
docker run --rm ruby:3.4.7-slim ruby -r securerandom -e 'puts SecureRandom.hex(64)'

# Generar RAILS_MASTER_KEY (o usar la existente de config/master.key)
docker run --rm ruby:3.4.7-slim ruby -r securerandom -e 'puts SecureRandom.hex(32)'
```

### 2. Configurar Variables de Entorno

Copia el archivo de ejemplo y edítalo con tus valores:

```bash
# En Linux/Mac
cp .env.production.example .env.production

# En Windows
copy .env.production.example .env.production
```

Edita `.env.production` y completa:
- `RAILS_MASTER_KEY` - La clave maestra de Rails
- `SECRET_KEY_BASE` - La clave secreta base
- `ALLOWED_HOST_DOMAINS` - Tu dominio (ej: `myapp.com,www.myapp.com`)
- Configuración SMTP para emails

**⚠️ IMPORTANTE**: Nunca subas `.env.production` a git!

### 3. Desplegar

#### En Linux/Mac:
```bash
chmod +x bin/deploy-production
./bin/deploy-production
```

#### En Windows:
```cmd
bin\deploy-production.bat
```

#### Manualmente:
```bash
# Cargar variables de entorno
set -a
source .env.production
set +a

# Build y deploy
docker compose -f docker-compose.prod.yml build
docker compose -f docker-compose.prod.yml up -d
```

### 4. Verificar el Deployment

```bash
# Ver el estado de los contenedores
docker compose -f docker-compose.prod.yml ps

# Ver logs en tiempo real
docker compose -f docker-compose.prod.yml logs -f app

# Verificar salud de la aplicación
curl http://localhost/up
```

La aplicación estará disponible en: **http://localhost** (o tu dominio configurado)

## 🔐 Primer Acceso

1. Accede a: http://localhost
2. Ingresa el email: **dev@localhost**
3. Revisa los logs para obtener el magic link:
   ```bash
   docker compose -f docker-compose.prod.yml logs app | grep magic
   ```

4. O ejecuta en la consola de Rails:
   ```bash
   docker compose -f docker-compose.prod.yml exec app ./bin/rails console
   
   # En la consola:
   identity = Identity.find_by(email_address: 'dev@localhost')
   magic_link = identity.magic_links.create!(purpose: :login, expires_at: 1.hour.from_now)
   puts "http://localhost/session/magic_link/#{magic_link.code}"
   ```

## 🔧 Comandos Útiles

### Gestión de Contenedores

```bash
# Detener la aplicación
docker compose -f docker-compose.prod.yml down

# Reiniciar la aplicación
docker compose -f docker-compose.prod.yml restart

# Ver logs
docker compose -f docker-compose.prod.yml logs -f app

# Ver uso de recursos
docker stats
```

### Gestión de la Base de Datos

```bash
# Backup de la base de datos
docker compose -f docker-compose.prod.yml exec app \
  sqlite3 /rails/storage/production.sqlite3 ".backup '/rails/storage/backup.db'"

# Restaurar backup
docker compose -f docker-compose.prod.yml exec app \
  sqlite3 /rails/storage/production.sqlite3 ".restore '/rails/storage/backup.db'"

# Consola de Rails
docker compose -f docker-compose.prod.yml exec app ./bin/rails console

# Ejecutar migraciones
docker compose -f docker-compose.prod.yml exec app ./bin/rails db:migrate
```

### Limpieza

```bash
# Detener y eliminar contenedores
docker compose -f docker-compose.prod.yml down

# Detener y eliminar contenedores + volúmenes (¡CUIDADO! Borra datos)
docker compose -f docker-compose.prod.yml down -v

# Limpiar imágenes antiguas
docker image prune -a
```

## 📊 Monitoreo

### Health Check

El contenedor tiene un health check incorporado:
```bash
docker compose -f docker-compose.prod.yml ps
```

### Logs

```bash
# Ver todos los logs
docker compose -f docker-compose.prod.yml logs -f

# Solo logs de errores
docker compose -f docker-compose.prod.yml logs -f | grep ERROR

# Últimas 100 líneas
docker compose -f docker-compose.prod.yml logs --tail=100
```

### Métricas

```bash
# Uso de CPU y memoria
docker stats fizzy-app-1

# Espacio en disco de volúmenes
docker system df -v
```

## 🔄 Actualización

Para actualizar a una nueva versión:

```bash
# 1. Hacer backup de la base de datos
docker compose -f docker-compose.prod.yml exec app \
  sqlite3 /rails/storage/production.sqlite3 ".backup '/tmp/backup-$(date +%Y%m%d).db'"

# 2. Copiar backup fuera del contenedor
docker cp fizzy-app-1:/tmp/backup-$(date +%Y%m%d).db ./backups/

# 3. Actualizar el código
git pull

# 4. Redesplegar
./bin/deploy-production
# o en Windows: bin\deploy-production.bat
```

## 🌐 Configuración con Dominio Real

### Con Nginx como Reverse Proxy

```nginx
server {
    listen 80;
    server_name yourdomain.com www.yourdomain.com;
    
    location / {
        proxy_pass http://localhost:80;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### Con Traefik

Agrega labels al servicio en `docker-compose.prod.yml`:
```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.fizzy.rule=Host(`yourdomain.com`)"
  - "traefik.http.routers.fizzy.entrypoints=websecure"
  - "traefik.http.routers.fizzy.tls.certresolver=letsencrypt"
```

## 🔒 Seguridad

### Recomendaciones para Producción

1. **SSL/TLS**: Usa un reverse proxy (Nginx/Traefik) con certificados SSL
2. **Firewall**: Limita el acceso al puerto 80 solo desde el reverse proxy
3. **Backups**: Automatiza backups regulares de la base de datos
4. **Monitoreo**: Implementa alertas para errores y caídas
5. **Actualizaciones**: Mantén Docker y la aplicación actualizados

### Variables Sensibles

Asegúrate de proteger:
- `.env.production` - Nunca lo subas a git
- `config/master.key` - Mantén en secreto
- Backups de base de datos - Encriptar si contienen datos sensibles

## 🐛 Solución de Problemas

### La aplicación no inicia

```bash
# Ver logs completos
docker compose -f docker-compose.prod.yml logs app

# Verificar variables de entorno
docker compose -f docker-compose.prod.yml exec app env | grep RAILS
```

### Error de base de datos

```bash
# Resetear base de datos (¡CUIDADO! Borra datos)
docker compose -f docker-compose.prod.yml exec app rm /rails/storage/.db_seeded
docker compose -f docker-compose.prod.yml restart app
```

### Problema con migraciones

```bash
# Ver estado de migraciones
docker compose -f docker-compose.prod.yml exec app ./bin/rails db:migrate:status

# Ejecutar migraciones manualmente
docker compose -f docker-compose.prod.yml exec app ./bin/rails db:migrate
```

### Puerto 80 en uso

Modifica el puerto en `docker-compose.prod.yml`:
```yaml
ports:
  - "8080:80"  # Usar puerto 8080 en lugar de 80
```

## 📈 Escalabilidad

Para manejar más tráfico:

1. **Usar PostgreSQL/MySQL** en lugar de SQLite:
   ```yaml
   environment:
     - DATABASE_URL=postgresql://user:pass@host/db
   ```

2. **Agregar Redis** para cache y jobs:
   ```yaml
   environment:
     - REDIS_URL=redis://redis:6379/0
   ```

3. **Múltiples instancias** con load balancer

## 📞 Soporte

Para problemas o preguntas:
- Revisa logs: `docker compose -f docker-compose.prod.yml logs -f`
- Consulta la documentación: `SINGLE_TENANT.md`
- Reporta issues en GitHub

## 📄 Licencia

Ver archivo LICENSE.md
