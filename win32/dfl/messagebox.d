// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.


///
module dfl.messagebox;

private import dfl.internal.winapi, dfl.internal.dlib, dfl.base;


///
enum MsgBoxButtons
{
	ABORT_RETRY_IGNORE = MB_ABORTRETRYIGNORE, ///
	OK = MB_OK, /// ditto
	OK_CANCEL = MB_OKCANCEL, /// ditto
	RETRY_CANCEL = MB_RETRYCANCEL, /// ditto
	YES_NO = MB_YESNO, /// ditto
	YES_NO_CANCEL = MB_YESNOCANCEL, /// ditto
}


///
enum MsgBoxIcon
{
	NONE = 0, ///
	
	ASTERISK = MB_ICONASTERISK, /// ditto
	ERROR = MB_ICONERROR, /// ditto
	EXCLAMATION = MB_ICONEXCLAMATION, /// ditto
	HAND = MB_ICONHAND, /// ditto
	INFORMATION = MB_ICONINFORMATION, /// ditto
	QUESTION = MB_ICONQUESTION, /// ditto
	STOP = MB_ICONSTOP, /// ditto
	WARNING = MB_ICONWARNING, /// ditto
}


enum MsgBoxDefaultButton
{
	BUTTON1 = MB_DEFBUTTON1, ///
	BUTTON2 = MB_DEFBUTTON2, /// ditto
	BUTTON3 = MB_DEFBUTTON3, /// ditto
	
	// Extra.
	BUTTON4 = MB_DEFBUTTON4,
}


///
enum MsgBoxOptions
{
	DEFAULT_DESKTOP_ONLY = MB_DEFAULT_DESKTOP_ONLY, ///
	RIGHT_ALIGN = MB_RIGHT, /// ditto
	LEFT_ALIGN = MB_RTLREADING, /// ditto
	SERVICE_NOTIFICATION = MB_SERVICE_NOTIFICATION, /// ditto
}


///
DialogResult msgBox(Dstring txt) // docmain
{
	return cast(DialogResult)dfl.internal.utf.messageBox(GetActiveWindow(), txt, "\0", MB_OK);
}

/// ditto
DialogResult msgBox(IWindow owner, Dstring txt) // docmain
{
	return cast(DialogResult)dfl.internal.utf.messageBox(owner ? owner.handle : GetActiveWindow(),
		txt, "\0", MB_OK);
}

/// ditto
DialogResult msgBox(Dstring txt, Dstring caption) // docmain
{
	return cast(DialogResult)dfl.internal.utf.messageBox(GetActiveWindow(), txt, caption, MB_OK);
}

/// ditto
DialogResult msgBox(IWindow owner, Dstring txt, Dstring caption) // docmain
{
	return cast(DialogResult)dfl.internal.utf.messageBox(owner ? owner.handle : GetActiveWindow(),
		txt, caption, MB_OK);
}

/// ditto
DialogResult msgBox(Dstring txt, Dstring caption, MsgBoxButtons buttons) // docmain
{
	return cast(DialogResult)dfl.internal.utf.messageBox(GetActiveWindow(), txt, caption, buttons);
}

/// ditto
DialogResult msgBox(IWindow owner, Dstring txt, Dstring caption,
	MsgBoxButtons buttons) // docmain
{
	return cast(DialogResult)dfl.internal.utf.messageBox(owner ? owner.handle : GetActiveWindow(),
		txt, caption, buttons);
}

/// ditto
DialogResult msgBox(Dstring txt, Dstring caption, MsgBoxButtons buttons,
	MsgBoxIcon icon) // docmain
{
	return cast(DialogResult)dfl.internal.utf.messageBox(GetActiveWindow(), txt,
		caption, buttons | icon);
}

/// ditto
DialogResult msgBox(IWindow owner, Dstring txt, Dstring caption, MsgBoxButtons buttons,
	MsgBoxIcon icon) // docmain
{
	return cast(DialogResult)dfl.internal.utf.messageBox(owner ? owner.handle : GetActiveWindow(),
		txt, caption, buttons | icon);
}

/// ditto
DialogResult msgBox(Dstring txt, Dstring caption, MsgBoxButtons buttons, MsgBoxIcon icon,
	MsgBoxDefaultButton defaultButton) // docmain
{
	return cast(DialogResult)dfl.internal.utf.messageBox(GetActiveWindow(), txt,
		caption, buttons | icon | defaultButton);
}

/// ditto
DialogResult msgBox(IWindow owner, Dstring txt, Dstring caption, MsgBoxButtons buttons,
	MsgBoxIcon icon, MsgBoxDefaultButton defaultButton) // docmain
{
	return cast(DialogResult)dfl.internal.utf.messageBox(owner ? owner.handle : GetActiveWindow(),
		txt, caption, buttons | icon | defaultButton);
}

/// ditto
DialogResult msgBox(IWindow owner, Dstring txt, Dstring caption, MsgBoxButtons buttons,
	MsgBoxIcon icon, MsgBoxDefaultButton defaultButton, MsgBoxOptions options) // docmain
{
	return cast(DialogResult)dfl.internal.utf.messageBox(owner ? owner.handle : GetActiveWindow(),
		txt, caption, buttons | icon | defaultButton | options);
}


deprecated final class MessageBox
{
	private this() {}
	
	
	static:
	deprecated alias msgBox show;
}


deprecated alias msgBox messageBox;

deprecated alias MsgBoxOptions MessageBoxOptions;
deprecated alias MsgBoxDefaultButton MessageBoxDefaultButton;
deprecated alias MsgBoxButtons MessageBoxButtons;
deprecated alias MsgBoxIcon MessageBoxIcon;

