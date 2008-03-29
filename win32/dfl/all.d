// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.


/// Imports all of DFL's public interface.
module dfl.all;


version(bud)
	version = build;
version(DFL_NO_BUD_DEF)
	version = DFL_NO_BUILD_DEF;


version(build)
{
	version(WINE)
	{
	}
	else
	{
		version(DFL_NO_LIB)
		{
		}
		else
		{
			pragma(link, "dfl_build");
			
			pragma(link, "ws2_32");
			pragma(link, "gdi32");
			pragma(link, "comctl32");
			pragma(link, "advapi32");
			pragma(link, "comdlg32");
			pragma(link, "ole32");
			pragma(link, "uuid");
		}
		
		version(DFL_NO_BUILD_DEF)
		{
		}
		else
		{
			pragma(build_def, "EXETYPE NT");
			version(gui)
			{
				pragma(build_def, "SUBSYSTEM WINDOWS,4.0");
			}
			else
			{
				pragma(build_def, "SUBSYSTEM CONSOLE,4.0");
			}
		}
	}
}


public import dfl.base, dfl.menu, dfl.control, dfl.usercontrol,
	dfl.form, dfl.drawing, dfl.panel, dfl.event,
	dfl.application, dfl.button, dfl.socket,
	dfl.timer, dfl.environment, dfl.label, dfl.textbox,
	dfl.listbox, dfl.splitter, dfl.groupbox, dfl.messagebox,
	dfl.registry, dfl.notifyicon, dfl.collections, dfl.data,
	dfl.clipboard, dfl.commondialog, dfl.richtextbox, dfl.tooltip,
	dfl.combobox, dfl.treeview, dfl.picturebox, dfl.tabcontrol,
	dfl.listview, dfl.statusbar, dfl.progressbar, dfl.resources,
	dfl.imagelist, dfl.toolbar;

