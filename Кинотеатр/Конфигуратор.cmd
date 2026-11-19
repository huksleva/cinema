@echo off
setlocal
pwsh -NoProfile -File "%~dp0scripts\Open.ps1" Designer
set "RESULT=%ERRORLEVEL%"
if not "%RESULT%"=="0" pause
exit /b %RESULT%
