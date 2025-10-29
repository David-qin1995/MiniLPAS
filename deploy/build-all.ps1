# MiniLPA Web 一键构建脚本 (PowerShell)
# 用于Windows开发机，生成Linux部署包

$ErrorActionPreference = "Continue"

Write-Host "=== MiniLPA Web Build Script ===" -ForegroundColor Cyan
Write-Host ""

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$BuildDir = Join-Path $PSScriptRoot "build"
$DistDir = Join-Path $PSScriptRoot "dist"

New-Item -ItemType Directory -Force -Path $BuildDir | Out-Null
New-Item -ItemType Directory -Force -Path $DistDir | Out-Null

# Check Java environment
if (-not $env:JAVA_HOME) {
    Write-Host "Error: Please set JAVA_HOME environment variable (Java 21 required)" -ForegroundColor Red
    exit 1
}

Write-Host "Java Version:" -ForegroundColor Yellow
try {
    $javaVersion = & "$env:JAVA_HOME\bin\java.exe" -version 2>&1
    Write-Host $javaVersion
} catch {
    Write-Host "Java is available"
}

Write-Host ""
Write-Host "1. Building backend service..." -ForegroundColor Cyan
Set-Location (Join-Path $ProjectRoot "web-backend")
& .\gradlew.bat clean bootJar --no-daemon
$BackendJar = Get-ChildItem "build\libs\*.jar" | Where-Object { $_.Name -notlike "*-plain.jar" } | Select-Object -First 1
if ($BackendJar) {
    # 创建app目录并复制JAR文件
    $AppDir = Join-Path $DistDir "app"
    New-Item -ItemType Directory -Force -Path $AppDir | Out-Null
    Copy-Item $BackendJar.FullName (Join-Path $AppDir "minilpa-backend.jar") -Force
    Write-Host "   Backend JAR: $($BackendJar.Name)" -ForegroundColor Green
} else {
    Write-Host "   Error: Backend JAR not found" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "2. Building local agent..." -ForegroundColor Cyan
Set-Location (Join-Path $ProjectRoot "local-agent")
& .\gradlew.bat clean build --no-daemon
$AgentJar = Get-ChildItem "build\libs\*.jar" | Where-Object { $_.Name -notlike "*-plain.jar" } | Select-Object -First 1
if ($AgentJar) {
    # 使用已创建的app目录
    $AppDir = Join-Path $DistDir "app"
    Copy-Item $AgentJar.FullName (Join-Path $AppDir "minilpa-agent.jar") -Force
    Write-Host "   Agent JAR: $($AgentJar.Name)" -ForegroundColor Green
} else {
    Write-Host "   Error: Agent JAR not found" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "3. Building frontend..." -ForegroundColor Cyan
$FrontendDir = Join-Path $ProjectRoot "web-frontend"
Set-Location $FrontendDir
if (-not (Test-Path "node_modules")) {
    Write-Host "   Installing dependencies..." -ForegroundColor Yellow
    $npmCmd = Get-Command npm -ErrorAction SilentlyContinue
    if (-not $npmCmd) {
        Write-Host "   Error: npm not found, please install Node.js" -ForegroundColor Red
        exit 1
    }
    npm install
    if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne $null) {
        Write-Host "   Error: npm install failed" -ForegroundColor Red
        exit 1
    }
}
npm run build
if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne $null) {
    Write-Host "   Error: npm build failed" -ForegroundColor Red
    if (-not (Test-Path "dist")) {
        exit 1
    }
}
if (Test-Path "dist") {
    $FrontendDest = Join-Path $DistDir "frontend"
    if (Test-Path $FrontendDest) {
        Remove-Item $FrontendDest -Recurse -Force
    }
    Copy-Item -Path "dist" -Destination $FrontendDest -Recurse -Force
    Write-Host "   Frontend built successfully" -ForegroundColor Green
} else {
    Write-Host "   Error: Frontend build failed, dist directory not found" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "4. Copying configuration files..." -ForegroundColor Cyan
$ConfigDir = Join-Path $DistDir "config"
New-Item -ItemType Directory -Force -Path $ConfigDir | Out-Null

# Copy configuration files
Copy-Item (Join-Path $PSScriptRoot "nginx.conf.example") (Join-Path $ConfigDir "nginx.conf.example") -Force
Copy-Item (Join-Path $PSScriptRoot "minilpa-backend.service") (Join-Path $ConfigDir "minilpa-backend.service") -Force
Copy-Item (Join-Path $PSScriptRoot "minilpa-agent.service") (Join-Path $ConfigDir "minilpa-agent.service") -Force
Copy-Item (Join-Path $PSScriptRoot "application-prod.yml") (Join-Path $ConfigDir "application.yml") -Force

# Copy installation scripts
if (Test-Path (Join-Path $PSScriptRoot "install.sh")) {
    Copy-Item (Join-Path $PSScriptRoot "install.sh") (Join-Path $ConfigDir "install.sh") -Force
    Write-Host "   install.sh copied" -ForegroundColor Gray
}
if (Test-Path (Join-Path $PSScriptRoot "update.sh")) {
    Copy-Item (Join-Path $PSScriptRoot "update.sh") (Join-Path $ConfigDir "update.sh") -Force
    Write-Host "   update.sh copied" -ForegroundColor Gray
}

# Copy LPAC files (if available)
Write-Host ""
Write-Host "5. Checking LPAC files..." -ForegroundColor Cyan
$lpacDir = Join-Path $DistDir "lpac"
New-Item -ItemType Directory -Force -Path $lpacDir | Out-Null

# Check for Linux LPAC in build directory
$linuxLpacInBuild = Join-Path $ProjectRoot "MiniLPA-main\build\lpac\linux_x86.zip"
if (Test-Path $linuxLpacInBuild) {
    Write-Host "   Found Linux LPAC in build directory" -ForegroundColor Green
    Write-Host "   Note: Extract and copy to lpac/linux-x86_64/ manually" -ForegroundColor Yellow
}

# Check for Windows LPAC (for reference)
$winLpac = Join-Path $ProjectRoot "MiniLPA-main\windows_x86\lpac.exe"
if (Test-Path $winLpac) {
    Write-Host "   Found Windows LPAC (Windows only)" -ForegroundColor Gray
}

# Create a README for LPAC setup
$lpacReadme = @"
# LPAC可执行文件配置说明

LPAC文件需要在部署服务器上手动配置。

## 文件位置

将LPAC可执行文件放在：
/www/wwwroot/minilpa/lpac/linux-x86_64/lpac

或根据你的服务器架构选择对应目录：
- linux-x86_64/
- linux-x86/
- windows-x86_64/  (如需要)

## 获取LPAC文件

1. 从MiniLPA Releases下载: https://github.com/EsimMoe/MiniLPA/releases/latest
2. 或从MiniLPA-main项目的build/lpac目录提取
3. 或手动编译: https://github.com/estkme/lpac

## 设置权限

chmod +x /www/wwwroot/minilpa/lpac/linux-x86_64/lpac

详细说明请参考: LPAC_SETUP.md
"@
$lpacReadme | Out-File -FilePath (Join-Path $lpacDir "README.txt") -Encoding UTF8
Write-Host "   Created LPAC README" -ForegroundColor Gray

Write-Host ""
Write-Host "=== Build Completed ===" -ForegroundColor Green
Write-Host ""
Write-Host "Deployment files location: $DistDir" -ForegroundColor Yellow
Write-Host ""
Write-Host "File list:" -ForegroundColor Cyan
Get-ChildItem $DistDir -Recurse | Select-Object FullName, @{Name="Size(KB)";Expression={[math]::Round($_.Length/1KB,2)}} | Format-Table -AutoSize
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Package the $DistDir directory" -ForegroundColor White
Write-Host "2. Upload to server /www/wwwroot/minilpa/" -ForegroundColor White
Write-Host "3. Follow deploy/DEPLOY.md for deployment" -ForegroundColor White
Write-Host ""

# 创建压缩包（可选）
$ZipFile = Join-Path $PSScriptRoot "minilpa-web-deploy.zip"
if (Test-Path $ZipFile) {
    Remove-Item $ZipFile -Force
}
Write-Host "Creating deployment package..." -ForegroundColor Cyan
Compress-Archive -Path "$DistDir\*" -DestinationPath $ZipFile -Force
Write-Host "Package created: $ZipFile" -ForegroundColor Green

