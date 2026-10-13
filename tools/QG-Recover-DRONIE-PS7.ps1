# QG // DRONIE-only in-place runner repair. Existing registration is untouched.
$ErrorActionPreference='Stop'
$ProgressPreference='SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
$u=[Security.Principal.WindowsIdentity]::GetCurrent()
$p=New-Object Security.Principal.WindowsPrincipal($u)
if(-not $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){throw 'Run PowerShell as Administrator.'}
if($env:COMPUTERNAME -ne 'DRONIE'){throw ('Expected DRONIE, found '+$env:COMPUTERNAME)}
$root=Join-Path $env:LOCALAPPDATA 'Clintware\QuillgeistLite'
$runtime=Join-Path $root 'runtime\quillgeist-lite'
$taskName='Clintware Quillgeist Lite Runner'
$serviceName='ClintwareQuillgeistLiteHealth'
if((Get-Service -Name $serviceName -ErrorAction Stop).Status -ne 'Running'){throw 'Existing QQ service is not running.'}
$task=Get-ScheduledTask -TaskName $taskName -ErrorAction Stop
if(@($task.Actions).Count -ne 1){throw 'Unexpected task action count.'}
$argsText=[string]$task.Actions[0].Arguments
if($argsText -notmatch 'start-qq-window\.ps1' -or $argsText -notmatch 'launcher\.ps1'){throw 'Unknown QQ scheduled task contract.'}
$pwsh=''
foreach($item in @((Join-Path $env:ProgramData 'Clintware\PowerShell\7.6.6\pwsh.exe'),(Join-Path $env:ProgramFiles 'PowerShell\7\pwsh.exe'))){
    if(Test-Path -LiteralPath $item -PathType Leaf){$pwsh=$item;break}
}
if(-not $pwsh){
    $command=Get-Command pwsh.exe -ErrorAction SilentlyContinue
    if($command){$pwsh=[string]$command.Source}
}
$work=Join-Path $env:TEMP ('CW-QG-DRONIE-'+[guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $work -Force|Out-Null
try{
    if(-not $pwsh){
        if(-not [Environment]::Is64BitProcess){throw 'Use 64-bit Windows PowerShell for this x64 repair.'}
        $zip=Join-Path $work 'PowerShell-7.6.6-win-x64.zip'
        Write-Host 'QG // Downloading official PowerShell 7.6.6' -ForegroundColor Cyan
        Invoke-WebRequest -UseBasicParsing -Uri 'https://github.com/PowerShell/PowerShell/releases/download/v7.6.6/PowerShell-7.6.6-win-x64.zip' -OutFile $zip -TimeoutSec 300
        $sum=(Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash
        if($sum -ne '02FE458BE20493FBDF43F61EA20610B811EE6C738AB1676C61B9CFCD1A33C860'){throw ('Official PowerShell checksum mismatch: '+$sum)}
        $stage=Join-Path $work 'power-shell'
        Expand-Archive -LiteralPath $zip -DestinationPath $stage -Force
        $dest=Join-Path $env:ProgramData 'Clintware\PowerShell\7.6.6'
        if(-not (Test-Path -LiteralPath (Join-Path $stage 'pwsh.exe') -PathType Leaf)){throw 'PowerShell executable not found in verified zip.'}
        New-Item -ItemType Directory -Path (Split-Path -Parent $dest) -Force|Out-Null
        if(Test-Path -LiteralPath $dest){Remove-Item -LiteralPath $dest -Recurse -Force}
        Move-Item -LiteralPath $stage -Destination $dest
        $pwsh=Join-Path $dest 'pwsh.exe'
    }
    & $pwsh -NoLogo -NoProfile -NonInteractive -Command '$PSVersionTable.PSVersion.ToString()'
    if($LASTEXITCODE -ne 0){throw 'PowerShell 7 launch failed.'}

    $stage=Join-Path $work 'reviewed'
    New-Item -ItemType Directory -Path $stage -Force|Out-Null
    $pairs=@(
      @{src='launcher.ps1';to=(Join-Path $root 'launcher.ps1');mark='Sync-LatestQQFunctionality'},
      @{src='runner.ps1';to=(Join-Path $root 'runner.ps1');mark='Get-QQRequestEnvelope'},
      @{src='tools/restore-runtime.ps1';to=(Join-Path $root 'restore-runtime.ps1');mark='Test-RuntimeBundle'},
      @{src='tasks/self-update.ps1';to='';mark='SYNC // reconciling QQ'}
    )
    foreach($pair in $pairs){
        $dest=Join-Path $stage ($pair.src -replace '/','_')
        $packaged=Join-Path $runtime ($pair.src -replace '/','\')
        if(Test-Path -LiteralPath $packaged -PathType Leaf){Copy-Item -LiteralPath $packaged -Destination $dest -Force}
        else{Invoke-WebRequest -Uri ('https://mcp.clintware.com/api/v1/quillgeist-lite/runtime/'+$pair.src) -UseBasicParsing -OutFile $dest}
        $body=[IO.File]::ReadAllText($dest,(New-Object Text.UTF8Encoding($false,$true)))
        if(-not $body.Contains([string]$pair.mark) -or $body.Contains('QG_RUNNER_TASK_ENCODING_V1') -or $body.Contains('QG_LAUNCHER_ENCODING_V1')){
            Invoke-WebRequest -Uri ('https://mcp.clintware.com/api/v1/quillgeist-lite/runtime/'+$pair.src+'?cb='+[guid]::NewGuid().ToString('N')) -UseBasicParsing -OutFile $dest
        }
    }
    $check=Join-Path $work 'check.ps1'
    $code=@'
param([string]$Path)
$bad=0
foreach($file in @(Get-ChildItem -LiteralPath $Path -Filter '*.ps1' -File)){
  $tokens=$null;$issues=$null
  [Management.Automation.Language.Parser]::ParseFile($file.FullName,[ref]$tokens,[ref]$issues)|Out-Null
  foreach($issue in @($issues)){Write-Host ("PARSE_FAIL "+$file.Name+" line "+$issue.Extent.StartLineNumber+": "+$issue.Message);$bad++}
}
if($bad){exit 74}
Write-Host 'PASS // reviewed PowerShell 7 parse checks'
'@
    [IO.File]::WriteAllText($check,$code,(New-Object Text.UTF8Encoding($false)))
    & $pwsh -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $check -Path $stage
    if($LASTEXITCODE -ne 0){throw 'Reviewed source parser gate failed; existing task unchanged.'}

    $backup=Join-Path $root ('recovery-backup-'+(Get-Date -Format 'yyyyMMdd-HHmmss'))
    New-Item -ItemType Directory -Path $backup -Force|Out-Null
    foreach($pair in $pairs){if($pair.to -and (Test-Path -LiteralPath $pair.to)){Copy-Item -LiteralPath $pair.to -Destination (Join-Path $backup ([IO.Path]::GetFileName($pair.to))) -Force}}
    Export-ScheduledTask -TaskName $taskName|Set-Content -LiteralPath (Join-Path $backup 'runner-task.xml') -Encoding UTF8

    if((Get-ScheduledTask -TaskName $taskName).State -eq 'Running'){Stop-ScheduledTask -TaskName $taskName;Start-Sleep -Seconds 2}
    foreach($pair in $pairs){if($pair.to){Copy-Item -LiteralPath (Join-Path $stage ($pair.src -replace '/','_')) -Destination $pair.to -Force}}
    $action=New-ScheduledTaskAction -Execute $pwsh -Argument $argsText -WorkingDirectory $root
    Set-ScheduledTask -TaskName $taskName -Action $action -ErrorAction Stop|Out-Null
    Enable-ScheduledTask -TaskName $taskName|Out-Null
    Start-ScheduledTask -TaskName $taskName
    Write-Host ('QG // DRONIE runner launched under PowerShell 7; backup '+$backup) -ForegroundColor Green
    $hbPath=Join-Path $root 'runner-heartbeat.json'
    for($i=0;$i -lt 25;$i++){
        Start-Sleep -Seconds 3
        if(Test-Path -LiteralPath $hbPath){
            try{
                $hb=Get-Content -LiteralPath $hbPath -Raw -Encoding UTF8|ConvertFrom-Json
                $fresh=((Get-Date).ToUniversalTime()-(Get-Item -LiteralPath $hbPath).LastWriteTimeUtc).TotalSeconds -lt 20
                if($fresh -and $hb.network_state -eq 'connected'){Write-Host 'QG // DRONIE CONNECTED' -ForegroundColor Green;return}
            }catch{}
        }
    }
    if(Test-Path -LiteralPath (Join-Path $root 'runner-crash.log')){Get-Content -LiteralPath (Join-Path $root 'runner-crash.log') -Tail 10}
    throw 'Runner restarted; server connection not yet verified.'
}finally{
    Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue
}
