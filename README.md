# Discovery-pET

Aplicación móvil para reportar, ubicar y dar seguimiento a mascotas perdidas, abandonadas, vistas en la calle o disponibles para adopción.

## Objetivo

Centralizar reportes comunitarios en un mapa colaborativo, permitiendo que usuarios, voluntarios, protectoras y administradores puedan actuar de forma coordinada.

## Alcance inicial del MVP

El MVP debe permitir:

1. Registro e inicio de sesión de usuarios.
2. Crear reportes de mascotas perdidas.
3. Crear reportes de animales vistos, abandonados o resguardados.
4. Subir fotos del animal.
5. Guardar ubicación del reporte.
6. Mostrar reportes en un mapa.
7. Abrir una ficha individual del caso.
8. Cambiar el estado del caso.
9. Reportar publicaciones inválidas.
10. Contar con una base mínima de moderación.

## Stack técnico propuesto

- App móvil: Flutter / Dart
- Backend: Supabase
- Base de datos: PostgreSQL
- Autenticación: Supabase Auth
- Archivos/fotos: Supabase Storage
- Mapas: Google Maps Flutter
- Notificaciones futuras: Firebase Cloud Messaging

## Estructura del repositorio

```text
Discovery-pET/
  app/
    mobile/
  backend/
    supabase/
      migrations/
      seed/
      policies/
  docs/
    00-gestion/
    01-funcional/
    02-tecnica/
    03-operacion/
    04-legal/
    05-ui-ux/
  assets/
  README.md
  CHANGELOG.md
```

## Inicio rápido para desarrollo local

### 1. Clonar el repositorio

```bash
git clone https://github.com/chambersgentile94-art/Discovery-pET.git
cd Discovery-pET
```

### 2. Crear app Flutter dentro de `app/mobile`

```bash
mkdir -p app
cd app
flutter create mobile
cd mobile
```

### 3. Agregar dependencias iniciales

```bash
flutter pub add supabase_flutter
flutter pub add google_maps_flutter
flutter pub add geolocator
flutter pub add image_picker
flutter pub add flutter_dotenv
```

### 4. Crear archivo de variables de entorno

Dentro de `app/mobile`, crear:

```bash
.env
```

Contenido esperado:

```env
SUPABASE_URL=https://TU-PROYECTO.supabase.co
SUPABASE_ANON_KEY=TU_PUBLIC_ANON_KEY
GOOGLE_MAPS_API_KEY=TU_API_KEY
```

No subir `.env` al repositorio.

### 5. Base de datos

Ejecutar las migraciones ubicadas en:

```text
backend/supabase/migrations/
```

## Estado del proyecto

Estado actual: inicialización de documentación y modelo de datos.

## Licencia

Pendiente de definir.
