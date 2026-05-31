# Discovery-pET - Changelog

Registro de cambios funcionales relevantes.

## Mayo 2026

### Base móvil

- Proyecto Flutter mobile inicial.
- Configuración de Supabase.
- Variables de entorno para backend.
- Pruebas Android por USB.

### Usuarios

- Login y registro.
- Perfil de usuario.
- Creación automática de perfil.
- Protección para evitar autoasignación de rol administrador.

### Reportes

- Creación de reportes.
- Categorías de animales.
- Ubicación por coordenadas.
- Foto desde cámara o galería.
- Storage de imágenes.
- Vista de mapa.
- Detalle de reporte.
- Mis reportes.
- Cierre de reportes.

### Mapa

- Se retiró Google Maps.
- Se adoptó OpenStreetMap con flutter_map.
- Selector de ubicación por mapa.
- Uso de ubicación actual del celular.

### Seguridad y base de datos

- RLS revisado en tablas principales.
- Policies de perfiles reforzadas.
- Policies de adopciones ajustadas.
- Policies de Storage ajustadas.
- Funciones internas movidas a schema privado cuando correspondía.
- Permisos de ejecución corregidos para evaluación de RLS.

### Adopciones

- Solicitudes de adopción.
- Gestión de solicitudes recibidas.
- Índice único para evitar solicitudes duplicadas.

### Moderación

- Denuncias de reportes.
- Vista de moderación para administradores.
- Ocultamiento de reportes inválidos.

### Alertas

- Preferencias de alerta por zona.
- Radio, coordenadas y categorías.
- Previsualización de reportes dentro de zona.
- Eventos de alerta automáticos.
- Recalcular alertas sobre reportes existentes.
- Bandeja Mis alertas.
- Marcar alerta como vista.
- Descartar alerta.
- Marcar pendientes como vistas.
- Actualización en tiempo real en Mis alertas.

### APK y CI

- Script local para APK debug.
- Workflow de GitHub Actions para APK debug descargable.
- Documentación de pruebas Android.

## Próximos pasos

- Contador de alertas en tiempo real en Inicio.
- Firebase Cloud Messaging.
- Tokens por dispositivo.
- Notificaciones push reales.
- Release firmado.
- Distribución interna.
- Mejoras visuales.
- Documentos legales básicos.
