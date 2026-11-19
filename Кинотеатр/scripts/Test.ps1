param([string]$Platform)
. (Join-Path $PSScriptRoot 'OneC.ps1')
$projectRoot = Split-Path -Parent $PSScriptRoot
$basePath = Join-Path $projectRoot 'build\infobase'
$assetsPath = Join-Path $projectRoot 'assets'
$logRoot = Join-Path $projectRoot 'build\logs'
if (-not (Test-Path -LiteralPath (Join-Path $basePath '1Cv8.1CD'))) { throw 'Сначала выполните Build.ps1' }
$exe = Find-OneC $Platform
Invoke-OneC $exe ('ENTERPRISE /F "' + $basePath + '" /C "Init|' + $assetsPath + '"') (Join-Path $logRoot 'init.log')
foreach ($kind in @('SelfTest','Smoke')) {
    $resultPath = Join-Path $logRoot ($kind + '-results.txt')
    if (Test-Path -LiteralPath $resultPath) { Move-Item -LiteralPath $resultPath -Destination ($resultPath + '.previous') -Force }
    Invoke-OneC $exe ('ENTERPRISE /F "' + $basePath + '" /C "' + $kind + '|' + $resultPath + '"') (Join-Path $logRoot ($kind + '.log'))
    if (-not (Test-Path -LiteralPath $resultPath)) { throw ('Не создан журнал ' + $resultPath) }
    $results = Get-Content -LiteralPath $resultPath
    $results | Write-Output
    if ($results -match '^FAIL') { throw 'Тесты обнаружили ошибку' }
    $expected = if ($kind -eq 'SelfTest') { 14 } else { 8 }
    if (@($results | Where-Object { $_ -like 'PASS *' }).Count -ne $expected) { throw 'Неверное число завершенных проверок' }
}
