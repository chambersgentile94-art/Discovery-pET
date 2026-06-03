# Discovery-pET - Preparación Firebase Cloud Messaging

Este documento describe el camino para activar notificaciones push reales en Android usando Firebase Cloud Messaging.

## Estado actual

La app ya tiene una bandeja interna de alertas:

- `alert_preferences`: configuración de zona, radio y categorías.
- `alert_events`: eventos generados cuando un reporte coincide con una zona.
- `Mis alertas`: pantalla interna para ver, abrir, descartar y marcar alertas como vistas.
- Supabase Realtime: refresco de alertas dentro de la app.
- `user_devices`: tabla preparada para guardar tokens push por usuario/dispositivo.

Todavía no se envían push notifications reales al sistema Android.

## Tabla preparada

La migración es:

```text
backend/supabase/migrations/0015_create_user_devices_for_push_notifications.sql
```

Tabla:

```text
public.user_devices
```

Campos principales:

```text
user_id
platform
device_id
push_token
app_version
is_active
last_seen_at
```

Cada usuario solo puede ver y actualizar sus propios dispositivos mediante RLS.

## Pasos para activar Firebase

### 1. Crear proyecto Firebase

Entrar a Firebase Console y crear un proyecto para Discovery-pET.

### 2. Agregar app Android

Usar el package name actual:

```text
com.discoverypet.mobile
```

Este package name debe coincidir con Android:

```text
app/mobile/android/app/build.gradle.kts
```

### 3. Descargar google-services.json

Firebase entrega el archivo:

```text
google-services.json
```

Debe colocarse en:

```text
app/mobile/android/app/google-services.json
```

Importante: este archivo no debería subirse al repositorio si contiene datos sensibles o si se quiere mantener separado por ambiente. Para builds automáticos se puede manejar como secreto de GitHub Actions.

### 4. Agregar dependencias Flutter

Dependencias esperadas:

```yaml
firebase_core
firebase_messaging
```

### 5. Configurar Android Gradle

Se debe agregar el plugin de Google Services en Android.

Archivos a revisar:

```text
app/mobile/android/settings.gradle.kts
app/mobile/android/build.gradle.kts
app/mobile/android/app/build.gradle.kts
```

### 6. Solicitar permisos de notificación

En Android 13+ se requiere permiso runtime para notificaciones.

Permiso Android:

```text
POST_NOTIFICATIONS
```

### 7. Registrar token FCM

Al iniciar sesión:

- Obtener token FCM.
- Guardarlo en `user_devices`.
- Actualizar `last_seen_at`.
- Marcar `is_active = true`.

Al cerrar sesión:

- Se puede marcar el dispositivo como inactivo.

### 8. Envío de push

Opciones posibles:

1. Supabase Edge Function que escucha o procesa eventos de `alert_events`.
2. Backend propio que lea `alert_events` pendientes y envíe FCM.
3. Job programado que procese pendientes.

Recomendación para MVP:

```text
Supabase Edge Function + Firebase Admin SDK / HTTP v1
```

## Flujo final deseado

```text
Usuario A configura alertas por zona.
Usuario B publica un reporte dentro del radio.
Supabase crea alert_event.
Backend busca dispositivos activos de Usuario A.
Backend envía push FCM.
Usuario A toca la notificación.
La app abre Mis alertas o detalle del reporte.
```

## Consideraciones de seguridad

- Nunca usar claves privadas de Firebase en la app móvil.
- La app solo guarda el token FCM del dispositivo.
- El envío push debe hacerse desde backend seguro.
- La service account de Firebase debe quedar en Supabase secrets o GitHub secrets, no en el repo.

## Pendiente

- Agregar dependencias Firebase.
- Configurar Android con `google-services.json`.
- Implementar `PushNotificationService` en Flutter.
- Registrar token en `user_devices`.
- Crear Edge Function para enviar push.
- Vincular alert_events con envío de notificaciones.
