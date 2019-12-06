    ; указываем ассемблеру, что целевая платформа - spectrum128(pentagon)
    device zxspectrum128
    
    ; адрес на который компилировать
    org #6100
    
begin_file:
    ; запрещаем прерывания
    di
    
    ; устанавливаем дно стека
    ld sp,#6100
    ; ld hl,#DEC0:push hl
    
loop:
    ; синий бордюр 
    ld a,1
    out (#fe),a
    
    nop
    nop
    
    nop:nop:nop; nop:nop:nop занимает столько же тактов, что и jr n (12)
    
    ; красный бордюр 
    ld a,2
    out (#fe),a

    nop
    nop
    
    jr loop
    
end_file:
    ; выводим размер банарника
    display "code size: ", /d, end_file - begin_file
    
    ; сохраняем sna(снапшот состояния) файл
    savesna "hello.sna", begin_file
    
    ; сохраняем метки
    labelslist "user.l"
