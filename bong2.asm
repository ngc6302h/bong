cpu 8086

SCREEN_WIDTH equ 320
SCREEN_HEIGHT equ 200
BAR_WIDTH equ 40
BAR_HEIGHT equ 5
BAR_SPEED equ 5

org 0x7c00
start:
mov ax, 0x0013                  ; set mode 0x13 (320x200x256 VGA)
int 10h

main_loop:
call clear_screen

; draw ball
mov ax, 0x0c07
xor bh, bh
mov cx, word [ball_x]
mov dx, word [ball_y]
int 10h
dec dx
int 10h
add dx, 2
int 10h
dec dx
dec cx
int 10h
add cx, 2
int 10h

; draw lower bar 
mov ax, 0x0c07
xor bh, bh
mov cx, BAR_WIDTH
add cx, word [lower_bar_x]
loop0:
mov dx, BAR_HEIGHT
add dx, word [lower_bar_y]
loop1:
int 10h
dec dx
cmp dx, word [lower_bar_y]
jne loop1
dec cx
cmp cx, word [lower_bar_x]
jne loop0

; draw upper bar
mov cx, BAR_WIDTH
add cx, word [upper_bar_x]
loop2:
mov dx, BAR_HEIGHT
add dx, word [upper_bar_y]
loop3:
int 10h
dec dx
cmp dx, word [upper_bar_y]
jne loop3
dec cx
cmp cx, word [upper_bar_x]
jne loop2

; read keyboard
mov ax, 1<<8
int 16h
test al, al ; check if key pressed
jz not_pressed
xor ax, ax
int 16h
cmp al, 'a'
je move_upper_bar_left
cmp al, 'd'
je move_upper_bar_right
cmp al, 'j'
je move_lower_bar_left
cmp al, 'l'
jne not_pressed
; update bar positions
move_lower_bar_right:
cmp word [lower_bar_x], SCREEN_WIDTH-BAR_WIDTH
jge not_pressed
add word [lower_bar_x], BAR_SPEED
jmp not_pressed
move_lower_bar_left:
cmp word [lower_bar_x], 0
jle not_pressed
sub word [lower_bar_x], BAR_SPEED
jmp not_pressed
move_upper_bar_right:
cmp word [upper_bar_x], SCREEN_WIDTH-BAR_WIDTH
jge not_pressed
add word [upper_bar_x], BAR_SPEED
jmp not_pressed
move_upper_bar_left:
cmp word [upper_bar_x], 0
jle not_pressed
sub word [upper_bar_x], BAR_SPEED
;jmp not_pressed

not_pressed:
; update ball direction
mov ax, word [ball_x]
add ax, word [ball_xdir]
cmp ax, 0
jle bounce_horizontally
cmp ax, SCREEN_WIDTH
jge bounce_horizontally
jmp check_bar_hit
bounce_horizontally:
neg word [ball_xdir]
jmp wait_more

check_bar_hit:
mov ax, word [ball_y]
cmp ax, BAR_HEIGHT
jle upper_bar_hit
cmp ax, SCREEN_HEIGHT-BAR_HEIGHT
jge lower_bar_hit
jmp move_ball

lower_bar_hit:
mov ax, word [lower_bar_x]
mov bx, word [ball_x]
cmp ax, bx
jle move_ball
mov cx, ax
add cx, BAR_WIDTH
cmp bx, cx
jge move_ball
add ax, BAR_WIDTH/2
sub bx, ax
mov ax, bx
mov bx, BAR_WIDTH/32
div bx
xor ah, ah
mov word [ball_xdir], ax
inc word [ball_ydir]
neg word [ball_ydir]

upper_bar_hit:
mov ax, word [upper_bar_x]
mov bx, word [ball_x]
cmp ax, bx
jle move_ball
mov cx, ax                      ; copy upper_bar_x
add cx, BAR_WIDTH
cmp cx, bx
jge move_ball
add ax, BAR_WIDTH/2
sub bx, ax
mov ax, bx
mov bx, BAR_WIDTH/32
div bx
xor ah, ah
mov word [ball_xdir], ax
dec word [ball_ydir]
neg word [ball_ydir]

move_ball:
; move ball
xor ax, ax
mov al, byte [ball_xdir]
xor bx, bx
mov bl, byte [ball_ydir]
add word [ball_x], ax
add word [ball_y], bx

wait_more:
xor ax, ax
int 1Ah
;and dx, 0x1
cmp dx, word [old_time]
je wait_more
mov word [old_time], dx

jmp main_loop

clear_screen:
mov ah, 0x06
xor al, al
mov bh, 0x0
xor cx, cx
mov dx, 0x184f
int 10h
mov ah, 0x02
xor bh, bh
xor dx, dx
int 10h
ret


kill:
  mov ax, 0x1000
  mov ax, ss
  mov sp, 0xf000
  mov ax, 0x5307
  mov bx, 0x0001
  mov cx, 0x0003
  int 0x15

;data start
ball_x: dw 140
ball_y: dw 100
ball_xdir: dw 4
ball_ydir: dw 1
upper_bar_x: dw 140
lower_bar_x: dw 140
upper_bar_y: dw 0
lower_bar_y: dw 194
old_time: dw 0
end:
times 510-($-$$) db 0x90
db 0x55, 0xaa                   ; boot sector signature
