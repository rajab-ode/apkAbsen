<#
.SYNOPSIS
  Install, build, dan jalankan proyek Absensi SMKN 5 (backend + aplikasi Android)
  untuk development lokal dengan database XAMPP.

.DESCRIPTION
  Setiap aksi selalu diawali pengecekan & instalasi yang aman diulang:
    - cek Node.js, npm, Flutter, adb, dan MySQL XAMPP
    - npm install di backend (hanya kalau node_modules belum ada / package-lock berubah)
    - buat backend\.env dari .env.example + JWT_SECRET acak (kalau belum ada)
    - nyalakan MySQL XAMPP kalau belum jalan, buat database, import database.sql
      + seed_local.sql HANYA kalau tabelnya belum ada (data lama tidak ditimpa)
    - flutter pub get (hanya kalau belum pernah / pubspec berubah)

  Aksi:
    all      (default) install -> build APK -> start backend -> pasang APK ke HP -> buka aplikasi
    install  hanya pengecekan & instalasi di atas
    build    install -> build APK
    start    install -> start backend -> flutter run (mode debug, bisa hot reload)
    backend  install backend & database -> start backend saja

.EXAMPLE
  .\absen.bat
  .\absen.bat start -Target emulator
  .\absen.bat build -ServerUrl http://192.168.1.10:3000
  .\absen.bat all -XamppPath C:\xampp
#>
param(
  [ValidateSet('all', 'install', 'build', 'start', 'backend')]
  [string]$Action = 'all',

  # device = HP fisik via USB (URL server = IP LAN PC ini), emulator = 10.0.2.2
  [ValidateSet('device', 'emulator')]
  [string]$Target = 'device',

  # Override URL server yang di-compile ke APK, mis. http://192.168.1.10:3000
  [string]$ServerUrl = '',

  [string]$XamppPath = 'D:\xampp',

  # Jangan import seed_local.sql saat database baru dibuat
  [switch]$NoSeed
)

$ErrorActionPreference = 'Stop'
$Root       = $PSScriptRoot
$BackendDir = Join-Path $Root 'backend'
$AppDir     = Join-Path $Root 'absensi_app'
$EnvFile    = Join-Path $BackendDir '.env'
$AppId      = 'com.smkn5kendari.absensi_app'
$ApkPath    = Join-Path $AppDir 'build\app\outputs\flutter-apk\app-release.apk'

# ---------------------------------------------------------------- helpers
function Step($msg) { Write-Host ""; Write-Host "==> $msg" -ForegroundColor Cyan }
function Ok($msg)   { Write-Host "    [OK] $msg" -ForegroundColor Green }
function Warn($msg) { Write-Host "    [!]  $msg" -ForegroundColor Yellow }
function Fail($msg) { Write-Host ""; Write-Host "[GAGAL] $msg" -ForegroundColor Red; exit 1 }

function Test-Cmd($name) { return [bool](Get-Command $name -ErrorAction SilentlyContinue) }

function Invoke-Native {
  # Jalankan program eksternal dan hentikan skrip kalau exit code-nya bukan 0
  param([string]$Exe, [string[]]$Arguments, [string]$What)
  & $Exe @Arguments
  if ($LASTEXITCODE -ne 0) { Fail "$What gagal (exit code $LASTEXITCODE)" }
}

function Test-Port([string]$HostName, [int]$Port) {
  if ($HostName -eq 'localhost') { $HostName = '127.0.0.1' }
  $client = New-Object System.Net.Sockets.TcpClient
  try {
    $async = $client.BeginConnect($HostName, $Port, $null, $null)
    if (-not $async.AsyncWaitHandle.WaitOne(1000)) { return $false }
    $client.EndConnect($async)
    return $true
  } catch { return $false } finally { $client.Close() }
}

function Read-DotEnv([string]$Path) {
  $map = @{}
  foreach ($line in Get-Content $Path) {
    if ($line -match '^\s*#' -or $line -notmatch '=') { continue }
    $idx = $line.IndexOf('=')
    $map[$line.Substring(0, $idx).Trim()] = $line.Substring($idx + 1).Trim()
  }
  return $map
}

function Get-Setting($map, $key, $default) {
  if ($map.ContainsKey($key) -and $map[$key] -ne '') { return $map[$key] }
  return $default
}

