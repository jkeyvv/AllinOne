# AllinOne — AI 开发环境离线安装包

## 项目概述

Windows 离线安装包，一键部署 AI 开发工具链（Python、Node.js、Claude Code、OpenCode、100+ Python 包、50+ VSCode 扩展、25 Claude 插件、WSL 发行版）。

## 工作流程

1. 在线机器：运行 `AllinOne.ps1 -Export -All` 导出到 AllinOne 目录
2. 拷贝 AllinOne 目录到离线机器
3. 离线机器：运行 `AllinOne.ps1 -Import -All` 导入到本机

> **Claude 插件说明：** `-Import -Claude` 只导入插件文件，不覆盖 API 配置。

## 核心文件

- `AllinOne.ps1` — 统一脚本（导出/导入）
- `ExportExtensions.ps1` — VSCode 扩展导出脚本（从 Marketplace 下载 .vsix，自动检测平台）
- `npm/` — npm 全局目录副本
- `site-packages/` — Python site-packages 副本
- `extensions/` — VSCode 扩展 .vsix 文件
- `installers/` — Python、Node.js 安装包
- `claude-plugins/` — Claude Code 插件目录副本
- `wsl/` — WSL 发行版导出文件（.tar）

## 脚本参数

| 参数 | 说明 |
|------|------|
| `-Export` | 导出模式（从本机导出到 AllinOne） |
| `-Import` | 导入模式（从 AllinOne 导入到本机） |
| `-All` | 操作全部 |
| `-Node` | 仅操作 npm |
| `-Python` | 仅操作 Python |
| `-VSCode` | 仅操作 VSCode 扩展 |
| `-Claude` | 仅操作 Claude 插件（不含 API 配置） |
| `-WSL` | 仅操作 WSL 发行版 |

## 常用命令

```powershell
# 导出全部（在线机器）
powershell -ExecutionPolicy Bypass -File AllinOne.ps1 -Export -All

# 导入全部（离线机器）
powershell -ExecutionPolicy Bypass -File AllinOne.ps1 -Import -All

# 仅导出 VSCode 扩展（在线机器）
powershell -ExecutionPolicy Bypass -File AllinOne.ps1 -Export -VSCode

# 仅导入 VSCode 扩展（离线机器）
powershell -ExecutionPolicy Bypass -File AllinOne.ps1 -Import -VSCode

# 仅导出 Claude 插件（在线机器）
powershell -ExecutionPolicy Bypass -File AllinOne.ps1 -Export -Claude

# 仅导入 Claude 插件（离线机器）
powershell -ExecutionPolicy Bypass -File AllinOne.ps1 -Import -Claude

# 仅导出 WSL（在线机器）
powershell -ExecutionPolicy Bypass -File AllinOne.ps1 -Export -WSL

# 仅导入 WSL（离线机器）
powershell -ExecutionPolicy Bypass -File AllinOne.ps1 -Import -WSL
```

## 导入/导出行为

所有组件导出时**不保留旧数据**，先清空再重新导出：

| 组件 | 导出行为 | 导入行为 |
|------|---------|---------|
| site-packages | 删除旧目录，重新复制 | 删除旧目录，重新复制 |
| npm | 删除旧目录，重新复制 | robocopy 镜像同步 |
| VSCode 扩展 | 删除旧目录，重新下载 | 逐个安装 .vsix |
| Claude 插件 | 删除旧目录，重新复制 | 删除旧目录，重新复制 |
| WSL | 覆盖 .tar 文件 | 导入到用户目录 |

## WSL 导入路径

WSL 导入默认安装到用户目录下：

```
%USERPROFILE%\WSL\<发行版名>
```

例如：`C:\Users\jkeyv\WSL\Debian`
