    ; указываем ассемблеру, что целевая платформа - spectrum128(pentagon)
    device zxspectrum128
    
disp equ #4000
attr equ #5800  
fast_point_table equ #a000; 1k table   
    
    ;define USE_FAST_POINT
    
    ; адрес на который компилировать
    org #6100
    
begin_file:
    ; устанавливаем дно стека
    ld sp,#6100
    ; разрешаем прерывания
    ei

    ; черный бордюр 
    xor a
    out (#fe),a    
    
    ; заполняем атрибуты
    ; ink - green
    ; paper - black
    ; bright - 1
    ld a,#44
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
    
    ifdef USE_FAST_POINT
    ld de,disp
    ld hl,fast_point_table
    call fast_point_table_init
    endif

.points_loop:
    halt
  
    ; blue border
    ld a,1:out (#fe),a   
    
    ld ixl,0
    ifndef USE_FAST_POINT
    ld b,110; 3 * 110 = 330 pts 
    else
    ld b,190; 190 * 3= 570 pts
    endif
.loop:
    ; draw point * 3
    dup 3
    ld d,ixl
    ld e,ixl
    ifndef USE_FAST_POINT
    call draw_point
    else
    call fast_point 
    endif
    edup
    inc ixl
    djnz .loop
    
    ; black border
    ld a,0:out (#fe),a 
    
    jp .points_loop

    di:halt
    
; Input:
; d - y
; e - x
; Used:
; c,h,l
; #4000 or ((y / 64) << 11) or (((y % 64) / 8) << 5) or ((y % 8) << 8)
draw_point:
    ; получаем байт для x%8
    ld h,high .point_bits
    ld a,e
    and #07
    or low .point_bits
    ld l,a
    ld c,(hl)
    ; high byte
    ; y (номер трети)
    ld a,d
    rra
    rra
    rra
    and #18
    ld h,a
    ; y (смещение внутри знакоместа)
    ld a,d
    and #07
    or h
    or #40; screen fix
    ld h,a
    ; low byte
    ; x div 8 -> e
    srl e
    srl e
    srl e
    ; y (номер ряда)
    ld a,d
    rla
    rla
    and #e0
    or e; x fix
    ld l,a
    ; на этом этапе в HL лежит адрес пиксела
    ; вы можете легко переделать процедуру для set/reset/change point
    ld a,(hl)
    or c
    ld (hl),a
    ret
    align 8
.point_bits:
    db 128,64,32,16,8,4,2,1
    
; Input:
; d - y
; e - x
; Used:
; h,l
fast_point:
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
    ld a,128;208;128;128;136;208;192;128
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
    
    ; сохраняем банарник в "drawpix.$C"
    savehob "drawpix.$C", "drawpix.C", begin_file, end_file - begin_file
    
    ; сохраняем sna(снапшот состояния) файл
    savesna "drawpix.sna", begin_file
    
    ; сохраняем метки
    labelslist "user.l"
