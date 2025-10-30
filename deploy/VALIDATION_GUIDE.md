# 部署文档验证指南

## 如何确认部署文档中的步骤能正常使用

### 方法1: 使用验证脚本（推荐）

#### 1.1 验证部署包完整性
```powershell
cd deploy
.\verify-package.ps1
```

此脚本会检查：
- ✅ JAR文件是否存在且大小合理
- ✅ 前端文件是否完整
- ✅ 配置文件是否齐全
- ✅ JAR文件格式是否正确

#### 1.2 测试部署步骤
```powershell
cd deploy
.\test-deployment-steps.ps1
```

此脚本会验证：
- ✅ 构建脚本是否存在
- ✅ 部署包是否完整
- ✅ 安装脚本格式是否正确
- ✅ 配置文件格式是否正确
- ✅ systemd服务文件格式是否正确
- ✅ Nginx配置是否包含必要内容

### 方法2: 手动检查清单

#### 检查清单
```powershell
# 1. 检查dist目录结构
cd deploy
Get-ChildItem dist -Recurse | Select-Object FullName

# 2. 检查必需文件
Test-Path dist\minilpa-backend.jar
Test-Path dist\minilpa-agent.jar
Test-Path dist\frontend\index.html
Test-Path dist\config\install.sh
Test-Path dist\config\update.sh
Test-Path dist\config\application.yml
Test-Path dist\config\minilpa-backend.service
Test-Path dist\config\minilpa-agent.service
Test-Path dist\config\nginx.conf.example

# 3. 检查文件大小（JAR应该>10MB）
(Get-Item dist\minilpa-backend.jar).Length / 1MB
```

### 方法3: 本地测试运行

使用 `test-run.ps1` 在本地构建并运行所有组件：

```powershell
cd deploy
.\test-run.ps1
```

这会：
1. 构建所有组件
2. 创建测试目录
3. 启动后端服务
4. 验证服务是否正常运行

如果本地测试通过，部署到服务器也应该能正常工作。

### 方法4: 逐步验证部署文档

#### Step 1: 构建部署包
```powershell
cd deploy
.\build-all.ps1
```

验证点：
- [ ] 构建成功无错误
- [ ] `dist` 目录被创建
- [ ] 所有文件都在 `dist` 目录中

#### Step 2: 检查文件清单
按照 `CHECKLIST.md` 检查所有文件是否存在。

#### Step 3: 验证脚本文件
```powershell
# Windows上检查安装脚本语法（如果安装了Git Bash）
bash -n dist\config\install.sh

# 或检查文件内容
Get-Content dist\config\install.sh | Select-Object -First 10
```

#### Step 4: 测试配置文件
```powershell
# 检查YAML格式（如果安装了Python yaml模块）
python -c "import yaml; yaml.safe_load(open('dist/config/application.yml'))"
```

### 常见问题排查

#### Q: 验证脚本提示文件缺失？
A: 重新运行构建脚本：
```powershell
.\build-all.ps1
```

#### Q: install.sh 不在 dist/config/？
A: 已修复构建脚本，新构建会自动包含。或手动复制：
```powershell
Copy-Item install.sh dist\config\install.sh
Copy-Item update.sh dist\config\update.sh
```

#### Q: 如何确认文件能正常运行？
A: 使用 `test-run.ps1` 在本地测试，确认服务能启动。

#### Q: 在Linux服务器上如何验证？
A: 
```bash
# 检查文件
cd /www/wwwroot/minilpa
ls -la
ls -la config/

# 检查安装脚本语法
bash -n config/install.sh

# 验证systemd服务文件格式
systemd-analyze verify config/minilpa-backend.service
systemd-analyze verify config/minilpa-agent.service

# 验证YAML格式（需要yq或Python）
python3 -c "import yaml; yaml.safe_load(open('config/application.yml'))"
```

### 部署前最终检查

在执行部署前，运行：

```powershell
cd deploy
# 1. 验证部署包
.\verify-package.ps1

# 2. 测试部署步骤
.\test-deployment-steps.ps1

# 3. 本地运行测试（可选）
.\test-run.ps1
```

如果所有验证都通过，说明部署文档中的步骤可以正常使用！

### 验证结果解读

#### ✅ 全部通过
所有必需文件存在，可以部署。

#### ⚠️ 有警告
某些非必需项缺失或格式可能有问题，但不影响基本部署。

#### ❌ 有错误
必需文件缺失，需要重新构建或修复问题。

