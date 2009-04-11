@cls
@rem   dfl -debug -ofdfl.exe dflexe.d

@set mydflflags=-version=DFL_NO_DRAG_DROP -version=DFL_NO_MENUS -version=DFL_NO_RESOURCES -version=DFL_NO_IMAGELIST -version=NO_MDI -version=DFL_NO_COMPAT

@set dfl_flags=%mydflflags%

dfl -dfl-build

dmd -debug -ofbin\dfl.exe dflexe.d -Ic:\dmd\import dfl_debug.lib -L/exet:nt/su:console:4.0 %mydflflags%

@rem   Clear the flags and recompile so those flags aren't still in the libs...
@rem   If it says "bad install", it's running the wrong dfl.exe, perhaps the newly compiled one.
@echo About to rebuild dfl libs again to reset the compile flags...
@pause
@set dfl_flags=
dfl -dfl-build
