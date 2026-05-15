# Próximo bloque de desarrollo

## Estado esperado antes de iniciar

Antes de continuar con pantallas y servicios, el repositorio debe contener la app Flutter generada en:

```text
app/mobile/
```

Archivos mínimos esperados:

```text
app/mobile/pubspec.yaml
app/mobile/lib/main.dart
app/mobile/android/
app/mobile/web/
```

## Bloque 1: estructura profesional de Flutter

Crear la siguiente estructura:

```text
app/mobile/lib/
  main.dart
  app.dart
  config/
    app_config.dart
  models/
    animal_report.dart
  screens/
    home_screen.dart
    map_screen.dart
    report_form_screen.dart
    adoption_screen.dart
    profile_screen.dart
  services/
    supabase_service.dart
  widgets/
    home_action_card.dart
```

## Bloque 2: navegación inicial

Reemplazar la app demo por una app con navegación entre:

- Inicio
- Mapa
- Reportar animal
- Adopciones
- Perfil

## Bloque 3: conexión Supabase

Preparar:

- Lectura de variables de entorno.
- Inicialización de Supabase.
- Servicio base para reportes.

## Bloque 4: formulario de reportes

Primera versión del formulario:

- Tipo de animal.
- Categoría del reporte.
- Título.
- Descripción.
- Urgencia.
- Ubicación manual o actual.

## Bloque 5: mapa

Primera versión del mapa:

- Mostrar pantalla de mapa.
- Preparar marcador de prueba.
- Luego conectar marcadores reales desde Supabase.

## Criterio de avance

No avanzar con servicios reales hasta que `app/mobile/pubspec.yaml` esté confirmado en GitHub.
