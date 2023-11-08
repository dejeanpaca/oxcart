@echo off

REM Check if we have lazbuild
@lazbuild -v >nul 2>&1

if %ERRORLEVEL% EQU 0 (
    echo "Found lazbuild"
) else (
    echo "Using default path"

    REM Set default path for lazarus
    @SET "PATH=%PATH%;C:\lazarus"

    REM Check if we have lazbuild again
    @lazbuild -v >nul 2>&1

    if %ERRORLEVEL% EQU 0 (
        echo "Lazbuild seems present"
    ) else (
        echo "Could not find lazbuild, check if it is set in your PATH."
        EXIT /B
    )
)

@lazbuild setup.lpi
@if %ERRORLEVEL% EQU 0 setup.exe %*
