# AllinOne — AI 开发环境离线安装包

一键部署 AI 开发全套工具链，适用于无网络或网络受限的 Windows 机器。

## 工作流程

1. **在线机器**：运行 `AllinOne.ps1 -Export -All` 将本机环境导出到 AllinOne 目录
2. **拷贝**：将整个 AllinOne 目录拷贝到离线机器（U盘、移动硬盘等）
3. **离线机器**：运行 `AllinOne.ps1 -Import -All` 从 AllinOne 目录导入到本机

## 包含组件

| 组件 | 参数 | 说明 |
|------|------|------|
| Python 依赖 | `-Python` | site-packages 目录，100+ 常用包 |
| npm 全局包 | `-Node` | Claude Code、OpenCode、Prettier 等 |
| VSCode 扩展 | `-VSCode` | 50+ .vsix 扩展文件 |
| Claude 插件 | `-Claude` | 25 个官方插件（不含 API 配置） |
| WSL 发行版 | `-WSL` | 默认 WSL 发行版完整导出 |

## 三种模式

| 模式 | 说明 |
|------|------|
| `-Export` | 从本机导出到 AllinOne 目录（在线机器使用） |
| `-Import` | 从 AllinOne 目录导入到本机（离线机器使用） |
| `-Clear` | 清除 AllinOne 目录下的导出文件，释放磁盘空间 |

## 快速开始

```powershell
# 导出全部（在线机器）
powershell -ExecutionPolicy Bypass -File AllinOne.ps1 -Export -All

# 导入全部（离线机器）
powershell -ExecutionPolicy Bypass -File AllinOne.ps1 -Import -All
```

---

## 各功能详细说明

### Python site-packages

导出/导入 Python 全局 site-packages 目录，包含所有通过 pip 安装的包。

**导出（在线机器）**

```powershell
powershell -ExecutionPolicy Bypass -File AllinOne.ps1 -Export -Python
```

- **来源**：`python -c "import site; print(site.getsitepackages()[1])"` 获取本机 site-packages 路径
- **目标**：`AllinOne/site-packages/`
- **行为**：先删除旧的 `site-packages/` 目录，再重新复制
- **清理**：自动删除 `__pycache__` 目录，减小体积
- **输出**：显示导出的包数量（按 `.dist-info` 目录计数）

**导入（离线机器）**

```powershell
powershell -ExecutionPolicy Bypass -File AllinOne.ps1 -Import -Python
```

- **来源**：`AllinOne/site-packages/`
- **目标**：离线机器的 Python site-packages 路径（自动检测）
- **行为**：先删除目标目录，再从 AllinOne 复制过去
- **前提**：离线机器需已安装同版本 Python

---

### npm 全局包

导出/导入 npm 全局安装的包（`node_modules` 目录）。

**导出（在线机器）**

```powershell
powershell -ExecutionPolicy Bypass -File AllinOne.ps1 -Export -Node
```

- **来源**：`npm root -g` 获取本机全局 node_modules 路径
- **目标**：`AllinOne/npm/`
- **行为**：先删除旧的 `npm/` 目录，再重新复制
- **清理**：自动删除 `.package-lock` 目录、`*.md`、`LICENSE*`、`CHANGELOG*`、`.npmignore`、`.gitignore` 等非必要文件
- **输出**：显示导出的包数量

**导入（离线机器）**

```powershell
powershell -ExecutionPolicy Bypass -File AllinOne.ps1 -Import -Node
```

- **来源**：`AllinOne/npm/`
- **目标**：离线机器的 npm 全局目录（自动检测）
- **行为**：使用 `robocopy /MIR` 镜像同步（只复制差异，效率高）
- **注意**：如果部分文件正在使用中会被跳过，不影响其他包

---

### VSCode 扩展

导出/导入 VSCode 扩展。导出时从 Marketplace 下载 `.vsix` 文件，导入时逐个安装。

**导出（在线机器）**

```powershell
powershell -ExecutionPolicy Bypass -File AllinOne.ps1 -Export -VSCode
```

- **流程**：自动调用 `ExportExtensions.ps1`
  1. 运行 `code --list-extensions` 获取已安装扩展列表
  2. 保存列表到 `extensions/extensions.txt`
  3. 从 VSCode Marketplace API 逐个下载 `.vsix` 文件
- **目标**：`AllinOne/extensions/`
- **平台检测**：自动检测 `win32-x64` 或 `win32-ia32`，优先下载对应平台版本，找不到则用通用版本
- **跳过已下载**：如果某个扩展的 `.vsix` 已存在，自动跳过
- **行为**：先删除旧的 `extensions/` 目录，再重新下载

**导入（离线机器）**

```powershell
powershell -ExecutionPolicy Bypass -File AllinOne.ps1 -Import -VSCode
```

- **来源**：`AllinOne/extensions/*.vsix`
- **行为**：逐个调用 `code --install-extension <vsix文件> --force` 安装
- **前提**：离线机器需已安装 VSCode（`code` 命令可用）
- **输出**：显示成功/失败数量

