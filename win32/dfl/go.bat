call makelib
@rem   This errorlevel check fails on Win9x because of the previous delete.
@rem   @if errorlevel 1 goto fail
@if not "%dfl_failed%" == "" goto fail


@if "%dmd_path%" == "" goto no_dmd

@set dmd_path_windows=%dmd_path%\windows
@if not exist %dmd_path_windows%\bin\dmd.exe set dmd_path_windows=%dmd_path%


@echo.

@if not "%dfl_go_move%" == "" goto do_move

@echo About to move DFL lib files to %dmd_path_windows%\lib (Close window or Ctrl+C to stop)
@pause

:do_move

@rem   @move /Y dfl_debug.lib %dmd_path_windows%\lib
@rem   @if errorlevel 1 goto fail
@rem   @move /Y dfl.lib %dmd_path_windows%\lib
@rem   @if errorlevel 1 goto fail
@rem   @move /Y dfl_build.lib %dmd_path_windows%\lib
@rem   @if errorlevel 1 goto fail

@move /Y dfl*.lib %dmd_path_windows%\lib
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
