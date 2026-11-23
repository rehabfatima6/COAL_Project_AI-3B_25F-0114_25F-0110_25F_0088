; M5 (FRAME BUFFER AND BLOCK OPERATIONS)
fb_segment dw 0

; Name: InitFrameBuffer
; Purpose: Compute and store the off-screen frame buffer segment above the .COM program's 64 KB segment (CS + 1000h)
; Inputs: None 
; Outputs: fb_segment set, ES pointed to fb_segment
; Registers changed: ES (set to fb_segment) ,all other registers and flags preserved

InitFrameBuffer:
    pushf
    push ax

    mov ax, cs
    add ax, 0x1000          
    mov [cs:fb_segment], ax
    mov es, ax              

    pop ax
    popf
    ret

; Name: ClearFrameBuffer
; Purpose: Fill the entire 320x200 off-screen frame buffer with a background colour using REP STOSW
; Inputs: colour (word on stack, low byte used: [bp+4])
; Outputs: Off-screen buffer filled; ES = fb_segment
; Registers changed: ES (set to fb_segment), all other registers and flags preserved

ClearFrameBuffer:
    push bp
    mov bp, sp

    pushf
    push ax
    push cx
    push di

    ; Ensure ES points to off-screen frame buffer
    mov ax, [cs:fb_segment]
    cmp ax, 0
    jne .seg_ready
    call InitFrameBuffer
    mov ax, [cs:fb_segment]
.seg_ready:
    mov es, ax

    ; Duplicate colour byte into AH and AL for 16-bit word writes
    mov al, [bp+4]
    mov ah, al

    xor di, di
    mov cx, FRAME_BUFFER_BYTES / 2 
    cld
    rep stosw

    pop di
    pop cx
    pop ax
    popf

    pop bp
    ret 2

; Name: PresentFrame
; Purpose: Copy the 64,000-byte off-screen frame buffer into VGA video memory (0xA000) using REP MOVSW
; Inputs: None
; Outputs: Screen updated cleanly; ES = fb_segment
; Registers changed: ES (set to fb_segment), all other registers and flags preserved

PresentFrame:
    pushf
    push ax
    push cx
    push si
    push di
    push ds

    ; Ensure fb_segment is initialized
    mov ax, [cs:fb_segment]
    cmp ax, 0
    jne .seg_ok
    call InitFrameBuffer
    mov ax, [cs:fb_segment]
.seg_ok:
    mov ds, ax              
    mov ax, 0xA000
    mov es, ax            

    xor si, si
    xor di, di
    mov cx, FRAME_BUFFER_BYTES / 2  
    cld
    rep movsw

    pop ds
    pop di
    pop si
    pop cx
    pop ax
    popf

    ; Leave ES pointing to fb_segment so subsequent drawing hits buffer
    push ax
    mov ax, [cs:fb_segment]
    mov es, ax
    pop ax
    ret