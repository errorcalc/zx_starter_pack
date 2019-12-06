    ; указываем ассемблеру, что целевая платформа - spectrum128(pentagon)
    device zxspectrum128
    
; здесь храниться огонь    
data   equ #a000;...#a300
; временный буффер для размытия
buffer equ #a300;...#a320

    
    ; адрес на который компилировать
    org #6100
    
    ; подключаем стандартные дефайны
    include "zx.asm"    
    
begin_file:
    ; устанавливаем дно стека
    ld sp,#6100
    ; разрешаем прерывания
    ei

    ; черный бордюр 
    xor a
    out (#fe),a    
    
    ; заполняем атрибуты
    ld a,ink_white or paper_blue
    ld hl,attr
    ld de,attr + 1
    ld bc,768 - 1
    ld (hl),a
    ldir
    
    ; заполняем экран шахматкой
	ld c,#AA
	ld de,disp
	ld b,192
.cls_loop:
	ld a,c
    cpl
    ld c,a
	push de
	dup 32
    ld (de),a
    inc de
	edup
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
    
    ;di:halt
    
    ; очищаем буффер
    ld a,127
    ld hl,data
    ld de,data + 1
    ld bc,768 - 1
    ld (hl),a
    ldir
    
.loop:
    halt
    
    ;ld a,(data + 736 + 15)
    ;and #13
    ;out (#fe),a 

    ; рисуем
    ld a,ink_white:out (#fe),a  
    ld de,attr
    ld hl,data
    ld bc,color_table_fire
    call draw_fire
    ld a,0:out (#fe),a  
      
    ; сдвигаем вверх
    ld a,ink_blue:out (#fe),a 
    ld de,data
    ld hl,data + 32
    ld c,5
    call fast_calc_fire
    ld a,0:out (#fe),a  
    
    /*
    ld a,255
    ld hl,data + 736
    ld de,data + 736 + 1
    ld bc,32
    ld (hl),a
    ldir
    */
    

    ; генерация
    ld a,ink_red:out (#fe),a 
    ;ld hl,data + 736
    ;call random_point
    ld hl,data + 736
    call random_span
    
    ; затухание
    ld hl,data + 736
    call sub_line    
    
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
    ld a,0:out (#fe),a 

    jp .loop
    
    di:halt
    
; bc - color table
; hl - data
; de - attr
draw_fire:
    ld a,24
.loop:
    ex af,af
    dup 32
    ; загружаем байт из data в A
    ; data[i++] -> A
    ld a,(hl)
    inc hl
    ; загружаем байт из color table для A в A
    ; color_table[A] -> A
    ld c,a
    ld a,(bc)
    ; сохраняем атрибут
    ld (de),a
    inc de
    edup
    ex af,af
    dec a
    jp nz,.loop
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
    
; сдвигает огонь вверх, с постепенным затуханием
; de - data
; hl - data + 32
; c - sub (сила затухания)
calc_fire:
    ld a,23
.loop:
    ex af,af
    dup 32
    ; сдвигаем строку вверх, параллельно отнимая C
    ld a,(hl):inc hl
    sub c
    ld (de),a:inc de
    edup
    ex af,af
    dec a
    jp nz,.loop
	ret    
    
; de - data
; hl - data + 32
; c - sub 
fast_calc_fire:
    dup 256
    ; сдвигаем строку вверх, параллельно отнимая C
    ld a,(hl):inc hl
    sub c
    ld (de),a:inc e
    edup
    inc d
    dup 256
    ; сдвигаем строку вверх, параллельно отнимая C
    ld a,(hl):inc hl
    sub c
    ld (de),a:inc e
    edup
    inc d
    dup (256 - 32)
    ; сдвигаем строку вверх, параллельно отнимая C
    ld a,(hl):inc hl
    sub c
    ld (de),a:inc e
    edup
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
	jr nc,$+2+2
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
	jr nc,$+2+2
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
    sub 80
	cp 127
	jr nc,$+2+2
	ld a,127
    ld (hl),a
    ; right
    ld de,31
    add hl,de
    ld a,(hl)
    sub 80
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
    .128 db paper_black   or attr_bright
    .4   db paper_black   or attr_bright
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

color_table_toxic:
    .128 db paper_black   or attr_bright
    .4   db paper_black   or attr_bright
	.4   db paper_blue    or ink_black
	.4   db paper_blue    or ink_blue	
	.8   db paper_blue    or ink_blue    or attr_bright
	.10  db paper_magenta or ink_blue    or attr_bright	
	.10  db paper_magenta or ink_magenta or attr_bright	
	.10  db paper_magenta or ink_red     or attr_bright
	.13  db paper_red     or ink_cyan    or attr_bright
	.15  db paper_cyan    or ink_green   or attr_bright
	.15  db paper_green   or ink_yellow  or attr_bright
    .15  db paper_yellow  or ink_white   or attr_bright
	.20  db paper_white   or ink_white   or attr_bright
   
    
end_file:
    ; выводим размер банарника
    display "code size: ", /d, end_file - begin_file
    
    ; сохраняем банарник в "fire.$C"
    savehob "fire.$C", "fire.C", begin_file, end_file - begin_file
    
    ; сохраняем sna(снапшот состояния) файл
    savesna "fire.sna", begin_file
    
    ; сохраняем метки
    labelslist "user.l"
