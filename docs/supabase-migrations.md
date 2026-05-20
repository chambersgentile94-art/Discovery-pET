# Discovery-pET - Migraciones Supabase

Este documento describe cómo aplicar cambios de base de datos en Supabase para Discovery-pET.

## Estado actual

Las migraciones SQL viven en:

```text
backend/supabase/migrations/
```

Orden actual recomendado:

```text
0001_initial_schema.sql
0002_create_profile_on_signup.sql
0003_storage_report_images_policies.sql
0004_admin_moderation_policies.sql
0005_adoption_requests_owner_policies.sql
0006_report_contact_fields.sql
```

## Método manual por SQL Editor

Usar este método durante el MVP.

1. Entrar al proyecto en Supabase.
2. Ir a `SQL Editor`.
3. Crear una nueva query.
4. Copiar el contenido completo de la migración pendiente.
5. Ejecutar con `Run`.
6. Verificar en `Table Editor` o `Authentication`, según corresponda.

## Reglas operativas

- Ejecutar migraciones en orden numérico.
- No pegar secretos ni tokens dentro de archivos SQL.
- Antes de ejecutar SQL destructivo, revisar dos veces.
- Evitar `drop table`, `truncate` o deletes masivos salvo que esté explícitamente aprobado.
- Las migraciones nuevas deben ser idempotentes siempre que sea posible usando:

```sql
add column if not exists
create index if not exists
create or replace function
```

PostgreSQL no soporta `create policy if not exists`; para reejecutar policies usar previamente:

```sql
drop policy if exists "Nombre de policy" on public.nombre_tabla;
```

## Marcar usuario administrador

Para habilitar el módulo Moderación en la app:

```sql
update public.profiles
set role = 'admin'
where email = 'TU_EMAIL_DE_LOGIN';
```

Después cerrar sesión en la app, volver a ingresar y refrescar inicio.

## Migraciones automáticas con GitHub Actions

Pendiente de habilitar.

Secretos necesarios en GitHub:

```text
SUPABASE_ACCESS_TOKEN
SUPABASE_PROJECT_ID
SUPABASE_DB_PASSWORD
```

No cargar estos valores en el código ni compartirlos en chats.

## Checklist después de migrar

- Abrir app y probar login.
- Crear reporte con foto.
- Ver reporte en mapa.
- Probar seguimiento.
- Probar Mis reportes.
- Probar solicitud de adopción.
- Probar moderación si el usuario tiene rol admin.
