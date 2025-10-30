# Extract LPAC from MiniLPA-Linux-x86_64 JAR

$ErrorActionPreference = "Continue"

Write-Host "=== Extract LPAC from MiniLPA Linux Package ===" -ForegroundColor Cyan
Write-Host ""

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$LinuxPackageJar = Join-Path $ProjectRoot "MiniLPA-Linux-x86_64\lib\app\MiniLPA-all.jar"
$OutputDir = Join-Path $ProjectRoot "lpac-extracted"

# Check if JAR exists
if (-not (Test-Path $LinuxPackageJar)) {
    Write-Host "Error: MiniLPA-all.jar not found" -ForegroundColor Red
    Write-Host "Path: $LinuxPackageJar" -ForegroundColor Gray
    exit 1
}

if (-not $env:JAVA_HOME) {
    Write-Host "Error: JAVA_HOME not set" -ForegroundColor Red
    exit 1
}

Write-Host "1. Extracting linux_x86.zip from JAR..." -ForegroundColor Yellow
$jarDir = Split-Path -Parent $LinuxPackageJar
Push-Location $jarDir

try {
    # Extract zip file
    & "$env:JAVA_HOME\bin\jar.exe" -xf MiniLPA-all.jar linux_x86.zip
    
    if (-not (Test-Path "linux_x86.zip")) {
        Write-Host "   Error: linux_x86.zip not found in JAR" -ForegroundColor Red
        exit 1
    }
    
    $zipSize = (Get-Item "linux_x86.zip").Length / 1KB
    Write-Host "   Extracted: linux_x86.zip ($([math]::Round($zipSize, 2)) KB)" -ForegroundColor Green
    
    Write-Host ""
    Write-Host "2. Extracting LPAC from zip..." -ForegroundColor Yellow
    
    # Create output directory
    New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
    
    # Extract zip
    Expand-Archive -Path "linux_x86.zip" -DestinationPath $OutputDir -Force
    
    # Find lpac file
    $lpacFiles = Get-ChildItem $OutputDir -Recurse -Filter "lpac*" | Where-Object { -not $_.PSIsContainer }
    
    if ($lpacFiles.Count -gt 0) {
        Write-Host "   Found LPAC files:" -ForegroundColor Green
        foreach ($lpac in $lpacFiles) {
            $size = $lpac.Length / 1KB
            $relativePath = $lpac.FullName.Replace($OutputDir + "\", "")
            Write-Host "     - $relativePath ($([math]::Round($size, 2)) KB)" -ForegroundColor Gray
        }
        
        Write-Host ""
        Write-Host "3. Copy LPAC for deployment..." -ForegroundColor Yellow
        $mainLpac = $lpacFiles | Where-Object { $_.Name -eq "lpac" -or $_.Name -eq "lpac.exe" } | Select-Object -First 1
        
        if ($mainLpac) {
            $deployPath = Join-Path $ProjectRoot "deploy\lpac\linux-x86_64"
            New-Item -ItemType Directory -Force -Path $deployPath | Out-Null
            
            Copy-Item $mainLpac.FullName (Join-Path $deployPath "lpac") -Force
            Write-Host "   Copied to: deploy\lpac\linux-x86_64\lpac" -ForegroundColor Green
            Write-Host "   Size: $([math]::Round($mainLpac.Length/1KB, 2)) KB" -ForegroundColor Gray
            
            Write-Host ""
            Write-Host "✅ LPAC extraction completed!" -ForegroundColor Green
            Write-Host ""
            Write-Host "Next steps:" -ForegroundColor Cyan
            Write-Host "  1. The LPAC file is ready in: deploy\lpac\linux-x86_64\lpac" -ForegroundColor White
            Write-Host "  2. When building deployment package, it will be included" -ForegroundColor White
            Write-Host "  3. Or manually copy to server: /www/wwwroot/minilpa/linux-x86_64/lpac" -ForegroundColor White
        } else {
            Write-Host "   Warning: Could not find main lpac executable" -ForegroundColor Yellow
        }
    } else {
        Write-Host "   Error: No LPAC files found in extracted zip" -ForegroundColor Red
        Write-Host "   Contents of extracted directory:" -ForegroundColor Yellow
        Get-ChildItem $OutputDir -Recurse | Select-Object -First 20 Name, FullName | Format-Table -AutoSize
    }
    
} finally {
    Pop-Location
}

