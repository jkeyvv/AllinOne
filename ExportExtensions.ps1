# ============================================
# ExportExtensions — 导出 VSCode 扩展为 .vsix
# 运行: powershell -ExecutionPolicy Bypass -File ExportExtensions.ps1
# ============================================

param(
    [string]$OutDir = (Join-Path $PSScriptRoot "extensions"),
    [string]$List   = ""
)

# 自动检测当前平台
$Platform = if ([Environment]::Is64BitOperatingSystem) { "win32-x64" } else { "win32-ia32" }

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"  # 隐藏 Web 请求进度提示

function Log($msg) { Write-Host "`n$msg" -ForegroundColor Cyan }
function OK($msg)  { Write-Host "  ✓ $msg" -ForegroundColor Green }
function Skip($msg) { Write-Host "  ⊘ $msg" -ForegroundColor Yellow }
function Info($msg) { Write-Host "  · $msg" -ForegroundColor Gray }
function Err($msg)  { Write-Host "  ✗ $msg" -ForegroundColor Red }

# 创建输出目录
if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir | Out-Null }

# 获取扩展列表
if ($List -and (Test-Path $List)) {
    Log "从列表文件读取: $List"
    $extensions = Get-Content $List | Where-Object { $_ -match "\S" -and $_ -notmatch "^\s*#" }
} else {
    Log "从已安装扩展读取"
    $extensions = code --list-extensions 2>&1
    if ($LASTEXITCODE -ne 0) {
        Err "无法读取 VSCode 扩展列表"
        exit 1
    }
}

# 保存扩展列表
$listFile = Join-Path $OutDir "extensions.txt"
$extensions | Out-File $listFile -Encoding utf8
Info "扩展列表: $listFile ($($extensions.Count) 个)"

# Marketplace API
$apiUrl = "https://marketplace.visualstudio.com/_apis/public/gallery/extensionquery"
$headers = @{
    "Content-Type" = "application/json"
    "Accept"       = "application/json;api-version=6.0-preview.1"
}

function Get-VsixUrl($extensionId) {
    $body = @{
        filters = @(@{
            criteria = @(@{
                filterType = 7
                value      = $extensionId
            })
        })
        flags = 914
    } | ConvertTo-Json -Depth 10

    try {
        $resp = Invoke-RestMethod -Uri $apiUrl -Method Post -Headers $headers -Body $body -TimeoutSec 30
        $ext = $resp.results[0].extensions[0]
        $version = $ext.versions[0]

        # 查找目标平台的 VSIX，优先匹配指定平台
        $vsixUrl = $null
        $universalUrl = $null

        foreach ($f in $version.files) {
            if ($f.assetType -eq "Microsoft.VisualStudio.Services.VSIXPackage") {
                # 检查是否是平台特定版本
                if ($f.source -match $Platform) {
                    $vsixUrl = $f.source
                    break
                }
                # 记录通用版本作为后备
                if ($f.source -match "universal" -or $f.source -notmatch "(win32|linux|darwin|alpine)") {
                    $universalUrl = $f.source
                }
            }
        }

        # 如果没有找到平台特定版本，使用通用版本
        if (-not $vsixUrl) { $vsixUrl = $universalUrl }

        if ($vsixUrl) {
            return @{
                url     = $vsixUrl
                name    = $ext.displayName
                version = $version.version
            }
        }
    } catch {
        return $null
    }
    return $null
}

# 下载 .vsix
Log "开始下载 .vsix"
$ok = 0
$fail = 0
$skip = 0

foreach ($extId in $extensions) {
    $extId = $extId.Trim()
    if (-not $extId) { continue }

    # 文件名: publisher.name-version.vsix
    $parts = $extId.Split(".")
    if ($parts.Count -lt 2) {
        Skip "$extId (无效 ID)"
        $skip++
        continue
    }

    # 检查是否已下载
    $existing = Get-ChildItem $OutDir -Filter "$($parts[1]).*.vsix" -ErrorAction SilentlyContinue
    if ($existing) {
        Skip "$extId (已存在: $($existing[0].Name))"
        $skip++
        continue
    }

    Info "下载: $extId"
    $info = Get-VsixUrl $extId

    if (-not $info) {
        Err "  $extId (无法获取下载链接)"
        $fail++
        continue
    }

    $fileName = "$($parts[0]).$($parts[1])-$($info.version).vsix"
    $outPath = Join-Path $OutDir $fileName

    try {
        Invoke-WebRequest -Uri $info.url -OutFile $outPath -TimeoutSec 120
        $size = [math]::Round((Get-Item $outPath).Length / 1MB, 1)
        OK "$fileName ($size MB)"
        $ok++
    } catch {
        Err "  $extId (下载失败: $_)"
        $fail++
    }
}

# 总结
Log "导出完成"
OK "成功: $ok"
if ($fail -gt 0) { Err "失败: $fail" }
if ($skip -gt 0) { Skip "跳过: $skip" }

$totalSize = [math]::Round((Get-ChildItem $OutDir -Filter "*.vsix" | Measure-Object -Property Length -Sum).Sum / 1MB, 1)
Info "总计: $totalSize MB"
Info "目录: $OutDir"
