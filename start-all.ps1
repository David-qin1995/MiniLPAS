# MiniLPA Local Startup Script
# Automatically check, build and start all services

$ErrorActionPreference = "Continue"
$ProjectRoot = $PSScriptRoot

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  MiniLPA Local Development Startup" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Check build artifacts
Write-Host "[1/5] Checking build artifacts..." -ForegroundColor Yellow
$backendJar = Get-ChildItem "$ProjectRoot\web-backend\build\libs\*.jar" -ErrorAction SilentlyContinue | Where-Object { $_.Name -notlike "*-plain.jar" } | Select-Object -First 1
$agentJar = Get-ChildItem "$ProjectRoot\local-agent\build\libs\*.jar" -ErrorAction SilentlyContinue | Where-Object { $_.Name -notlike "*-plain.jar" } | Select-Object -First 1

if (-not $backendJar) {
    Write-Host "  Backend JAR not found. Building..." -ForegroundColor Yellow
    cd "$ProjectRoot\web-backend"
    .\gradlew.bat clean build bootJar --no-daemon | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  Backend build failed!" -ForegroundColor Red
        exit 1
    }
    $backendJar = Get-ChildItem "build\libs\*.jar" | Where-Object { $_.Name -notlike "*-plain.jar" } | Select-Object -First 1
    cd $ProjectRoot
    Write-Host "  Backend built successfully" -ForegroundColor Green
} else {
    Write-Host "  Backend JAR: OK" -ForegroundColor Green
}

if (-not $agentJar) {
    Write-Host "  Agent JAR not found. Building..." -ForegroundColor Yellow
    cd "$ProjectRoot\local-agent"
    .\gradlew.bat clean build --no-daemon | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  Agent build failed!" -ForegroundColor Red
        exit 1
    }
    $agentJar = Get-ChildItem "build\libs\*.jar" | Where-Object { $_.Name -notlike "*-plain.jar" } | Select-Object -First 1
    cd $ProjectRoot
    Write-Host "  Agent built successfully" -ForegroundColor Green
} else {
    Write-Host "  Agent JAR: OK" -ForegroundColor Green
}

# Check port usage
Write-Host "`n[2/5] Checking ports..." -ForegroundColor Yellow
$port8080 = Get-NetTCPConnection -LocalPort 8080 -ErrorAction SilentlyContinue
$port3000 = Get-NetTCPConnection -LocalPort 3000 -ErrorAction SilentlyContinue

if ($port8080) {
    Write-Host "  Port 8080 is in use (PID: $($port8080.OwningProcess))" -ForegroundColor Yellow
    Write-Host "  Using existing backend service" -ForegroundColor Cyan
} else {
    Write-Host "  Port 8080: Available" -ForegroundColor Green
}

if ($port3000) {
    Write-Host "  Port 3000 is in use (PID: $($port3000.OwningProcess))" -ForegroundColor Yellow
    Write-Host "  Using existing frontend service" -ForegroundColor Cyan
} else {
    Write-Host "  Port 3000: Available" -ForegroundColor Green
}

# Get Java 21 path from gradle.properties
$javaHome = (Get-Content "$ProjectRoot\web-backend\gradle.properties" | Select-String "org.gradle.java.home" | ForEach-Object { ($_.Line -replace 'org.gradle.java.home=', '').Trim() -replace '\\\\', '\' })
$javaExe = Join-Path $javaHome "bin\java.exe"
if (-not (Test-Path $javaExe)) {
    Write-Host "  ERROR: Java 21 not found at $javaExe" -ForegroundColor Red
    Write-Host "  Please check gradle.properties configuration" -ForegroundColor Yellow
    exit 1
}

# Start backend service
Write-Host "`n[3/5] Starting backend service..." -ForegroundColor Yellow
if (-not (Get-NetTCPConnection -LocalPort 8080 -ErrorAction SilentlyContinue)) {
    Write-Host "  Starting backend on port 8080..." -ForegroundColor Cyan
    Write-Host "  Using Java: $javaExe" -ForegroundColor Gray
    $backendCmd = "cd '$ProjectRoot\web-backend'; Write-Host '=== Backend Service (Port 8080) ===' -ForegroundColor Cyan; & '$javaExe' -jar '$($backendJar.FullName)'"
    Start-Process powershell -ArgumentList "-NoExit", "-Command", $backendCmd -WindowStyle Normal
    Write-Host "  Backend service window opened" -ForegroundColor Green
    Write-Host "  Waiting for backend to start (this may take 15-30 seconds)..." -ForegroundColor Cyan
    $backendReady = $false
    for ($i = 0; $i -lt 30; $i++) {
        Start-Sleep -Seconds 2
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:8080/api/devices/status" -TimeoutSec 1 -ErrorAction Stop
            $backendReady = $true
            Write-Host "`n  Backend is ready!" -ForegroundColor Green
            break
        } catch {
            Write-Host "." -NoNewline -ForegroundColor Gray
        }
    }
    if (-not $backendReady) {
        Write-Host "`n  Warning: Backend may still be starting. Check the backend window." -ForegroundColor Yellow
    }
} else {
    Write-Host "  Backend already running" -ForegroundColor Green
}

# Start agent service
Write-Host "`n[4/5] Starting agent service..." -ForegroundColor Yellow
Write-Host "  Starting agent..." -ForegroundColor Cyan
Write-Host "  Using Java: $javaExe" -ForegroundColor Gray
$agentCmd = "cd '$ProjectRoot\local-agent'; Write-Host '=== Agent Service ===' -ForegroundColor Cyan; & '$javaExe' -jar '$($agentJar.FullName)'"
Start-Process powershell -ArgumentList "-NoExit", "-Command", $agentCmd -WindowStyle Normal
Write-Host "  Agent service window opened" -ForegroundColor Green
Start-Sleep -Seconds 3

# Start frontend service
Write-Host "`n[5/5] Checking frontend service..." -ForegroundColor Yellow
if (-not (Get-NetTCPConnection -LocalPort 3000 -ErrorAction SilentlyContinue)) {
    Write-Host "  Starting frontend on port 3000..." -ForegroundColor Cyan
    cd "$ProjectRoot\web-frontend"
    if (-not (Test-Path "node_modules")) {
        Write-Host "  Installing dependencies..." -ForegroundColor Cyan
        npm install --silent
    }
    $frontendCmd = "cd '$ProjectRoot\web-frontend'; Write-Host '=== Frontend Service (Port 3000) ===' -ForegroundColor Cyan; npm run dev"
    Start-Process powershell -ArgumentList "-NoExit", "-Command", $frontendCmd -WindowStyle Normal
    cd $ProjectRoot
    Write-Host "  Frontend service window opened" -ForegroundColor Green
    Write-Host "  Waiting for frontend to start..." -ForegroundColor Cyan
    Start-Sleep -Seconds 5
} else {
    Write-Host "  Frontend already running" -ForegroundColor Green
}

# Final status check
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Startup Complete!" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "Access URLs:" -ForegroundColor Cyan
Write-Host "  Frontend: http://localhost:3000" -ForegroundColor White
Write-Host "  Backend:  http://localhost:8080" -ForegroundColor White
Write-Host "  API Test: http://localhost:8080/api/devices/status" -ForegroundColor White

Write-Host "`nService Windows:" -ForegroundColor Cyan
Write-Host "  Check the opened PowerShell windows for service logs" -ForegroundColor Gray
Write-Host "  Close windows to stop services" -ForegroundColor Gray

Write-Host "`nPress any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

