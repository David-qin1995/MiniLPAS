# 在MiniLPA-Linux-x86_64包中找到LPAC的方法

## 问题分析

`MiniLPA-Linux-x86_64` 目录是一个**打包好的Linux应用程序**，LPAC文件不在可见的文件系统中。

## LPAC的存储方式

根据 `MiniLPA-main/src/main/kotlin/moe/sekiu/minilpa/Main.kt` 的代码：

```kotlin
fun extractResources()
{
    Manifest.loadManifests()
    if (BuildConfig.LPAC_BUILD_TIME > setting.`lpac-build-time`)
    {
        ZipInputStream(bufferedResourceStream("$platform.zip")).unzip(lpacFolder)
        setting.update { `lpac-build-time` = BuildConfig.LPAC_BUILD_TIME }
    }
}
```

**LPAC是作为资源文件打包在JAR中的！**

### 提取位置

1. **资源文件位置**: JAR资源中的 `linux-x86_64.zip`
2. **运行时提取**: 应用首次运行时提取到 `~/.minilpa/linux-x86_64/lpac`
3. **提取条件**: 只有当 `BuildConfig.LPAC_BUILD_TIME` 更新时才重新提取

## 从MiniLPA-Linux-x86_64包中提取LPAC

### 方法1: 从JAR资源中提取（推荐）

```powershell
# 1. 检查JAR中的资源
cd MiniLPA-Linux-x86_64\lib\app
$env:JAVA_HOME\bin\jar.exe -tf MiniLPA-all.jar | Select-String "linux.*zip"

# 2. 提取zip文件
$env:JAVA_HOME\bin\jar.exe -xf MiniLPA-all.jar linux-x86_64.zip

# 3. 解压zip文件
Expand-Archive -Path linux-x86_64.zip -DestinationPath extracted

# 4. 查找lpac文件
Get-ChildItem extracted -Recurse -Filter "lpac*"
```

### 方法2: 从MiniLPA-main构建产物获取

```powershell
# 1. 构建资源
cd MiniLPA-main
.\gradlew.bat setupResources

# 2. 查找构建产物
Get-ChildItem build\resources\main -Filter "*linux*.zip"
Get-ChildItem build\lpac -Filter "*linux*.zip"

# 3. 解压并提取lpac
Expand-Archive -Path build\lpac\linux_x86.zip -DestinationPath temp
Get-ChildItem temp -Recurse -Filter "lpac"
```

### 方法3: 从GitHub Releases下载

直接下载独立LPAC文件：
- https://github.com/EsimMoe/MiniLPA/releases/latest
- 通常在 `MiniLPA-Linux-x86_64.tar.gz` 或其他发布包中

## 实际提取步骤

### Windows PowerShell提取脚本

```powershell
$jarPath = "MiniLPA-Linux-x86_64\lib\app\MiniLPA-all.jar"
$outputDir = "extracted_lpac"

# 创建输出目录
New-Item -ItemType Directory -Force -Path $outputDir | Out-Null

# 提取linux-x86_64.zip
cd MiniLPA-Linux-x86_64\lib\app
& "$env:JAVA_HOME\bin\jar.exe" -xf MiniLPA-all.jar linux-x86_64.zip

# 解压zip
if (Test-Path linux-x86_64.zip) {
    Expand-Archive -Path linux-x86_64.zip -DestinationPath $outputDir -Force
    
    # 查找lpac
    $lpac = Get-ChildItem $outputDir -Recurse -Filter "lpac" | Where-Object { -not $_.PSIsContainer }
    if ($lpac) {
        Write-Host "找到LPAC: $($lpac.FullName)" -ForegroundColor Green
        Write-Host "大小: $([math]::Round($lpac.Length/1KB, 2)) KB" -ForegroundColor Gray
    }
}
```

### Linux Bash提取脚本

```bash
#!/bin/bash
JAR_PATH="MiniLPA-Linux-x86_64/lib/app/MiniLPA-all.jar"
OUTPUT_DIR="extracted_lpac"

# 提取linux-x86_64.zip
cd MiniLPA-Linux-x86_64/lib/app
jar -xf MiniLPA-all.jar linux-x86_64.zip

# 解压
if [ -f linux-x86_64.zip ]; then
    unzip -d "$OUTPUT_DIR" linux-x86_64.zip
    
    # 查找lpac
    find "$OUTPUT_DIR" -name "lpac" -type f
fi
```

## 验证提取的LPAC

提取后，检查文件：

```bash
# 检查文件类型
file extracted_lpac/lpac

# 检查大小（应该约500-1000KB）
ls -lh extracted_lpac/lpac

# 在Linux上测试（如果有Linux环境）
chmod +x extracted_lpac/lpac
./extracted_lpac/lpac version
```

## 部署使用

提取到LPAC后：

```bash
# 在Linux服务器上
mkdir -p /www/wwwroot/minilpa/linux-x86_64
# 上传提取的lpac文件
cp extracted_lpac/lpac /www/wwwroot/minilpa/linux-x86_64/lpac
chmod +x /www/wwwroot/minilpa/linux-x86_64/lpac
```

## 注意事项

1. **二进制兼容性**: 确保提取的LPAC与目标Linux系统架构匹配（x86_64）
2. **依赖库**: LPAC可能需要系统库（libcurl等），确保已安装
3. **权限**: 上传后必须设置执行权限 `chmod +x`
4. **测试**: 在目标系统上测试LPAC是否能正常运行

