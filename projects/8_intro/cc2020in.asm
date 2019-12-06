;  *** errorsoft 2019 ***
;      tg: @errorsoft
;    site: errorsoft.org
;  github: errorcalc
; license: Beer Demoscene License v1

    ; указываем ассемблеру, что целевая платформа - spectrum128(pentagon)
    device zxspectrum128 
       
    ;define USE_IM2_MUSIC   
    define SCROLL_TEXT   
       
data   equ #9000;...#a300
buffer equ #9300; 32 байта
text_buffer_data equ #9400; 256 байт
im2_table equ #9E00; 257 байт!

    ; адрес на который компилировать
    org #6100
    
    ; подключаем стандартные дефайны
    include "zx.asm"    
    
begin_file:
main:
    di
    ld sp,#6100
    
    ; черный бордюр 
    xor a
    out (#fe),a    
    
    ; заполняем атрибуты
    ld a,0
    ld hl,attr
    ld de,attr + 1
    ld bc,768 - 1
    ld (hl),a
    ldir
    
    ; заполняем экран шахматкой
    ld hl,img_data
	ld de,disp
	ld b,192
.cls_loop:
	push de
    push bc
	dup 32
    ldi
	edup
    pop bc
	pop de
    ; down de
    inc d
    ld a,d
    and 7
    jr nz,.exit_down_de
    ld a,e
    sub -32
    ld e,a
    sbc a,a
    and -8
    add a,d
    ld d,a
.exit_down_de:
	djnz .cls_loop
    

    ; устанавливаем прерывания
    ld a,high im2_handler; #8787
    ld hl,im2_table; #9e00
    call setup_im2

    /*
    ; плохой метод установить прерывания
    ld a,#9e
    ld i,a
    ld de,#8787
    ld (#9eff),de
    im 2
    */
    
    ; инициализируем музыку
    call #a000 
    
    ; очищаем буффер
    ld a,127
    ld hl,data
    ld de,data + 1
    ld bc,768 - 1
    ld (hl),a
    ldir
    
    ; инициализируем бегущую строку
    call text_init
    
    ei
    
.loop:
    halt
    
    ;ld a,1:out (#fe),a 
    ; рисуем
    ld de,attr
    ld hl,data
    ld bc,color_table_fire
    call fast_draw_fire
    ;ld a,0:out (#fe),a 
    
    ifdef SCROLL_TEXT
    ; рисование бегущей строки
    
.print_hack:
    nop
    nop
    nop
    
    ; сохраняем в de адрес вывода текста
.text_y_hack equ $+2
    ld de,(.table_y)   
      
    ; каждый второй фрейм мы только рисуем текст, без его сколлинга
    ld a,(.frame)
    xor 1
    ld (.frame),a
    jp z,.only_print; ----->
 
    ; хакаем ld de,(.table_y) 
    ; .table_y = ((.table_y + 2) and #1f) or low .table_y
    ld a,(.text_y_hack)
    inc a
    inc a
    and #1f
    or low .table_y
    ld (.text_y_hack),a 
    
    ; копируем байты из буффера в атриббуты
    ld hl,text_buffer
    dup (32 * 8)
    ldi
    edup    
    
    ; скроллим текст 
    call text_print 
    
    jp .end_print_text
    
.only_print:; <-----

    ; or-им байты из буффера в атриббуты
    ld hl,text_buffer
    dup (32 * 8)
    ld a,(de)
    or (hl)
    ld (de),a
    inc de
    inc l
    edup

.end_print_text:
    endif

    ; сдвигаем вверх
    ld de,data
    ld hl,data + 32
    ld c,4
    call fast_calc_fire 
     
    ; генерация
    ld hl,data + 736
    ;call random_point
    ld hl,data + 736
    call random_span
    
    ; затухание
    ld hl,data + 736
    call sub_line    
    ;ld hl,data + 736
    ;call sub_line  
    
    ; сглаживание left
    ld hl,data + 736
    ld de,buffer
    call smoth_line_left
    ; сглаживание right    
    ld hl,buffer
    ld de,data + 736
    call smoth_line_right    
    ; copy
    ;ld bc,32
    ;ld hl,buffer
    ;ld de,data + 736
    ;ldir
    
    ; фиксим границы
    ld hl,data + 736
    call fix_frames 

    ; cлучайный сдвиг (ветер)
    ld hl,data + 736 
    call try_random_shift_line

    ifndef USE_IM2_MUSIC
    ; play music
    call #a005 
    endif

    jp .loop
.frame db 0

    ifdef USE_IM2_MUSIC
.table_base_y equ 6
    else USE_IM2_MUSIC
.table_base_y equ 3
    endif
    
    align 64
    ; int(0.1+5+5*cos(x*(2pi/15))) x=[0..15]
.table_y:
    dw attr + 32 *(10 + .table_base_y)
    dw attr + 32 *(9 + .table_base_y)
    dw attr + 32 *(8 + .table_base_y)
    dw attr + 32 *(6 + .table_base_y)
    dw attr + 32 *(4 + .table_base_y)
    dw attr + 32 *(2 + .table_base_y)
    dw attr + 32 *(1 + .table_base_y)
    dw attr + 32 *(0 + .table_base_y)
    dw attr + 32 *(0 + .table_base_y)
    dw attr + 32 *(1 + .table_base_y)
    dw attr + 32 *(2 + .table_base_y)
    dw attr + 32 *(4 + .table_base_y)
    dw attr + 32 *(6 + .table_base_y)
    dw attr + 32 *(8 + .table_base_y)
    dw attr + 32 *(9 + .table_base_y)
    dw attr + 32 *(10 + .table_base_y)


text_background_color equ #00
text_foreground_color equ #7F
text_buffer equ text_buffer_data
text_font equ 15616 - 256 
text_font_width equ 7
text_string:
    byte "    3..   2..   1..   0.....................? ... .. . "
    byte "Hello scener! You are invited to Chaos Constructions 2020 demoparty! At 22-23 August, Saint-Peterburg, Russia. "
    byte "This is the largest Russian demoparty. At the party there will be a large screen, a lot of demosceners, "
    byte "a retro exhibition, beeeeeer, and cool demos! "
    byte "Come to us and do not forget to bring the prod with you!   "
    byte "*** chaosconstructions.ru ***   "
    byte "This invitro from errorsoft: Error(code) & Quiet(music) special to B4CKSP4CE visitors!   "
    byte "It's open source, see github.com/errorcalc/zx_starter_pack     " ,0 

text_print:
    ; сдвигаем текст в буффере
    ld de,text_buffer
    ld hl,text_buffer + 1
    ld b,8
.loop_shift:
    push bc
    dup 31
    ldi
    edup
    pop bc
    inc hl
    inc de
    djnz .loop_shift
    
    ; сохраняем в буффере символа изображение нового сомвол из строки
    ; при необходимости text_shift == 0
    ld a,(.text_shift)
    or a
    jr nz,.skip_get_symbol
    ld de,(.text_ptr)
    ld h,a
    ld a,(de)
    ld l,a
    add hl,hl
    add hl,hl
    add hl,hl  
    ld de,text_font
    add hl,de
    ; copy
    ld de,.symbol_store
    ld bc,8
    ldir
.skip_get_symbol

    ; впечатываем полоску пикселей из буффера символа
    ld hl,text_buffer + 31
    ld de,32
    ld ix,.symbol_store
    ;
    ld b,8    
.print_loop:    
    ld c,(ix)
    ld a,c
    sla c
    ld (ix),c
    inc ix
    ;
    and 128
    jr nz,.print_1
    ld a,text_background_color
    jr .print_end
.print_1:
    ld a,text_foreground_color
.print_end:
    ld (hl),a
    ;
    add hl,de
    djnz .print_loop
    
    ; если символ полностью пропечатан, достаем код следующего символа из строки
    ld a,(.text_shift)
    inc a
    cp text_font_width
    jr c,.skip_new_symbol
    ld hl,(.text_ptr)
    inc hl
    ld a,(hl)
    or a
    jr nz,.skip_restart
    ;начинаем сначала
    ;ld hl,text_string
    ifdef SCROLL_TEXT
    ; хакаем вывод строки
    ;
    ld a,#c3; jp
    ld (main.print_hack),a  
    ld de,main.end_print_text
    ld (main.print_hack+1),de
    ;
    endif
.skip_restart:
    ld (.text_ptr),hl
    xor a
.skip_new_symbol:
    ld (.text_shift),a
    ret
     
.text_ptr:
    dw text_string
.text_shift:
    db 0
.symbol_store:
    .8 db 0
    
text_init:
    ld hl,text_string
    ld (text_print.text_ptr),hl
    ld hl,text_buffer
    ;
    ld a,text_background_color
    ld hl,text_buffer
    ld de,text_buffer + 1
    ld bc,256 - 1
    ld (hl),a
    ldir
    ret
    
; bc - color table
; hl - data
; de - attr
fast_draw_fire:
    ld a,3
.loop:
    ex af,af
    dup 256
    ; загружаем байт из data в A
    ; data[i++] -> C
    ld c,(hl)
    inc l
    ; загружаем байт из color table для C в A
    ; color_table[C] -> A
    ld a,(bc)
    ; сохраняем атрибут
    ld (de),a
    inc e
    edup
    inc h
    inc d
    ex af,af
    dec a
    jp nz,.loop
	ret 

    
; de - data
; hl - data + 32
; c - sub 
fast_calc_fire:
    call .up8
    call .up8
    dup (256 - 32)
    ; сдвигаем строку вверх, параллельно отнимая C
    ld a,(hl):inc hl
    sub c
    ld (de),a:inc e
    edup
	ret 
.up8:
    dup 256
    ; сдвигаем строку вверх, параллельно отнимая C
    ld a,(hl):inc hl
    sub c
    ld (de),a:inc e
    edup
    inc d
    ret
   
; сдвигает линию в HL в вероятностью 1/8
try_random_shift_line:
    ; с вероятностью 7/8 выходим
    call random_elite
    and #07
    ret nz
    ; сдвигаем линию влево
    ld c,(hl)
    ld d,h:ld e,l
    inc de
	dup 31
    ld a,(de)
    ld (hl),a
    inc hl
    inc de
    edup
    ld (hl),c
    ret
   
; размывание линии, влево
; hl - src
; de - dst   
smoth_line_left:
    push hl
	dup 31
    ; получаем среднее значение двух байтов 
    ; [HL++]/2+[HL]/2 -> A
	ld a,(hl)
    inc hl
	ld c,(hl)
	srl a
	srl c
	add c
    
    ; фиксим A 
	cp 127
	jp nc,$+2+3
	ld a,127
 
    ; сохраняем A -> [DE++]
	ld (de),a
    inc de
	edup
    
    ; частный случай
	ld a,(hl)
    pop hl
	ld c,(hl)
	srl a
	srl c
	add c
    ;
	cp 127
	jr nc,$+2+2
	ld a,127
    ;
	ld (de),a
    ret
   
; размывание линии, вправо
; hl - src + 31
; de - dst + 31  
smoth_line_right:
    push hl
    push de
    inc de
	dup 31
    ; получаем среднее значение двух байтов
    ; [HL++]/2+[HL]/2 -> A
	ld a,(hl)
    inc hl
	ld c,(hl)
	srl a
	srl c
	add c
    
    ; фиксим A 
	cp 127
	jp nc,$+2+3
	ld a,127
 
    ; сохраняем A -> [DE++]
	ld (de),a
    inc de
	edup
    
    ; частный случай
	ld a,(hl)
    pop de
    pop hl
	ld c,(hl)
	srl a
	srl c
	add c
    ;
	cp 127
	jr nc,$+2+2
	ld a,127
    ;
	ld (de),a
    ret

; затухание линии в HL
sub_line:
	dup 32
    ; [HL] - 2 -> A
	ld a,(hl)
    sub 2
    cp 127
    ; фиксим
    jp nc,$+5
    ld a,127
    ; A -> [HL++}
	ld (hl),a
    inc hl
	edup
    ret
    
fix_frames:
    ; left
    ld a,(hl)
    sub 20
	cp 127
	jr nc,$+2+2
	ld a,127
    ld (hl),a
    ; right
    ld de,31
    add hl,de
    ld a,(hl)
    sub 20
	cp 127
	jr nc,$+2+2
	ld a,127
    ld (hl),a
    ret
    
; добавление рандомной точки в HL
random_point:
    ; рандомно выбираем x[0..31] -> HL
	call random_elite
	and #1f
	ld d,0
	ld e,a
	add hl,de
	; цвет -> A
	call random_elite
	or #c0
    ; прибавляем A к значению в [HL]
	ld c,(hl)
	add c
	; фиксим, если необходимо
	jr nc,$+4
	ld a,255
	; сохраняем A в [HL]
	ld (hl),a
    ret
    
; добавление рандомного отрезка в HL
random_span:
    ; рандомная ширина [1..4] -> B
	call random_elite
    and #03
    inc a
    ld b,a
    ; рандомно выбираем x[0..31] -> HL
	call random_elite
	and #1f
	ld d,0
	ld e,a
	add hl,de
    
.loop:
	; цвет -> A
	call random_elite
	or #c0
    ; прибавляем A к значению в [HL]
	ld c,(hl)
	add c
	; фиксим, если необходимо
	jr nc,$+4
	ld a,255
	; сохраняем A в [HL]
	ld (hl),a
    inc hl
    ; выходим, если дошли до конца > 31
    inc e
    bit 5,e
    ret nz
    djnz .loop
    
    ret
    
; генерация случайного числа 0..255 -> A
random_elite:
    ld a,(.store)
    ld d,a
    ld a,(.store+1)
    ld (.store),a
    add a,d
    ld d,a
    ld a,(.store+2)
    ld (.store+1),a
    add a,d
    rlca
    ld (.store+2),a
    ret
.store:
    db 0,42,109
    
    align 256
color_table_fire:
    .128 db paper_black   or attr_bright or ink_blue
    .4   db paper_black   or ink_blue
	.4   db paper_black    or ink_blue  or attr_bright
	.4   db paper_black    or ink_magenta or attr_bright	
	.8   db paper_blue    or ink_blue    or attr_bright
	.12  db paper_magenta or ink_blue    or attr_bright	
	.6   db paper_magenta or ink_magenta or attr_bright	
	.12  db paper_magenta or ink_red     or attr_bright
	.13  db paper_red     or ink_red     or attr_bright
	.18  db paper_red     or ink_yellow	 or attr_bright
	.12  db paper_yellow  or ink_yellow  or attr_bright
    .15  db paper_yellow  or ink_white   or attr_bright
	.15  db paper_white   or ink_white   or attr_bright
	.5   db paper_cyan   or ink_white   or attr_bright
/*
    .128 db paper_black   or attr_bright or ink_blue
    .4   db paper_black   or attr_bright or ink_blue
	.4   db paper_blue    or ink_black 
	.4   db paper_blue    or ink_blue	
	.8   db paper_blue    or ink_blue    or attr_bright
	.10  db paper_magenta or ink_blue    or attr_bright	
	.10  db paper_magenta or ink_magenta or attr_bright	
	.10  db paper_magenta or ink_red     or attr_bright
	.13  db paper_red     or ink_red     or attr_bright
	.15  db paper_red     or ink_yellow	 or attr_bright
	.15  db paper_yellow  or ink_yellow  or attr_bright
    .15  db paper_yellow  or ink_white   or attr_bright
	.20  db paper_white   or ink_white   or attr_bright
*/

; hl - inttab (257 bytes), align 256
; a - im2 proc (addr = aa, for ex: a = c0 => addr = c0c0)
setup_im2:
    di
    ld d,h
    ld e,l
    inc de
    ld (hl),a
    ld bc,256
    ldir
    ;
    dec h
    ld a,h
    ld i,a
    im 2
    ret

    display "End main code: ", $
    
    assert $ <= #8787
    org #8787
im2_handler:
    ifdef USE_IM2_MUSIC
    push ix 
    push iy
    push bc 
    push de
    push hl
    push af
    exx
    push bc
    push de
    push hl
    ex af,af
    push af
    ; play music
    call #a005 
    pop af 
    pop hl 
    pop de
    pop bc
    ex af,af
    pop af
    exx
    pop hl
    pop de
    pop bc
    pop iy
    pop ix
    else
    nop
    nop
    nop
    nop
    endif
    ei
    ret
   
img_data:
    incbin "cc2020.bin"
   
    display "End code: ", $
   
    
    assert $ <= #a000
    ; музыка должна быть скомпилена на #a000
    org #a000
    inchob "Quiet.$c"
    
end_file:
    ; выводим размер банарника
    display "Code size: ", /d, end_file - begin_file
    
    ; выводим end
    display "End byte: ", end_file
    
    ; сохраняем банарник в "cc2020in.$C"
    savehob "cc2020in.$C", "cc2020in.C", begin_file, end_file - begin_file
    
    ; сохраняем sna(снапшот состояния) файл
    savesna "cc2020in.sna", begin_file
    
    ; сохраняем метки
    labelslist "user.l"
