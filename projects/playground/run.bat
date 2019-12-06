@echo off

rem Params
set name=playground

echo ---------           Compile           ---------
..\..\sjasm\sjasmplus playground.asm --nofakes

echo ---------           Running           ---------
rem Copy labels to emulator
copy "user.l" "..\..\us\"
del user.l

..\..\us\unreal %name%.sna