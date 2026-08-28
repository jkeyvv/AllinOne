# AllinOne — AI 开发环境离线安装包

## 项目概述

Windows 离线安装包，一键部署 AI 开发工具链（Python、Node.js、Claude Code、OpenCode、100+ Python 包、50+ VSCode 扩展、25 Claude 插件、WSL 发行版）。

## 工作流程

1. 在线机器：运行 `AllinOne.ps1 -Export -All` 导出到 AllinOne 目录
2. 拷贝 AllinOne 目录到离线机器
3. 离线机器：运行 `AllinOne.ps1 -Import -All` 导入到本机

> **Claude 插件说明：** `-Import -Claude` 只导入插件文件，不覆盖 API 配置。

## 核心文件

- `AllinOne.ps1` — 统一脚本（导出/导入/清除）
- `ExportExtensions.ps1` — VSCode 扩展导出脚本（从 Marketplace 下载 .vsix，按平台精确匹配）
- `npm/` — npm 全局目录副本
- `site-packages/` — Python site-packages 副本
- `extensions/` — VSCode 扩展 .vsix 文件
- `installers/` — Python、Node.js 安装包
- `claude-plugins/` — Claude Code 插件目录副本
- `wsl/` — WSL 发行版导出文件（.tar）

## 三种模式

| 模式 | 说明 |
|------|------|
| `-Export` | 从本机导出到 AllinOne 目录（在线机器使用） |
| `-Import` | 从 AllinOne 目录导入到本机（离线机器使用） |
| `-Clear` | 清除 AllinOne 目录下的导出文件，释放磁盘空间 |

## 脚本参数

| 参数 | 说明 |
|------|------|
| `-Export` | 导出模式 |
| `-Import` | 导入模式 |
| `-Clear` | 清除模式 |
| `-All` | 操作全部组件 |
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

# 清除全部导出目录
powershell -ExecutionPolicy Bypass -File AllinOne.ps1 -Clear -All

# 仅导出/导入/清除 VSCode 扩展
powershell -ExecutionPolicy Bypass -File AllinOne.ps1 -Export -VSCode
powershell -ExecutionPolicy Bypass -File AllinOne.ps1 -Import -VSCode
powershell -ExecutionPolicy Bypass -File AllinOne.ps1 -Clear -VSCode

# 仅导出/导入/清除 Claude 插件
powershell -ExecutionPolicy Bypass -File AllinOne.ps1 -Export -Claude
powershell -ExecutionPolicy Bypass -File AllinOne.ps1 -Import -Claude
powershell -ExecutionPolicy Bypass -File AllinOne.ps1 -Clear -Claude

# 仅导出/导入/清除 WSL
powershell -ExecutionPolicy Bypass -File AllinOne.ps1 -Export -WSL
powershell -ExecutionPolicy Bypass -File AllinOne.ps1 -Import -WSL
powershell -ExecutionPolicy Bypass -File AllinOne.ps1 -Clear -WSL
```

## 导入/导出行为

所有组件导出时**不保留旧数据**，先清空再重新导出：

| 组件 | 导出行为 | 导入行为 | 清除行为 |
|------|---------|---------|---------|
| site-packages | 删除旧目录，重新复制 | 删除旧目录，重新复制 | 删除目录 |
| npm | 删除旧目录，重新复制 | robocopy 镜像同步 | 删除目录 |
| VSCode 扩展 | 删除旧目录，重新下载（按平台匹配） | 逐个安装 .vsix | 删除目录 |
| Claude 插件 | 删除旧目录，重新复制 | 删除旧目录，重新复制 + 路径适配 | 删除目录 |
| WSL | 覆盖 .tar 文件 | 导入到用户目录 | 删除目录 |

## VSCode 扩展导出说明

`ExportExtensions.ps1` 通过 Marketplace API 下载 .vsix，按 `TargetPlatform` 属性精确匹配平台：
- 优先匹配 `win32-x64` 或 `win32-ia32`（自动检测）
- 找不到则使用通用版本（无 targetPlatform 属性）
- 跳过其他平台（linux、darwin 等）

## Claude 插件导入说明

导入时自动适配用户路径：检测 `installed_plugins.json` 中的 `installPath`，如果导出机器的用户路径与当前机器不同，自动替换。

## WSL 导入路径

WSL 导入默认安装到用户目录下：

```
%USERPROFILE%\WSL\<发行版名>
```

例如：`C:\Users\jkeyv\WSL\Debian`

## Git 说明

以下目录由 `-Export` 自动生成，不提交到 Git：
- `npm/`、`site-packages/`、`extensions/`、`claude-plugins/`、`wsl/`、`installers/`
