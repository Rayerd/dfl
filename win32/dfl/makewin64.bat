rem DFL64 minimum link batch

rem You have to change this paths to your machine environment.
set LIBCMD="C:\Program Files (x86)\Microsoft Visual Studio 10.0\VC\bin\amd64\lib.exe"
set VCCOMMON="C:\Program Files (x86)\Microsoft Visual Studio 10.0\Common7\IDE"
set VCLIB64="C:\Program Files (x86)\Windows Kits\8.0\Lib\Win8\um\x64"

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
