    ; указываем ассемблеру, что целевая платформа - spectrum128(pentagon)
    device zxspectrum128
    
    ; адрес на который компилировать
    org #6100
    
begin_file:
    ; запрещаем прерывания
    di
    
    ;xor a:ld b,7
loop:
    ; синий бордюр 
    ld a,1
    ;inc a:and b
    out (#fe),a
    
    nop:nop:nop
    
    ; красный бордюр 
    ld a,2
    ;inc a:and b
    out (#fe),a
    
    nop:nop:nop
    
    ; зеленый бордюр 
    ld a,4
    ;inc a:and b
    out (#fe),a

    jr loop
    
end_file:
    ; выводим размер банарника
    display "code size: ", /d, end_file - begin_file
    
    ; сохраняем банарник в "hello.$C"
    savehob "hello.$C", "hello.C", begin_file, end_file - begin_file
    
    ; сохраняем sna(снапшот состояния) файл
    savesna "hello.sna", begin_file
    
    ; сохраняем метки
    labelslist "user.l"
