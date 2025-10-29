=== LPAC文件快速参考 ===

当前项目中有：
   MiniLPA-main\windows_x86\lpac.exe (Windows版本，0.59 MB)

Linux部署需要（需手动获取）：
   位置: /www/wwwroot/minilpa/linux-x86_64/lpac
  
   获取方式:
    1. GitHub: https://github.com/EsimMoe/MiniLPA/releases/latest
    2. 构建: cd MiniLPA-main && .\gradlew.bat setupResources
    3. 编译: https://github.com/estkme/lpac

    配置:
    mkdir -p /www/wwwroot/minilpa/linux-x86_64
    chmod +x /www/wwwroot/minilpa/linux-x86_64/lpac

详细说明: deploy/LPAC_SETUP.md
