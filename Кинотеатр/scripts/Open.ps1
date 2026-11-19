param(
    [Parameter(Mandatory)]
    [ValidateSet('Designer', 'Enterprise')]
    [string]$Mode
)

. (Join-Path $PSScriptRoot 'OneC.ps1')
$projectRoot = Split-Path -Parent $PSScriptRoot
$database = Join-Path $projectRoot 'database'
if (-not (Test-Path -LiteralPath (Join-Path $database '1Cv8.1CD') -PathType Leaf)) {
    $database = Join-Path $projectRoot 'build\infobase'
}
if (-not (Test-Path -LiteralPath (Join-Path $database '1Cv8.1CD') -PathType Leaf)) {
    throw 'Нет базы в database или build/infobase. Скопируйте базу из комплекта либо выполните scripts/Build.ps1.'
}

$exe = Find-OneC
Start-Process -FilePath $exe -ArgumentList ($Mode + ' /F "' + $database + '"')