function Test-NewerThan([string]$Source, [string]$Marker) {
  # true kalau $Marker belum ada atau lebih tua dari $Source
  if (-not (Test-Path $Marker)) { return $true }
  if (-not (Test-Path $Source)) { return $false }
  return (Get-Item $Source).LastWriteTime -gt (Get-Item $Marker).LastWriteTime
}

function Get-LanIp {
  try {
    $cfg = Get-NetIPConfiguration -ErrorAction Stop |
      Where-Object { $_.IPv4DefaultGateway -ne $null -and $_.NetAdapter.Status -eq 'Up' } |
      Select-Object -First 1
    if ($cfg) { return $cfg.IPv4Address[0].IPAddress }
  } catch { }
  return $null
}

# ---------------------------------------------------------------- 1. prasyarat
function Test-Prerequisites([bool]$NeedApp) {
  Step 'Cek prasyarat'

  if (-not (Test-Cmd 'node')) { Fail 'Node.js belum terpasang. Install versi 18+ dari https://nodejs.org lalu buka terminal baru.' }
  $nodeVer = (& node -v).Trim()
  $major = [int]($nodeVer.TrimStart('v').Split('.')[0])
  if ($major -lt 18) { Fail "Node.js $nodeVer terlalu lama, butuh 18 atau lebih baru." }
  Ok "Node.js $nodeVer"

  if (-not (Test-Cmd 'npm.cmd')) { Fail 'npm tidak ditemukan (biasanya ikut terpasang bersama Node.js).' }
  Ok "npm $((& npm.cmd -v).Trim())"

  if (-not (Test-Path (Join-Path $XamppPath 'mysql\bin\mysql.exe'))) {
    if (Test-Path 'C:\xampp\mysql\bin\mysql.exe') {
      $script:XamppPath = 'C:\xampp'
    } else {
      Fail "MySQL XAMPP tidak ditemukan di $XamppPath. Jalankan ulang dengan -XamppPath <folder xampp>."
    }
  }
  Ok "XAMPP di $XamppPath"

  if ($NeedApp) {
    if (-not (Test-Cmd 'flutter')) { Fail 'Flutter belum terpasang / belum ada di PATH. Lihat https://docs.flutter.dev/get-started/install/windows' }
    Ok 'Flutter ditemukan'
    if (Test-Cmd 'adb') { Ok 'adb ditemukan' } else { Warn 'adb tidak ada di PATH: APK tidak bisa dipasang otomatis ke HP.' }
  }
}

