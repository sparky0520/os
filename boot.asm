; boot file
[BITS 16]
[ORG 0x7c00]

start:
    xor ax,ax
    mov ds,ax
    mov es,ax
    mov ss,ax
    mov sp,0x7c00 ;grows downwards when pushed

TestExtension:
    mov [DriveId],dl
    mov ah,0x41 ;function 41 (disk extension service)
    mov bx,0x55aa
    int 0x13 ;bios interrupt 13
    jc NotSupported
    cmp bx,0xaa55   ;bios returns value aa55 in bx on success
    jne NotSupported

PrintMessage:
    mov ah,0x13
    mov al,1
    mov bx,0xa
    xor dx,dx
    mov bp,Message
    mov cx,MessageLen
    int 0x10

NotSupported:
End:
    hlt
    jmp End ;permanently halt program

DriveId:    db 0
Message:    db "Disk extension is supported"
MessageLen: equ $-Message   ; dynamic length

times (0x1be - ($-$$)) db 0
    ; partition table specified so that bios identifies the usb drive as hard disk not floppy disk
    db 80h
    db 0,2,0 ; sector 1 in lba terms
    db 0f0h
    db 0ffh,0ffh,0ffh
    dd 1
    dd (20*16*63-1) ; partition size is 10mb, no. of sectors = 10mb/512b

    times(16*3) db 0
    ; signature signifies valid boot code
    db 0x55
    db 0xaa