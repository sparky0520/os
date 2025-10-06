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

LoadLoader:
    mov si,ReadPacket ;structure
    mov word[si],0x10 ;structure length - 16 bytes
    mov word[si+2],5 ;number of sectors
    mov word[si+4],0x7e00 ;offset
    mov word[si+6],0 ;segment
    mov dword[si+8],1 ;sector 1 (lba), sector 2(chs) - address low
    mov dword[si+0xc],0 ;address high
    mov dl,[DriveId]
    mov ah,0x42
    int 0x13
    jc ReadError

    mov dl,[DriveId]
    jmp 0x7e00

NotSupported:
ReadError:
    mov ah,0x13
    mov al,1
    mov bx,0xa
    xor dx,dx
    mov bp,Message
    mov cx,MessageLen
    int 0x10

End:
    hlt
    jmp End ;permanently halt program

ReadPacket: times 16 db 0
DriveId:    db 0
Message:    db "Error occured in boot process"
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