# ---------------------------------------------------------------- 2. backend
function Install-Backend {
  Step 'Dependensi backend (npm)'
  $marker = Join-Path $BackendDir 'node_modules\.package-lock.json'
  if (Test-NewerThan (Join-Path $BackendDir 'package-lock.json') $marker) {
    Push-Location $BackendDir
    try { Invoke-Native 'npm.cmd' @('install') 'npm install' } finally { Pop-Location }
    Ok 'npm install selesai'
  } else {
    Ok 'node_modules sudah lengkap, dilewati'
  }

  Step 'File backend\.env'
  if (-not (Test-Path $EnvFile)) {
    Copy-Item (Join-Path $BackendDir '.env.example') $EnvFile
    Ok '.env dibuat dari .env.example'
  } else {
    Ok '.env sudah ada'
  }

  $envMap = Read-DotEnv $EnvFile
  $secret = Get-Setting $envMap 'JWT_SECRET' ''
  if ($secret -eq '' -or $secret -eq 'ganti_dengan_secret_yang_kuat') {
    $bytes = New-Object byte[] 32
    [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
    $newSecret = ($bytes | ForEach-Object { $_.ToString('x2') }) -join ''
    $content = @(Get-Content $EnvFile)
    if ($content -match '^\s*JWT_SECRET\s*=') {
      $content = $content -replace '^\s*JWT_SECRET\s*=.*$', "JWT_SECRET=$newSecret"
    } else {
      $content += "JWT_SECRET=$newSecret"
    }
    Set-Content -Path $EnvFile -Value $content -Encoding ASCII
    Ok 'JWT_SECRET acak dibuat'
  }
}

# ---------------------------------------------------------------- 3. database
function Initialize-Database {
  Step 'Database MySQL (XAMPP)'
  $envMap = Read-DotEnv $EnvFile
  $dbHost = Get-Setting $envMap 'DB_HOST' 'localhost'
  $dbPort = [int](Get-Setting $envMap 'DB_PORT' '3306')
  $dbUser = Get-Setting $envMap 'DB_USER' 'root'
  $dbPass = Get-Setting $envMap 'DB_PASSWORD' ''
  $dbName = Get-Setting $envMap 'DB_NAME' 'absensi_smkn5'

  if (-not (Test-Port $dbHost $dbPort)) {
    $isLocal = @('localhost', '127.0.0.1') -contains $dbHost
    if (-not $isLocal) { Fail "Database $dbHost`:$dbPort tidak bisa dihubungi." }

    Warn 'MySQL belum jalan, menyalakan MySQL XAMPP...'
    $mysqld = Join-Path $XamppPath 'mysql\bin\mysqld.exe'
    $myIni  = Join-Path $XamppPath 'mysql\bin\my.ini'
    Start-Process -FilePath $mysqld -ArgumentList "--defaults-file=`"$myIni`"", '--standalone' `
      -WorkingDirectory $XamppPath -WindowStyle Minimized
    $up = $false
    for ($i = 0; $i -lt 30; $i++) {
      Start-Sleep -Seconds 1
      if (Test-Port $dbHost $dbPort) { $up = $true; break }
    }
    if (-not $up) { Fail 'MySQL tidak menyala dalam 30 detik. Coba Start MySQL dari XAMPP Control Panel lalu ulangi.' }
  }
  Ok "MySQL aktif di $dbHost`:$dbPort"

  $mysql = Join-Path $XamppPath 'mysql\bin\mysql.exe'
  $base  = @("--host=$dbHost", "--port=$dbPort", "--user=$dbUser", '--default-character-set=utf8mb4')
  # Password lewat env var supaya tidak muncul di daftar proses & tidak memicu prompt
  $env:MYSQL_PWD = $dbPass
  try {
    Invoke-Native $mysql ($base + @('-e', "CREATE DATABASE IF NOT EXISTS ``$dbName`` CHARACTER SET utf8mb4;")) 'Membuat database'
    Ok "Database $dbName siap"

    $q = "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='$dbName' AND table_name='users';"
    $count = & $mysql @base -N -e $q
    if ($LASTEXITCODE -ne 0) { Fail 'Tidak bisa membaca database. Cek DB_USER / DB_PASSWORD di backend\.env.' }

    if ([int]("$count".Trim()) -eq 0) {
      # "source" dipakai karena PowerShell tidak punya redirect "<" seperti cmd/bash.
      # Path diberi kutip tunggal karena folder proyek bisa mengandung spasi.
      $schema = (Join-Path $BackendDir 'database.sql') -replace '\\', '/'
      Invoke-Native $mysql ($base + @($dbName, '-e', "source '$schema'")) 'Import database.sql'
      Ok 'Tabel dibuat dari database.sql'

      if (-not $NoSeed) {
        $seed = (Join-Path $BackendDir 'seed_local.sql') -replace '\\', '/'
        Invoke-Native $mysql ($base + @($dbName, '-e', "source '$seed'")) 'Import seed_local.sql'
        Ok 'Data uji diimpor (admin/admin123, guru1/guru123, siswa1/siswa123)'
      }
    } else {
      Ok 'Tabel sudah ada, import dilewati (data lama aman)'
    }
  } finally {
    Remove-Item Env:\MYSQL_PWD -ErrorAction SilentlyContinue
  }
}

# ---------------------------------------------------------------- 4. aplikasi
function Install-App {
  Step 'Dependensi aplikasi (flutter pub get)'
  $marker = Join-Path $AppDir '.dart_tool\package_config.json'
  if ((Test-NewerThan (Join-Path $AppDir 'pubspec.yaml') $marker) -or
      (Test-NewerThan (Join-Path $AppDir 'pubspec.lock') $marker)) {
    Push-Location $AppDir
    try { Invoke-Native 'flutter' @('pub', 'get') 'flutter pub get' } finally { Pop-Location }
    Ok 'flutter pub get selesai'
  } else {
    Ok 'Paket Flutter sudah lengkap, dilewati'
  }
}

function Resolve-ServerUrl {
  if ($ServerUrl -ne '') { return $ServerUrl }
  $port = Get-Setting (Read-DotEnv $EnvFile) 'PORT' '3000'
  if ($Target -eq 'emulator') { return "http://10.0.2.2:$port" }
  $ip = Get-LanIp
  if (-not $ip) { Fail 'IP LAN PC tidak terdeteksi. Isi manual: -ServerUrl http://<IP-PC>:3000' }
  return "http://$ip`:$port"
}

function Build-Apk([string]$Url) {
  Step "Build APK (SERVER_URL=$Url)"
  Push-Location $AppDir
  try {
    Invoke-Native 'flutter' @('build', 'apk', '--release', "--dart-define=SERVER_URL=$Url") 'flutter build apk'
  } finally { Pop-Location }
  Ok "APK: $ApkPath"
  Warn 'APK ini menunjuk ke server LOKAL. Jangan dibagikan ke siswa; build produksi: flutter build apk (tanpa --dart-define).'
}

# ---------------------------------------------------------------- 5. start
function Start-Backend {
  Step 'Menjalankan backend'
  $port = [int](Get-Setting (Read-DotEnv $EnvFile) 'PORT' '3000')
  $health = "http://localhost:$port/api/health"

  if (Test-Port 'localhost' $port) {
    Warn "Port $port sudah dipakai, anggap backend sudah jalan."
  } else {
    $cmd = "`$host.UI.RawUI.WindowTitle = 'Backend Absensi (port $port)'; Set-Location -LiteralPath '$BackendDir'; npm.cmd run dev"
    Start-Process powershell -ArgumentList '-NoExit', '-ExecutionPolicy', 'Bypass', '-Command', $cmd
  }

  for ($i = 0; $i -lt 30; $i++) {
    try {
      $r = Invoke-RestMethod -Uri $health -TimeoutSec 2
      if ($r.status -eq 'ok') { Ok "Backend aktif: $health"; return }
    } catch { }
    Start-Sleep -Seconds 1
  }
  Fail "Backend tidak merespons di $health. Lihat pesan error di jendela 'Backend Absensi'."
}

function Install-ApkToDevice {
  Step 'Memasang APK ke perangkat'
  if (-not (Test-Cmd 'adb')) { Warn "adb tidak ada. Salin manual: $ApkPath"; return }

  $devices = & adb devices | Select-Object -Skip 1 | Where-Object { $_ -match '\tdevice$' }
  if (-not $devices) {
    Warn "Tidak ada HP/emulator terhubung (cek USB debugging). Pasang manual: $ApkPath"
    return
  }
  $serial = ($devices | Select-Object -First 1).Split("`t")[0]
  Invoke-Native 'adb' @('-s', $serial, 'install', '-r', $ApkPath) 'adb install'
  & adb -s $serial shell monkey -p $AppId -c android.intent.category.LAUNCHER 1 | Out-Null
  Ok "Terpasang & dibuka di $serial"
}

function Start-FlutterRun([string]$Url) {
  Step "flutter run (SERVER_URL=$Url) - tekan r untuk hot reload, q untuk keluar"
  Push-Location $AppDir
  try { & flutter run "--dart-define=SERVER_URL=$Url" } finally { Pop-Location }
}

function Show-FirewallHint([string]$Url) {
  if ($Target -eq 'device' -and $Url -notmatch '10\.0\.2\.2') {
    Warn "HP harus satu Wi-Fi dengan PC. Kalau aplikasi tidak bisa konek ke $Url,"
    Warn 'izinkan Node.js di Windows Defender Firewall untuk jaringan Private.'
  }
}

# ---------------------------------------------------------------- main
$needApp = $Action -ne 'backend'
Test-Prerequisites $needApp
Install-Backend
Initialize-Database
if ($needApp) { Install-App }

switch ($Action) {
  'install' { }
  'backend' { Start-Backend }
  'build'   { Build-Apk (Resolve-ServerUrl) }
  'start'   {
    $url = Resolve-ServerUrl
    Start-Backend
    Show-FirewallHint $url
    Start-FlutterRun $url
  }
  'all'     {
    $url = Resolve-ServerUrl
    Build-Apk $url
    Start-Backend
    Install-ApkToDevice
    Show-FirewallHint $url
  }
}

Write-Host ""
Write-Host "Selesai ($Action)." -ForegroundColor Green
