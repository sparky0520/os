[BITS 16]
[ORG 0x7e00]

Start:
    mov [DriveId],dl

    ;testing if 0x80000001 value is supported
    mov eax,0x80000000 ;asking cpu what is it's highest extended function
    cpuid
    cmp eax,0x80000001
    jb NotSupported ;jump if below what we need

    mov eax,0x80000001
    cpuid
    test edx,(1<<29) ;long mode bit
    jz NotSupported
    test edx,(1<<26) ;1GB page support bit
    jz NotSupported

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
    jmp End

DriveId:    db 0
Message:    db "long mode is supported"
MessageLen: equ $-Message   ; dynamic length