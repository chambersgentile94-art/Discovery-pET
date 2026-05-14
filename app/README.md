# App móvil

La aplicación móvil de Discovery-pET se generará dentro de esta carpeta.

## Crear proyecto Flutter

Desde la raíz del repositorio:

```bash
cd app
flutter create mobile
cd mobile
```

## Dependencias iniciales

```bash
flutter pub add supabase_flutter
flutter pub add google_maps_flutter
flutter pub add geolocator
flutter pub add image_picker
flutter pub add flutter_dotenv
```

## Archivo de entorno local

Crear manualmente:

```text
app/mobile/.env
```

Contenido esperado:

```env
SUPABASE_URL=https://TU-PROYECTO.supabase.co
SUPABASE_ANON_KEY=TU_PUBLIC_ANON_KEY
GOOGLE_MAPS_API_KEY=TU_GOOGLE_MAPS_API_KEY
```

No subir `.env` al repositorio.
