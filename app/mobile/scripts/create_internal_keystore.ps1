param(
  [string]$KeystorePath = "android/app/discovery-pet-internal.jks",
  [string]$Alias = "discovery-pet-internal"
)

$ErrorActionPreference = "Stop"

Write-Host "== Discovery-pET: crear keystore interna ==" -ForegroundColor Cyan
Write-Host "Este archivo NO debe subirse al repositorio." -ForegroundColor Yellow

$storePassword = Read-Host "Password del keystore" -AsSecureString
$keyPassword = Read-Host "Password de la key" -AsSecureString

$storePasswordPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($storePassword))
$keyPasswordPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($keyPassword))

New-Item -ItemType Directory -Force -Path (Split-Path -Parent $KeystorePath) | Out-Null

keytool -genkeypair `
  -v `
  -keystore $KeystorePath `
  -storetype JKS `
  -keyalg RSA `
  -keysize 2048 `
  -validity 10000 `
  -alias $Alias `
  -storepass $storePasswordPlain `
  -keypass $keyPasswordPlain `
  -dname "CN=Discovery-pET, OU=Internal, O=Discovery-pET, L=Viedma, ST=Rio Negro, C=AR"

Write-Host "Keystore creada:" -ForegroundColor Green
Write-Host $KeystorePath -ForegroundColor Green
Write-Host "Alias:" -ForegroundColor Green
Write-Host $Alias -ForegroundColor Green
Write-Host "Generando base64 al portapapeles..." -ForegroundColor Cyan

[Convert]::ToBase64String([IO.File]::ReadAllBytes((Resolve-Path $KeystorePath))) | Set-Clipboard

Write-Host "Base64 copiado al portapapeles. Cargarlo en GitHub secret DP_ANDROID_KEYSTORE_B64." -ForegroundColor Green
Write-Host "Tambien cargar estos secrets:" -ForegroundColor Yellow
Write-Host "DP_ANDROID_KEYSTORE_PASSWORD"
Write-Host "DP_ANDROID_KEY_ALIAS = $Alias"
Write-Host "DP_ANDROID_KEY_PASSWORD"
