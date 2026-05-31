# Discovery-pET - Estado actual del proyecto

Última actualización funcional: alertas internas, APK automático y distribución de pruebas.

## Objetivo del proyecto

Discovery-pET es una aplicación móvil para reportar, visualizar y dar seguimiento a animales perdidos, vistos en la calle, abandonados, heridos, resguardados o disponibles para adopción.

El objetivo inicial es construir un MVP funcional que permita:

- Registrar usuarios.
- Publicar reportes con foto, ubicación y categoría.
- Ver reportes en mapa.
- Ver detalle y seguimiento de casos.
- Gestionar reportes propios.
- Denunciar publicaciones.
- Moderar reportes desde usuarios administradores.
- Configurar alertas por zona.
- Generar alertas internas cuando un reporte coincide con una zona configurada.
- Instalar APK debug en celulares de prueba.

## Stack actual

### App móvil

- Flutter.
- Dart.
- Android como plataforma principal de pruebas.
- OpenStreetMap mediante `flutter_map`.
- Geolocator para ubicación actual.
- Image picker para fotos.
- Supabase Flutter para backend, Auth, Storage, Database y Realtime.

### Backend

- Supabase.
- PostgreSQL.
- Row Level Security activo.
- Storage público controlado por policies.
- Triggers y funciones SQL para alertas.

### CI/CD

- GitHub Actions.
- Workflow Flutter CI.
- Workflow Android Debug APK para generar APK descargable desde GitHub.

## Funcionalidades implementadas

### Autenticación

- Login.
- Registro.
- Sesión persistente mediante Supabase Auth.
- Perfil de usuario.

### Perfil

- Nombre.
- Email.
- Teléfono opcional.
- Ciudad.
- Rol.
- Protección para evitar autoasignación de `admin` desde la app/base.

### Reportes

- Crear reportes.
- Categorías:
  - Mascota perdida.
  - Animal visto.
  - Animal abandonado.
  - Animal resguardado.
  - En adopción.
  - Animal herido.
- Título.
- Descripción.
- Urgencia.
- Ubicación aproximada.
- Latitud y longitud.
- Selección de ubicación por mapa OpenStreetMap.
- Uso de ubicación actual del celular.
- Foto desde galería o cámara.
- Teléfono opcional visible por reporte.

### Mapa

- Vista de reportes públicos.
- Marcadores sobre OpenStreetMap.
- Sin dependencia de Google Maps.

### Mis reportes

- Visualización de reportes propios.
- Cierre de reportes.
- Seguimiento por estado.

### Detalle de reporte

- Visualización completa del caso.
- Foto.
- Ubicación.
- Datos de contacto si el creador decidió mostrarlo.
- Seguimiento / actualizaciones.
- Denuncia de publicación.
- Solicitud de adopción cuando corresponde.

### Moderación

- Tabla `report_flags`.
- Vista de denuncias pendientes para administradores.
- Acciones sobre denuncias/reportes.
- Policies de admin reforzadas mediante función privada.

### Adopciones

- Vista de reportes en categoría adopción.
- Solicitudes de adopción.
- Gestión de solicitudes recibidas para reportes propios.
- Índice único para evitar duplicación de solicitudes por usuario/reporte.

### Alertas por zona

- Tabla `alert_preferences`.
- Configuración por usuario:
  - Ciudad/zona.
  - Latitud.
  - Longitud.
  - Radio en km.
  - Categorías a notificar.
  - Activar/pausar alertas.
- Previsualización de reportes actuales dentro del radio configurado.
- Botón para elegir zona en mapa.
- Botón para usar ubicación actual.

### Eventos de alerta

- Tabla `alert_events`.
- Trigger automático al crear reportes nuevos.
- Cálculo de distancia mediante función SQL.
- Filtro por radio y categorías.
- Evita notificar al creador del reporte.
- Recalcular alertas manualmente sobre reportes ya existentes.
- Bandeja `Mis alertas`.
- Marcar alerta como vista.
- Descartar alerta.
- Marcar todas las pendientes como vistas.
- Actualización en tiempo real en pantalla `Mis alertas` mediante Supabase Realtime.

### APK de pruebas

- Script local:
  - `app/mobile/scripts/build_debug_apk.ps1`
- Workflow GitHub Actions:
  - `.github/workflows/android-debug-apk.yml`
- Artifact descargable:
  - `discovery-pet-debug-apk`

## Estado aproximado del MVP

Estimación actual:

```text
85% funcional para MVP interno de pruebas.
```

Falta principalmente:

- Push notifications reales con Firebase Cloud Messaging.
- Mejoras visuales finales.
- Flujo formal de recuperación de contraseña.
- Ajustes de UX.
- Política de privacidad y términos.
- Build release firmado.
- Publicación interna por Play Console o Firebase App Distribution.

## Próximos pasos recomendados

1. Terminar contador de alertas en tiempo real en Inicio.
2. Revisar CI de GitHub y corregir warnings/errores si aparecen.
3. Implementar Firebase Cloud Messaging.
4. Guardar tokens FCM por usuario/dispositivo.
5. Crear función/edge function para enviar push cuando se genere `alert_events`.
6. Mejorar pantalla de detalle de reporte.
7. Preparar release interno firmado.
