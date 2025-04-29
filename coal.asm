[org 0x0100]
jmp start

; Data Section
snakebody: db '~'
snakefood: db 'o'
snakerow: db 12
snakecolumn: db 40
direction: db 0x4D 
score: dw 0
gameovermessage: db 'Game Over Press R to restart or Q to quit', 0
scoremessage: db 'Score: ', 0
speedmessage: db 'Select Speed: 1 for Slow, 2 for Medium, 3 for Fast', 0
restartmessage: db 'Press R to restart', 0
quitmessage: db 'Press Q to quit', 0
eatingsoundfrequency: dw 2000 
crashingsoundfrequency: dw 500 
maximumlength equ 100
snakelength: dw 1
snakesegments: times maximumlength db 0, 0 
foodrow: db 0
foodcolumn: db 0
gamespeed: dw 0x0002 

; Code Section
clearscreen:
    mov ax, 0xb800
    mov es, ax
    xor di, di
    mov ax, 0x0720
    mov cx, 2000
    rep stosw
    ret

playsound:
    push ax
    push bx
    push cx
    
    mov al, 182
    out 43h, al
    mov ax, [eatingsoundfrequency]
    out 42h, al
    mov al, ah
    out 42h, al
    
    in al, 61h
    or al, 00000011b
    out 61h, al
    
    mov cx, 0x0001
    mov dx, 0x0000
    mov ah, 0x86
    int 15h
    
    in al, 61h
    and al, 11111100b
    out 61h, al
    
    pop cx
    pop bx
    pop ax
    ret

playcrashsound:
    push ax
    mov ax, [crashingsoundfrequency]
    mov [eatingsoundfrequency], ax 
    call playsound
    mov ax, 2000
    mov [eatingsoundfrequency], ax 
    pop ax
    ret

drawsnake:
    mov ax, 0xb800
    mov es, ax
    
    mov cx, [snakelength]
    mov si, snakesegments
drawloop:
    xor ax, ax
    mov al, [si] 
    mov bx, 160
    mul bx
    mov di, ax
    xor ax, ax
    mov al, [si+1] 
    shl ax, 1
    add di, ax
    
    mov ax, 0x0F7E 
    mov word [es:di], ax
    
    add si, 2
    loop drawloop
    ret

drawfood:
    mov ax, 0xb800
    mov es, ax
    xor ax, ax
    mov al, [foodrow]
    mov bx, 160
    mul bx
    mov di, ax
    xor ax, ax
    mov al, [foodcolumn]
    shl ax, 1
    add di, ax
    mov ax, 0x0C6F
    mov word [es:di], ax
    ret

generatefood:
    pusha
tryagain:
    mov ah, 00h      
    int 1Ah          
    mov ax, dx
    xor dx, dx
    mov cx, 23      
    div cx
    inc dl           
    mov [foodrow], dl
    
    mov ah, 00h
    int 1Ah
    mov ax, dx
    xor dx, dx
    mov cx, 78       
    div cx
    inc dl          
    mov [foodcolumn], dl
    
    mov cx, [snakelength]
    mov si, snakesegments
checkloop:
    mov al, [foodrow]
    cmp al, [si]
    jne nextsegment
    mov al, [foodcolumn]
    cmp al, [si+1]
    je tryagain
nextsegment:
    add si, 2
    loop checkloop
    
    popa
    ret

displayscore:
    pusha
    mov ax, 0xb800
    mov es, ax
    mov di, 0        
    
    mov si, scoremessage
    mov ah, 0x0F     
scoreloop:
    lodsb
    cmp al, 0
    je scoredone
    stosw
    jmp scoreloop
    
scoredone:
    mov ax, [score]
    mov bx, 10
    xor cx, cx
    
digitloop:
    xor dx, dx
    div bx
    add dl, '0'
    push dx
    inc cx
    test ax, ax
    jnz digitloop
    
printloop:
    pop ax
    mov ah, 0x0F
    stosw
    loop printloop
    
    popa
    ret

checkinghindrance:
    mov al, [snakesegments] 
    cmp al, 0
    jb gameovercollision
    cmp al, 24
    ja gameovercollision
    
    mov al, [snakesegments+1] 
    cmp al, 0
    jb gameovercollision
    cmp al, 79
    ja gameovercollision
    
    mov cx, [snakelength]
    dec cx
    jz nohindrance 
    
    mov si, snakesegments
    mov di, si
    add di, 2 
    
hindranceloop:
    mov al, [si] 
    cmp al, [di]
    jne nextsegmentcollision
    mov al, [si+1] 
    cmp al, [di+1]
    je gameovercollision
nextsegmentcollision:
    add di, 2
    loop hindranceloop
    
nohindrance:
    ret

gameovercollision:
    call playcrashsound 
    jmp gameoverscreen

gameoverscreen:
    call clearscreen
    
    mov ax, 0xb800
    mov es, ax
    mov di, 160*10 + 50
    mov si, gameovermessage
    mov ah, 0x0C     
messageloop:
    lodsb
    cmp al, 0
    je displayscorescreen
    stosw
    jmp messageloop
    
displayscorescreen:
    mov di, 160*12 + 60
    mov si, scoremessage
    mov ah, 0x0F
