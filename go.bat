@echo off
setlocal

rem  How to use:
rem    go.bat           # Same as 32mscoff
rem    go.bat 32mscoff  # 32-Bit COFF
rem    go.bat 64        # 64-Bit

for /f %%a in ('echo prompt $e ^| cmd') do set ESC=%%a

rem   You can change the default object model here.
if "%~1" == "64" (
  set MODEL=64
) else (
  set MODEL=32mscoff
)

call makelib "%~1"
rem   This errorlevel check fails on Win9x because of the previous delete.
rem   if errorlevel 1 goto failed
if not "%dfl_failed%" == "" goto failed

if dmd_path == "" set dmd_path=%dmd_path%\windows

if "%MODEL%" == "64" (
  if not exist "%dmd_path%\bin64\dmd.exe" goto no_dmd
) else if "%MODEL%" == "32mscoff" (
  if not exist "%dmd_path%\bin\dmd.exe" goto no_dmd
)

if "%MODEL%" == "64" (
  set output_path="%dmd_path%\lib64"
) else if "%MODEL%" == "32mscoff" (
  set output_path="%dmd_path%\lib32mscoff"
)

echo.

echo About to move DFL lib files to %ESC%[36m%output_path%%ESC%[0m (Close window or Ctrl+C to stop)
pause

:do_move
pushd source\dfl

move /Y "..\..\bin\dfl*.lib" %output_path%
if errorlevel 1 goto failed
goto completed

:no_dmd
echo dmd_path environment variable not set; cannot copy lib files.
goto failed

:failed
echo.
echo %ESC%[31mgo.bat failed.%ESC%[0m
goto done

:completed
echo.
echo %ESC%[32mgo.bat completed.%ESC%[0m

:done
popd
