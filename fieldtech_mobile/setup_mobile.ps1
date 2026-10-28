# Ejecutar DENTRO de la carpeta fieldtech_mobile:  .\setup_mobile.ps1
# 1) Respalda lib/, test/ y pubspec.yaml  2) Ejecuta flutter create
# 3) Restaura esos archivos  4) Agrega permisos Android/iOS  5) flutter pub get
$ErrorActionPreference = 'Stop'
$raiz = $PSScriptRoot
Set-Location $raiz

$bak = Join-Path $env:TEMP 'fieldtech_bak'
if (Test-Path $bak) { Remove-Item $bak -Recurse -Force }
New-Item -ItemType Directory $bak | Out-Null
Copy-Item lib, test, pubspec.yaml -Destination $bak -Recurse

flutter create --org com.fieldtech --project-name fieldtech_mobile .

Remove-Item lib, test, pubspec.yaml -Recurse -Force
Copy-Item (Join-Path $bak '*') -Destination $raiz -Recurse -Force

# ---- Android: permisos y tráfico HTTP sin cifrar ----
$manifest = Join-Path $raiz 'android\app\src\main\AndroidManifest.xml'
$xml = Get-Content $manifest -Raw
if ($xml -notmatch 'ACCESS_FINE_LOCATION') {
    $permisos = @"
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.INTERNET" />
    <application
        android:usesCleartextTraffic="true"
"@
    $xml = $xml -replace '<application', $permisos
    Set-Content -Path $manifest -Value $xml -Encoding UTF8 -NoNewline
    Write-Host 'AndroidManifest.xml actualizado.'
}

# ---- iOS: justificaciones de uso ----
$plist = Join-Path $raiz 'ios\Runner\Info.plist'
$p = Get-Content $plist -Raw
if ($p -notmatch 'NSCameraUsageDescription') {
    $claves = @"
	<key>NSLocationWhenInUseUsageDescription</key>
	<string>FieldTech requiere su ubicacion para georreferenciar la incidencia.</string>
	<key>NSCameraUsageDescription</key>
	<string>FieldTech requiere la camara para capturar evidencia fotografica.</string>
	<key>NSPhotoLibraryUsageDescription</key>
	<string>FieldTech requiere la galeria para seleccionar fotos de archivo.</string>
</dict>
</plist>
"@
    $p = $p -replace '</dict>\s*</plist>', $claves
    Set-Content -Path $plist -Value $p -Encoding UTF8 -NoNewline
    Write-Host 'Info.plist actualizado.'
}

flutter pub get
Write-Host 'Listo. Ahora ejecute: flutter analyze ; flutter test ; flutter run'
