param([string]$Platform)
. (Join-Path $PSScriptRoot 'OneC.ps1')
$projectRoot = Split-Path -Parent $PSScriptRoot
$buildRoot = Join-Path $projectRoot 'build'
$basePath = Join-Path $buildRoot 'infobase'
$srcPath = Join-Path $projectRoot 'src'
$logRoot = Join-Path $buildRoot 'logs'
New-Item -ItemType Directory -Path $basePath,$logRoot -Force | Out-Null
$exe = Find-OneC $Platform
if (-not (Test-Path -LiteralPath (Join-Path $basePath '1Cv8.1CD'))) {
    Invoke-OneC $exe ('CREATEINFOBASE "File=""' + $basePath + '"";"') (Join-Path $logRoot 'create.log')
}
Invoke-OneC $exe ('DESIGNER /F "' + $basePath + '" /LoadConfigFromFiles "' + $srcPath + '"') (Join-Path $logRoot 'load.log')
Invoke-OneC $exe ('DESIGNER /F "' + $basePath + '" /UpdateDBCfg') (Join-Path $logRoot 'update.log')
Invoke-OneC $exe ('DESIGNER /F "' + $basePath + '" /CheckConfig -Server -ThinClient -ThickClientManagedApplication -HandlersExistence') (Join-Path $logRoot 'check.log')
Write-Output ('Готова отдельная база: ' + $basePath)
