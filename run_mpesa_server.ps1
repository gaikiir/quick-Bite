# Run M-Pesa Proxy Server in Background
# This script starts the server and keeps it running

param(
    [switch]$Stop,
    [switch]$Status
)

$pythonPath = "$env:USERPROFILE\AppData\Local\Programs\Python\Python311\python.exe"
$serverPath = "$PSScriptRoot\mpesa_proxy_server.py"
$logPath = "$PSScriptRoot\mpesa_server.log"

if ($Stop) {
    Write-Host "🛑 Stopping M-Pesa Proxy Server..."
    Get-Process python* | Where-Object { $_.MainWindowTitle -like "*mpesa*" -or $_.CommandLine -like "*mpesa_proxy_server*" } | Stop-Process -Force
    Write-Host "✅ Server stopped"
    exit
}

if ($Status) {
    $processes = Get-Process python* | Where-Object { $_.CommandLine -like "*mpesa_proxy_server*" }
    if ($processes) {
        Write-Host "✅ M-Pesa Proxy Server is running"
        Write-Host "PID: $($processes.Id)"
        Write-Host "Started: $($processes.StartTime)"
    } else {
        Write-Host "❌ M-Pesa Proxy Server is not running"
    }
    exit
}

Write-Host "🚀 Starting M-Pesa Proxy Server in background..."
Write-Host "📱 This server handles CORS issues for M-Pesa integration"
Write-Host "🌐 Server will be available at: http://localhost:5000"
Write-Host "🔗 Set proxyUrl in MpesaConfig to: http://localhost:5000/api/mpesa"
Write-Host "💡 For production, deploy this to a cloud service"
Write-Host ""

# Check if already running
$existing = Get-Process python* | Where-Object { $_.CommandLine -like "*mpesa_proxy_server*" }
if ($existing) {
    Write-Host "⚠️ Server is already running (PID: $($existing.Id))"
    Write-Host "Use .\run_mpesa_server.ps1 -Stop to stop it first"
    exit
}

# Start server in background
$job = Start-Job -ScriptBlock {
    param($python, $server, $log)
    & $python $server > $log 2>&1
} -ArgumentList $pythonPath, $serverPath, $logPath

Start-Sleep -Seconds 2

# Check if job started successfully
$jobStatus = Get-Job -Id $job.Id
if ($jobStatus.State -eq "Running") {
    Write-Host "✅ M-Pesa Proxy Server started successfully!"
    Write-Host "📝 Logs: $logPath"
    Write-Host "🛑 To stop: .\run_mpesa_server.ps1 -Stop"
    Write-Host "📊 Status: .\run_mpesa_server.ps1 -Status"
} else {
    Write-Host "❌ Failed to start server"
    Receive-Job -Job $job
}