# Fizzy - Single Tenant Mode

Este proyecto ha sido configurado para funcionar en modo **single-tenant** para facilitar el desarrollo local sin necesidad de configurar múltiples cuentas o subdominios.

## 🚀 Inicio Rápido

### Requisitos Previos
- Docker y Docker Compose instalados
- Puertos 3006 y 8025 disponibles

### Levantar la Aplicación

```bash
docker compose up -d
```

La aplicación estará disponible en: **http://localhost:3006**

### Detener la Aplicación

```bash
docker compose down
```

## 📋 Características del Modo Single-Tenant

- ✅ **Sin configuración de multi-tenancy**: No necesitas agregar IDs de cuenta en la URL
- ✅ **Acceso directo en localhost**: Funciona directamente en `http://localhost:3006`
- ✅ **Base de datos SQLite**: Datos persistentes en el volumen `storage`
- ✅ **Datos de prueba incluidos**: Cuenta, usuario y board creados automáticamente
- ✅ **MailHog integrado**: Ver emails de prueba en `http://localhost:8025`

## 👤 Credenciales de Desarrollo

Para acceder a la aplicación:

1. Ve a: http://localhost:3006
2. Ingresa el email: **dev@localhost**
3. Recibirás un magic link que puedes:
   - Ver en los logs: `docker compose logs app | grep "magic"`
   - Ver en MailHog UI: http://localhost:8025

## 🔧 Comandos Útiles

### Ver Logs en Tiempo Real
```bash
docker compose logs -f app
```

### Acceder a la Consola de Rails
```bash
docker compose exec app ./bin/rails console
```

### Resetear la Base de Datos
```bash
docker compose exec app rm /rails/storage/.db_seeded
docker compose restart app
```

### Ejecutar Tests
```bash
docker compose exec app ./bin/rails test
```

## 📁 Estructura de Datos

La aplicación crea automáticamente:
- **Cuenta**: "Default Account" (ID: 1)
- **Usuario**: Dev User (dev@localhost) con rol de owner
- **Board**: "Tasks" con acceso completo
- **Columnas**: Triage, In Progress, Done

## 🌐 Servicios Disponibles

| Servicio | URL | Descripción |
|----------|-----|-------------|
| Aplicación Web | http://localhost:3006 | Interfaz principal de Fizzy |
| MailHog UI | http://localhost:8025 | Visualizador de emails de desarrollo |
| MailHog SMTP | localhost:1025 | Servidor SMTP para la aplicación |

## ⚙️ Configuración

La configuración de single-tenant se activa con la variable de entorno:
```yaml
SINGLE_TENANT=true
```

Definida en `docker-compose.yml`

## 🔍 Solución de Problemas

### La aplicación no inicia
```bash
docker compose logs app
```

### Base de datos corrupta
```bash
docker compose down -v
docker compose up -d
```

### Cambios en el código no se reflejan
El código está montado como volumen, los cambios deberían reflejarse automáticamente. Si no:
```bash
docker compose restart app
```

## 📝 Notas

- Este modo está diseñado **solo para desarrollo local**
- No usar en producción
- Los datos persisten en el volumen Docker `storage_data`
- Para volver al modo multi-tenant, elimina o cambia `SINGLE_TENANT=true` en `docker-compose.yml`

## 🎯 Diferencias con el Modo Multi-Tenant

| Característica | Multi-Tenant | Single-Tenant |
|----------------|--------------|---------------|
| URL | `fizzy.localhost:3006/{account_id}/` | `localhost:3006/` |
| Múltiples Cuentas | ✅ Sí | ❌ No (una cuenta por defecto) |
| Configuración DNS | Requerida | ❌ No requerida |
| Complejidad | Alta | Baja |
| Uso | Producción | Desarrollo local |
