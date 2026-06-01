# Discovery-pET - Preparación para Firebase Cloud Messaging

Este documento describe el camino para activar notificaciones push reales en Android.

## Estado actual

La app ya tiene:

- Preferencias de alerta por zona.
- Eventos internos de alerta en `alert_events`.
- Bandeja `Mis alertas`.
- Supabase Realtime para actualizar pantallas abiertas.
- Tabla `user_devices` preparada para guardar tokens push.

Todavía no se activó Firebase en Flutter porque falta crear el proyecto Firebase y descargar el archivo real `google-services.json`.

## Tabla de dispositivos

La migración `0015_create_user_devices_for_push_notifications.sql` crea:

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

Uso esperado:

- Cada usuario puede registrar uno o más dispositivos.
- Cada dispositivo guarda un token FCM.
- Cuando se genera un evento en `alert_events`, una función futura podrá buscar dispositivos activos y enviar push.

## Pasos para crear Firebase

1. Entrar a Firebase Console.
2. Crear proyecto: `Discovery-pET`.
3. Agregar app Android.
4. Package name:

```text
com.discoverypet.mobile
```

5. Descargar:

```text
google-services.json
```

6. Colocar el archivo en:

```text
app/mobile/android/app/google-services.json
```

7. No subir ese archivo si contiene datos sensibles o si se prefiere manejarlo por CI/CD.

## Próximos cambios Flutter

Cuando esté `google-services.json`, agregar:

```yaml
firebase_core
firebase_messaging
```

Luego:

- Inicializar Firebase en `main.dart`.
- Pedir permiso de notificaciones.
- Obtener token FCM.
- Registrar token en `user_devices`.
- Actualizar `last_seen_at` al iniciar app.

## Próximo backend

Crear una Edge Function o mecanismo backend para:

1. Detectar nuevo `alert_events` pendiente.
2. Buscar dispositivos activos del usuario.
3. Enviar push con FCM.
4. Marcar evento como `sent` si corresponde.

## Nota operativa

Hasta activar FCM, la app ya puede operar con:

- Bandeja interna de alertas.
- Realtime mientras la app está abierta.
- Recalcular alertas manualmente.
