param(
  [string]$KeystorePath = "android/app/discovery-pet-internal.jks",
  [string]$Alias = "discovery-pet-internal"
)

$ErrorActionPreference = "Stop"

function Find-Keytool {
  $cmd = Get-Command keytool -ErrorAction SilentlyContinue
  if ($cmd) {
    return $cmd.Source
  }

  $candidates = @(
    "$env:JAVA_HOME\bin\keytool.exe",
    "$env:ProgramFiles\Android\Android Studio\jbr\bin\keytool.exe",
    "$env:ProgramFiles\Android\Android Studio\jre\bin\keytool.exe",
    "${env:ProgramFiles(x86)}\Android\Android Studio\jbr\bin\keytool.exe",
    "${env:ProgramFiles(x86)}\Android\Android Studio\jre\bin\keytool.exe"
  )

  foreach ($candidate in $candidates) {
    if ($candidate -and (Test-Path $candidate)) {
      return $candidate
    }
  }

  $searchRoots = @(
    "$env:ProgramFiles\Android",
    "$env:ProgramFiles\Java",
    "${env:ProgramFiles(x86)}\Java"
  )

  foreach ($root in $searchRoots) {
    if ($root -and (Test-Path $root)) {
      $found = Get-ChildItem -Path $root -Filter keytool.exe -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
      if ($found) {
        return $found.FullName
      }
    }
  }

  return $null
}

Write-Host "== Discovery-pET: crear keystore interna ==" -ForegroundColor Cyan
Write-Host "Este archivo NO debe subirse al repositorio." -ForegroundColor Yellow

$keytoolPath = Find-Keytool
if (-not $keytoolPath) {
  Write-Host "No se encontro keytool.exe." -ForegroundColor Red
  Write-Host "Instala un JDK o verifica Android Studio." -ForegroundColor Yellow
  Write-Host "Rutas habituales:" -ForegroundColor Yellow
  Write-Host "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe"
  Write-Host "C:\Program Files\Java\jdk-*\bin\keytool.exe"
  throw "keytool.exe no disponible"
}

Write-Host "Usando keytool:" -ForegroundColor Green
Write-Host $keytoolPath -ForegroundColor Green

$storePassword = Read-Host "Password del keystore" -AsSecureString
$keyPassword = Read-Host "Password de la key" -AsSecureString

$storePasswordPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($storePassword))
$keyPasswordPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($keyPassword))

New-Item -ItemType Directory -Force -Path (Split-Path -Parent $KeystorePath) | Out-Null

& $keytoolPath -genkeypair `
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
