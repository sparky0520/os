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

LoadKernel:
    mov si,ReadPacket ;structure
    mov word[si],0x10 ;structure length - 16 bytes
    mov word[si+2],100 ;number of sectors
    mov word[si+4],0 ;offset
    mov word[si+6],0x1000 ;segment - 0x10000
    mov dword[si+8],6 ;7th sector (lba is 0 indexed)
    mov dword[si+0xc],0 ;address high
    mov dl,[DriveId]
    mov ah,0x42 ;extended read (lba mode)
    int 0x13
    jc ReadError

GetMemInfoStart:
    mov eax,0xe820
    mov edx,0x534d4150 ;ascii code for smap
    mov ecx,20  ;memory block size 20 bytes
    mov edi,0x9000
    xor ebx,ebx
    int 0x15
    jc NotSupported ;cf set on first call means service not available

GetMemInfo:
    add edi,20 ;next memory block 20 bytes after
    mov eax,0xe820
    mov edx,0x534d4150
    mov ecx,20
    int 0x15
    jc GetMemDone ;if cf 0, we got all memory blocks

    test ebx,ebx ;if ebx not 0, fetch next memory block
    jnz GetMemInfo

GetMemDone:
TestA20:
    mov ax,0xffff
    mov es,ax
    mov word[ds:0x7c00],0xa200
    cmp word[es:0x7c10],0xa200
    jne SetA20LineDone
    mov word[ds:0x7c00],0xb200 ;could be 0x107c00 might have 0xa200 originally
    cmp word[es:0x7c10],0xb200 ;double checking here
    je End

SetA20LineDone:
    xor ax,ax
    mov es,ax

    mov ah,0x13
    mov al,1
    mov bx,0xa
    xor dx,dx
    mov bp,Message
    mov cx,MessageLen
    int 0x10

ReadError:
NotSupported:
End:
    hlt
    jmp End

DriveId:    db 0
Message:    db "A20 line is enabled"
MessageLen: equ $-Message   ; dynamic length
ReadPacket: times 16 db 0