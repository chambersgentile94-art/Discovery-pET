param(
  [string]$BackendUrl = "https://dsuwojpgiuvkyvwbuyte.supabase.co",
  [Parameter(Mandatory = $true)]
  [string]$BackendPublicKey
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$MobileDir = Resolve-Path (Join-Path $ScriptDir "..")
$DistDir = Join-Path $MobileDir "dist"
$OutputApk = Join-Path $MobileDir "build\app\outputs\flutter-apk\app-debug.apk"
$FinalApk = Join-Path $DistDir "discovery-pet-debug.apk"

Set-Location $MobileDir

Write-Host "== Discovery-pET: generando APK debug ==" -ForegroundColor Cyan
Write-Host "Backend: $BackendUrl"

flutter pub get
flutter build apk --debug `
  --dart-define=DP_BACKEND_URL=$BackendUrl `
  --dart-define=DP_BACKEND_PUBLIC_KEY=$BackendPublicKey

if (!(Test-Path $OutputApk)) {
  throw "No se encontro el APK generado: $OutputApk"
}

New-Item -ItemType Directory -Force -Path $DistDir | Out-Null
Copy-Item -Force $OutputApk $FinalApk

Write-Host "APK generado correctamente:" -ForegroundColor Green
Write-Host $FinalApk -ForegroundColor Green