scoreloopscreen:
    lodsb
    cmp al, 0
    je printscore
    stosw
    jmp scoreloopscreen
    
printscore:
    mov ax, [score]
    mov bx, 10
    xor cx, cx
    
digitloopscreen:
    xor dx, dx
    div bx
    add dl, '0'
    push dx
    inc cx
    test ax, ax
    jnz digitloopscreen
    
printloopscreen:
    pop ax
    mov ah, 0x0F
    stosw
    loop printloopscreen
    
    mov di, 160*14 + 56
    mov si, restartmessage
    mov ah, 0x0A
restartloop:
    lodsb
    cmp al, 0
    je quitmsg
    stosw
    jmp restartloop
    
quitmsg:
    mov di, 160*15 + 56
    mov si, quitmessage
quitloop:
    lodsb
    cmp al, 0
    je waitkey
    stosw
    jmp quitloop
    
waitkey:
    mov ah, 0
    int 16h
    
    cmp al, 'r'
    je restartgame
    cmp al, 'R'
    je restartgame
    
    cmp al, 'q'
    je exitgame
    cmp al, 'Q'
    je exitgame
    
    jmp waitkey
    
restartgame:
    jmp start

checkingfoodeaten:
    mov si, snakesegments 
    mov al, [si] 
    cmp al, [foodrow]
    jne continueeating
    
    mov al, [si+1] 
    cmp al, [foodcolumn]
    jne continueeating
    
    call playsound
    
    inc word [score]
    mov ax, [snakelength]
    cmp ax, maximumlength
    jae continueeating 
    inc word [snakelength]
    
    call displayscore
    call generatefood
    call drawfood
    
continueeating:
    ret

movesnake:
    mov cx, [snakelength]
    dec cx
    jz moveheadonly 
    
    mov si, snakesegments
    add si, cx
    add si, cx 
    mov di, si
    sub di, 2  
    
shiftloop:
    mov ax, [di]
    mov [si], ax
    sub si, 2
    sub di, 2
    loop shiftloop
    
moveheadonly:
    mov si, snakesegments 
    
    cmp byte [direction], 0x48 
    je moveup
    cmp byte [direction], 0x50 
    je movedown
    cmp byte [direction], 0x4B 
    je moveleft
    cmp byte [direction], 0x4D 
    je moveright
    
moveup:
    dec byte [si] 
    jmp donemoving
movedown:
    inc byte [si] 
    jmp donemoving
moveleft:
    dec byte [si+1] 
    jmp donemoving
moveright:
    inc byte [si+1] 
donemoving:
    ret

delay:
    push cx
    push dx
    mov cx, [gamespeed]
    mov dx, 0x0000
    mov ah, 0x86
    int 15h
    pop dx
    pop cx
    ret

selectspeed:
    call clearscreen
    
    mov ax, 0xb800
    mov es, ax
    mov di, 160*12 + 40
    mov si, speedmessage
    mov ah, 0x0F
speedloopselect:
    lodsb
    cmp al, 0
    je waitkeyspeed
    stosw
    jmp speedloopselect
    
waitkeyspeed:
    mov ah, 0
    int 16h
    
    cmp al, '1'
    je slowspeed
    cmp al, '2'
    je mediumspeed
    cmp al, '3'
    je fastspeed
    
    jmp waitkeyspeed 
    
slowspeed:
    mov word [gamespeed], 0x0003
    ret
mediumspeed:
    mov word [gamespeed], 0x0002
    ret
fastspeed:
    mov word [gamespeed], 0x0001
    ret

start:
    mov word [snakelength], 1
    mov byte [snakesegments], 12 
    mov byte [snakesegments+1], 40 
    mov word [score], 0
    mov byte [direction], 0x4D 
    
    call selectspeed
    
    mov ah, 0
    mov al, 3
    int 10h

    call clearscreen
    call generatefood
    call drawfood
    call drawsnake
    call displayscore

gameloop:
    mov ah, 1
    int 16h
    jz movesnakenow   
    
    mov ah, 0
    int 16h
    
    cmp ah, 0x48     
    je setingupdirection
    cmp ah, 0x50     
    je setingdowndirection
    cmp ah, 0x4B     
    je setingleftdirection
    cmp ah, 0x4D     
    je setingrightdirection
    jmp movesnakenow
    
setingupdirection:
    cmp byte [direction], 0x50 
    je movesnakenow
    mov byte [direction], ah
    jmp movesnakenow
    
setingdowndirection:
    cmp byte [direction], 0x48 
    je movesnakenow
    mov byte [direction], ah
    jmp movesnakenow
    
setingleftdirection:
    cmp byte [direction], 0x4D 
    je movesnakenow
    mov byte [direction], ah
    jmp movesnakenow
    
setingrightdirection:
    cmp byte [direction], 0x4B 
    je movesnakenow
    mov byte [direction], ah
    
movesnakenow:
    call movesnake
    call clearscreen
    call drawfood
    call drawsnake
    call checkingfoodeaten
    call checkinghindrance
    
    call delay
    
    jmp gameloop
    
exitgame:
    mov ax, 0x4c00
    int 21h