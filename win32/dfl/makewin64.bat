rem DFL64 minimum link batch
rem This requies DMD tools _and_ MSVC build tools (tested with MSVC 2013 Community Ed.),

rem You have to change these paths to your machine environment.
rem "Visual Studio 12.0" means MSVC 2013.
rem sc.ini in dmd2/windows/bin will help you.

rem path to linker
rem set LIBCMD="C:\Program Files (x86)\Microsoft Visual Studio 10.0\VC\bin\amd64\lib.exe"
set LIBCMD="C:\Program Files (x86)\Microsoft Visual Studio 12.0\VC\bin\x86_amd64\lib.exe"

rem path to mspdb120.dll, mspdb110.dll, mspdb100.dll, and so on
rem IMPORTANT: The MSVC build tools may depends on dlls which are separated into x86/x64 on installation,
rem            then you MUST choose a path to the suitable version.
rem set VCCOMMON="C:\Program Files (x86)\Microsoft Visual Studio 10.0\Common7\IDE"
rem set VCCOMMON=C:\Program Files (x86)\Microsoft Visual Studio 12.0\VC\bin\amd64
set VCCOMMON=C:\Program Files (x86)\Microsoft Visual Studio 12.0\VC\bin

rem path to Windows SDK static libs (ex.gdi32.lib)
set VCLIB64="C:\Program Files (x86)\Windows Kits\8.1\Lib\winv6.3\um\x64"

@set PATH=%VCCOMMON%;%PATH%

@set DFLSRCS=all.d application.d base.d button.d clipboard.d clippingform.d collections.d colordialog.d combobox.d commondialog.d control.d data.d drawing.d environment.d event.d filedialog.d folderdialog.d fontdialog.d form.d groupbox.d imagelist.d internal\clib.d internal\com.d internal\d1.d internal\d2.d internal\dlib.d internal\utf.d internal\winapi.d internal\wincom.d label.d listbox.d listview.d menu.d messagebox.d notifyicon.d package.d panel.d picturebox.d progressbar.d registry.d resources.d richtextbox.d socket.d splitter.d statusbar.d tabcontrol.d textbox.d timer.d toolbar.d tooltip.d treeview.d usercontrol.d
@set DFLOBJS=all.obj application.obj base.obj button.obj clipboard.obj clippingform.obj collections.obj colordialog.obj combobox.obj commondialog.obj control.obj data.obj drawing.obj environment.obj event.obj filedialog.obj folderdialog.obj fontdialog.obj form.obj groupbox.obj imagelist.obj clib.obj com.obj d1.obj d2.obj dlib.obj utf.obj winapi.obj wincom.obj label.obj listbox.obj listview.obj menu.obj messagebox.obj notifyicon.obj package.obj panel.obj picturebox.obj progressbar.obj registry.obj resources.obj richtextbox.obj socket.obj splitter.obj statusbar.obj tabcontrol.obj textbox.obj timer.obj toolbar.obj tooltip.obj treeview.obj usercontrol.obj
@set DFLIMPLIBS=gdi32.lib comctl32.lib comdlg32.lib ole32.lib advapi32.lib uuid.lib
@set DFLIMPLIBS2=user32.lib oleaut32.lib
@rem set DFLIMPLIBS3=user32_dfl64.lib oleaut32_dfl64.lib shell32_dfl64.lib

@echo DFL64: The warnings by LNK4006,LNK4221 are a known problem.

dmd.exe -m64 -c -w -dw -gs -g -debug %DFLSRCS%
if ERRORLEVEL 1 goto error
%LIBCMD% /out:dfl_debug.lib /libpath:%VCLIB64% %DFLOBJS% %DFLIMPLIBS% %DFLIMPLIBS2%
if ERRORLEVEL 1 goto error
del /Q %DFLOBJS%
if ERRORLEVEL 1 goto error
dmd.exe -m64 -c -w -dw -gs -release -O %DFLSRCS%
if ERRORLEVEL 1 goto error
%LIBCMD% /out:dfl.lib /libpath:%VCLIB64% %DFLOBJS% %DFLIMPLIBS% %DFLIMPLIBS2%
if ERRORLEVEL 1 goto error
@rem this may probably be Win32 only...
rem %LIBCMD% /out:dfl_build.lib %DFLIMPLIBS3%
rem if ERRORLEVEL 1 goto error

del /Q %DFLOBJS%
@rem if ERRORLEVEL 1 goto error

@rem this flag used when called by go.bat
@set dfl_failed=
goto end

:error
@set dfl_failed=1
echo failed
:end
pause
