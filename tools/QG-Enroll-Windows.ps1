# Clintware QG: Windows enrollment recovery installer.
# Public distributable, no embedded credentials. Run as Administrator.
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw 'Open Windows PowerShell as Administrator, then run this installer.'
}

$base = 'https://mcp.clintware.com/api/v1/quillgeist-lite/runtime'
$home = Join-Path $env:LOCALAPPDATA 'Clintware\QuillgeistLite'
$work = Join-Path $env:TEMP ('Clintware-QG-Recovery-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $work | Out-Null
try {
    $restore = Join-Path $work 'restore-runtime.official.ps1'
    $safeRestore = Join-Path $work 'restore-runtime.encoding-safe.ps1'
    $bootstrap = Join-Path $work 'bootstrap.official.ps1'
    $safeBootstrap = Join-Path $work 'bootstrap.encoding-safe.ps1'
    Invoke-WebRequest -UseBasicParsing -Uri ($base + '/tools/restore-runtime.ps1?cb=' + [guid]::NewGuid().ToString('N')) -OutFile $restore -Headers @{'Cache-Control'='no-cache'}
    Invoke-WebRequest -UseBasicParsing -Uri ($base + '/bootstrap.ps1?cb=' + [guid]::NewGuid().ToString('N')) -OutFile $bootstrap -Headers @{'Cache-Control'='no-cache'}

    $utf8Strict = New-Object System.Text.UTF8Encoding($false,$true)
    $utf8Bom = New-Object System.Text.UTF8Encoding($true)
    $restoreSource = [IO.File]::ReadAllText($restore,$utf8Strict)
    $needle = '            Move-Item -LiteralPath $temp -Destination $Destination -Force'
    if ($restoreSource.Split([string[]]@($needle),[StringSplitOptions]::None).Length -ne 2 -or
        -not $restoreSource.Contains('Test-RuntimeBundle $stage')) {
        throw 'Reviewed restore-runtime contract changed. No installation attempted.'
    }
    $encodingGuard = @'
            # Preserve UTF-8 semantics for Windows PowerShell 5.1 task parsing.
            if ($RemotePath.EndsWith('.ps1',[StringComparison]::OrdinalIgnoreCase)) {
                $bytes = [IO.File]::ReadAllBytes($temp)
                $bom = ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
                if (-not $bom) {
                    $decoded = (New-Object System.Text.UTF8Encoding($false,$true)).GetString($bytes)
                    [IO.File]::WriteAllText($temp,$decoded,(New-Object System.Text.UTF8Encoding($true)))
                }
            }
'@
    $restoreSource = $restoreSource.Replace($needle,$encodingGuard + [Environment]::NewLine + $needle)
    [IO.File]::WriteAllText($safeRestore,$restoreSource,$utf8Bom)

    $bootstrapSource = [IO.File]::ReadAllText($bootstrap,$utf8Strict)
    $restoreCall = '& $restore -HomeDir $HomeDir'
    if ($bootstrapSource.Split([string[]]@($restoreCall),[StringSplitOptions]::None).Length -ne 2 -or
        -not $bootstrapSource.Contains('Run-Checkpoint 5')) {
        throw 'Reviewed bootstrap contract changed. No installation attempted.'
    }
    $safeRestoreLiteral = "'" + $safeRestore.Replace("'","''") + "'"
    $bootstrapSource = $bootstrapSource.Replace($restoreCall,('& ' + $safeRestoreLiteral + ' -HomeDir $HomeDir'))
    [IO.File]::WriteAllText($safeBootstrap,$bootstrapSource,$utf8Bom)

    foreach ($path in @($safeRestore,$safeBootstrap)) {
        $tokens=$null; $syntaxErrors=$null
        [Management.Automation.Language.Parser]::ParseFile($path,[ref]$tokens,[ref]$syntaxErrors) | Out-Null
        if (@($syntaxErrors).Count -gt 0) {
            throw ('QG recovery validation rejected ' + $path + ': ' + ($syntaxErrors -join '; '))
        }
    }
    Write-Host 'QG // Starting reviewed five-checkpoint enrollment with UTF-8-safe staging.' -ForegroundColor Cyan
    $global:LASTEXITCODE=0
    & $safeBootstrap -NoElevate
    if ($LASTEXITCODE -ne 0) { throw ('QG bootstrap failed with exit code ' + $LASTEXITCODE) }

    $resultPath = Join-Path $home 'bootstrap-result.json'
    if (-not (Test-Path -LiteralPath $resultPath)) { throw 'No enrollment receipt was produced.' }
    $result = Get-Content -LiteralPath $resultPath -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($result.five_step_loop -ne 'passed') { throw 'The five enrollment checkpoints did not pass.' }
    Write-Host ('QG // ENROLLMENT VERIFIED // ' + $env:COMPUTERNAME + ' // ' + $result.status) -ForegroundColor Green
    Write-Host ('RECEIPT // ' + $resultPath) -ForegroundColor Cyan
}
finally {
    Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue
}
