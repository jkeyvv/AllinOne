# AllinOne — AI 开发环境离线安装包

一键部署 AI 开发全套工具链，适用于无网络或网络受限的 Windows 机器。

## 包含组件

| 组件 | 说明 |
|------|------|
| Python | 编程语言运行时 |
| Node.js | JavaScript 运行时 |
| Claude Code | Anthropic 官方 AI 编程 CLI |
| OpenCode | AI 编程助手 |
| Python 依赖 | 100+ 包，AI/ML、Web、文档处理等常用库 |
| VSCode 扩展 | 50+ 扩展，嵌入式开发、C/C++、Python 等 |
| Claude 插件 | 25 个官方插件，代码审查、LSP、前端设计等 |
| WSL 发行版 | 默认 WSL Linux 发行版完整导出 |

## 用法

```powershell
# 导出全部（在线机器）
powershell -ExecutionPolicy Bypass -File AllinOne.ps1 -Export -All

# 导入全部（离线机器）
powershell -ExecutionPolicy Bypass -File AllinOne.ps1 -Import -All

# 仅导出 npm
powershell -ExecutionPolicy Bypass -File AllinOne.ps1 -Export -Node

# 仅导入 npm
powershell -ExecutionPolicy Bypass -File AllinOne.ps1 -Import -Node

# 仅导出 Python
powershell -ExecutionPolicy Bypass -File AllinOne.ps1 -Export -Python

# 仅导入 Python
powershell -ExecutionPolicy Bypass -File AllinOne.ps1 -Import -Python

# 仅导出 VSCode 扩展
powershell -ExecutionPolicy Bypass -File AllinOne.ps1 -Export -VSCode

# 仅导入 VSCode 扩展
powershell -ExecutionPolicy Bypass -File AllinOne.ps1 -Import -VSCode

# 仅导出 Claude 插件
powershell -ExecutionPolicy Bypass -File AllinOne.ps1 -Export -Claude

# 仅导入 Claude 插件
powershell -ExecutionPolicy Bypass -File AllinOne.ps1 -Import -Claude

# 仅导出 WSL
powershell -ExecutionPolicy Bypass -File AllinOne.ps1 -Export -WSL

# 仅导入 WSL
powershell -ExecutionPolicy Bypass -File AllinOne.ps1 -Import -WSL
```

## 目录结构

```
AllinOne/
├── AllinOne.ps1           # 统一脚本（导出/导入）
├── ExportExtensions.ps1   # VSCode 扩展导出脚本（在线使用）
├── installers/            # Python、Node.js 安装包
├── npm/                   # npm 全局目录副本
├── site-packages/         # Python site-packages 副本
├── extensions/            # VSCode 扩展 .vsix 文件
├── claude-plugins/        # Claude Code 插件目录副本
└── wsl/                   # WSL 发行版导出文件（.tar）
```

## VSCode 扩展导出

`ExportExtensions.ps1` 用于从 Marketplace 下载 .vsix 文件（需要联网）：

```powershell
# 从已安装扩展导出（自动检测当前平台）
powershell -ExecutionPolicy Bypass -File ExportExtensions.ps1

# 从列表文件导出
powershell -ExecutionPolicy Bypass -File ExportExtensions.ps1 -List extensions.txt

# 导出到指定目录
powershell -ExecutionPolicy Bypass -File ExportExtensions.ps1 -OutDir D:\backup\extensions
```

> **注意：** `AllinOne.ps1 -Export -VSCode` 会自动调用此脚本，通常无需单独运行。脚本会自动检测当前平台（win32-x64 或 win32-ia32）。

## WSL 发行版

使用 `-WSL` 参数可导出/导入默认 WSL 发行版：

- **导出**：自动获取默认发行版，导出为 `wsl/<发行版名>.tar`
- **导入**：从 `.tar` 文件导入，安装到 `%USERPROFILE%\WSL\<发行版名>`

```powershell
# 导出默认 WSL（在线机器）
powershell -ExecutionPolicy Bypass -File AllinOne.ps1 -Export -WSL

# 导入 WSL（离线机器）
powershell -ExecutionPolicy Bypass -File AllinOne.ps1 -Import -WSL
```

## 注意事项

- 适用于已安装 Python、Node.js、VSCode 的环境
- `-Export` 导出到 AllinOne 目录，`-Import` 从 AllinOne 导入到本机，100% 离线
- 所有组件导出时**不保留旧数据**，先清空再重新导出
- 所有组件自动适配不同机器的用户路径
- Claude 插件导入不会覆盖 API 配置
- WSL 导出文件较大（通常数 GB），请确保目标磁盘有足够空间
