// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.


///
module dfl.commondialog;

import dfl.application;
import dfl.base;
import dfl.control;
import dfl.drawing;
import dfl.event;

import dfl.internal.winapi;
import dfl.internal.utf;

public import dfl.filedialog;
public import dfl.folderdialog;
public import dfl.colordialog;
public import dfl.fontdialog;


///
abstract class CommonDialog // docmain
{
	///
	abstract void reset();
	
	///
	// Uses currently active window of the application as owner.
	abstract DialogResult showDialog();
	
	/// ditto
	abstract DialogResult showDialog(IWindow owner);
	
	
	///
	Event!(CommonDialog, HelpEventArgs) helpRequest;
	
	
	protected:
	
	///
	// See the CDN_* Windows notification messages.
	UINT_PTR hookProc(HWND hwnd, UINT msg, WPARAM wparam, LPARAM lparam)
	{
		switch(msg)
		{
			case WM_NOTIFY:
				{
					NMHDR* nmhdr;
					nmhdr = cast(NMHDR*)lparam;
					switch(nmhdr.code)
					{
						case CDN_HELP:
							{
								Point pt;
								GetCursorPos(&pt.point);
								onHelpRequest(new HelpEventArgs(pt));
							}
							break;
						
						default:
					}
				}
				break;
			
			default:
		}
		
		return 0;
	}
	
	
	// TODO: implement.
	//LRESULT ownerWndProc(HWND hwnd, UINT msg, WPARAM wparam, LPARAM lparam)
	
	
	///
	void onHelpRequest(HelpEventArgs ea)
	{
		helpRequest(this, ea);
	}
	
	
	///
	abstract bool runDialog(HWND owner);
	
	
	package final void _cantrun()
	{
		throw new DflException("Error running dialog");
	}
}
