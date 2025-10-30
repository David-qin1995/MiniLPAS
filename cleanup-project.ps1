# 项目清理脚本 - 删除不必要的文件，只保留开发和部署必需文件
# 请仔细检查后再执行

$ErrorActionPreference = "Continue"

Write-Host "=== MiniLPA 项目清理工具 ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "将删除以下类型的文件：" -ForegroundColor Yellow
Write-Host "  1. 临时问题排查文档" -ForegroundColor Gray
Write-Host "  2. 重复的文档和脚本" -ForegroundColor Gray
Write-Host "  3. 测试和验证脚本" -ForegroundColor Gray
Write-Host "  4. 构建产物目录（可重新生成）" -ForegroundColor Gray
Write-Host "  5. Windows发布包（仅用于提取LPAC）" -ForegroundColor Gray
Write-Host "  6. 重复的MiniLPAS目录" -Foreground應當Gray
Write-Host ""
Write-Host "将保留：" -ForegroundColor Green
Write-Host "  - 源代码目录（web-backend, local-agent, web-frontend）" -ForegroundColor White
Write-Host "  - 部署脚本和配置（deploy/目录）" -ForegroundColor White
Write-Host "  - 核心文档（README.md, docs/）" -ForegroundColor White
Write-Host "  - CI/CD配置（.github/）" -ForegroundColor White
Write-Host "  - Gradle配置和wrapper" -ForegroundColor White
Write-Host ""
$confirm = Read-Host "确认执行清理? (yes/no)"
if ($confirm -ne "yes") {
    Write-Host "已取消" -ForegroundColor Yellow
    exit 0
}

Write-Host "`n开始清理..." -ForegroundColor Cyan

# 1. 删除临时问题排查文档
$tempDocs = @(
    "PCSC错误说明.md",
    "LPAC缺失说明.md",
    "修复白屏问题.md",
    "Java版本差异说明.md",
    "Java版本差异分析.md",
    "Java版本问题已解决.md",
    "Java路径问题分析.md",
    "GradleJava21问题修复说明.md",
    "GradleWrapper问题修复.md",
    "修复总结.md",
    "运行状态.md",
    "问题总结.md",
    "运行失败原因和解决方案.md",
    "解决Java版本差异的说明.md",
    "启动失败排查结果.md",
    "最终修复说明.md",
    "nginx配置优化建议.md",
    "Nginx配置修复方案.md",
    "nginx配置检查.md",
    "检查部署状态.md",
    "快速启动.md",
    "启动说明.md",
    "部署失败排查指南.md",
    "修复Java路径.ps1",
    "修复并启动.ps1",
    "快速修复Java.ps1",
    "诊断运行问题.ps1",
    "启动本地项目.ps1",
    "启动服务.ps1",
    "立即启动.ps1",
    "启动所有服务.ps1",
    "编译运行.ps1",
    "本地启动.ps1",
    "复制私钥.bat",
    "查看公钥.bat",
    "添加公钥到服务器.txt",
    "操作步骤.txt",
    "系统优化参考文档.md",
    "web-frontend\优化总结.md",
    "web-frontend\启动说明.md",
    "web-frontend\运行前端.md",
    "web-frontend\快速启动.bat",
    "web-frontend\start-dev.ps1"
)

foreach ($file in $tempDocs) {
    if (Test-Path $file) {
        Remove-Item $file -Force -ErrorAction SilentlyContinue
        Write-Host "  删除: $file" -ForegroundColor Gray
    }
}

# 2. 删除重复的文档（保留根目录的版本）
$duplicateDocs = @(
    "PROJECT_STATUS.md",
    "QUICK_DEPLOY.md",
    "QUICK_START.md",
    "README_WEB.md",
    "RUN_PROJECT.md",
    "START_GUIDE.md",
    "TROUBLESHOOTING.md",
    "WEB_ARCHITECTURE.md",
    "FEATURES_IMPLEMENTED.md",
    "IMPLEMENTATION_PLAN.md"
)

foreach ($file in $duplicateDocs) {
    if (Test-Path $file) {
        Remove-Item $file -Force -ErrorAction SilentlyContinue
        Write-Host "  删除: $file" -ForegroundColor Gray
    }
}

# 3. 删除测试和验证脚本
$testScripts = @(
    "deploy\test-deployment-steps.ps1",
    "deploy\test-run.ps1",
    "deploy\test-summary.md",
    "deploy\verify-package.ps1",
    "deploy\extract-lpac-from-linux-package.ps1",
    "deploy\extract-lpac.ps1",
    "deploy\get-lpac.ps1"
)

foreach ($file in $testScripts) {
    if (Test-Path $file) {
        Remove-Item $file -Force -ErrorAction SilentlyContinue
        Write-Host "  删除: $file" -ForegroundColor Gray
    }
}

# 4. 删除重复的文档（保留deploy目录的）
$deployDuplicateDocs = @(
    "deploy\CHECKLIST.md",
    "deploy\FIND_LPAC_LINUX.md",
    "deploy\LPAC_QUICK_REF.md",
    "deploy\NGINX_FIX.md",
    "deploy\UPLOAD_GUIDE.md",
    "deploy\VALIDATION_GUIDE.md"
)

foreach ($file in $deployDuplicateDocs) {
    if (Test-Path $file) {
        Remove-Item $file -Force -ErrorAction SilentlyContinue
        Write-Host "  删除: $file" -ForegroundColor Gray
    }
}

# 5. 删除构建产物目录（可重新生成）
$buildDirs = @(
    "web-backend\build",
    "local-agent\build",
    "web-frontend\dist",
    "web-frontend\node_modules"
)

foreach ($dir in $buildDirs) {
    if (Test-Path $dir) {
        Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "  删除目录: $dir" -ForegroundColor Gray
    }
}

# 6. 删除Windows发布包（LPAC已提取）
if (Test-Path "MiniLPA-Windows-x86_64") {
    Remove-Item "MiniLPA-Windows-x86_64" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "  删除: MiniLPA-Windows-x86_64" -ForegroundColor Gray
}

# 7. 删除重复的MiniLPAS目录
Если (Test-Path "MiniLPAS") {
    Remove-Item "MiniLPAS" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "  删除: MiniLPAS" -ForegroundColor Gray
}

# 8. 删除其他临时文件
$otherFiles = @(
    "ftp-ai-install.exe"
)

foreach ($file in $otherFiles) {
    if (Test-Path $file) {
        Remove-Item $file -Force -ErrorAction SilentlyContinue
        Write-Host "  删除: $file" -ForegroundColor Gray
    }
}

Write-Host "`n清理完成！" -ForegroundColor Green
Write-Host ""
Write-Host "保留的核心文件：" -ForegroundColor Cyan
Write-Host "  - README.md (主文档)" -ForegroundColor White
Write-Host "  - docs/ (项目文档)" -ForegroundColor White
Write-Host "  - deploy/ (部署脚本和配置)" -ForegroundColor White
Write-Host "  - web-backend/, local-agent/, web-frontend/ (源代码)" -ForegroundColor White
Write-Host "  - .github/ (CI/CD)" -ForegroundColor White
Write-Host "  - start-all.ps1 (本地启动脚本)" -ForegroundColor White
Write-Host "  - 本地编译运行指南.md (开发指南)" -ForegroundColor White

