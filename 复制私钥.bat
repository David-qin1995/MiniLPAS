@echo off
echo ========================================
echo 复制私钥到剪贴板（用于 GitHub Secrets）
echo ========================================
echo.

powershell -Command "$key = Get-Content '%USERPROFILE%\.ssh\baota_github_key' -Raw; $key | Set-Clipboard"

if %errorlevel% == 0 (
    echo ✅ 私钥已复制到剪贴板！
    echo.
    echo 现在你可以：
    echo 1. 打开 GitHub：https://github.com/David-qin1995/MiniLPAS/settings/secrets/actions
    echo 2. 点击 New repository secret
    echo 3. Name 输入：BAOTA_SSH_KEY
    echo 4. Secret 输入框按 Ctrl+V 粘贴
    echo 5. 点击 Add secret
    echo.
) else (
    echo ❌ 复制失败，请检查密钥文件是否存在
    echo.
)

pause

