@echo off

REM Check if we have lazbuild
where /q lazbuild

if ERRORLEVEL 0 (
    echo "Found lazbuild"
) else (
    echo "Could not find lazbuild, check if it is set in your PATH."
    EXIT /B
)

EXIT /B

@lazbuild setup.lpi
@if %ERRORLEVEL% EQU 0 setup.exe %*
