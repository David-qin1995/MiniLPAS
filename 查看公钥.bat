@echo off
echo ========================================
echo 查看公钥（用于添加到服务器）
echo ========================================
echo.
echo 公钥内容：
echo.
type "%USERPROFILE%\.ssh\baota_github_key.pub"
echo.
echo ========================================
echo 请复制上面显示的全部内容
echo 然后添加到宝塔面板：安全 - SSH管理 - 添加SSH密钥
echo ========================================
echo.
pause

