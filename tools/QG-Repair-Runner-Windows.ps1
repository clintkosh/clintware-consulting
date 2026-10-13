# Clintware QG: in-place repair for an already enrolled Windows runner.
# Does not request a new identity credential or reinstall the Windows service.
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw 'Open PowerShell as Administrator and run the same command.'
}

$installRoot = Join-Path $env:LOCALAPPDATA 'Clintware\QuillgeistLite'
$programRoot = Join-Path $env:ProgramData 'Clintware\QuillgeistLite'
$serviceName = 'ClintwareQuillgeistLiteHealth'
$taskName = 'Clintware Quillgeist Lite Runner'
$configFile = Join-Path $programRoot 'service.json'
$helper = Join-Path $installRoot 'qg-runner-encoding-guard.ps1'
$marker = Join-Path $programRoot 'maintenance.lock'

if (-not (Test-Path -LiteralPath $configFile -PathType Leaf)) {
    throw 'Machine credential is missing. This repair is only for enrolled machines.'
}
$config = Get-Content -LiteralPath $configFile -Raw -Encoding UTF8 | ConvertFrom-Json
if (-not $config.DeviceId -or -not $config.Token -or -not $config.Endpoint) {
    throw 'Existing machine credential is incomplete. No changes made.'
}
if ([string]$config.DeviceId -ne $env:COMPUTERNAME) {
    throw ('Unexpected machine credential: ' + [string]$config.DeviceId + ' (current: ' + $env:COMPUTERNAME + ')')
}
$service = Get-Service -Name $serviceName -ErrorAction Stop
if ($service.Status -ne 'Running') {
    throw 'The health service is not running. This in-place runner-only repair requires it.'
}
[void](Get-ScheduledTask -TaskName $taskName -ErrorAction Stop)

$helperUrl = 'https://raw.githubusercontent.com/clintkosh/clintware-consulting/13c4ef498c61826b7622b1c6a539f288172c00ff/tools/QG-Runner-Encoding-Guard.ps1'
$helperTemp = $helper + '.new'
Invoke-WebRequest -Uri $helperUrl -UseBasicParsing -OutFile $helperTemp -TimeoutSec 30
if ((Get-Item -LiteralPath $helperTemp).Length -lt 3000 -or -not (Get-Content $helperTemp -Raw).Contains('QG_ENCODING_STAGED_RUNTIME_V1')) {
    throw 'Reviewed source guard download did not pass integrity markers.'
}
$tokens=$null
$errors=$null
[Management.Automation.Language.Parser]::ParseFile($helperTemp,[ref]$tokens,[ref]$errors) | Out-Null
if (@($errors).Count -gt 0) { throw ('Reviewed source guard has parser errors: ' + (@($errors) -join '; ')) }
Move-Item -LiteralPath $helperTemp -Destination $helper -Force

$madeMarker = -not (Test-Path -LiteralPath $marker)
if ($madeMarker) {
    Set-Content -LiteralPath $marker -Value ((Get-Date).ToUniversalTime().ToString('o')) -Encoding ASCII
}

try {
    $task = Get-ScheduledTask -TaskName $taskName -ErrorAction Stop
    if ($task.State -eq 'Running') {
        Stop-ScheduledTask -TaskName $taskName -ErrorAction Stop
        Start-Sleep -Seconds 2
    }
    $paths = @(Get-ChildItem -LiteralPath $installRoot -Recurse -Filter '*.ps1' -File -ErrorAction Stop)
    $reviewed = 0
    foreach ($entry in $paths) {
        $kind = switch ($entry.Name.ToLowerInvariant()) {
            'restore-runtime.ps1' { 'Restore'; break }
            'launcher.ps1' { 'Launcher'; break }
            'runner.ps1' { 'Runner'; break }
            default { 'Script' }
        }
        & $helper -SourceFile $entry.FullName -Kind $kind
        $reviewed++
    }

    foreach ($critical in @(
        (Join-Path $installRoot 'launcher.ps1'),
        (Join-Path $installRoot 'restore-runtime.ps1'),
        (Join-Path $installRoot 'runtime\quillgeist-lite\tasks\self-update.ps1')
    )) {
        if (-not (Test-Path -LiteralPath $critical -PathType Leaf)) {
            throw ('Required runner file missing: ' + $critical)
        }
    }

    $launcherBody = Get-Content -LiteralPath (Join-Path $installRoot 'launcher.ps1') -Raw -Encoding UTF8
    if (-not $launcherBody.Contains('QG_LAUNCHER_ENCODING_V1')) {
        throw 'Launcher did not receive the persistent source encoding gate.'
    }
    $runnerBody = Get-Content -LiteralPath (Join-Path $installRoot 'runner.ps1') -Raw -Encoding UTF8
    if (-not $runnerBody.Contains('QG_RUNNER_TASK_ENCODING_V1')) {
        throw 'Runner did not receive the task source encoding gate.'
    }
    Write-Host ('QG // ' + $reviewed + ' PowerShell sources parsed and encoding-checked') -ForegroundColor Green

    if ($madeMarker) {
        Remove-Item -LiteralPath $marker -Force -ErrorAction SilentlyContinue
        $madeMarker = $false
    }

    Enable-ScheduledTask -TaskName $taskName -ErrorAction Stop | Out-Null
    Start-ScheduledTask -TaskName $taskName -ErrorAction Stop

    $heartbeatFile = Join-Path $installRoot 'runner-heartbeat.json'
    $connected = $false
    for ($i=0; $i -lt 12; $i++) {
        Start-Sleep -Seconds 4
        if (Test-Path -LiteralPath $heartbeatFile) {
            try {
                $beat = Get-Content -LiteralPath $heartbeatFile -Raw -Encoding UTF8 | ConvertFrom-Json
                $fresh = ((Get-Date).ToUniversalTime() - (Get-Item -LiteralPath $heartbeatFile).LastWriteTimeUtc).TotalSeconds -lt 20
                if ($fresh -and [string]$beat.network_state -eq 'connected') { $connected = $true; break }
            } catch {}
        }
    }

    Write-Host ('MACHINE // ' + [string]$config.DeviceId)
    Write-Host ('SERVICE // ' + (Get-Service -Name $serviceName).Status)
    Write-Host ('RUNNER TASK // ' + (Get-ScheduledTask -TaskName $taskName).State)
    if ($connected) {
        Write-Host 'QG // RUNNER CONNECTED // local heartbeat verified' -ForegroundColor Green
    } else {
        $log = Join-Path $installRoot 'runner-crash.log'
        if (Test-Path -LiteralPath $log) {
            Write-Host 'LATEST RUNNER DIAGNOSTICS:'
            Get-Content -LiteralPath $log -Tail 8
        }
        throw 'Service is running, but the runner did not report a fresh connected heartbeat.'
    }
}
finally {
    if ($madeMarker) {
        Remove-Item -LiteralPath $marker -Force -ErrorAction SilentlyContinue
    }
}
