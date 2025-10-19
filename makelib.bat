@echo off
setlocal

rem   Make DFL.
rem   https://github.com/Rayerd/dfl

rem   How to use:
rem     makelib.bat           # Same as 32mscoff
rem     makelib.bat 32mscoff  # 32-Bit COFF
rem     makelib.bat 64        # 64-Bit

rem   Requires libs of DMD and MSVC build tools.
rem   Free downloads DMD from https://dlang.org/download.html.
rem   Free downloads MSVC build tools from https://visualstudio.microsoft.com/vs/community/.

rem   If you prefer to make DFL64 or 32-bit COFF library format,
rem   This requies DMD tools _and_ MSVC build tools (tested with Visual Studio 2022 Community Ed.)

for /f %%a in ('echo prompt $e ^| cmd') do set ESC=%%a

if "%~1" == "64" (
  call makecoff.bat %1
  goto clean
)
if "%~1" == "32mscoff" (
  call makecoff.bat %1
  goto clean
)
if "%~1" == "" (
  call makecoff.bat
  goto clean
)

echo.
echo The parameter [%ESC%[36m%~1%ESC%[0m] is %ESC%[31minvalid%ESC%[0m.
echo [%ESC%[36m64%ESC%[0m] for x64 or [%ESC%[36m32mscoff%ESC%[0m] for x86 is able to use.
exit /b

:clean
echo.
del source\dfl\*.obj
