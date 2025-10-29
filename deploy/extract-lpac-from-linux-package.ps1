# Extract LPAC from MiniLPA Linux Package

$ErrorActionPreference = "Continue"

Write-Host "=== Extract LPAC from MiniLPA Linux Package ===" -ForegroundColor Cyan
Write-Host ""

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$LinuxPackageDir = Join-Path $ProjectRoot "MiniLPA-Linux-x86_64"
$MiniLPAMainDir = Join-Path $ProjectRoot "MiniLPA-main"

# Check Linux package directory
if (-not (Test-Path $LinuxPackageDir)) {
    Write-Host "Error: MiniLPA-Linux-x86_64 directory not found" -ForegroundColor Red
    Write-Host "Path: $LinuxPackageDir" -ForegroundColor Gray
    exit 1
}

Write-Host "1. Checking MiniLPA-Linux-x86_64 directory structure..." -ForegroundColor Yellow
Get-ChildItem $LinuxPackageDir -Directory | ForEach-Object {
    Write-Host "   $($_.Name)/" -ForegroundColor Gray
}

Write-Host ""
Write-Host "2. Searching for LPAC executable..." -ForegroundColor Yellow

# Search for possible LPAC file locations
$possiblePaths = @(
    Join-Path $LinuxPackageDir "lib\runtime\bin\lpac"),
    Join-Path $LinuxPackageDir "lib\runtime\lib\lpac"),
    Join-Path $LinuxPackageDir "bin\lpac"),
    Join-Path $LinuxPackageDir "lib\lpac"),
    Join-Path $LinuxPackageDir "lpac")

$found = $false
foreach ($path in $possiblePaths) {
    if (Test-Path $path) {
        $size = (Get-Item $path).Length / 1KB
        Write-Host "   Found: $path ($([math]::Round($size, 2)) KB)" -ForegroundColor Green
        $found = $true
    }
}

if (-not $found) {
    Write-Host "   LPAC executable not found in Linux package directory" -ForegroundColor Yellow
}

# Check JAR file for LPAC resources
Write-Host ""
Write-Host "3. Checking if LPAC is embedded in JAR as resource..." -ForegroundColor Yellow
$jarPath = Join-Path $LinuxPackageDir "lib\app\MiniLPA-all.jar"
if (Test-Path $jarPath) {
    if ($env:JAVA_HOME) {
        try {
            $jarList = & "$env:JAVA_HOME\bin\jar.exe" -tf $jarPath 2>&1 | Select-String -Pattern "lpac.*\.(so|exe|bin)|linux.*lpac|resources.*lpac" | Select-Object -First 20
            if ($jarList) {
                Write-Host "   Found LPAC-related files in JAR:" -ForegroundColor Green
                $jarList | ForEach-Object { Write-Host "     $_" -ForegroundColor Gray }
            } else {
                Write-Host "   LPAC not found as resource in JAR" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "   Cannot read JAR file contents" -ForegroundColor Yellow
        }
    } else {
        Write-Host "   JAVA_HOME not set, cannot check JAR contents" -ForegroundColor Yellow
    }
} else {
    Write-Host "   JAR file not found" -ForegroundColor Yellow
}

# Check MiniLPA-main build directory
Write-Host ""
Write-Host "4. Checking MiniLPA-main build artifacts..." -ForegroundColor Yellow
$buildLpacDir = Join-Path $MiniLPAMainDir "build\lpac"
if (Test-Path $buildLpacDir) {
    $lpacFiles = Get-ChildItem $buildLpacDir -Recurse -Filter "*.zip"
    if ($lpacFiles.Count -gt 0) {
        $lpacFiles | ForEach-Object {
            $size = $_.Length / 1MB
            Write-Host "   Found: $($_.FullName.Replace($ProjectRoot + '\', '')) ($([math]::Round($size, 2)) MB)" -ForegroundColor Green
        }
    } else {
        Write-Host "   No LPAC archives found" -ForegroundColor Yellow
    }
} else {
    Write-Host "   build/lpac directory does not exist" -ForegroundColor Yellow
    Write-Host "   Run: cd MiniLPA-main" -ForegroundColor Gray
    Write-Host "        .\gradlew.bat setupResources" -ForegroundColor Gray
}

Write-Host ""
Write-Host "5. Conclusion:" -ForegroundColor Yellow
Write-Host "   MiniLPA Linux package is a packaged application." -ForegroundColor White
Write-Host "   LPAC executable is likely:" -ForegroundColor White
Write-Host "   1. Downloaded at runtime by the application" -ForegroundColor Gray
Write-Host "   2. Available separately from GitHub Releases" -ForegroundColor Gray
Write-Host "   3. Needs to be extracted from build artifacts" -ForegroundColor Gray
Write-Host ""
Write-Host "Recommendations:" -ForegroundColor Cyan
Write-Host "   - Download LPAC from GitHub Releases: https://github.com/EsimMoe/MiniLPA/releases/latest" -ForegroundColor White
Write-Host "   - Extract from MiniLPA-main/build/lpac/ if available" -ForegroundColor White
Write-Host "   - Or compile from source: https://github.com/estkme/lpac" -ForegroundColor White
