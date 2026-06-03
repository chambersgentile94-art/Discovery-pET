# Discovery-pET - APK interno firmado

Este procedimiento permite generar APKs internos que se pueden instalar como actualizacion en celulares de prueba.

## Objetivo

Evitar diferencias de firma entre APKs generados en distintas maquinas.

Con este flujo:

- GitHub Actions firma siempre con la misma keystore.
- Los celulares pueden instalar una nueva version encima de la anterior.
- No hace falta desinstalar la app en cada actualizacion.

## Archivos agregados

```text
.github/workflows/android-internal-apk.yml
app/mobile/scripts/create_internal_keystore.ps1
```

## Paso 1 - Crear keystore interna

En la PC:

```powershell
cd C:\Users\admin\Desktop\App\Discovery-pET\app\mobile
.\scripts\create_internal_keystore.ps1
```

El script crea:

```text
app/mobile/android/app/discovery-pet-internal.jks
```

Tambien copia al portapapeles el contenido en base64 para cargarlo en GitHub Actions.

## Paso 2 - Cargar secretos en GitHub

Ir a:

```text
GitHub > Discovery-pET > Settings > Secrets and variables > Actions > New repository secret
```

Crear estos secrets:

```text
DP_ANDROID_KEYSTORE_B64
DP_ANDROID_KEYSTORE_PASSWORD
DP_ANDROID_KEY_ALIAS
DP_ANDROID_KEY_PASSWORD
```

Valor recomendado para alias:

```text
discovery-pet-internal
```

Tambien deben existir:

```text
DP_BACKEND_PUBLIC_KEY
FIREBASE_GOOGLE_SERVICES_JSON_B64
```

Opcional:

```text
DP_BACKEND_URL
```

## Paso 3 - Ejecutar workflow

En GitHub:

```text
Actions > Android Internal Signed APK > Run workflow
```

Cuando termine, descargar el artifact:

```text
discovery-pet-internal-signed-apk
```

Dentro estara:

```text
discovery-pet-internal.apk
README.txt
```

## Instalacion en celular

La primera vez puede ser necesario desinstalar la app anterior si venia de una firma debug distinta.

Luego, todas las versiones generadas por este workflow deberian instalarse encima como actualizacion.

## Regla operativa

Conservar una copia segura de la keystore y de sus credenciales. Si se cambia la keystore, Android no permitira actualizar encima.
