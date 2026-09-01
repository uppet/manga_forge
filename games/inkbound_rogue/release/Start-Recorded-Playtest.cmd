@echo off
chcp 65001 >nul
setlocal EnableExtensions DisableDelayedExpansion
cd /d "%~dp0"

set "GAME_EXIT=0"
set "GAME_EXE=%~dp0InkboundRogue.exe"
if exist "%GAME_EXE%" goto game_found
echo [ERROR] InkboundRogue.exe must be beside this launcher.
echo [错误] 请将本脚本与 InkboundRogue.exe 放在同一目录。
set "GAME_EXIT=2"
goto finish

:game_found
echo.
echo ============================================================
echo   INKBOUND ROGUE - RECORDED PLAYTEST
echo   《Inkbound Rogue》本地记录试玩模式
echo ============================================================
echo.
echo This mode records semantic gameplay events, coarse performance,
echo F6-F9 moment markers, optional game screenshots, and the exit survey.
echo It does NOT record raw input, microphone, camera, account data, or
echo send anything over the network. Files stay in the selected folder.
echo.
echo 此模式记录游戏事件、粗粒度性能、F6-F9 时刻标记、可选游戏截图
echo 与退出问卷；不记录原始输入、麦克风、摄像头或账户信息，亦不会
echo 自动联网传输。所有文件只保存在所选目录。
echo.
if /I "%INKBOUND_LAUNCHER_ACCEPT%"=="1" goto consent_granted
choice /C YN /N /M "Enable local recording? / 是否启用本地记录？ [Y/N]: "
if errorlevel 2 goto consent_declined

:consent_granted
set "PARTICIPANT_CODE=%~1"
if defined PARTICIPANT_CODE goto participant_ready
set /P "PARTICIPANT_CODE=Anonymous participant code / 匿名玩家代号 [anonymous]: "
:participant_ready
if not defined PARTICIPANT_CODE set "PARTICIPANT_CODE=anonymous"

set "OUTPUT_ROOT=%INKBOUND_PLAYTEST_DIR%"
if not "%~2"=="" set "OUTPUT_ROOT=%~2"
if not defined OUTPUT_ROOT set "OUTPUT_ROOT=%~dp0playtest-logs"
for %%I in ("%OUTPUT_ROOT%") do set "OUTPUT_ROOT=%%~fI"
if exist "%OUTPUT_ROOT%\." goto output_ready
mkdir "%OUTPUT_ROOT%" 2>nul
if exist "%OUTPUT_ROOT%\." goto output_ready
echo [ERROR] Could not create output folder: "%OUTPUT_ROOT%"
echo [错误] 无法创建输出目录："%OUTPUT_ROOT%"
set "GAME_EXIT=3"
goto finish

:output_ready
for /F "usebackq delims=" %%I in (`powershell.exe -NoProfile -Command "Get-Date -Format 'yyyyMMdd-HHmmss-fff'"`) do set "SESSION_STAMP=%%I"
if not defined SESSION_STAMP set "SESSION_STAMP=%RANDOM%-%RANDOM%"

set "INKBOUND_PLAYTEST=1"
set "INKBOUND_PLAYTEST_SESSION=PT-%SESSION_STAMP%"
set "INKBOUND_PLAYTEST_PARTICIPANT=%PARTICIPANT_CODE%"
set "INKBOUND_PLAYTEST_DIR=%OUTPUT_ROOT%"
set "INKBOUND_BUILD_ID=standalone-recorded-playtest"
set "INKBOUND_GIT_COMMIT=distributed-build"

echo.
echo Session / 会话：%INKBOUND_PLAYTEST_SESSION%
echo Output / 输出：%INKBOUND_PLAYTEST_DIR%\%INKBOUND_PLAYTEST_SESSION%
echo Markers / 标记：F6 Bug ^| F7 Confusing ^| F8 Unfair ^| F9 Highlight
echo.
start "" /wait "%GAME_EXE%"
set "GAME_EXIT=%ERRORLEVEL%"
echo.
echo Game closed with exit code %GAME_EXIT%.
echo 游戏已退出，日志目录：
echo "%INKBOUND_PLAYTEST_DIR%\%INKBOUND_PLAYTEST_SESSION%"
if /I "%INKBOUND_LAUNCHER_NO_OPEN%"=="1" goto finish
start "" explorer.exe "%OUTPUT_ROOT%"
goto finish

:consent_declined
echo Local recording was not enabled. / 未启用本地记录。

:finish
if /I "%INKBOUND_LAUNCHER_NO_PAUSE%"=="1" exit /B %GAME_EXIT%
echo.
pause
exit /B %GAME_EXIT%
