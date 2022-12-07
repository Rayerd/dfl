pushd source
dmd -m64 -L/SUBSYSTEM:WINDOWS -L/ENTRY:mainCRTStartup hello_dfl.d
hello_dfl.exe
popd
