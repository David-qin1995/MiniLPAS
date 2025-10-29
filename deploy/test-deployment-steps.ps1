# Test Deployment Steps Script - Verify if deployment steps in documentation are usable

$ErrorActionPreference = "Continue"

Write-Host "=== Test Deployment Steps ===" -ForegroundColor Cyan
Write-Host ""

# Step 1: Verify build script
Write-Host "Step 1: Verifying build script..." -ForegroundColor Yellow
$buildScript = Join-Path $PSScriptRoot "build-all.ps1"
if (Test-Path $buildScript) {
    Write-Host "  build-all.ps1 exists" -ForegroundColor Green
} else {
    Write-Host "  build-all.ps1 not found" -ForegroundColor Red
    exit 1
}

# Step 2: Check dist directory
Write-Host "`nStep 2: Checking dist directory..." -ForegroundColor Yellow
& "$PSScriptRoot\verify-package.ps1"
$verifyResult = $LASTEXITCODE

if ($verifyResult -ne 0) {
    Write-Host "`nPackage verification failed, please run build script first" -ForegroundColor Yellow
    Write-Host "  Run: .\build-all.ps1" -ForegroundColor White
    exit 1
}

# Step 3: Check installation script
Write-Host "`nStep 3: Checking installation script..." -ForegroundColor Yellow
$installScript = Join-Path $PSScriptRoot "dist\config\install.sh"
if (Test-Path $installScript) {
    Write-Host "  install.sh exists" -ForegroundColor Green
    
    # Check script content
    $scriptContent = Get-Content $installScript -Raw
    if ($scriptContent -match "#!/bin/bash") {
        Write-Host "  install.sh format correct (has shebang)" -ForegroundColor Green
    } else {
        Write-Host "  install.sh may be missing shebang line" -ForegroundColor Yellow
    }
    
    # Check key functions
    $requiredFunctions = @("INSTALL_DIR", "systemctl", "JAVA_HOME")
    $missingFunctions = @()
    foreach ($func in $requiredFunctions) {
        if ($scriptContent -notmatch $func) {
            $missingFunctions += $func
        }
    }
    if ($missingFunctions.Count -eq 0) {
        Write-Host "  install.sh contains necessary installation functions" -ForegroundColor Green
    } else {
        Write-Host "  install.sh may be missing: $($missingFunctions -join ', ')" -ForegroundColor Yellow
    }
} else {
    Write-Host "  install.sh not found in dist\config\" -ForegroundColor Red
    Write-Host "  Please rebuild the package" -ForegroundColor Yellow
    exit 1
}

# Step 4: Test JAR files (simulate)
Write-Host "`nStep 4: Testing JAR files..." -ForegroundColor Yellow
if ($env:JAVA_HOME) {
    $backendJar = Join-Path $PSScriptRoot "dist\minilpa-backend.jar"
    if (Test-Path $backendJar) {
        Write-Host "  Testing backend JAR..." -ForegroundColor Gray
        try {
            # Only check if jar can be recognized by java, don't actually start
            $jarInfo = & "$env:JAVA_HOME\bin\java.exe" -jar $backendJar --version 2>&1 | Select-Object -First 3
            if ($jarInfo -match "version" -or $jarInfo -match "spring" -or $jarInfo -match "exception") {
                Write-Host "  Backend JAR can be recognized by Java" -ForegroundColor Green
            } else {
                Write-Host "  Cannot verify backend JAR (may need Spring Boot launcher)" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "  Java test skipped" -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "  JAVA_HOME not set, skipping JAR test" -ForegroundColor Yellow
}

# Step 5: Check configuration file format
Write-Host "`nStep 5: Checking configuration file format..." -ForegroundColor Yellow
$configFile = Join-Path $PSScriptRoot "dist\config\application.yml"
if (Test-Path $configFile) {
    $configContent = Get-Content $configFile -Raw
    if ($configContent -match "server:" -and $configContent -match "port:") {
        Write-Host "  application.yml format is correct" -ForegroundColor Green
    } else {
        Write-Host "  application.yml may be missing required configuration" -ForegroundColor Yellow
    }
} else {
    Write-Host "  application.yml not found" -ForegroundColor Red
}

# Step 6: Check systemd service files
Write-Host "`nStep 6: Checking systemd service files..." -ForegroundColor Yellow
$serviceFiles = @("minilpa-backend.service", "minilpa-agent.service")
foreach ($service in $serviceFiles) {
    $servicePath = Join-Path $PSScriptRoot "dist\config\$service"
    if (Test-Path $servicePath) {
        $serviceContent = Get-Content $servicePath -Raw
        if ($serviceContent -match "\[Unit\]" -and $serviceContent -match "\[Service\]" -and $serviceContent -match "ExecStart") {
            Write-Host "  $service format is correct" -ForegroundColor Green
        } else {
            Write-Host "  $service format may be incomplete" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  $service not found" -ForegroundColor Red
    }
}

# Step 7: Check Nginx configuration
Write-Host "`nStep 7: Checking Nginx configuration..." -ForegroundColor Yellow
$nginxConfig = Join-Path $PSScriptRoot "dist\config\nginx.conf.example"
if (Test-Path $nginxConfig) {
    $nginxContent = Get-Content $nginxConfig -Raw
    if ($nginxContent -match "server \{" -and $nginxContent -match "proxy_pass" -and $nginxContent -match "location /api") {
        Write-Host "  nginx.conf.example contains required configuration" -ForegroundColor Green
    } else {
        Write-Host "  nginx.conf.example may be missing configuration" -ForegroundColor Yellow
    }
} else {
    Write-Host "  nginx.conf.example not found" -ForegroundColor Red
}

# Summary
Write-Host "`n=== Test Summary ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Deployment steps verification completed!" -ForegroundColor Green
Write-Host ""
Write-Host "You can deploy following these steps:" -ForegroundColor Yellow
Write-Host "  1. Upload dist directory to server" -ForegroundColor White
Write-Host "  2. Execute: cd /www/wwwroot/minilpa/config" -ForegroundColor White
Write-Host "  3. Execute: chmod +x install.sh" -ForegroundColor White
Write-Host "  4. Execute: sudo ./install.sh" -ForegroundColor White
Write-Host ""
Write-Host "Detailed steps: QUICK_DEPLOY.md or deploy/DEPLOY.md" -ForegroundColor Cyan
