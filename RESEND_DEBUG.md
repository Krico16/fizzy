# Debug de Resend Email Integration

## Pasos para verificar que Resend está funcionando:

### 1. Verificar variables de entorno en Dokploy

Asegúrate de que estas variables estén configuradas:

```bash
RESEND_API_KEY=re_xxxxxxxxxxxxxxxxxxxxxxxxxx
MAILER_HOST=tu-dominio.com
RAILS_ENV=production
```

### 2. Reconstruir la imagen de Docker

Después de los cambios, reconstruye la imagen:

```bash
docker compose -f docker-compose.prod.yml build
```

O en Dokploy, haz un nuevo deploy.

### 3. Verificar logs de inicio

Cuando la aplicación arranque, deberías ver estos mensajes en los logs:

```
🔧 Registering Resend delivery method for ActionMailer
✅ Resend delivery method registered successfully
📧 Configuring email delivery with Resend API
✅ Email delivery method set to: resend
```

### 4. Verificar logs al enviar un email

Cuando se intente enviar un email, verás:

**Si funciona:**
```
🚀 Attempting to send email via Resend API
   To: [email@example.com]
   Subject: Your subject here
✅ Email sent successfully via Resend API
   Response: {...}
```

**Si falla:**
```
❌ Resend API error: ErrorClass - error message
   Backtrace: ...
```

### 5. Verificar que la API key es correcta

Puedes verificar en la consola de Rails:

```ruby
# Conectarse al contenedor
docker compose -f docker-compose.prod.yml exec app bin/rails console

# En la consola de Rails
ENV["RESEND_API_KEY"]
# => Debería mostrar tu API key

ActionMailer::Base.delivery_method
# => Debería mostrar :resend
```

### 6. Enviar un email de prueba

Desde la consola de Rails:

```ruby
MagicLinkMailer.sign_in_instructions(MagicLink.first).deliver_now
```

### 7. Errores comunes

**Error: "API key not found"**
- Verifica que RESEND_API_KEY esté configurada correctamente
- Verifica que empiece con "re_"

**Error: "Domain not verified"**
- Ve a Resend dashboard y verifica tu dominio
- Hasta que esté verificado, solo puedes enviar a emails de prueba

**Error: "From address not verified"**
- La dirección "from" debe usar un dominio verificado en Resend
- Configura MAILER_FROM_ADDRESS con tu dominio verificado

### 8. Verificar en Resend Dashboard

- Ve a https://resend.com/emails
- Deberías ver los emails enviados allí
- Si no aparecen, el problema es en la configuración de Rails

## Comandos útiles

```bash
# Ver logs en tiempo real
docker compose -f docker-compose.prod.yml logs -f app

# Ver solo logs de email
docker compose -f docker-compose.prod.yml logs app | grep -E "Resend|Email|resend"

# Reiniciar el contenedor
docker compose -f docker-compose.prod.yml restart app
```
