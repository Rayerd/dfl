@rem   Make DFL.
@rem   http://www.dprogramming.com/dfl.php
@rem   Modified for 64-bit and COFF object format

@rem   How to use:
@rem     makecoff.bat          # Same as 32mscoff
@rem     makecoff.bat 32mscoff # 32-bit COFF
@rem     makecoff.bat 64       # 64-bit

@rem   Requires DMD and DMC's libs
@rem   Free downloads from https://dlang.org/download.html

@rem   If you prefer to make DFL64 or 32-bit COFF library format,
@rem   This requies DMD tools _and_ MSVC build tools (tested with MSVC 2015 Community Ed.),

@echo off
@cls

@rem   For DUB.
pushd source\dfl

@rem   You can change the default object model here
set MODEL=32mscoff
if not "%~1"=="" set MODEL=%~1

@rem   Either set the environment variables dmd_path and dmc_path
@rem   or fix the paths below.

if not "%dmd_path%" == "" goto dmd_set
set dmd_path=c:\dmd
:dmd_set
set dmd_path_windows=%dmd_path%\windows
if not exist %dmd_path_windows%\bin\dmd.exe set dmd_path_windows=%dmd_path%
set _stdcwindowsd=
set _stdcwindowsobj=
if not "%dlib%" == "Tango" goto dfl_not_tango_files
set _stdcwindowsd=internal/_stdcwindows.d
set _stdcwindowsobj=_stdcwindows.obj
:dfl_not_tango_files

@rem   You have to change these paths to your machine environment.
@rem   "Visual Studio 14.0" means MSVC 2015.
@rem   sc.ini in dmd2/windows/bin will help you.

@rem   path to linker
set LIBCMD="%VCINSTALLDIR%\bin\lib.exe"

@rem   path to mspdb140.dll, mspdb120.dll, mspdb110.dll, mspdb100.dll, and so on
@rem   IMPORTANT: The MSVC build tools may depends on dlls which are separated into x86/x64 on installation,
@rem              then you MUST choose a path to the suitable version.
@rem set VCCOMMON="C:\Program Files (x86)\Microsoft Visual Studio 10.0\Common7\IDE"
@rem set VCCOMMON="C:\Program Files (x86)\Microsoft Visual Studio 12.0\VC\bin\amd64"
set VCCOMMON="%VCINSTALLDIR%\bin"

@rem   path to Windows SDK static libs (ex.gdi32.lib)
@if "%MODEL%" == "64" (
  @rem set WINSDKLIB="C:\Program Files (x86)\Microsoft SDKs\Windows\v7.1A\Lib\x64"
  @rem set WINSDKLIB="%WINSDKLIB%\Lib\winv6.3\um\x64"
  set WINSDKLIB="%dmd_path%\lib64\mingw"
  set dmd_lib_path="%dmd_path%\lib64"
) else if "%MODEL%" == "32mscoff" (
  @rem set WINSDKLIB="C:\Program Files (x86)\Microsoft SDKs\Windows\v7.1A"
  @rem set WINSDKLIB="%WINSDKLIB%\Lib\winv6.3\um\x86"
  set WINSDKLIB="%dmd_path%\lib32mscoff\mingw"
  set dmd_lib_path="%dmd_path%\lib32mscoff"
)

@set PATH=%VCCOMMON%;%PATH%

set dfl_files=package.d all.d base.d application.d internal/dlib.d internal/clib.d internal/utf.d internal/com.d control.d clippingform.d form.d registry.d drawing.d menu.d notifyicon.d commondialog.d filedialog.d folderdialog.d panel.d textboxbase.d textbox.d richtextbox.d picturebox.d listbox.d groupbox.d splitter.d usercontrol.d button.d label.d collections.d internal/winapi.d internal/wincom.d event.d socket.d timer.d environment.d messagebox.d tooltip.d combobox.d treeview.d tabcontrol.d colordialog.d listview.d data.d clipboard.d fontdialog.d progressbar.d resources.d statusbar.d imagelist.d toolbar.d trackbar.d sharedcontrol.d printing.d chart.d %_stdcwindowsd%

set dfl_objs=package.obj all.obj base.obj application.obj dlib.obj clib.obj utf.obj com.obj control.obj clippingform.obj form.obj registry.obj drawing.obj menu.obj notifyicon.obj commondialog.obj filedialog.obj folderdialog.obj panel.obj textboxbase.obj textbox.obj richtextbox.obj picturebox.obj listbox.obj groupbox.obj splitter.obj usercontrol.obj button.obj label.obj collections.obj winapi.obj wincom.obj event.obj socket.obj timer.obj environment.obj messagebox.obj tooltip.obj combobox.obj treeview.obj tabcontrol.obj colordialog.obj listview.obj data.obj clipboard.obj fontdialog.obj progressbar.obj resources.obj statusbar.obj imagelist.obj toolbar.obj trackbar.obj sharedcontrol.obj printing.obj chart.obj %_stdcwindowsobj%

@rem   Also update link pragmas for build.
if  "%MODEL%" == "64" (
  set dfl_libs_dfl=%dmd_path%\lib64\undead.lib
) else (
  set dfl_libs_dfl=%dmd_path%\lib32mscoff\undead.lib
)
set dfl_libs_dfl=%WINSDKLIB%\user32.lib %WINSDKLIB%\shell32.lib %WINSDKLIB%\oleaut32.lib %dfl_libs_dfl%
set dfl_libs=%WINSDKLIB%\gdi32.lib %WINSDKLIB%\comctl32.lib %WINSDKLIB%\advapi32.lib %WINSDKLIB%\comdlg32.lib %WINSDKLIB%\ole32.lib %WINSDKLIB%\uuid.lib %WINSDKLIB%\ws2_32.lib %dfl_libs_dfl%

@rem   -version=NO_DRAG_DROP -version=NO_MDI
@rem   -debug=SHOW_MESSAGE_INFO -debug=MESSAGE_PAUSE
@rem set dfl_flags=%dfl_flags% -debug=SHOW_MESSAGENFO
set _dfl_flags=%dfl_flags% -wi

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

%dmd_path_windows%\bin\dmd -m%MODEL% -c %dfl_debug_flags% %_dfl_flags% %dfl_options% -I.. %dfl_files%
@if errorlevel 1 goto oops

@echo.
@echo Making debug lib...

%LIBCMD% /out:dfl_debug.lib /libpath:%WINSDKLIB% %dfl_libs% %dfl_objs%
@if errorlevel 1 goto oops
@echo We may ignore warnings of 4006,4221...


@echo.
@echo Compiling release DFL...

%dmd_path_windows%\bin\dmd -m%MODEL% -c %dfl_release_flags% %_dfl_flags% %dfl_options% -I.. %dfl_files%
@if errorlevel 1 goto oops

@echo.
@echo Making release lib...

%LIBCMD% /out:dfl.lib /libpath:%WINSDKLIB% %dfl_libs% %dfl_objs%
@if errorlevel 1 goto oops
@echo We may ignore warnings of 4006,4221...


@rem this flag used when called from go.bat
@set dfl_failed=
@goto done
:oops
@set dfl_failed=1
@echo.
@echo Failed.


:done
@echo.
@echo makecoff.bat completed.

@rem   For DUB.
@popd
