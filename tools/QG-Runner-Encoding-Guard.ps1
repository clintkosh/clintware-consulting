param(
    [Parameter(Mandatory=$true)][string]$SourceFile,
    [ValidateSet('Script','Restore','Launcher','Runner')][string]$Kind = 'Script'
)
$ErrorActionPreference = 'Stop'
$strictUtf8 = [Text.UTF8Encoding]::new($false,$true)
$bomUtf8 = [Text.UTF8Encoding]::new($true)
$originalBytes = [IO.File]::ReadAllBytes($SourceFile)
$hasBom = ($originalBytes.Length -ge 3 -and $originalBytes[0] -eq 239 -and $originalBytes[1] -eq 187 -and $originalBytes[2] -eq 191)
$source = $strictUtf8.GetString($originalBytes)
$previous = $source

function Insert-AfterExactlyOnce([string]$Text,[string]$Anchor,[string]$Addition) {
    if ($Text.Split([string[]]@($Anchor),[StringSplitOptions]::None).Length -ne 2) {
        throw ('QG recovery source contract changed: ' + $Anchor)
    }
    return $Text.Replace($Anchor,$Anchor + [Environment]::NewLine + $Addition)
}

if ($Kind -eq 'Restore' -and -not $source.Contains('QG_ENCODING_STAGED_RUNTIME_V1')) {
    $anchor = '            Move-Item -LiteralPath $temp -Destination $Destination -Force'
    $patch = @'
            # QG_ENCODING_STAGED_RUNTIME_V1: preserve PowerShell 5.1 parse semantics.
            if ($RemotePath.EndsWith('.ps1',[StringComparison]::OrdinalIgnoreCase)) {
                $stageKind = if ($RemotePath -eq 'launcher.ps1') { 'Launcher' } elseif ($RemotePath -eq 'runner.ps1') { 'Runner' } else { 'Script' }
                & (Join-Path $HomeDir 'qg-runner-encoding-guard.ps1') -SourceFile $temp -Kind $stageKind
            }
'@
    $source = $source.Replace($anchor,$patch + [Environment]::NewLine + $anchor)
    if ($source -eq $previous) { throw 'QG restore task download hook not found.' }
}
if ($Kind -eq 'Launcher' -and -not $source.Contains('QG_LAUNCHER_ENCODING_V1')) {
    $restoreDownload = '    Invoke-WebRequest -Uri "https://mcp.clintware.com/api/v1/quillgeist-lite/runtime/tools/restore-runtime.ps1" -OutFile $temp -UseBasicParsing -TimeoutSec 25'
    $source = Insert-AfterExactlyOnce $source $restoreDownload "    # QG_LAUNCHER_ENCODING_V1: verify and normalize downloaded runtime files."
    $source = Insert-AfterExactlyOnce $source $restoreDownload ( "    & (Join-Path " + '$HomeDir' + " 'qg-runner-encoding-guard.ps1') -SourceFile " + '$temp' + " -Kind Restore" )
    $restoreRun = '& $restorePath -HomeDir $HomeDir'
    $source = Insert-AfterExactlyOnce $source $restoreRun '  # QG_RUNTIME_RESTORE_CHECKED'
    $source = $source.Replace($restoreRun,'  & (Join-Path $HomeDir ''qg-runner-encoding-guard.ps1'') -SourceFile $restorePath -Kind Restore' + [Environment]::NewLine + '  ' + $restoreRun)

    $specDownload = '      Invoke-WebRequest -Uri $requestUrl -OutFile $temp -UseBasicParsing -TimeoutSec 20 -ErrorAction Stop'
    $specPatch = @'
      if ($spec.Kind -eq "powershell") {
        $sourceKind = if ($spec.Path -eq $PSCommandPath) { "Launcher" } elseif ($spec.Path -eq $RunnerPath) { "Runner" } else { "Script" }
        & (Join-Path $HomeDir 'qg-runner-encoding-guard.ps1') -SourceFile $temp -Kind $sourceKind
      }
'@
    $source = Insert-AfterExactlyOnce $source $specDownload $specPatch

    $runnerDownload = '    Invoke-WebRequest -Uri ($RunnerUrl + "?cb=" + [Guid]::NewGuid().ToString("n")) -OutFile $temp -UseBasicParsing -Headers @{"Cache-Control"="no-cache"}'
    $runnerPatch = '    & (Join-Path $HomeDir ''qg-runner-encoding-guard.ps1'') -SourceFile $temp -Kind Runner'
    $source = Insert-AfterExactlyOnce $source $runnerDownload $runnerPatch
}
if ($Kind -eq 'Runner' -and -not $source.Contains('QG_RUNNER_TASK_ENCODING_V1')) {
    $taskDownload = '      Invoke-WebRequest -Uri $uri -OutFile $tempSource -UseBasicParsing -TimeoutSec 25 -ErrorAction Stop'
    $source = Insert-AfterExactlyOnce $source $taskDownload "      # QG_RUNNER_TASK_ENCODING_V1: validate exact UTF-8 source before parsing." 
    $taskPatch = '      & (Join-Path $HomeDir ''qg-runner-encoding-guard.ps1'') -SourceFile $tempSource -Kind Script'
    $source = Insert-AfterExactlyOnce $source $taskDownload $taskPatch
}

if ($source -ne $previous -or -not $hasBom) {
    $temp = $SourceFile + '.qg-verified'
    try {
        [IO.File]::WriteAllText($temp,$source,$bomUtf8)
        $tokens=$null
        $parseErrors=$null
        [Management.Automation.Language.Parser]::ParseFile($temp,[ref]$tokens,[ref]$parseErrors) | Out-Null
        if (@($parseErrors).Count -gt 0) {
            throw ('QG parser rejected ' + $SourceFile + ': ' + ((@($parseErrors) | ForEach-Object { $_.Message }) -join '; '))
        }
        Move-Item -LiteralPath $temp -Destination $SourceFile -Force
    } finally {
        Remove-Item -LiteralPath $temp -Force -ErrorAction SilentlyContinue
    }
}
