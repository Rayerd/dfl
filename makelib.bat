@rem   Make DFL.
@rem   https://github.com/Rayerd/dfl

@rem   Requires DMD and DMC's libs
@rem   Free downloads from https://dlang.org/download.html

@rem  How to use:
@rem    makelib.bat           # Same as 32mscoff
@rem    makelib.bat 32mscoff  # 32-Bit COFF
@rem    makelib.bat 64        # 64-Bit

@if "%~1" == "64" (
  @call makecoff.bat %1
  goto done
)
@if "%~1" == "32mscoff" (
  @call makecoff.bat %1
  goto done
)
@if "%~1" == "" (
  @call makecoff.bat
  goto done
)
@if "%~1" == "32omf" (
  @echo.
  @echo '32omf' is already invalid option.
  goto done
) else (
  set dmd_omf_flag=
)

@echo off
@cls

@rem   For DUB.
pushd source\dfl

@rem   Either set the environment variables dmd_path and dmc_path
@rem   or fix the paths below.

if not "%dmd_path%" == "" goto dmd_set
set dmd_path=c:\dmd
:dmd_set
set dmd_path_windows=%dmd_path%\windows
if not exist %dmd_path_windows%\bin\dmd.exe set dmd_path_windows=%dmd_path%
if not "%dmc_path%" == "" goto dmc_set
set dmc_path=c:\dm
:dmc_set

if exist "%dmc_path%" goto got_dmc
@rem @echo DMC not found; using DMD path (if you get errors, install DMC)
set dmc_path=%dmd_path_windows%
:got_dmc


set _stdcwindowsd=
set _stdcwindowsobj=
if not "%dlib%" == "Tango" goto dfl_not_tango_files
set _stdcwindowsd=internal/_stdcwindows.d
set _stdcwindowsobj=_stdcwindows.obj
:dfl_not_tango_files

set dfl_files=package.d all.d base.d application.d internal/dlib.d internal/clib.d internal/utf.d internal/com.d internal/dpiaware.d control.d clippingform.d form.d registry.d drawing.d menu.d notifyicon.d commondialog.d filedialog.d folderdialog.d panel.d textboxbase.d textbox.d richtextbox.d picturebox.d listbox.d groupbox.d splitter.d usercontrol.d button.d label.d collections.d internal/winapi.d internal/wincom.d event.d socket.d timer.d environment.d messagebox.d tooltip.d combobox.d treeview.d tabcontrol.d colordialog.d listview.d data.d clipboard.d fontdialog.d progressbar.d resources.d statusbar.d imagelist.d toolbar.d trackbar.d sharedcontrol.d printing.d chart.d %_stdcwindowsd%

set dfl_objs=package.obj all.obj base.obj application.obj dlib.obj clib.obj utf.obj com.obj dpiaware.obj control.obj clippingform.obj form.obj registry.obj drawing.obj menu.obj notifyicon.obj commondialog.obj filedialog.obj folderdialog.obj panel.obj textboxbase.obj textbox.obj richtextbox.obj picturebox.obj listbox.obj groupbox.obj splitter.obj usercontrol.obj button.obj label.obj collections.obj winapi.obj wincom.obj event.obj socket.obj timer.obj environment.obj messagebox.obj tooltip.obj combobox.obj treeview.obj tabcontrol.obj colordialog.obj listview.obj data.obj clipboard.obj fontdialog.obj progressbar.obj resources.obj statusbar.obj imagelist.obj toolbar.obj trackbar.obj sharedcontrol.obj printing.obj chart.obj %_stdcwindowsobj%

@rem   Also update link pragmas for build.
set dfl_libs_dfl=%dmd_path%\lib\user32.lib %dmd_path%\lib\shell32.lib %dmd_path%\lib\oleaut32.lib %dmd_path%\lib\undead.lib
set dfl_libs=%dmc_path%\lib\gdi32.lib %dmc_path%\lib\comctl32.lib %dmc_path%\lib\advapi32.lib %dmc_path%\lib\comdlg32.lib %dmc_path%\lib\ole32.lib %dmc_path%\lib\uuid.lib %dmd_path_windows%\lib\ws2_32.lib %dfl_libs_dfl%

@rem   -version=NO_DRAG_DROP -version=NO_MDI
@rem   -debug=SHOW_MESSAGE_INFO -debug=MESSAGE_PAUSE
@rem set dfl_flags=%dfl_flags% -debug=SHOW_MESSAGENFO
set _dfl_flags=%dfl_flags% -wi %dmd_omf_flag%

if not "%dfl_debug_flags%" == "" goto dfl_debug_flags_set
	set dfl_debug_flags=-debug -version=DFL_UNICODE
:dfl_debug_flags_set

if not "%dfl_release_flags%" == "" goto dfl_release_flags_set
@rem	if not "%dlib%" == "Tango" goto dfl_not_release_tango
@rem	echo Due to a bug in DMD, release mode dfl lib will not include -inline; use environment variable dfl_release_flags to override.
@rem	set dfl_release_flags=-O -release
@rem	goto dfl_release_flags_set
@rem	:dfl_not_release_tango
	set dfl_release_flags=-O -release -version=DFL_UNICODE
:dfl_release_flags_set


@echo on


@if "%dfl_ddoc%" == "" goto after_dfl_ddoc
@echo.
@echo Generating ddoc documentation...

%dmd_path_windows%\bin\dmd %_dfl_flags% %dfl_options% -c -o- -Dddoc %dfl_files%
@if errorlevel 1 goto oops

@if "%dfl_ddoc%" == "only" goto done
@if not "%dfl_ddoc_only%" == "" goto done
:after_dfl_ddoc


@rem   @echo.
@rem   @echo Generating headers...
@rem   @del *.di
@rem   %dmd_path_windows%\bin\dmd -H -o- -c -I.. %_dfl_flags% %dfl_options% %dfl_files%
@rem   @if errorlevel 1 goto oops


@echo.
@echo Compiling debug DFL...

%dmd_path_windows%\bin\dmd -c %dfl_debug_flags% %_dfl_flags% %dfl_options% -I.. %dfl_files%
@if errorlevel 1 goto oops

@echo.
@echo Making debug lib...

%dmc_path%\bin\lib -c -n -p128 dfl_debug.lib %dfl_libs% %dfl_objs%
@if errorlevel 1 goto oops


@echo.
@echo Compiling release DFL...

%dmd_path_windows%\bin\dmd -c %dfl_release_flags% %_dfl_flags% %dfl_options% -I.. %dfl_files%
@if errorlevel 1 goto oops

@echo.
@echo Making release lib...

%dmc_path%\bin\lib -c -n -p128 dfl.lib %dfl_libs% %dfl_objs%
@if errorlevel 1 goto oops


@set dfl_failed=
@goto done
:oops
@set dfl_failed=1
@echo.
@echo Failed.


:done
@echo.
@echo Done.


@rem   @del %dfl_objs%
@del source\dfl\*.obj

@rem   For DUB.
@popd
