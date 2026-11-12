@echo off
rem Pembungkus absen.ps1 supaya bisa dijalankan dengan klik dua kali atau dari cmd
rem tanpa perlu mengubah ExecutionPolicy Windows. Contoh: absen.bat start -Target emulator
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0absen.ps1" %*
set EXITCODE=%ERRORLEVEL%
rem Tahan jendela kalau dibuka lewat klik dua kali, supaya hasilnya bisa dibaca
echo %cmdcmdline% | find /i "%~0" >/dev/null && pause
exit /b %EXITCODE%
