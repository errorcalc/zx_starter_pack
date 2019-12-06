# gul
**Graphics UtiL** for converting monochrome **PNG** image to **BIN** file.
You can use this for ZX-Spectrum and other 8-bit computers, Arduino and etc, use together with https://github.com/errorcalc/AnotherGraphicsLibrary ...

### Params:
* < -src Source PNG/BMP image > - **in image**
* < -dst Destination BIN file > - **out bin**
* [ -bg RED,GREEN,BLUE ] - **background color (0,0,0 by default), other colors are foreground color**
* [ -dev 0...255 ] - **What deviation from *bg* can be determined as the background color (20 by default)**

### Usage:
![screen](screen.png)
```
gul -src sample.png -dst sample.bin -bg 202,202,202
errorsoft.org "gul"
Source = C:\sources\zx\gul\sample.png
Destanation = C:\sources\zx\gul\sample.bin
Background Color = (202, 202, 202)
Deviation = 20
Width = 166 (20.75 attr)
Height = 100 (12.5 attr)
Size = 2100
ok!
```

This util used in SleepInvaders ZX-Spectrum Demo: https://www.youtube.com/watch?v=GdBTQEAS9s4
