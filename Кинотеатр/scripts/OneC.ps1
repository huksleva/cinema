Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Find-OneC {
    param([string]$ExplicitPath)
    if ($ExplicitPath) {
        if (-not (Test-Path -LiteralPath $ExplicitPath)) { throw 'Указанная платформа не найдена' }
        return (Resolve-Path -LiteralPath $ExplicitPath).Path
    }
    $candidates = @()
    foreach ($rootPath in @('C:\Program Files (x86)\1cv8t','C:\Program Files\1cv8','C:\Program Files (x86)\1cv8')) {
        if (Test-Path -LiteralPath $rootPath) {
            $candidates += Get-ChildItem -LiteralPath $rootPath -Directory | Where-Object { $_.Name -match '^\d+\.\d+\.\d+\.\d+$' } | ForEach-Object {
                $executable = Join-Path $_.FullName ('bin\' + $(if ($rootPath -like '*1cv8t') {'1cv8t.exe'} else {'1cv8.exe'}))
                if (Test-Path -LiteralPath $executable) { Get-Item -LiteralPath $executable }
            }
        }
    }
    if (-not $candidates) { throw 'Платформа 1С не найдена. Укажите -Platform полный_путь_к_exe' }
    return ($candidates | Sort-Object { [version]$_.Directory.Parent.Name } -Descending | Select-Object -First 1).FullName
}

function Invoke-OneC {
    param([string]$Executable,[string]$Arguments,[string]$LogPath)
    $process = Start-Process -FilePath $Executable -ArgumentList ($Arguments + ' /Out "' + $LogPath + '" /DisableStartupMessages /DisableStartupDialogs') -WindowStyle Hidden -PassThru
    if (-not $process.WaitForExit(120000)) { throw ('1С не завершилась за 120 секунд. Проверьте процесс ' + $process.Id + ' и журнал ' + $LogPath) }
    if ($process.ExitCode -ne 0) {
        if (Test-Path -LiteralPath $LogPath) { Get-Content -LiteralPath $LogPath | Write-Host }
        throw ('1С завершилась с кодом ' + $process.ExitCode)
    }
}
