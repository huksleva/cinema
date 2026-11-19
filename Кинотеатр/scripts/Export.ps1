param([Parameter(Mandatory=$true)][string]$Database,[string]$Platform)
. (Join-Path $PSScriptRoot 'OneC.ps1')
$projectRoot = Split-Path -Parent $PSScriptRoot
$srcPath = Join-Path $projectRoot 'src'
$logRoot = Join-Path $projectRoot 'build\logs'
New-Item -ItemType Directory -Path $logRoot -Force | Out-Null
$databasePath = (Resolve-Path -LiteralPath $Database).Path
if (-not (Test-Path -LiteralPath (Join-Path $databasePath '1Cv8.1CD'))) { throw 'В каталоге отсутствует файловая база 1С' }
$exe = Find-OneC $Platform
Invoke-OneC $exe ('DESIGNER /F "' + $databasePath + '" /DumpConfigToFiles "' + $srcPath + '"') (Join-Path $logRoot 'export.log')
Write-Output 'Выгружено в src. Проверьте git diff перед коммитом.'
