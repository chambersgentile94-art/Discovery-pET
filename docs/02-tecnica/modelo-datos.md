# Modelo de datos - Discovery-pET

## Objetivo

Definir la estructura inicial de base de datos para el MVP.

## Entidades principales

- profiles
- animal_reports
- report_images
- report_updates
- adoption_requests
- report_flags

## Tabla: profiles

Guarda información pública y operativa de cada usuario autenticado.

Campos:

- id: UUID vinculado a auth.users.
- full_name: nombre visible.
- email: correo.
- phone: teléfono opcional.
- role: user, volunteer, shelter, vet, admin.
- city: ciudad.
- avatar_url: imagen de perfil.
- is_verified: indica si fue validado.
- created_at.
- updated_at.

## Tabla: animal_reports

Guarda los casos publicados.

Campos:

- id.
- created_by.
- animal_type: dog, cat, other.
- category: lost, seen, abandoned, rescued, adoption, injured.
- title.
- description.
- status.
- urgency.
- latitude.
- longitude.
- approximate_address.
- contact_phone.
- show_contact_phone.
- is_public.
- created_at.
- updated_at.
- closed_at.

## Tabla: report_images

Guarda imágenes asociadas a reportes.

Campos:

- id.
- report_id.
- image_url.
- storage_path.
- created_at.

## Tabla: report_updates

Guarda comentarios y cambios de estado.

Campos:

- id.
- report_id.
- user_id.
- comment.
- old_status.
- new_status.
- created_at.

## Tabla: adoption_requests

Guarda solicitudes de adopción.

Campos:

- id.
- report_id.
- requester_id.
- message.
- status.
- created_at.

## Tabla: report_flags

Guarda denuncias de publicaciones.

Campos:

- id.
- report_id.
- user_id.
- reason.
- status.
- created_at.

## Estados sugeridos

- reported
- searching
- recently_seen
- someone_going
- sheltered
- vet_care
- foster_home
- adoption
- adopted
- reunited
- closed_unresolved
- invalid

## Categorías sugeridas

- lost
- seen
- abandoned
- rescued
- adoption
- injured

## Urgencias sugeridas

- low
- medium
- high
