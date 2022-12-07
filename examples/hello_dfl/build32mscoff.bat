pushd source
dmd -m32mscoff -L/SUBSYSTEM:WINDOWS -L/ENTRY:mainCRTStartup hello_dfl.d
hello_dfl.exe
popd
