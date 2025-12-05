# Dokploy Deployment Configuration for Fizzy

## Variables de Entorno Requeridas

En Dokploy, configura estas variables de entorno:

```env
# Required
RAILS_ENV=production
RAILS_MASTER_KEY=your-master-key-here
SECRET_KEY_BASE=your-secret-key-base-here

# Single Tenant Mode
SINGLE_TENANT=true

# Hosts (reemplaza con tu dominio)
ALLOWED_HOST_DOMAINS=fizzy.krico.dev,krico.dev
MAILER_HOST=fizzy.krico.dev

# Database (SQLite por defecto)
DATABASE_ADAPTER=sqlite

# Rails Settings (requeridas para assets y logs)
RAILS_LOG_LEVEL=info
RAILS_SERVE_STATIC_FILES=true
RAILS_LOG_TO_STDOUT=true

# SMTP Configuration (OPCIONAL - si no se configura, los emails no se enviarán pero la app funcionará)
# Sin SMTP, el login magic link solo funcionará en modo desarrollo
# SMTP_HOST=smtp.example.com
# SMTP_PORT=587
# SMTP_USERNAME=your-smtp-user
# SMTP_PASSWORD=your-smtp-password
# SMTP_DOMAIN=krico.dev

# Asset Host (opcional, solo si usas CDN)
# ASSET_HOST=https://cdn.krico.dev
```

## Configuración en Dokploy

### 1. Crear la Aplicación

1. En Dokploy, crea una nueva aplicación tipo **Docker**
2. Selecciona tu repositorio Git
3. Configura el **Dockerfile**: `Dockerfile` (en la raíz)

### 2. Puerto de Exposición

**IMPORTANTE**: Configura el puerto interno como **3000** (no 80)

Esto es porque Thruster escucha en puerto 80 dentro del contenedor, pero Rails por defecto está en 3000. Para Dokploy es mejor usar directamente Rails.

**Solución**: Agrega en las variables de entorno de Dokploy:
```
PORT=3000
```

O modifica el **CMD** en el build para usar directamente Rails sin Thruster.

### 3. Comando de Inicio (Override)

Si los assets no cargan, usa este comando personalizado en lugar del CMD del Dockerfile:

```bash
./bin/rails server -b 0.0.0.0 -p 3000
```

Esto bypasea Thruster y usa directamente Puma.

### 4. Health Check

Configura el health check en:
```
Path: /up
Port: 3000
```

### 5. Volúmenes (Opcional)

Para persistir la base de datos SQLite:
```
/rails/storage -> Volumen persistente
```

## Troubleshooting Assets

### Problema 1: Assets no se cargan (404) con Cloudflare Tunnels

**Causa**: Rails no está sirviendo archivos estáticos en producción

**Solución Completa**:

1. **Variables de entorno en Dokploy**:
```env
RAILS_SERVE_STATIC_FILES=true
RAILS_LOG_TO_STDOUT=true
RAILS_LOG_LEVEL=info
```

Estas variables están ya incluidas en el `docker-compose.prod.yml` actualizado.

2. **Archivos actualizados para Propshaft**:
- `app/assets/stylesheets/app.css` - Los `@import` ahora usan `@import url()` 
- `config/environments/production.rb` - Habilitado public_file_server
- `config/initializers/assets.rb` - Configuración de precompilación

3. **Reconstruir y desplegar**:
```bash
# En Dokploy, forzar rebuild sin caché
docker build --no-cache -t fizzy .
```

**Verificación**: 
1. Después de desplegar, verifica en los logs de Dokploy que aparezca: `Serving static files`
2. Prueba acceder directamente a un asset: `https://fizzy.krico.dev/assets/app.css`
3. Verifica que los CSS importados también se cargan: `https://fizzy.krico.dev/assets/base.css`
4. Si algunos archivos CSS no se encuentran, verifica que el build incluyó: `rails assets:precompile`

### Problema 2: Error 500 en /session (Magic Link)

**Causa**: El mailer no está configurado correctamente en producción

**Solución**: 

**Opción 1 - Configurar SMTP (Recomendado para producción real)**:
```env
MAILER_HOST=fizzy.krico.dev
SMTP_HOST=smtp.gmail.com  # o tu proveedor SMTP
SMTP_PORT=587
SMTP_USERNAME=tu-email@gmail.com
SMTP_PASSWORD=tu-app-password
SMTP_DOMAIN=krico.dev
```

**Opción 2 - Deshabilitar envío de emails (Solo para testing)**:
Si no configuras SMTP, la aplicación ahora manejará el error gracefully y no crasheará, pero los magic links no se enviarán por email. Esto es útil para testing inicial pero no para producción real.

**Nota**: Sin SMTP configurado, el sistema de autenticación magic link no funcionará para usuarios reales.

### Problema 3: Thruster no funciona en Dokploy

**Causa**: Conflicto de puertos

