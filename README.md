# DFL

This unofficial project is a migration of [D Forms Library (DFL)](http://wiki.dprogramming.com/Dfl/HomePage "D Forms Library (DFL)") that is managed on SVN.
DFL is a Win32 windowing library for the D language.

```d
import dfl;

void main()
{
	Form form = new Form;
	form.text = "Welcom to DFL";
	form.size = Size(300, 300);

	Button _button = new Button;
	_button.text = "OK";
	_button.location = Point(20, 20);
	_button.size = Size(100, 50);
	_button.click ~= (Control c, EventArgs e) => msgBox("OK button is clicked.");
	_button.parent = form;

	Application.run(form);
}
```
![screen shot](./image/welcomtodfl.png "screen shot")

## Recent major features
- **Windows OMF support has been removed (for DMD v2.109.0).**
- **Registered DFL to DUB.**
- Supported multiple screens.
- Module "dfl.chart" is now comming.
	- TableRenderer (with example)
	- LineGraphRenderer (with example)
	- TimeChartRenderer (with example)
- Module "dfl.printing" is now comming.
	- PrintDialog
	- PrintSetupDialog
	- PrintPreviewDialog
- Remove dflexe.
- Remove GTK-based DFL.
- Remove some bundled libraries such as user32_dfl.lib etc... (From now on, use dmd-bundled libraries such as the MinGW platform library and so on.)

## Screen shots

![screen shot](./examples/buttons/image/screenshot.png "screen shot")
![screen shot](./examples/tabcontrol/image/screenshot.png "screen shot")
![screen shot](./examples/listview/image/screenshot.png "screen shot")
![screen shot](./examples/statusbar/image/screenshot.png "screen shot")
![screen shot](./examples/splitter/image/screenshot.png "screen shot")
![screen shot](./examples/scrollbar/image/screenshot.png "screen shot")
![screen shot](./examples/imagelist/image/screenshot.png "screen shot")
![screen shot](./examples/commondialog/image/screenshot.png "screen shot")
![screen shot](./examples/commondialog/image/screenshot2.png "screen shot")
![screen shot](./examples/tooltip/image/screenshot.png "screen shot")
![screen shot](./examples/progressbar/image/screenshot3.png "screen shot")
![screen shot](./examples/clipboard/image/screenshot.png "screen shot")
![screen shot](./examples/clippingform/image/screenshot.png "screen shot")
![screen shot](./examples/picturebox/image/screenshot.png "screen shot")
![screen shot](./examples/notifyicon/image/screenshot.png "screen shot")
![screen shot](./examples/timer/image/screenshot.png "screen shot")
![screen shot](./examples/contextmenu/image/screenshot.png "screen shot")
![screen shot](./examples/toolbar/image/screenshot.png "screen shot")
![screen shot](./examples/richtextbox/image/screenshot.png "screen shot")
![screen shot](./examples/dclock/image/screenshot.png "screen shot")
![screen shot](./examples/tablerenderer/image/screenshot.png "screen shot")
![screen shot](./examples/linegraphrenderer/image/screenshot.png "screen shot")
![screen shot](./examples/timechartrenderer/image/screenshot.png "screen shot")

## Usage
First, you make new DUB project:
```bat
> cd examples\new_project
> dub init
```
Add DFL to local DUB registry:
```bat
> dub add dfl
> dub list
Packages present in the system and known to dub:
  dfl 0.10.0: c:\your\path\dfl\0.10.0\dfl\
  silly 1.2.0-dev.2: c:\your\path\silly\1.2.0-dev.2\silly\
  undead 1.1.8: c:\your\path\undead\1.1.8\undead\
```
Build and run your GUI applications with DUB as below:
```bat
> dub build -a=x86_64
> dub run
```
**IMPORTANT**: DUB is building **dfl_dub.lib** that is **not** containing **undead.lib** and WINSDK libraries.

## APPENDIX: Build and Install dfl.lib and dfl_debug.lib
### 1. Set environment variables
Fix the paths below:
```bat
set dmd_path=c:\d\dmd2\windows
set dmc_path=c:\dmc\dm
```
### 2. Install the undeaD library
DFL is required the undeaD library (**undead.lib**).
Download a ZIP file from https://github.com/dlang/undead.
Extract **undeaD-master.zip** and run the below with either option `-a=x86_mscoff` or `-a=x86_64`:
```bat
> cd undeaD-master
> dub build -a=x86_64
    Starting Performing "debug" build using C:\D\dmd2\windows\bin\dmd.exe for x86_64.
  Up-to-date undead ~master: target for configuration [library] is up to date.
> dir bin /b
undead.lib
```
Copy the **undead.lib** to `your/lib/dir`.

### 3. Make dfl.lib and dfl_debug.lib
Run **makelib.bat** (MSVC required):
```bat
> cd dfl/win32/dfl
> makelib.bat           # 32-bit mscoff
```
or (MSVC required)
```bat
> makelib.bat 32mscoff  # ditto
```
or (MSVC required)
```bat
> makelib.bat 64        # 64-bit mscoff
```
Also copy **dfl.lib** and **dfl_debug.lib** in `dfl/source` to `your/lib/dir`.

**IMPORTANT**: Both library files are containing the **undead.lib** and WINSDK libraries such as **user32.lib**, **gdi32.lib** and so on.

In order to make and move *.lib to paths below:
- **go.bat** (MSVC required) : Make and move *.lib to `%dmd_path%\lib32mscoff`
- **go.bat 32mscoff** (MSVC required) : ditto
- **go64.bat** (MSVC required) : Make and move *.lib to `%dmd_path%\lib64`

## License
DFL is under the boost and/or zlib/libpng license.

However, trackbar.d is covered by the MIT license.
