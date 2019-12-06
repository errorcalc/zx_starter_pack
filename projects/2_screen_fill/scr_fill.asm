    ; указываем ассемблеру, что целевая платформа - spectrum128(pentagon)
    device zxspectrum128
    
disp equ #4000
attr equ #5800     
    
    ;define USE_DOWN_HL
    
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
    ; ink - white
    ; paper - black
    ; bright - 1
    ld a,#47
    ; заполняем атрибуты значением регистра A
    ld hl,attr
    ld de,attr + 1
    ld bc,768 - 1
    ; копируем A в байт по адресу HL
    ld (hl),a
    ; инструкция ldir копирует BC байтов
    ; из источника(HL) в назначение(DE).
    ; благодаря тому что источник и назначеме пересекаются
    ; мы заполняем attr значением в регистре A
    ldir
    
    ; очищаем экран
    xor a
    ld hl,disp
    ld de,disp + 1
    ld bc,6144 - 1
    ld (hl),a
    ldir
    
    ifndef USE_DOWN_HL
    ; ----------------------------------------------------
    ; построчно заполняем экран
    ld hl,disp
    ld a,#ff
    ; цикл заполнения строк
    ; кол-во строк в B
    ld b,192
.loop:
    ; заполняем строку 
    push bc
    ; с одной линии экрана 32 байта
    ld b,32
.x_loop:
    ld (hl),a
    inc hl
    djnz .x_loop
    pop bc
    
    ; ждем 2 фрейма
    halt
    halt
    
    ; djnz - инструкция цикла, декремент B, и повтор, если B <> 0
    djnz .loop
    ; ----------------------------------------------------
    di:halt

    else
    ; ----------------------------------------------------
    ; построчно заполняем экран
    ld hl,disp
    ; цикл заполнения строк
    ; кол-во строк в B
    ld b,192
.loop:
    ; заполняем строку 
    push hl
    ld a,#ff
    dup 32
    ld (hl),a
    inc hl
    edup
    pop hl
    ; переходим на строку ниже
    call down_hl
    
    ; ждем 2 фрейма
    halt
    halt
    
    ; djnz - инструкция цикла, декремент B, и повтор, если B <> 0
    djnz .loop
    ; ----------------------------------------------------
    di:halt
    
down_hl:
    inc h
    ld a,h
    and 7
    jr nz,.exit_down_hl
    ld a,l
    sub -32
    ld l,a
    sbc a,a
    and -8
    add a,h
    ld h,a
.exit_down_hl:
    ret

    endif
    
end_file:
    ; выводим размер банарника
    display "code size: ", /d, end_file - begin_file
    
    ; сохраняем банарник в "hello.$C"
    savehob "scr_fill.$C", "scr_fill.C", begin_file, end_file - begin_file
    
    ; сохраняем sna(снапшот состояния) файл
    savesna "scr_fill.sna", begin_file
    
    ; сохраняем метки
    labelslist "user.l"
