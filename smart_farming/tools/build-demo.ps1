param([switch]$SkipChecks, [switch]$Offline)
$ErrorActionPreference = 'Stop'
$project = Split-Path -Parent $PSScriptRoot
$toolRoot = 'D:\Wahyu\.tools'
if (Test-Path -LiteralPath "$toolRoot\java\bin\java.exe") { $env:JAVA_HOME = "$toolRoot\java" }
if (Test-Path -LiteralPath "$toolRoot\android-sdk") {
    $env:ANDROID_HOME = "$toolRoot\android-sdk"
    $env:ANDROID_SDK_ROOT = $env:ANDROID_HOME
}
$env:GRADLE_USER_HOME = "$toolRoot\gradle"
$env:GRADLE_OPTS = '-Dorg.gradle.daemon=false'
Set-Location -LiteralPath $project
flutter pub get
if ($LASTEXITCODE -ne 0) { throw 'flutter pub get gagal' }
if (!$SkipChecks) {
    flutter analyze
    if ($LASTEXITCODE -ne 0) { throw 'flutter analyze gagal' }
    flutter test
    if ($LASTEXITCODE -ne 0) { throw 'flutter test gagal' }
}
$buildOptions = @()
if ($Offline) { $buildOptions += '--dart-define=MIKIKO_FIREBASE=false' }
flutter build apk --release @buildOptions
if ($LASTEXITCODE -ne 0) { throw 'Build APK gagal' }
$destination = Join-Path $project 'dist'
New-Item -ItemType Directory -Force -Path $destination | Out-Null
$versionLine = Select-String -LiteralPath "$project\pubspec.yaml" -Pattern '^version:\s*([^+\s]+)'
$appVersion = $versionLine.Matches[0].Groups[1].Value
$variant = if ($Offline) { 'demo' } else { 'firebase' }
$apkPath = Join-Path $destination "MIKIKO-Smart-Farming-v$appVersion-$variant.apk"
Copy-Item -LiteralPath "$project\build\app\outputs\flutter-apk\app-release.apk" -Destination $apkPath -Force
Get-FileHash -LiteralPath $apkPath -Algorithm SHA256 | Format-List
