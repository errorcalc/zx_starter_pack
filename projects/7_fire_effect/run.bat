@echo off

rem mode
set mode=trd
rem Params
set name=fire
set loader_name=fire
set start_line=10

echo --------- Create BASIC loader for TRD ---------
rem Convert basic loader from loader.bas(basic source)
rem to loader.tap(tape image) 
..\..\utils\bas2tap -s%loader_name% -a%start_line% -c loader_trd.bas loader.tap

rem Convert loader in loader.tap(tape image) to %loader_name%.$B(hobeta file)
..\..\utils\tapto0 -f loader.tap
..\..\utils\0tohob %loader_name%.000

rem Delete temp files
del %loader_name%.000
del loader.tap

echo ---------           Compile           ---------
..\..\sjasm\sjasmplus fire.asm --nofakes -Dmode=\"%mode%\"

echo ---------           Make TRD          ---------
rem Create empty %name%(disk image)
..\..\utils\trdtool # %name%.trd

rem Copy %loader_name%.$B(hobeta file) to %name%.trd(disk image)
..\..\utils\trdtool + %name%.trd %loader_name%.$B
del %loader_name%.$B

rem Copy boot to %name%.trd
..\..\utils\trdtool + %name%.trd "..\..\boots\realmasters_boot.$B"

rem Copy bin to %name%.trd
..\..\utils\trdtool + %name%.trd fire.$C

echo ---------           Make TAP          ---------
rem Make tap loader
..\..\utils\bas2tap -s%loader_name% -a%start_line% -c loader_tap.bas %name%.tap

rem Copy bin to %name%.tap
..\..\utils\taptool +$ %name%.tap fire.$C

echo ---------           Running           ---------
rem Copy labels to emulator
copy "user.l" "..\..\us\"
del user.l

if %mode% == sna (
..\..\us\unreal %name%.sna
)
if %mode% == trd (
..\..\us\unreal %name%.trd
)
if %mode% == tap (
..\..\us\unreal %name%.tap
)