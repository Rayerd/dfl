@rem  How to use:
@rem    go.bat           # Same as 32mscoff
@rem    go.bat 32mscoff  # 32-Bit COFF
@rem    go.bat 32omf     # 32-bit OMF
@rem    go.bat 64        # 64-Bit

call makelib "%~1"
@rem   This errorlevel check fails on Win9x because of the previous delete.
@rem   @if errorlevel 1 goto fail
@if not "%dfl_failed%" == "" goto fail


@if "%dmd_path%" == "" goto no_dmd

@set dmd_path_windows=%dmd_path%\windows
@if not exist %dmd_path_windows%\bin\dmd.exe set dmd_path_windows=%dmd_path%

@if "%dmd_lib_path%" == "" set dmd_lib_path=%dmd_path_windows%\lib

@echo.

@if not "%dfl_go_move%" == "" goto do_move

@echo About to move DFL lib files to %dmd_lib_path% (Close window or Ctrl+C to stop)
@pause

:do_move

@rem   @move /Y dfl_debug.lib %dmd_lib_path%
@rem   @if errorlevel 1 goto fail
@rem   @move /Y dfl.lib %dmd_lib_path%
@rem   @if errorlevel 1 goto fail

@pushd source\dfl

@move /Y dfl*.lib %dmd_lib_path%
@if errorlevel 1 goto fail


@goto done

:no_dmd
@echo dmd_path environment variable not set; cannot copy lib files.
@goto done

:fail
@echo Failed.
@pause

:done
@echo Done.

@popd
