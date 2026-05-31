# Discovery-pET - APK automático desde GitHub Actions

Este documento explica cómo generar y descargar un APK debug desde GitHub, sin compilar localmente.

## Requisito previo

Cargar la clave pública de Supabase como secreto del repositorio:

```text
GitHub > Discovery-pET > Settings > Secrets and variables > Actions > New repository secret
```

Nombre:

```text
DP_BACKEND_PUBLIC_KEY
```

Valor:

```text
sb_publishable_...
```

No usar la service role key. Para la app móvil se usa únicamente la clave pública/publishable.

Opcionalmente, cargar la URL como variable:

```text
GitHub > Discovery-pET > Settings > Secrets and variables > Actions > Variables > New repository variable
```

Nombre:

```text
DP_BACKEND_URL
```

Valor:

```text
https://dsuwojpgiuvkyvwbuyte.supabase.co
```

Si no se carga esta variable, el workflow usa esa URL por defecto.

## Generar APK manualmente desde GitHub

1. Entrar al repositorio en GitHub.
2. Ir a `Actions`.
3. Seleccionar `Android Debug APK`.
4. Tocar `Run workflow`.
5. Elegir rama `main`.
6. Ejecutar.
7. Esperar a que termine el workflow.
8. Entrar al run generado.
9. Descargar el artifact:

```text
discovery-pet-debug-apk
```

Dentro del ZIP estará:

```text
discovery-pet-debug.apk
README.txt
```

## Instalación en Android

1. Descargar el artifact ZIP.
2. Extraer `discovery-pet-debug.apk`.
3. Pasarlo al celular.
4. Abrir el APK.
5. Permitir instalación desde esa fuente si Android lo solicita.
6. Instalar encima de la versión anterior.

## Uso recomendado

- Celular principal: usar `flutter run` para desarrollo con hot reload.
- Segundo celular: usar APK descargado desde GitHub Actions.

## Consideraciones

- Este APK es debug, no es para Play Store.
- El artifact se conserva 14 días.
- Cada push a `main` que modifique `app/mobile/**` también dispara el build automático.
- El package name se mantiene como `com.discoverypet.mobile`, por lo que se puede instalar encima.
