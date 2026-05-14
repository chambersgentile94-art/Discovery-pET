# Arquitectura técnica - Discovery-pET

## Objetivo

Definir una arquitectura simple, mantenible y escalable para el MVP de Discovery-pET.

## Componentes principales

```text
App Flutter
  |
  |-- Autenticación
  |-- Mapa
  |-- Cámara / galería
  |-- Formularios de reportes
  |-- Ficha de caso
  |
Supabase
  |-- Auth
  |-- PostgreSQL
  |-- Storage
  |-- Row Level Security
  |
Firebase Cloud Messaging
  |-- Notificaciones futuras
```

## App móvil

La aplicación móvil será desarrollada con Flutter.

Responsabilidades:

- Login y registro.
- Lectura y escritura de reportes.
- Subida de imágenes.
- Visualización de mapa.
- Gestión básica de perfil.
- Actualización de estados.

## Backend

El backend principal será Supabase.

Responsabilidades:

- Autenticación de usuarios.
- Base de datos PostgreSQL.
- Reglas de seguridad con RLS.
- Almacenamiento de imágenes.
- APIs automáticas para lectura/escritura.

## Base de datos

La base de datos usará PostgreSQL con tablas principales:

- profiles
- animal_reports
- report_images
- report_updates
- adoption_requests
- report_flags

## Storage

Las imágenes se guardarán en Supabase Storage.

Bucket sugerido:

```text
report-images
```

Estructura sugerida:

```text
report-images/{report_id}/{image_id}.jpg
```

## Seguridad

Medidas iniciales:

- RLS habilitado en todas las tablas.
- Los usuarios solo editan sus propios reportes.
- Los usuarios solo actualizan su propio perfil.
- Los reportes públicos pueden ser leídos por usuarios autenticados.
- Las denuncias quedan vinculadas al usuario autenticado.
- Las claves privadas nunca deben subirse al repositorio.

## Entornos

Entornos sugeridos:

- dev: desarrollo local.
- staging: pruebas controladas.
- production: operación real.

Para el MVP puede iniciarse solo con dev y production.

## Decisiones pendientes

- Elegir entre Google Maps y Mapbox de forma definitiva.
- Definir si la app permitirá lectura pública sin login.
- Definir política de notificaciones.
- Definir proceso de moderación operativo.