**单独使用导出脚本**

`ExportExtensions.ps1` 也可以独立使用：

```powershell
# 从已安装扩展导出
powershell -ExecutionPolicy Bypass -File ExportExtensions.ps1

# 从指定列表文件导出
powershell -ExecutionPolicy Bypass -File ExportExtensions.ps1 -List my-extensions.txt

# 导出到指定目录
powershell -ExecutionPolicy Bypass -File ExportExtensions.ps1 -OutDir D:\backup\ext
```

---

### Claude 插件

导出/导入 Claude Code 插件目录（`~/.claude/plugins`）。

**导出（在线机器）**

```powershell
powershell -ExecutionPolicy Bypass -File AllinOne.ps1 -Export -Claude
```

- **来源**：`%USERPROFILE%\.claude\plugins\`
- **目标**：`AllinOne/claude-plugins/`
- **行为**：先删除旧的 `claude-plugins/` 目录，再从本机复制整个 plugins 目录
- **包含**：已安装插件、marketplace 缓存、插件目录等
- **不包含**：Claude API 配置（密钥等保留在本机）

**导入（离线机器）**

```powershell
powershell -ExecutionPolicy Bypass -File AllinOne.ps1 -Import -Claude
```

- **来源**：`AllinOne/claude-plugins/`
- **目标**：`%USERPROFILE%\.claude\plugins\`
- **行为**：先删除目标目录，再从 AllinOne 复制过去
- **路径适配**：自动检测 `installed_plugins.json` 中的用户路径，如果与当前机器不同则自动替换（例如 `C:\Users\张三` → `C:\Users\李四`）

---

### WSL 发行版

导出/导入默认 WSL Linux 发行版。

**导出（在线机器）**

```powershell
powershell -ExecutionPolicy Bypass -File AllinOne.ps1 -Export -WSL
```

- **来源**：自动检测 `wsl --list --verbose` 中标记为 `*` 的默认发行版
- **目标**：`AllinOne/wsl/<发行版名>.tar`
- **行为**：调用 `wsl --export` 导出为 `.tar` 文件
- **注意**：导出文件通常数 GB，请确保目标磁盘有足够空间

**导入（离线机器）**

```powershell
powershell -ExecutionPolicy Bypass -File AllinOne.ps1 -Import -WSL
```

- **来源**：`AllinOne/wsl/*.tar`
- **目标**：`%USERPROFILE%\WSL\<发行版名>\`
- **行为**：调用 `wsl --import` 从 `.tar` 文件导入，安装到用户目录下
- **前提**：离线机器需已启用 WSL 功能

---

### 清除导出目录

清除 AllinOne 目录下已导出的文件，释放磁盘空间。可以按组件单独清除，也可以一次性全部清除。

```powershell
# 清除全部导出目录
powershell -ExecutionPolicy Bypass -File AllinOne.ps1 -Clear -All

# 仅清除 npm
powershell -ExecutionPolicy Bypass -File AllinOne.ps1 -Clear -Node

# 仅清除 Python
powershell -ExecutionPolicy Bypass -File AllinOne.ps1 -Clear -Python

# 仅清除 VSCode 扩展
powershell -ExecutionPolicy Bypass -File AllinOne.ps1 -Clear -VSCode

# 仅清除 Claude 插件
powershell -ExecutionPolicy Bypass -File AllinOne.ps1 -Clear -Claude

# 仅清除 WSL
powershell -ExecutionPolicy Bypass -File AllinOne.ps1 -Clear -WSL
```

- **行为**：直接删除对应的导出目录（`site-packages/`、`npm/`、`extensions/`、`claude-plugins/`、`wsl/`）
- **注意**：清除后需要重新 `-Export` 才能再次导入

---

## 目录结构

```
AllinOne/
├── AllinOne.ps1           # 统一脚本（导出/导入）
├── ExportExtensions.ps1   # VSCode 扩展导出脚本
├── CLAUDE.md              # Claude Code 项目说明
├── README.md              # 本文档
├── .gitignore
│
│   ↓ 以下目录由 -Export 自动生成，不提交到 Git ↓
│
├── installers/            # Python、Node.js 安装包
├── npm/                   # npm 全局目录副本
├── site-packages/         # Python site-packages 副本
├── extensions/            # VSCode 扩展 .vsix 文件
├── claude-plugins/        # Claude Code 插件目录副本
└── wsl/                   # WSL 发行版导出文件（.tar）
```

## 注意事项

- 适用于已安装 Python、Node.js、VSCode 的环境
- `-Export` 导出到 AllinOne 目录，`-Import` 从 AllinOne 导入到本机，100% 离线
- 所有组件导出时**不保留旧数据**，先清空再重新导出
- 所有组件自动适配不同机器的用户路径
- Claude 插件导入不会覆盖 API 配置
- WSL 导出文件较大（通常数 GB），请确保目标磁盘有足够空间
