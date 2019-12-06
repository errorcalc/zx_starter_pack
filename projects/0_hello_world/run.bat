@echo off

rem Params
set name=hello

echo ---------           Compile           ---------
..\..\sjasm\sjasmplus hello.asm --nofakes

echo ---------           Running           ---------
rem Copy labels to emulator
copy "user.l" "..\..\us\"
del user.l

..\..\us\unreal %name%.sna