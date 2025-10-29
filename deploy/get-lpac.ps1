# 获取LPAC文件的辅助脚本（Windows）

$ErrorActionPreference = "Continue"

Write-Host "=== LPAC File Location Script ===" -ForegroundColor Cyan
Write-Host ""

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$MiniLPADir = Join-Path $ProjectRoot "MiniLPA-main"

# 检查MiniLPA-main是否存在
if (-not (Test-Path $MiniLPADir)) {
    Write-Host "Error: MiniLPA-main directory not found" -ForegroundColor Red
    exit 1
}

Write-Host "1. Checking for Windows LPAC..." -ForegroundColor Yellow
$winLpac = Join-Path $MiniLPADir "windows_x86\lpac.exe"
if (Test-Path $winLpac) {
    $size = (Get-Item $winLpac).Length / 1MB
    Write-Host "   Windows LPAC found: $([math]::Round($size, 2)) MB" -ForegroundColor Green
} else {
    Write-Host "   Windows LPAC not found" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "2. Checking build directory for LPAC..." -ForegroundColor Yellow
$buildLpacDir = Join-Path $MiniLPADir "build\lpac"
if (Test-Path $buildLpacDir) {
    $lpacZips = Get-ChildItem $buildLpacDir -Filter "*.zip" -Recurse
    if ($lpacZips.Count -gt 0) {
        Write-Host "   Found LPAC archives:" -ForegroundColor Green
        $lpacZips | ForEach-Object {
            $size = $_.Length / 1MB
            Write-Host "     - $($_.Name): $([math]::Round($size, 2)) MB" -ForegroundColor Gray
            Write-Host "        Location: $($_.FullName.Replace($ProjectRoot + '\', ''))" -ForegroundColor Gray
        }
    } else {
        Write-Host "   No LPAC archives found in build directory" -ForegroundColor Yellow
    }
} else {
    Write-Host "   Build directory not found" -ForegroundColor Yellow
    Write-Host "   Run: cd MiniLPA-main && .\gradlew.bat setupResources" -ForegroundColor Gray
}

Write-Host ""
Write-Host "3. LPAC file locations for deployment:" -ForegroundColor Yellow
Write-Host "   Windows: MiniLPA-main\windows_x86\lpac.exe" -ForegroundColor Gray
Write-Host "   Linux:   Need to download or extract from build/lpac/" -ForegroundColor Gray
Write-Host "   macOS:   Need to download or extract from build/lpac/" -ForegroundColor Gray

Write-Host ""
Write-Host "4. How to get Linux LPAC:" -ForegroundColor Yellow
Write-Host "   Option 1: Download from GitHub Releases" -ForegroundColor White
Write-Host "     https://github.com/EsimMoe/MiniLPA/releases/latest" -ForegroundColor Gray
Write-Host ""
Write-Host "   Option 2: Build from MiniLPA-main" -ForegroundColor White
Write-Host "     cd MiniLPA-main" -ForegroundColor Gray
Write-Host "     .\gradlew.bat setupResources" -ForegroundColor Gray
Write-Host "     # Files will be in build/lpac/" -ForegroundColor Gray
Write-Host ""
Write-Host "   Option 3: Compile from source" -ForegroundColor White
Write-Host "     https://github.com/estkme/lpac" -ForegroundColor Gray

Write-Host ""
Write-Host "5. Deployment location:" -ForegroundColor Yellow
Write-Host "   Linux server: /www/wwwroot/minilpa/lpac/linux-x86_64/lpac" -ForegroundColor Gray
Write-Host ""
Write-Host "For detailed instructions, see: LPAC_SETUP.md" -ForegroundColor Cyan

