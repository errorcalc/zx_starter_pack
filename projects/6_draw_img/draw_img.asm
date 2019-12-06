    ; указываем ассемблеру, что целевая платформа - spectrum128(pentagon)
    device zxspectrum128
    
disp equ #4000
attr equ #5800  
    
    ; адрес на который компилировать
    org #6100
    
    ; записывает в регистровую пару reg адрес для координат x,y
    macro ld_sxy reg, x, y
    ld reg,#4000 or ((((y) / 64) << 11) or ((((y) % 64) / 8) << 5) or (((y) % 8) << 8) + (x))
    endm
    
begin_file:
    ; разрешаем прерывания
    ei

    ; белый бордюр 
    ld a,7
    out (#fe),a    
    
    ; заполняем атрибуты
    ; ink - black
    ; paper - white
    ; bright - 0
    ld a,#38
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

.loop:
    halt
    
    ;ld de,disp
    ld_sxy de,(256/2-img_w/2)/8,192/2-img_h/2
    ld hl,img_data
    ld b,img_h
    ld c,img_w/8
    call draw_img   

    ld_sxy de,(256/2-backspace_w/2)/8,160
    ld hl,backspace_data
    ld b,backspace_h
    ld c,backspace_w/8
    call draw_img  
    
    jp .loop
    
; de - output addr
; hl - src
; b - height
; c - width
draw_img:
.y_loop:
    ; copy line
    push bc
    push de
    ld b,0
    ldir
    pop de
    pop bc
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
    djnz .y_loop
    ret
    
img_w equ 168
img_h equ 100
img_data:
    incbin "img.bin"
    
backspace_w equ 80
backspace_h equ 32
backspace_data:
    incbin "backspace.bin"
    
end_file:
    ; выводим размер банарника
    display "code size: ", /d, end_file - begin_file
    
    ; сохраняем банарник в "draw_img.$C"
    savehob "draw_img.$C", "draw_img.C", begin_file, end_file - begin_file
    
    ; сохраняем sna(снапшот состояния) файл
    savesna "draw_img.sna", begin_file
    
    ; сохраняем метки
    labelslist "user.l"
