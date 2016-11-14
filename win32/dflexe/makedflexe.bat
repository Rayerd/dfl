@cls
@rem   dfl -debug -ofdfl.exe dflexe.d

@set _old_dfl_options=%dfl_options%
@set dfl_options=

@set mydflflags=-version=DFL_NO_DRAG_DROP -version=DFL_NO_MENUS -version=DFL_NO_RESOURCES -version=DFL_NO_IMAGELIST -version=NO_MDI -version=DFL_NO_COMPAT -version=DFL_NO_MULTIPLE_SCREENS

@set dfl_flags=%mydflflags%

dfl -dfl-build

dmd -debug -ofbin\dfl.exe dflexe.d -I.. dfl_debug.lib -L/exet:nt/su:console:4.0 %mydflflags%

@set dfl_flags=
@set dfl_options=%_old_dfl_options%

@echo.
@rem   Clear the flags and recompile so those flags aren't still in the libs...
@rem   If it says "bad install", it's running the wrong dfl.exe, perhaps the newly compiled one.
@echo About to rebuild dfl libs again to reset the compile flags...
@pause
dfl -dfl-build
