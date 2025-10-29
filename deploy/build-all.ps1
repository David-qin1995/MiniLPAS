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
Write-Host "5. Processing LPAC files..." -ForegroundColor Cyan
$lpacDir = Join-Path $DistDir "lpac"
New-Item -ItemType Directory -Force -Path $lpacDir | Out-Null

# Try to extract LPAC from MiniLPA-Linux-x86_64 package
$linuxPackageJar = Join-Path $ProjectRoot "MiniLPA-Linux-x86_64\lib\app\MiniLPA-all.jar"
$extractedLpac = Join-Path $ProjectRoot "MiniLPA-Linux-x86_64\lib\app\lpac_extracted\lpac"
$localLpacDir = Join-Path $PSScriptRoot "lpac"

# Check if we have extracted LPAC locally
if (Test-Path $localLpacDir) {
    $linuxLpac = Join-Path $localLpacDir "linux-x86_64\lpac"
    if (Test-Path $linuxLpac) {
        $destLpacDir = Join-Path $lpacDir "linux-x86_64"
        New-Item -ItemType Directory -Force -Path $destLpacDir | Out-Null
        Copy-Item $linuxLpac (Join-Path $destLpacDir "lpac") -Force
        $size = (Get-Item $linuxLpac).Length / 1KB
        Write-Host "   Copied LPAC from local extract: $([math]::Round($size, 2)) KB" -ForegroundColor Green
    }
}

# Try extracting from MiniLPA-Linux-x86_64 JAR if available
if (-not (Test-Path (Join-Path $lpacDir "linux-x86_64\lpac")) -and (Test-Path $linuxPackageJar) -and $env:JAVA_HOME) {
    Write-Host "   Attempting to extract LPAC from MiniLPA-Linux-x86_64 JAR..." -ForegroundColor Yellow
    $jarDir = Split-Path -Parent $linuxPackageJar
    Push-Location $jarDir
    try {
        # Extract linux_x86.zip
        & "$env:JAVA_HOME\bin\jar.exe" -xf MiniLPA-all.jar linux_x86.zip -ErrorAction SilentlyContinue
        if (Test-Path "linux_x86.zip") {
            # Extract zip
            $tempDir = Join-Path $jarDir "lpac_temp"
            New-Item -ItemType Directory -Force -Path $tempDir | Out-Null
            Expand-Archive -Path "linux_x86.zip" -DestinationPath $tempDir -Force -ErrorAction SilentlyContinue
            
            # Find and copy lpac
            $lpacFile = Get-ChildItem $tempDir -Recurse -Filter "lpac" | Where-Object { -not $_.PSIsContainer } | Select-Object -First 1
            if ($lpacFile) {
                $destLpacDir = Join-Path $lpacDir "linux-x86_64"
                New-Item -ItemType Directory -Force -Path $destLpacDir | Out-Null
                Copy-Item $lpacFile.FullName (Join-Path $destLpacDir "lpac") -Force
                $size = $lpacFile.Length / 1KB
                Write-Host "   Extracted and copied LPAC: $([math]::Round($size, 2)) KB" -ForegroundColor Green
            }
            Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item "linux_x86.zip" -Force -ErrorAction SilentlyContinue
        }
    } catch {
        Write-Host "   Could not extract from JAR: $_" -ForegroundColor Yellow
    } finally {
        Pop-Location
    }
}

# Check for Windows LPAC (for reference)
$winLpac = Join-Path $ProjectRoot "MiniLPA-main\windows_x86\lpac.exe"
if (Test-Path $winLpac) {
    Write-Host "   Found Windows LPAC (Windows only)" -ForegroundColor Gray
}

# Check if LPAC was copied
$finalLpac = Join-Path $lpacDir "linux-x86_64\lpac"
if (Test-Path $finalLpac) {
    Write-Host "   ✅ Linux LPAC included in deployment package" -ForegroundColor Green
} else {
    Write-Host "   ⚠️  Linux LPAC not found, will need manual configuration" -ForegroundColor Yellow
}

# Create a README for LPAC setup
$lpacReadme = @"
# LPAC可执行文件配置说明

LPAC文件已包含在部署包中（如果找到的话）。

## 文件位置

LPAC文件应该在：
/www/wwwroot/minilpa/linux-x86_64/lpac

（注意：local-agent的工作目录是 /www/wwwroot/minilpa）

## 如果没有自动包含

1. 从MiniLPA Releases下载: https://github.com/EsimMoe/MiniLPA/releases/latest
2. 从MiniLPA-Linux-x86_64包中提取（使用 deploy/extract-lpac.ps1）
3. 从MiniLPA-main项目的build/lpac目录提取
4. 或手动编译: https://github.com/estkme/lpac

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

