# ============================================
# AllinOne — AI 开发环境工具
# 运行: powershell -ExecutionPolicy Bypass -File AllinOne.ps1
# ============================================

param(
    [switch]$Export,
    [switch]$Import,
    [switch]$Clear,
    [switch]$All,
    [switch]$Node,
    [switch]$Python,
    [switch]$VSCode,
    [switch]$Claude,
    [switch]$WSL
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

if (-not $Export -and -not $Import -and -not $Clear) {
    Write-Host "`n用法:" -ForegroundColor Yellow
    Write-Host "  AllinOne.ps1 -Export -All      导出全部"
    Write-Host "  AllinOne.ps1 -Export -Node     导出 npm"
    Write-Host "  AllinOne.ps1 -Export -Python   导出 Python"
    Write-Host "  AllinOne.ps1 -Export -VSCode   导出 VSCode 扩展"
    Write-Host "  AllinOne.ps1 -Export -Claude   导出 Claude 插件"
    Write-Host "  AllinOne.ps1 -Export -WSL      导出 WSL"
    Write-Host "  AllinOne.ps1 -Import -All      导入全部"
    Write-Host "  AllinOne.ps1 -Import -Node     导入 npm"
    Write-Host "  AllinOne.ps1 -Import -Python   导入 Python"
    Write-Host "  AllinOne.ps1 -Import -VSCode   导入 VSCode 扩展"
    Write-Host "  AllinOne.ps1 -Import -Claude   导入 Claude 插件"
    Write-Host "  AllinOne.ps1 -Import -WSL      导入 WSL"
    Write-Host "  AllinOne.ps1 -Clear  -All      清除全部导出目录"
    Write-Host "  AllinOne.ps1 -Clear  -Node     清除 npm"
    Write-Host "  AllinOne.ps1 -Clear  -Python   清除 Python"
    Write-Host "  AllinOne.ps1 -Clear  -VSCode   清除 VSCode 扩展"
    Write-Host "  AllinOne.ps1 -Clear  -Claude   清除 Claude 插件"
    Write-Host "  AllinOne.ps1 -Clear  -WSL      清除 WSL`n"
    exit 0
}

if (-not $All -and -not $Node -and -not $Python -and -not $VSCode -and -not $Claude -and -not $WSL) {
    Write-Host "`n请指定范围: -All / -Node / -Python / -VSCode / -Claude / -WSL`n" -ForegroundColor Yellow
    exit 0
}

# ============================================
# Clear
# ============================================

if ($Clear) {
    Log "清除导出目录"

    function Remove-ExportDir($name) {
        $dir = Join-Path $scriptDir $name
        if (Test-Path $dir) {
            Remove-Item $dir -Recurse -Force
            OK "已清除 $name/"
        } else {
            Skip "$name/ 不存在"
        }
    }

    if ($All -or $Python)  { Remove-ExportDir "site-packages" }
    if ($All -or $Node)    { Remove-ExportDir "npm" }
    if ($All -or $VSCode)  { Remove-ExportDir "extensions" }
    if ($All -or $Claude)  { Remove-ExportDir "claude-plugins" }
    if ($All -or $WSL)     { Remove-ExportDir "wsl" }

    OK "清除完成"
    exit 0
}

function Log($msg) { Write-Host "`n$msg" -ForegroundColor Cyan }
function OK($msg)  { Write-Host "  ✓ $msg" -ForegroundColor Green }
function Skip($msg) { Write-Host "  ⊘ $msg" -ForegroundColor Yellow }
function Info($msg) { Write-Host "  · $msg" -ForegroundColor Gray }

# ============================================
# Export
# ============================================

if ($Export) {
    Log "AllinOne 导出"

    if ($All -or $Python) {
        Log "导出 site-packages"
        $src = (python -c "import site; print(site.getsitepackages()[1])" 2>&1).Trim()
        $dst = Join-Path $scriptDir "site-packages"
        if (Test-Path $dst) { Remove-Item $dst -Recurse -Force }
        Info "源: $src"
        Info "目标: $dst"
        Copy-Item $src $dst -Recurse -Force
        Get-ChildItem $dst -Recurse -Directory -Filter "__pycache__" | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        $n = (Get-ChildItem $dst -Directory | Where-Object { $_.Name -match "\.dist-info$" }).Count
        OK "已导出 $n 个包"
    }

    if ($All -or $Node) {
        Log "导出 npm"
        $src = Split-Path (npm root -g 2>&1).Trim()
        $dst = Join-Path $scriptDir "npm"
        if (Test-Path $dst) { Remove-Item $dst -Recurse -Force }
        Info "源: $src"
        Info "目标: $dst"
        Copy-Item $src $dst -Recurse -Force
        Get-ChildItem $dst -Recurse -Directory -Filter ".package-lock" | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        Get-ChildItem $dst -Recurse -Include "*.md", "LICENSE*", "CHANGELOG*", ".npmignore", ".gitignore" | Remove-Item -Force -ErrorAction SilentlyContinue
        $n = (Get-ChildItem (Join-Path $dst "node_modules") -Directory).Count
        OK "已导出 $n 个包"
    }

    if ($All -or $VSCode) {
        Log "导出 VSCode 扩展"
        $exportScript = Join-Path $scriptDir "ExportExtensions.ps1"
        if (Test-Path $exportScript) {
            # 清空旧扩展目录
            $extDir = Join-Path $scriptDir "extensions"
            if (Test-Path $extDir) { Remove-Item $extDir -Recurse -Force }
            & powershell -ExecutionPolicy Bypass -File $exportScript
        } else {
            Skip "ExportExtensions.ps1 不存在"
        }
    }

    if ($All -or $Claude) {
        Log "导出 Claude 插件"
        $srcPlugins = Join-Path $env:USERPROFILE ".claude\plugins"
        $dst = Join-Path $scriptDir "claude-plugins"
        if (Test-Path $srcPlugins) {
            if (Test-Path $dst) { Remove-Item $dst -Recurse -Force }
            Info "源: $srcPlugins"
            Info "目标: $dst"
            Copy-Item $srcPlugins $dst -Recurse -Force
            $pluginCount = 0
            $marketplaceDir = Join-Path $dst "marketplaces\claude-plugins-official\plugins"
            if (Test-Path $marketplaceDir) {
                $pluginCount = (Get-ChildItem $marketplaceDir -Directory).Count
            }
            OK "已导出 $pluginCount 个插件（不含 API 配置）"
        } else {
            Skip "没有 .claude\plugins 目录"
        }
    }

    if ($All -or $WSL) {
        Log "导出 WSL"
        # wsl --list 输出 UTF-16 编码，需要用 .NET 方法处理
        try {
            $psi = New-Object System.Diagnostics.ProcessStartInfo
            $psi.FileName = "wsl.exe"
            $psi.Arguments = "--list --verbose"
            $psi.RedirectStandardOutput = $true
            $psi.StandardOutputEncoding = [System.Text.Encoding]::Unicode
            $psi.UseShellExecute = $false
            $psi.CreateNoWindow = $true
            $process = [System.Diagnostics.Process]::Start($psi)
            $wslOutput = $process.StandardOutput.ReadToEnd()
            $process.WaitForExit()
        } catch {
            Skip "WSL 不可用"
            $wslOutput = ""
        }

        $defaultDistro = $null
        if ($wslOutput) {
            $lines = $wslOutput -split '\r?\n' | Where-Object { $_ -match '\S' }
            foreach ($line in $lines) {
                if ($line -match '^\*\s*(\S+)') {
                    $defaultDistro = $Matches[1]
                    break
                }
            }
        }

        if (-not $defaultDistro) {
            Skip "没有默认 WSL 发行版"
        } else {
            Info "默认发行版: $defaultDistro"
            $wslDir = Join-Path $scriptDir "wsl"
            if (-not (Test-Path $wslDir)) { New-Item -ItemType Directory -Path $wslDir | Out-Null }
            $exportFile = Join-Path $wslDir "$defaultDistro.tar"
            Info "导出到: $exportFile"
            wsl --export $defaultDistro $exportFile
            if ($LASTEXITCODE -eq 0) {
                $size = [math]::Round((Get-Item $exportFile).Length / 1GB, 2)
                OK "已导出 $defaultDistro ($size GB)"
            } else {
                Write-Host "  ✗ 导出失败" -ForegroundColor Red
            }
        }
    }

    OK "导出完成"
}

# ============================================
# Import
# ============================================

if ($Import) {
    Log "AllinOne 导入"

    if ($All -or $Python) {
        Log "导入 site-packages"
        $src = Join-Path $scriptDir "site-packages"
        $dst = (python -c "import site; print(site.getsitepackages()[1])" 2>&1).Trim()
        if (Test-Path $src) {
            if (Test-Path $dst) { Remove-Item $dst -Recurse -Force }
            Info "源: $src"
            Info "目标: $dst"
            Copy-Item $src $dst -Recurse -Force
            $n = (Get-ChildItem $dst -Directory | Where-Object { $_.Name -match "\.dist-info$" }).Count
            OK "已导入 $n 个包"
        } else {
            Skip "没有 site-packages"
        }
    }

    if ($All -or $Node) {
        Log "导入 npm"
        $src = Join-Path $scriptDir "npm"
        $dst = Split-Path (npm root -g 2>&1).Trim()
        if (Test-Path $src) {
            Info "源: $src"
            Info "目标: $dst"
            $roboArgs = @($src, $dst, "/MIR", "/R:1", "/W:1", "/NFL", "/NDL", "/NJH", "/NJS", "/NC", "/NS")
            $roboResult = & robocopy @roboArgs
            $exitCode = $LASTEXITCODE
            if ($exitCode -lt 8) {
                $n = (Get-ChildItem (Join-Path $dst "node_modules") -Directory -ErrorAction SilentlyContinue).Count
                OK "已导入 $n 个包"
                if ($exitCode -ge 4) {
                    Skip "部分文件被跳过（可能正在使用中）"
                }
            } else {
                Write-Host "  ✗ robocopy 失败，退出码: $exitCode" -ForegroundColor Red
            }
        } else {
            Skip "没有 npm"
        }
    }

    if ($All -or $VSCode) {
        Log "导入 VSCode 扩展"
        $extDir = Join-Path $scriptDir "extensions"
        if (Test-Path $extDir) {
            $vsixFiles = Get-ChildItem $extDir -Filter "*.vsix"
            if ($vsixFiles.Count -eq 0) {
                Skip "没有 .vsix 文件"
            } else {
                $ok = 0
                $fail = 0
                foreach ($vsix in $vsixFiles) {
                    try {
                        code --install-extension $vsix.FullName --force 2>&1 | Out-Null
                        if ($LASTEXITCODE -eq 0) {
                            OK "$($vsix.Name)"
                            $ok++
                        } else {
                            Write-Host "  ✗ $($vsix.Name)" -ForegroundColor Red
                            $fail++
                        }
                    } catch {
                        Write-Host "  ✗ $($vsix.Name): $_" -ForegroundColor Red
                        $fail++
                    }
                }
                Info "成功: $ok, 失败: $fail"
            }
        } else {
            Skip "没有 extensions 目录"
        }
    }

    if ($All -or $Claude) {
        Log "导入 Claude 插件"
        $src = Join-Path $scriptDir "claude-plugins"
        $dstPlugins = Join-Path $env:USERPROFILE ".claude\plugins"
        if (Test-Path $src) {
            Info "源: $src"
            Info "目标: $dstPlugins"
            if (Test-Path $dstPlugins) { Remove-Item $dstPlugins -Recurse -Force }
            Copy-Item $src $dstPlugins -Recurse -Force
            $installedFile = Join-Path $dstPlugins "installed_plugins.json"
            if (Test-Path $installedFile) {
                $content = Get-Content $installedFile -Raw
                if ($content -match '"installPath":\s*"([^"]+?)\\\.claude\\plugins') {
                    $srcUserDir = $Matches[1]
                    $dstUserDir = $env:USERPROFILE
                    if ($srcUserDir -ne $dstUserDir) {
                        $content = $content.Replace($srcUserDir, $dstUserDir)
                        Set-Content $installedFile -Value $content -NoNewline
                        Info "已更新路径: $srcUserDir -> $dstUserDir"
                    }
                }
            }
            $pluginCount = 0
            $marketplaceDir = Join-Path $dstPlugins "marketplaces\claude-plugins-official\plugins"
            if (Test-Path $marketplaceDir) {
                $pluginCount = (Get-ChildItem $marketplaceDir -Directory).Count
            }
            OK "已导入 $pluginCount 个插件（不含 API 配置）"
        } else {
            Skip "没有 claude-plugins 目录"
        }
    }

    if ($All -or $WSL) {
        Log "导入 WSL"
        $wslDir = Join-Path $scriptDir "wsl"
        if (Test-Path $wslDir) {
            $tarFiles = Get-ChildItem $wslDir -Filter "*.tar"
            if ($tarFiles.Count -eq 0) {
                Skip "没有 .tar 文件"
            } else {
                foreach ($tar in $tarFiles) {
                    $distroName = $tar.BaseName
                    $installPath = Join-Path $env:USERPROFILE "WSL\$distroName"
                    Info "发行版: $distroName"
                    Info "安装路径: $installPath"
                    Info "源: $($tar.FullName)"
                    if (-not (Test-Path $installPath)) { New-Item -ItemType Directory -Path $installPath | Out-Null }
                    wsl --import $distroName $installPath $tar.FullName
                    if ($LASTEXITCODE -eq 0) {
                        OK "已导入 $distroName"
                    } else {
                        Write-Host "  ✗ 导入失败: $distroName" -ForegroundColor Red
                    }
                }
            }
        } else {
            Skip "没有 wsl 目录"
        }
    }

    OK "导入完成"
}
