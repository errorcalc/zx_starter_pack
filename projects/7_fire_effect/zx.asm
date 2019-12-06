	ifndef zx_asm
	define zx_asm
    
def_view_screen1 equ #00 
def_view_screen2 equ #08
def_write_screen1 equ 5
def_write_screen2 equ 7
def_swap_screen equ #0a
    
disp equ #4000
attr equ #5800
disp2 equ #C000
attr2 equ #D800

;              +------H------+ +------L------+
;             -+-------------+-+-------------+-
;             ¦0¦1¦0¦t¦t¦s¦s¦s¦z¦z¦z¦x¦x¦x¦x¦x¦
;             -------+-+-+---+-+---+-+-------+-
;                    +-+ +---+ +---+ +-------+
;                     1    2     3       4
;
; 1(t)  Номер трети 0..2
; 2(s)  Смещение внутри знакоместа 0..7
; 3(z)  Номер ряда 0..7
; 4(x)  Номер столбца
;
;
;             -----------------
;             ¦f¦b¦p¦p¦p¦i¦i¦i¦
;             -+-+-+---+-+---+-
;    flash <---+ | +---+ +---+
;     bright <---+ paper  ink   
;
; D0..D2 - цвет "чернил" (INK)
; D3..D5 - цвет "бумаги" (PAPER)
; D6 - бит яркости (BRIGHT)
; D7 - бит мерцания (FLASH)
;
; 0 000 Чёрный    Black
; 1 001 Синий	  Blue
; 2 010 Красный   Red
; 3 011 Пурпурный Magenta
; 4 100 Зелёный   Green
; 5 101 Голубой   Cyan
; 6 110 Жёлтый    Yellow
; 7 111 Белый     White

ink_black           equ %00000000
ink_blue            equ %00000001
ink_red             equ %00000010
ink_magenta         equ %00000011
ink_green           equ %00000100
ink_cyan            equ %00000101
ink_yellow          equ %00000110
ink_white           equ %00000111

paper_black           equ %00000000
paper_blue            equ %00001000
paper_red             equ %00010000
paper_magenta         equ %00011000
paper_green           equ %00100000
paper_cyan            equ %00101000
paper_yellow          equ %00110000
paper_white           equ %00111000

attr_bright           equ %01000000
attr_flash            equ %10000000


    ; запись в reg адреса строки на экране, по y
    macro ld_sy reg, y
    ld reg,#4000 or (((y) / 64) << 11) or ((((y) % 64) / 8) << 5) or (((y) % 8) << 8)
    endm
    
    ; запись в reg адреса строки на втором экране, по y
    macro ld_s2y reg, y
    ld reg,#C000 or (((y) / 64) << 11) or ((((y) % 64) / 8) << 5) or (((y) % 8) << 8)
    endm

    ; запись в reg адреса байта на экране, по x(0..31) и y
    macro ld_sxy reg, x, y
    ld reg,#4000 or ((((y) / 64) << 11) or ((((y) % 64) / 8) << 5) or (((y) % 8) << 8) + (x))
    endm
    
    ; запись в reg адреса байта на втором экране, по x(0..31) и y
    macro ld_s2xy reg, x, y
    ld reg,#C000 or ((((y) / 64) << 11) or ((((y) % 64) / 8) << 5) or (((y) % 8) << 8) + (x))
    endm
    
    ; создание equ с именем name по x, y (адрес байта на экране)
    macro equ_sxy name, x, y
name equ #4000 or ((((y) / 64) << 11) or ((((y) % 64) / 8) << 5) or (((y) % 8) << 8) + (x))
    endm
    
    ; создание equ с именем name по x, y (адрес байта на втором экране)
    macro equ_s2xy name, x, y
name equ #C000 or ((((y) / 64) << 11) or ((((y) % 64) / 8) << 5) or (((y) % 8) << 8) + (x))
    endm
    
    ; создание dw по x, y (адрес байта на экране)    
    macro dw_sxy x, y
    dw (#4000 or ((((y) / 64) << 11) or ((((y) % 64) / 8) << 5) or (((y) % 8) << 8) + (x)))
    endm
    
    ; создание dw по x, y (адрес байта на втором экране)    
    macro dw_s2xy x, y
    dw (#C000 or ((((y) / 64) << 11) or ((((y) % 64) / 8) << 5) or (((y) % 8) << 8) + (x)))
    endm
    
    endif
    