# Discovery-pET - Pruebas con APK Android

Este documento explica cómo generar e instalar un APK debug para probar Discovery-pET en otro celular sin tener que correr `flutter run` en cada equipo.

## Cuándo usar cada método

### Desarrollo rápido en tu celular principal

Usar:

```powershell
flutter run -d android --dart-define=DP_BACKEND_URL=https://dsuwojpgiuvkyvwbuyte.supabase.co --dart-define=DP_BACKEND_PUBLIC_KEY=TU_CLAVE_PUBLICA_SUPABASE
```

Luego usar:

```text
r = hot reload
R = hot restart
q = salir
```

### Prueba en otro celular

Usar APK debug:

```powershell
cd C:\Users\admin\Desktop\App\Discovery-pET\app\mobile
.\scripts\build_debug_apk.ps1 -BackendPublicKey "TU_CLAVE_PUBLICA_SUPABASE"
```

El APK queda en:

```text
app/mobile/dist/discovery-pet-debug.apk
```

## Instalación en otro celular

Opciones:

1. Enviar el archivo APK por cable USB, Drive, Telegram, WhatsApp Web o correo.
2. Abrir el archivo desde el celular.
3. Android va a pedir permitir instalación desde esa fuente.
4. Aceptar e instalar.

## Consideraciones

- Este APK es de debug, no sirve para publicar en Play Store.
- El otro celular no necesita Flutter instalado.
- Cada vez que se quiera probar una versión nueva, se genera otro APK y se instala encima.
- Para instalar encima sin perder sesión/datos, el package name debe mantenerse igual: `com.discoverypet.mobile`.
- Si Android bloquea la instalación, habilitar `Instalar apps desconocidas` para la app desde donde se abre el APK.

## Prueba con dos usuarios

Celular A:

```text
Usuario A configura alertas por zona.
```

Celular B:

```text
Usuario B publica un reporte dentro de esa zona.
```

Celular A:

```text
Mis alertas debería mostrar la alerta generada.
```

## Recomendación operativa

Para desarrollo diario:

```text
- Celular principal: flutter run + hot reload.
- Segundo celular: APK debug.
```

Más adelante, cuando el MVP esté más estable, conviene crear builds release firmadas y distribuir por Firebase App Distribution o Play Console Internal Testing.
