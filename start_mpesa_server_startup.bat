@echo off
REM M-Pesa Proxy Server Startup Script
REM Add this to Windows Startup folder for automatic launch

cd /d "C:\Users\%USERNAME%\Desktop\webdev\android_dev\quick_bite"

REM Check if already running
tasklist /FI "IMAGENAME eq python.exe" /FI "WINDOWTITLE eq M-Pesa Proxy Server" 2>NUL | find /I /N "python.exe">NUL
if %ERRORLEVEL% EQU 0 (
    echo M-Pesa Proxy Server is already running
    goto :eof
)

echo Starting M-Pesa Proxy Server...
start "M-Pesa Proxy Server" /B "C:\Users\%USERNAME%\AppData\Local\Programs\Python\Python311\python.exe" mpesa_proxy_server.py

echo M-Pesa Proxy Server started in background
timeout /t 2 /nobreak > nul