**Solución**: Usa Rails directamente sin Thruster:
```bash
# En Dokploy, configura el comando de inicio como:
./bin/rails server -b 0.0.0.0 -p 3000
```

### Problema 4: Error "Could not find table 'solid_cache_entries'"

**Causa**: Las tablas de Solid Cache/Queue/Cable no existen en la base de datos SQLite

**Solución**: 

El `docker-entrypoint` ahora carga automáticamente los schemas necesarios en el primer inicio. Si ya tienes un despliegue con este error:

1. **Elimina el archivo marker** para forzar la reinicialización:
```bash
# En Dokploy, ejecuta en el contenedor:
rm /rails/storage/.db_seeded
```

2. **Reinicia el contenedor** en Dokploy

3. **O manualmente carga los schemas**:
```bash
# Dentro del contenedor:
./bin/rails db:schema:load:cache
./bin/rails db:schema:load:queue
./bin/rails db:schema:load:cable
```

**Para deployments nuevos**: El entrypoint ahora maneja esto automáticamente.

### Problema 5: Assets precompilados no se encuentran

**Causa**: Assets no se copiaron correctamente

**Solución**: Verifica en los logs del build que veas:
```
I, [timestamp] INFO -- : Writing /rails/public/assets/...
```

Si no aparece, fuerza la recompilación:
```bash
docker build --no-cache -t fizzy .
```

## Configuración Recomendada para Dokploy

### Opción 1: Sin Thruster (Recomendado para Dokploy)

Crea un archivo `Dockerfile.dokploy`:

```dockerfile
# syntax=docker/dockerfile:1
FROM ruby:3.4.7-slim AS base
WORKDIR /rails

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libjemalloc2 libvips sqlite3 libssl-dev && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development"

FROM base AS build
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libyaml-dev pkg-config && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache

COPY . .
RUN bundle exec bootsnap precompile -j 1 app/ lib/
RUN SECRET_KEY_BASE_DUMMY=1 RAILS_ENV=production ./bin/rails assets:precompile

FROM base
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash
USER 1000:1000

COPY --chown=rails:rails --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --chown=rails:rails --from=build /rails /rails

ENTRYPOINT ["/rails/bin/docker-entrypoint"]

EXPOSE 3000
CMD ["./bin/rails", "server", "-b", "0.0.0.0", "-p", "3000"]
```

Y en Dokploy usa: `Dockerfile.dokploy`

### Opción 2: Con Thruster (Avanzado)

Si quieres usar Thruster, necesitas configurar:

1. **Puerto interno**: 80
2. **Variables de entorno**:
   ```env
   THRUSTER_HTTP_PORT=80
   ```
3. **Nginx/Proxy**: Dokploy debe proxear al puerto 80 del contenedor

## Verificación Post-Deploy

Después de desplegar, verifica:

1. **Assets compilados**:
   ```bash
   docker exec <container> ls -la /rails/public/assets
   ```

2. **Logs de Rails**:
   ```bash
   docker logs <container> -f
   ```

3. **Test de assets**:
   ```bash
   curl https://fuzzy.krico.dev/assets/application-[hash].css
   ```

## Configuración Nginx (Si aplica)

Si Dokploy usa Nginx como proxy, verifica que tenga:

```nginx
location /assets/ {
    proxy_pass http://container:3000;
    proxy_set_header Host $host;
    proxy_cache_valid 200 1y;
    add_header Cache-Control "public, immutable";
}
```

## Comandos Útiles

```bash
# Rebuild sin cache
docker build --no-cache -t fizzy .

# Verificar assets en el contenedor
docker run --rm fizzy ls -la /rails/public/assets

# Ver variables de entorno
docker run --rm fizzy env | grep RAILS

# Probar localmente con mismo setup de Dokploy
docker run -p 3000:3000 \
  -e RAILS_ENV=production \
  -e SECRET_KEY_BASE=test \
  -e SINGLE_TENANT=true \
  -e ALLOWED_HOST_DOMAINS=localhost \
  -e RAILS_SERVE_STATIC_FILES=true \
  fizzy ./bin/rails server -b 0.0.0.0 -p 3000
```

## Checklist de Deployment

- [ ] Variables de entorno configuradas
- [ ] `RAILS_SERVE_STATIC_FILES=true` establecido
- [ ] `ALLOWED_HOST_DOMAINS` incluye tu dominio
- [ ] Puerto configurado a 3000
- [ ] Assets precompilados en build
- [ ] Health check configurado
- [ ] Dominio apuntando correctamente
- [ ] SSL/TLS activo

## Soporte

Si los assets aún no cargan después de todo esto:

1. Revisa los logs del contenedor
2. Verifica que `/rails/public/assets` tenga archivos
3. Confirma que `RAILS_SERVE_STATIC_FILES=true`
4. Prueba acceder directamente a: `https://fuzzy.krico.dev/up`
5. Revisa los logs de Nginx/Proxy de Dokploy
