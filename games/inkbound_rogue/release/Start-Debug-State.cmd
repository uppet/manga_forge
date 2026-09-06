@echo off
chcp 65001 >nul
setlocal EnableExtensions DisableDelayedExpansion
cd /d "%~dp0"

set "GAME_EXIT=0"
set "GAME_EXE=%~dp0LastInkwarden.exe"
set "STATE_FILE=%~1"
if not defined STATE_FILE set "STATE_FILE=%~dp0startup-state.json"
for %%I in ("%STATE_FILE%") do set "STATE_FILE=%%~fI"

if not exist "%GAME_EXE%" (
  echo [ERROR] LastInkwarden.exe must be beside this launcher.
  echo [错误] 请将本脚本与 LastInkwarden.exe 放在同一目录。
  set "GAME_EXIT=2"
  goto finish
)
if not exist "%STATE_FILE%" (
  echo [ERROR] Startup-state JSON was not found: "%STATE_FILE%"
  echo [错误] 找不到启动状态 JSON："%STATE_FILE%"
  set "GAME_EXIT=3"
  goto finish
)

echo.
echo ============================================================
echo   LAST INKWARDEN - DEBUG STARTUP STATE
echo   《墨卫残章》特殊启动状态
echo ============================================================
echo State / 配置：%STATE_FILE%
echo Save and GameAnalytics writes are disabled for this run.
echo 本次运行不会写入正式存档，也不会向 GameAnalytics 发送数据。
echo.

set "INKBOUND_STARTUP_STATE=%STATE_FILE%"
start "" /wait "%GAME_EXE%"
set "GAME_EXIT=%ERRORLEVEL%"

:finish
if /I "%INKBOUND_DEBUG_LAUNCHER_NO_PAUSE%"=="1" exit /B %GAME_EXIT%
echo.
pause
exit /B %GAME_EXIT%
