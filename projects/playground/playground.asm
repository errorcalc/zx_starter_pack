    ; указываем ассемблеру, что целевая платформа - spectrum128(pentagon)
    device zxspectrum128
    
    ; адрес на который компилировать
    org #6100
    
begin_file:
    ; запрещаем прерывания
    di
    ; устанавливаем дно стека
    ld sp,#6100
    
    ld a,8
    ld b,2
    
    sub b; a-b->a
    
    ; a = 6
    
    cp 6; a ? this
    
    jr z,euqal; a = xx, black
    jr c,less; a < xx, blue
    jr nc,more; a > xx, red, можно заменить на просто "jr more"   
    
    di:halt
    
euqal:
    ; black border
    ld a,0:out (#fe),a 
    di:halt

less:
    ; blue border
    ld a,1:out (#fe),a 
    di:halt
    
more:
    ; red border
    ld a,2:out (#fe),a 
    di:halt
    
end_file:
    ; выводим размер банарника
    display "code size: ", /d, end_file - begin_file
    
    ; сохраняем sna(снапшот состояния) файл
    savesna "playground.sna", begin_file
    
    ; сохраняем метки
    labelslist "user.l"
