
@echo off
echo Cleaning previous builds...
del *.obj >nul 2>&1
del *.exe >nul 2>&1

echo Compiling POS.asm...
ml /c /coff pos.asm
if errorlevel 1 (
    echo ❌ Compilation failed.
    pause
    exit /b
)

echo Linking...
link /subsystem:console pos.obj
if errorlevel 1 (
    echo ❌ Linking failed.
    pause
    exit /b
)

echo.
echo ✅ Build successful!
pause
