# 部署包验证脚本 - 检查dist目录是否完整可用

$ErrorActionPreference = "Continue"

Write-Host "=== MiniLPA Web Package Verification ===" -ForegroundColor Cyan
Write-Host ""

$DistDir = Join-Path $PSScriptRoot "dist"
$errors = @()
$warnings = @()
$success = @()

# Check if dist directory exists
if (-not (Test-Path $DistDir)) {
    Write-Host "Error: dist directory does not exist!" -ForegroundColor Red
    Write-Host "Please run: .\build-all.ps1" -ForegroundColor Yellow
    exit 1
}

Write-Host "Checking dist directory..." -ForegroundColor Cyan

# 1. Check JAR files
Write-Host "`n1. Checking JAR files..." -ForegroundColor Yellow
$backendJar = Join-Path $DistDir "minilpa-backend.jar"
$agentJar = Join-Path $DistDir "minilpa-agent.jar"

if (Test-Path $backendJar) {
    $size = (Get-Item $backendJar).Length / 1MB
            if ($size -gt 10) {
                $success += "Backend JAR: $([math]::Round($size, 2)) MB"
            } else {
                $warnings += "Backend JAR too small ($([math]::Round($size, 2)) MB), may be incomplete"
            }
} else {
    $errors += "Missing: minilpa-backend.jar"
}

if (Test-Path $agentJar) {
    $size = (Get-Item $agentJar).Length / 1MB
    $success += "Agent JAR: $([math]::Round($size, 2)) MB"
} else {
    $errors += "Missing: minilpa-agent.jar"
}

# 2. Check frontend files
Write-Host "`n2. Checking frontend files..." -ForegroundColor Yellow
$frontendDir = Join-Path $DistDir "frontend"
if (Test-Path $frontendDir) {
    $indexHtml = Join-Path $frontendDir "index.html"
    if (Test-Path $indexHtml) {
        $success += "Frontend: index.html exists"
        $assetsDir = Join-Path $frontendDir "assets"
        if (Test-Path $assetsDir) {
            $assetFiles = Get-ChildItem $assetsDir -File
            if ($assetFiles.Count -gt 0) {
                $success += "Frontend assets: $($assetFiles.Count) files"
            } else {
                $warnings += "Frontend assets directory is empty"
            }
        } else {
            $warnings += "Frontend assets directory not found"
        }
    } else {
        $errors += "Missing: frontend/index.html"
    }
} else {
    $errors += "Missing: frontend/ directory"
}

# 3. Check configuration files
Write-Host "`n3. Checking configuration files..." -ForegroundColor Yellow
$configDir = Join-Path $DistDir "config"
if (-not (Test-Path $configDir)) {
    $errors += "Missing: config/ directory"
} else {
    $requiredFiles = @(
        "install.sh",
        "update.sh",
        "application.yml",
        "minilpa-backend.service",
        "minilpa-agent.service",
        "nginx.conf.example"
    )
    
    foreach ($file in $requiredFiles) {
        $filePath = Join-Path $configDir $file
        if (Test-Path $filePath) {
            $success += "Config file: $file"
        } else {
            $errors += "Missing config file: config/$file"
        }
    }
}

# 4. Verify JAR files (try to read manifest)
Write-Host "`n4. Verifying JAR file integrity..." -ForegroundColor Yellow
if ($env:JAVA_HOME) {
    try {
        # 检查后端JAR
        if (Test-Path $backendJar) {
            $jarInfo = & "$env:JAVA_HOME\bin\jar.exe" -tf $backendJar 2>&1 | Select-Object -First 1
            if ($jarInfo -match "META-INF") {
                $success += "Backend JAR format is correct"
            } else {
                $warnings += "Backend JAR may be corrupted"
            }
        }
        
        # Check agent JAR
        if (Test-Path $agentJar) {
            $jarInfo = & "$env:JAVA_HOME\bin\jar.exe" -tf $agentJar 2>&1 | Select-Object -First 1
            if ($jarInfo -match "META-INF" -or $jarInfo -match "\.class") {
                $success += "Agent JAR format is correct"
            } else {
                $warnings += "Agent JAR may be corrupted"
            }
        }
    } catch {
        $warnings += "Cannot verify JAR files (JAVA_HOME required)"
    }
} else {
    $warnings += "JAVA_HOME not set, skipping JAR verification"
}

# 5. Calculate file size statistics
Write-Host "`n5. Calculating file sizes..." -ForegroundColor Yellow
$totalSize = (Get-ChildItem $DistDir -Recurse -File | Measure-Object -Property Length -Sum).Sum / 1MB
$success += "Total package size: $([math]::Round($totalSize, 2)) MB"

# Output results
Write-Host "`n=== Verification Results ===" -ForegroundColor Cyan
Write-Host ""

if ($success.Count -gt 0) {
    Write-Host "Passed items ($($success.Count)):" -ForegroundColor Green
    foreach ($item in $success) {
        Write-Host "   $item" -ForegroundColor Gray
    }
}

if ($warnings.Count -gt 0) {
    Write-Host "`nWarnings ($($warnings.Count)):" -ForegroundColor Yellow
    foreach ($item in $warnings) {
        Write-Host "   $item" -ForegroundColor Gray
    }
}

if ($errors.Count -gt 0) {
    Write-Host "`nErrors ($($errors.Count)):" -ForegroundColor Red
    foreach ($item in $errors) {
        Write-Host "   $item" -ForegroundColor Gray
    }
    Write-Host "`nPackage is incomplete, please rebuild!" -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "`nPackage verification passed! All required files exist." -ForegroundColor Green
    Write-Host "`nReady to upload to server for deployment." -ForegroundColor Cyan
    exit 0
}

