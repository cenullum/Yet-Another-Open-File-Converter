@echo off
setlocal enabledelayedexpansion

:: Configuration
set "APP_NAME=Yet Another Open File Converter"
set "BUILD_DIR=build_files_windows"
set "FFMPEG_URL=https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip"

echo ======================================================
echo Starting build process for: %APP_NAME%
echo ======================================================

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
echo [1/5] Setting up virtual environment in %BUILD_DIR%...
if not exist "%BUILD_DIR%\venv" (
    python -m venv "%BUILD_DIR%\venv"
)
call "%BUILD_DIR%\venv\Scripts\activate.bat"

:: 4. Install Dependencies
echo [2/5] Installing build dependencies (PySide6, PyInstaller)...
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
python -m pip install PyInstaller

:: 5. Download FFmpeg
echo [3/5] Handling FFmpeg...
set "FFMPEG_ZIP=%BUILD_DIR%\ffmpeg.zip"
set "FFMPEG_BIN_DIR=%BUILD_DIR%\ffmpeg_bin"

if not exist "%BUILD_DIR%\ffmpeg.exe" (
    echo Downloading FFmpeg from gyan.dev...
    powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; (New-Object Net.WebClient).DownloadFile('%FFMPEG_URL%', '%FFMPEG_ZIP%')"
    
    echo Extracting FFmpeg...
    powershell -Command "Expand-Archive -Path '%FFMPEG_ZIP%' -DestinationPath '%FFMPEG_BIN_DIR%' -Force"
    
    :: Find ffmpeg.exe in the extracted folders and move it to BUILD_DIR
    for /r "%FFMPEG_BIN_DIR%" %%f in (ffmpeg.exe) do (
        if exist "%%f" (
            copy /y "%%f" "%BUILD_DIR%\ffmpeg.exe"
        )
    )
    
    :: Cleanup
    del "%FFMPEG_ZIP%"
    rmdir /s /q "%FFMPEG_BIN_DIR%"
) else (
    echo [INFO] FFmpeg already exists in %BUILD_DIR%.
)

:: 6. Build with PyInstaller
echo [4/5] Running PyInstaller...

:: Prepare data arguments
set "ADD_DATA=--add-data styles.py;."
set "ADD_DATA=%ADD_DATA% --add-data settings_manager.py;."
set "ADD_DATA=%ADD_DATA% --add-data converter_worker.py;."
set "ADD_DATA=%ADD_DATA% --add-data logger.py;."
set "ADD_DATA=%ADD_DATA% --add-data %BUILD_DIR%\ffmpeg.exe;."

:: Check for icon
set "ICON_ARG="
if exist "icon.png" (
    set "ICON_ARG=--icon icon.png"
)

pyinstaller --noconsole --onefile --clean ^
    --name "%APP_NAME%" ^
    --workpath "%BUILD_DIR%\work" ^
    --specpath "%BUILD_DIR%" ^
    --distpath "%BUILD_DIR%\dist" ^
    %ADD_DATA% ^
    %ICON_ARG% ^
    main.py

echo [5/5] Finalizing...
if exist "%BUILD_DIR%\dist\%APP_NAME%.exe" (
    echo ======================================================
    echo SUCCESS! 
    echo Your executable is located at: %BUILD_DIR%\dist\%APP_NAME%.exe
    echo ======================================================
) else (
    echo [ERROR] Build failed. Check the output above for details.
)

deactivate
pause
