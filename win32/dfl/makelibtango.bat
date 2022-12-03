@goto done

@set _dlib_save89824=%dlib%
@set dlib=Tango

@call makelib.bat

@set dlib=%_dlib_save89824%

:done
@echo Now, DFL with Tango library is not work.
