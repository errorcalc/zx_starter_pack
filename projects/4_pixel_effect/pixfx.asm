    ; указываем ассемблеру, что целевая платформа - spectrum128(pentagon)
    device zxspectrum128
    
disp equ #4000
attr equ #5800  
fast_point_table equ #a000; 1k table   
point_array equ #a400; 512b
    
    ; адрес на который компилировать
    org #6100
    
begin_file:
    ; разрешаем прерывания
    ei

    ; черный бордюр 
    xor a
    out (#fe),a    
    
    ; заполняем атрибуты
    ; ink - cyan
    ; paper - black
    ; bright - 1
    ld a,#45
    ld hl,attr
    ld de,attr + 1
    ld bc,768 - 1
    ld (hl),a
    ldir
    
    ; очищаем экран
    xor a
    ld hl,disp
    ld de,disp + 1
    ld bc,6144 - 1
    ld (hl),a
    ldir
    
    ; генерируем таблицу для рисования пикселей
    ld de,disp
    ld hl,fast_point_table
    call fast_point_table_init
 
    ; gen stars
    ld ix,point_array
    ld b,160
.gen_loop:
    ; gen random y
.regen_y:
    call random_elite
    ; сравниваем A с 192
    cp 192
    ; если A-192 >= 0 => флаг C не установлен
    ; no snow effect
    jr nc,.regen_y
    ld (ix),a: inc ix
    ; gen random x
    call random_elite
    ld (ix),a: inc ix
    djnz .gen_loop

.loop:
    halt
 
    ld ix,point_array
    ld b,160
.draw_loop:
    
    ; стираем точку
    ld d,(ix)
    ld e,(ix+1)
    push de
    call clear_point
    pop de
    ; ставим точку
    ld a,b
    and 7
    inc a
    add e
    ld e,a
    ld (ix+1),e
    ; snow effect
    ;inc d:inc d
    ;ld (ix),d
    call draw_point  

    inc ix: inc ix
 
    ; border fun
    ; ld a,e:and 3:out (#fe),a; bb
    ; xor a:out (#fe),a; bb
    djnz .draw_loop
    
    jp .loop
    
random_elite:
    ld a,(random_store)
    ld d,a
    ld a,(random_store+1)
    ld (random_store),a
    add a,d
    ld d,a
    ld a,(random_store+2)
    ld (random_store+1),a
    add a,d
    rlca
    ld (random_store+2),a
    ret

random_store:
    db 0,42,109    
    
; Input:
; d - y
; e - x
; Used:
; h,l
draw_point:
    ld h,high fast_point_table;7
    ; y
    ld l,d;4
    ld d,(hl);7
    inc h;4
    ; x
    ld a,(hl);7 sss
    inc h;4
    ld l,e;4
    or (hl);7 смещение в байтах
    ld e,a;4
    ;
    inc h;4
    ld a,(de);7
    or (hl);7
    ld (de),a;7
 
    ret;10
    ; 49 + 28 = 77
    ; 49 + 24 = 73  

; Input:
; d - y
; e - x
; Used:
; h,l
clear_point:
    ld h,high fast_point_table;7
    ; y
    ld l,d;4
    ld d,(hl);7
    inc h;4
    ; x
    ld a,(hl);7 sss
    inc h;4
    ld l,e;4
    or (hl);7 смещение в байтах
    ld e,a;4
    ;
    inc h;4
    ex de,hl
    ld a,(de);7
    cpl
    and (hl);7
    ld (hl),a;7
 
    ret;10
    ; 49 + 28 = 77
    ; 49 + 24 = 73     
    
; hl - fast_point_table
; de - screen addr (#4000,#c000)
fast_point_table_init:  
    ; генерация таблицы старшего байта адреса по Y
    ; заполняет 192(256) байтов 3 группами по 8*8
    ; %ddd00000,%ddd00001,%ddd00010,%ddd00011,%ddd00100,%ddd00101,%ddd00110,%ddd00111
    ; ...
    ; %ddd01000,%ddd01001,%ddd01010,%ddd01011,%ddd01100,%ddd01101,%ddd01110,%ddd01111
    ; ...
    ; %ddd10000,%ddd10001,%ddd10010,%ddd10011,%ddd10100,%ddd10101,%ddd10110,%ddd10111
    ld c,#00
.loop4:
    ld b,64
.loop44:
    ld a,l; смещение внутри знакоместа
    and #07
    or d; начало адреса
    or c; номер трети
    ld (hl),a
    inc hl
    djnz .loop44
    ld a,c
    add #08
    ld c,a
    cp #18
    jr nz,.loop4  
    ; пропускаем 64 байта
    ;ld l,0
    ;inc h
    ; ловушка, перенаправляющая вывод в пзу, при попытке нарисовать за экраном
    ld b,64
    ld a,0
.hook4:
    ld (hl),a
    inc hl
    djnz .hook4
    ; генерация таблицы смещения знакоместа в трети по Y
    ; заполняет 192(256) байтов 3 группами по 8*8
    ; #00,#00,#00,#00,#00,#00,#00,#00, 
    ; #20,#20,#20,#20,#20,#20,#20,#20,
    ; #40,#40,#40,#40,#40,#40,#40,#40,
    ; ...
    ; #E0,#E0,#E0,#E0,#E0,#E0,#E0,#E0,
    ; #00,#00,#00,#00,#00,#00,#00,#00, 
    ; ...
    ; логика повторений в том что по inc(младший байт) можно будет извлечь атриббутах в ряду по y
    ld a,0; текущее значение
    ex af,af
    ld a,8*3; сколько групп по 8 байтов
.loop3:
    ex af,af
    ld b,8
.loop33:
    ld (hl),a
    inc hl
    djnz .loop33
    add #20
    ex af,af
    dec a
    and a
    jr nz,.loop3
    ; пропускаем 64 байта
    ;ld l,0
    ;inc h
    ; ловушка, перенаправляющая вывод в пзу, при попытке нарисовать за экраном
    ld b,64
    ld a,0
.hook3:
    ld (hl),a
    inc hl
    djnz .hook3
    ; генерация таблицы смещения байта в строке
    ; заполняет 256 байтов 32 нарастающими группами по 8 байт 
    ; 0,0,0,0,0,0,0,0, 1,1,1,1,1,1,1,1, 2,2,2,2,2,2,2,2...
    ; логика повторений в том что по inc(младший байт) можно будет извлечь смещение
    ld a,0
.loop2:
    ld b,8
.loop22:
    ld (hl),a
    inc hl
    djnz .loop22
    inc a
    cp 32
    jr nz,.loop2    
    ; генерация таблицы смещения пиксела в байте
    ; заполняет 256 байтов повторяющимся паттерном 1,2,4,8,16,32,64,127,1,2..
.pixel_bit:
    ld a,128
    ; snow effect
    ;ld a,208;128;208
    ld b,0
.loop1:
    ld (hl),a
    rrc a
    inc hl
    djnz .loop1
    ret
    
end_file:
    ; выводим размер банарника
    display "code size: ", /d, end_file - begin_file
    
    ; сохраняем банарник в "pixfx.$C"
    savehob "pixfx.$C", "pixfx.C", begin_file, end_file - begin_file
    
    ; сохраняем sna(снапшот состояния) файл
    savesna "pixfx.sna", begin_file
    
    ; сохраняем метки
    labelslist "user.l"
