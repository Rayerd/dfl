@rem   Make DFL.
@rem   http://www.dprogramming.com/dfl.php
@rem   Modified for 64-bit and COFF object format

@rem   Requires DMD and DMC's libs
@rem   Free downloads from http://www.digitalmars.com/d/dcompiler.html and http://www.digitalmars.com/download/freecompiler.html

@rem   If you prefer to make DFL64 or 32-bit COFF library format,
@rem   This requies DMD tools _and_ MSVC build tools (tested with MSVC 2013 Community Ed.),

@echo off
@cls

@rem   you can change the default object model here
set MODEL=32mscoff
if not "%1"=="" set MODEL=%1


@rem   You have to change these paths to your machine environment.
@rem   "Visual Studio 12.0" means MSVC 2013.
@rem   sc.ini in dmd2/windows/bin will help you.

@rem   path to linker
@rem set LIBCMD="C:\Program Files (x86)\Microsoft Visual Studio 10.0\VC\bin\amd64\lib.exe"
set LIBCMD="C:\Program Files (x86)\Microsoft Visual Studio 12.0\VC\bin\x86_amd64\lib.exe"

@rem   path to mspdb120.dll, mspdb110.dll, mspdb100.dll, and so on
@rem   IMPORTANT: The MSVC build tools may depends on dlls which are separated into x86/x64 on installation,
@rem              then you MUST choose a path to the suitable version.
@rem set VCCOMMON="C:\Program Files (x86)\Microsoft Visual Studio 10.0\Common7\IDE"
@rem set VCCOMMON=C:\Program Files (x86)\Microsoft Visual Studio 12.0\VC\bin\amd64
set VCCOMMON=C:\Program Files (x86)\Microsoft Visual Studio 12.0\VC\bin

@rem   path to Windows SDK static libs (ex.gdi32.lib)
@if "%MODEL%"=="64" (
  @rem set WINSDKLIB="C:\Program Files (x86)\Microsoft SDKs\Windows\v7.1A\Lib\x64"
  set WINSDKLIB="C:\Program Files (x86)\Windows Kits\8.1\Lib\winv6.3\um\x64"
) else (
  @rem set WINSDKLIB="C:\Program Files (x86)\Microsoft SDKs\Windows\v7.1A"
  set WINSDKLIB="C:\Program Files (x86)\Windows Kits\8.1\Lib\winv6.3\um\x86"
)

@set PATH=%VCCOMMON%;%PATH%

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

set dfl_files=package.d all.d base.d application.d internal/stream.d internal/dlib.d internal/clib.d internal/utf.d internal/com.d control.d clippingform.d form.d registry.d drawing.d menu.d notifyicon.d commondialog.d filedialog.d folderdialog.d panel.d textbox.d richtextbox.d picturebox.d listbox.d groupbox.d splitter.d usercontrol.d button.d label.d collections.d internal/winapi.d internal/wincom.d event.d socket.d timer.d environment.d messagebox.d tooltip.d combobox.d treeview.d tabcontrol.d colordialog.d listview.d data.d clipboard.d fontdialog.d progressbar.d resources.d statusbar.d imagelist.d toolbar.d %_stdcwindowsd%

set dfl_objs=package.obj all.obj base.obj application.obj stream.obj dlib.obj clib.obj utf.obj com.obj control.obj clippingform.obj form.obj registry.obj drawing.obj menu.obj notifyicon.obj commondialog.obj filedialog.obj folderdialog.obj panel.obj textbox.obj richtextbox.obj picturebox.obj listbox.obj groupbox.obj splitter.obj usercontrol.obj button.obj label.obj collections.obj winapi.obj wincom.obj event.obj socket.obj timer.obj environment.obj messagebox.obj tooltip.obj combobox.obj treeview.obj tabcontrol.obj colordialog.obj listview.obj data.obj clipboard.obj fontdialog.obj progressbar.obj resources.obj statusbar.obj imagelist.obj toolbar.obj %_stdcwindowsobj%

@rem   Also update link pragmas for build.
@rem set dfl_libs_dfl=user32_dfl.lib shell32_dfl.lib olepro32_dfl.lib
set dfl_libs_dfl=user32.lib shell32.lib oleaut32.lib
set dfl_libs=gdi32.lib comctl32.lib advapi32.lib comdlg32.lib ole32.lib uuid.lib ws2_32.lib %dfl_libs_dfl%

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

@echo.
@rem this may probably be Win32 only...
@rem   @echo Making build lib...

@rem   %LIBCMD% /out:dfl_build.lib
@rem   @if errorlevel 1 goto oops


@rem   This file is used by dfl.exe
@echo dlib=%dlib%>dflcompile.info
@echo dfl_options=%dfl_options%>>dflcompile.info
@%dmd_path_windows%\bin\dmd>>dflcompile.info

@rem this flag used when called from go.bat
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
@del *.obj

pause
