@echo off
setlocal enabledelayedexpansion

:: Get script directory (this always ends with a backslash)
set "BASE_DIR=%~dp0"

:: Configuration
set "APP_NAME=Yet Another Open File Converter"
set "BUILD_DIR=%BASE_DIR%build_files_windows"
set "FFMPEG_URL=https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip"
set "DESKTOP_DIR=%USERPROFILE%\Desktop"

echo ======================================================
echo Starting build process for: %APP_NAME%
echo ======================================================
echo Script Location: %BASE_DIR%

:: 1. Check for Python
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Python is not installed or not in PATH.
    pause
    exit /b 1
)

:: 2. Create build directory
if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"

:: 3. Setup Virtual Environment
echo [1/5] Setting up virtual environment...
if not exist "%BUILD_DIR%\venv" (
    python -m venv "%BUILD_DIR%\venv"
)
call "%BUILD_DIR%\venv\Scripts\activate.bat"

:: 4. Install Dependencies
echo [2/5] Installing build dependencies...
python -m pip install --upgrade pip
python -m pip install -r "%BASE_DIR%requirements.txt"
python -m pip install PyInstaller

:: 5. Download FFmpeg
echo [3/5] Handling FFmpeg...
set "FFMPEG_ZIP=%BUILD_DIR%\ffmpeg.zip"
set "FFMPEG_BIN_DIR=%BUILD_DIR%\ffmpeg_bin"
set "FFMPEG_EXE=%BUILD_DIR%\ffmpeg.exe"

if not exist "%FFMPEG_EXE%" (
    echo Downloading FFmpeg from gyan.dev...
    powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; (New-Object Net.WebClient).DownloadFile('%FFMPEG_URL%', '%FFMPEG_ZIP%')"
    
    echo Extracting FFmpeg...
    powershell -Command "Expand-Archive -Path '%FFMPEG_ZIP%' -DestinationPath '%FFMPEG_BIN_DIR%' -Force"
    
    :: Find ffmpeg.exe in the extracted folders and move it to BUILD_DIR
    echo Locating ffmpeg.exe...
    for /r "%FFMPEG_BIN_DIR%" %%f in (ffmpeg.exe) do (
        if exist "%%f" (
            copy /y "%%f" "%FFMPEG_EXE%"
        )
    )
    
    :: Cleanup
    if exist "%FFMPEG_ZIP%" del "%FFMPEG_ZIP%"
    if exist "%FFMPEG_BIN_DIR%" rmdir /s /q "%FFMPEG_BIN_DIR%"
) else (
    echo [INFO] FFmpeg already exists at %FFMPEG_EXE%
)

:: 6. Build with PyInstaller
echo [4/5] Running PyInstaller...

:: Prepare data arguments - Using absolute paths for source and "." for destination in package
set ADD_DATA=--add-data "%BASE_DIR%styles.py;."
set ADD_DATA=%ADD_DATA% --add-data "%BASE_DIR%settings_manager.py;."
set ADD_DATA=%ADD_DATA% --add-data "%BASE_DIR%converter_worker.py;."
set ADD_DATA=%ADD_DATA% --add-data "%BASE_DIR%logger.py;."
set ADD_DATA=%ADD_DATA% --add-data "%FFMPEG_EXE%;."

:: Check for icon.ico in the root directory
set "ICON_ARG="
if exist "%BASE_DIR%icon.ico" (
    set "ICON_ARG=--icon "%BASE_DIR%icon.ico""
    echo [INFO] Using icon: %BASE_DIR%icon.ico
) else (
    echo [WARNING] icon.ico not found in %BASE_DIR%
)

:: Run PyInstaller
pyinstaller --noconsole --onefile --clean ^
    --name "%APP_NAME%" ^
    --workpath "%BUILD_DIR%\work" ^
    --specpath "%BUILD_DIR%" ^
    --distpath "%BUILD_DIR%\dist" ^
    %ADD_DATA% ^
    %ICON_ARG% ^
    "%BASE_DIR%main.py"

echo [5/5] Finalizing...
set "RESULT_EXE=%BUILD_DIR%\dist\%APP_NAME%.exe"

if exist "%RESULT_EXE%" (
    echo ======================================================
    echo SUCCESS! 
    echo Copying executable to Desktop...
    copy /y "%RESULT_EXE%" "%DESKTOP_DIR%\"
    
    echo ======================================================
    echo DONE! Your executable is on your Desktop:
    echo "%DESKTOP_DIR%\%APP_NAME%.exe"
    echo ======================================================
) else (
    echo [ERROR] Build failed. Check the output above for details.
)

deactivate
pause
