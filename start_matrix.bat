@echo off
setlocal EnableExtensions
cd /d "%~dp0"

set "ROOT=%CD%"
set "APPDIR=%ROOT%\matrix-login"
set "PHP="

rem ---------------------------------------------------------------
rem 1. 查找 PHP CLI（优先 phpStudy 7.3，其次 PATH，再扫描 phpStudy）
rem ---------------------------------------------------------------
if exist "C:\phpstudy_pro\Extensions\php\php7.3.4nts\php.exe" (
    set "PHP=C:\phpstudy_pro\Extensions\php\php7.3.4nts\php.exe"
)
if not defined PHP (
    where php >nul 2>nul && set "PHP=php"
)
if not defined PHP (
    for /d %%D in ("C:\phpstudy_pro\Extensions\php\php*") do (
        if not defined PHP if exist "%%~D\php.exe" set "PHP=%%~D\php.exe"
    )
)

if not defined PHP (
    echo [x] PHP CLI not found.
    echo     Install PHP 7.3+ or edit the PHP path in this file.
    pause
    exit /b 1
)

"%PHP%" -r "exit(PHP_VERSION_ID >= 70300 ? 0 : 1);" >nul 2>&1
if errorlevel 1 (
    echo [x] PHP 7.3+ is required. Current PHP:
    "%PHP%" -v
    pause
    exit /b 1
)

if not exist "%APPDIR%\index.php" (
    echo [x] matrix-login not found at: %APPDIR%
    pause
    exit /b 1
)

if not exist "%ROOT%\matrix-router.php" (
    echo [x] matrix-router.php not found in: %ROOT%
    pause
    exit /b 1
)

rem ---------------------------------------------------------------
rem 2. 准备项目 Python venv 与依赖
rem ---------------------------------------------------------------
set "PY=%ROOT%\venv\Scripts\python.exe"

if not exist "%PY%" (
    echo [*] Creating Python venv ...
    where py >nul 2>nul
    if not errorlevel 1 (
        py -m venv "%ROOT%\venv"
    )
    if not exist "%PY%" (
        python -m venv "%ROOT%\venv"
    )
)

if not exist "%PY%" (
    echo [x] Failed to create venv. Install Python 3.9+ first.
    pause
    exit /b 1
)

"%PY%" -c "import sys; raise SystemExit(0 if sys.version_info >= (3, 9) else 1)" >nul 2>&1
if errorlevel 1 (
    echo [x] Python 3.9+ is required. Current version:
    "%PY%" --version
    pause
    exit /b 1
)

"%PY%" -c "import requests" >nul 2>&1
if errorlevel 1 (
    echo [*] Installing Python dependencies ...
    "%PY%" -m pip install -r "%ROOT%\requirements.txt"
    if errorlevel 1 (
        echo [x] pip install failed. Check network / requirements.txt.
        pause
        exit /b 1
    )
)

"%PY%" -c "import selenium" >nul 2>&1
if errorlevel 1 (
    echo [!] selenium not installed: XSS DOM execution check will fall back
    echo     to static analysis. To enable it:
    echo     "%PY%" -m pip install selenium
    echo.
)

rem ---------------------------------------------------------------
rem 3. 选择地址与端口
rem    start_matrix.bat [端口] [绑定地址]
rem    例：start_matrix.bat 18081 localhost
rem        start_matrix.bat 18081 192.168.1.10
rem ---------------------------------------------------------------
set "PORT=%~1"
if not defined PORT set "PORT=18081"

set "HOST=%~2"
if not defined HOST set "HOST=127.0.0.1"

echo %PORT%| findstr /R "^[0-9][0-9]*$" >nul
if errorlevel 1 (
    echo [x] Invalid port: %PORT%
    pause
    exit /b 1
)
if %PORT% LSS 1 set "PORT=18081"
if %PORT% GTR 65535 set "PORT=18081"

set "BROWSER_HOST=%HOST%"
if "%HOST%"=="0.0.0.0" set "BROWSER_HOST=127.0.0.1"

:check_port
netstat -ano | findstr /R /C:":%PORT% " | findstr /I "LISTENING" >nul
if not errorlevel 1 (
    set /a PORT+=1
    goto check_port
)

rem ---------------------------------------------------------------
rem 4. 启动
rem ---------------------------------------------------------------
echo ================================================================
echo  MATRIX TOOL CONSOLE
echo  project : %ROOT%
echo  bind    : %HOST%:%PORT%
echo  URL     : http://%BROWSER_HOST%:%PORT%/matrix-login/
echo  note    : this launcher does NOT depend on any local vulnerable
echo            range; fill the target URL inside the page.
echo  stop    : close this window or press Ctrl+C
echo ================================================================
echo.

start "" /min powershell -NoProfile -Command "Start-Sleep -Seconds 2; Start-Process 'http://%BROWSER_HOST%:%PORT%/matrix-login/'"

"%PHP%" -d display_errors=1 -d error_reporting=E_ALL -S %HOST%:%PORT% -t "%ROOT%" "%ROOT%\matrix-router.php"
if errorlevel 1 (
    echo.
    echo [x] PHP server exited with an error. Read the message above.
    pause
)
