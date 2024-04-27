rem new scons setup: https://github.com/godotengine/godot/pull/66242

scons p=windows -j12 target=editor bits=64 dev_build=yes
rem echo godot.windows.tools.64.exe %* > bin\godot.bat