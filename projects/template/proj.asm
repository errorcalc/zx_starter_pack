    ; указываем ассемблеру, что целевая платформа - spectrum128(pentagon)
    device zxspectrum128 
       
    ; адрес на который компилировать
    org #6100
    
    ; подключаем стандартные дефайны
    include "zx.asm"    
    
begin_file:
main:
    ; устанавливаем дно стека
    ld sp,#6100
    
    ; черный бордюр 
    xor a
    out (#fe),a    
    
    ; очищаем экран
    xor a
    ld hl,disp
    ld de,disp + 1
    ld bc,6144 - 1
    ld (hl),a
    ldir
    
    
    ld ixl,0
loop:    
    ei:halt:di
    
    ; заполняем атрибуты
    ld a,ixl
    and #7f
    ld hl,attr
    ld de,attr + 1
    ld bc,768 - 1
    ld (hl),a
    ldir
    
    inc ixl
    jp loop
    
    
end_file:
    ; выводим размер банарника
    display "Code size: ", /d, end_file - begin_file
    
    ; выводим end
    display "End byte: ", end_file
    
    ; сохраняем банарник в "proj.$C"
    savehob "proj.$C", "proj.C", begin_file, end_file - begin_file
    
    ; сохраняем sna(снапшот состояния) файл
    savesna "proj.sna", begin_file
    
    ; сохраняем метки
    labelslist "user.l"
