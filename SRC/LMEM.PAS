{$I-} {$A+} {$R-} {$S-} {$Q-} {$G+} {$N+} {$D-} {$L-} {$Y-} {$X-}
Unit LMem;
Interface
Const
    CMaxByte = High(Byte);
    CMinByte = Low(Byte);
    CMaxShort = High(ShortInt);
    CMinShort = Low(ShortInt);
    CMaxInt = High(Integer);
    CMinInt = Low(Integer);
    CMaxWord = High(Word);
    CMinWord = Low(Word);
    CMaxLong = High(LongInt);
    CMinLong = Low(LongInt);
    CMaxBuf = 65520;
Type
    TBuffer = Array [1..CMaxBuf] Of Byte;
    TCBuffer = Array [1..CMaxBuf] Of Char;
    TWBuffer = Array [1..CMaxBuf Div SizeOf(Word)] Of Word;
    TIBuffer = Array [1..CMaxBuf Div SizeOf(Integer)] Of Integer;
    TLBuffer = Array [1..CMaxBuf Div SizeOf(LongInt)] Of LongInt;
    TSBuffer = Array [1..CMaxBuf Div SizeOf(String)] Of String;
    TBufferP = ^TBuffer;
    TWBufferP = ^TWBuffer;
    TIBufferP = ^TIBuffer;
    TLBufferP = ^TLBuffer;
    TCBufferP = ^TCBuffer;
    TSBufferP = ^TSBuffer;

    Function CreateBuf(ASize: Word): Pointer;
    Function SizeOfBuf(ABuf: Pointer): Word;
    Function ResizeBuf(ABuf: Pointer; ANewSize: Word): Pointer;
    Function DestroyBuf(ABuf: Pointer): Pointer;
    Function BytesToKB(Bytes: LongInt): LongInt;
    Function KBToBytes(KBs: LongInt): LongInt;
    Procedure MoveMem(AFrom, ATo: Pointer; Size: Word);
    Procedure FillMem(ASource: Pointer; Value: Byte; Size: Word);

Implementation
Type
    TErr = (E_CantCreateBuf);
Const
    ET_CantCreateBuf = 'Не удалось создать буфер требуемого размера в динамической памяти';

    Procedure OnError(AErr: TErr); Forward;

Function CreateBuf(ASize: Word): Pointer;
Var
    TempP: Pointer;
Begin
    If (ASize = 0) Or (ASize > 65520) Then OnError(E_CantCreateBuf);
    Inc(ASize, 2);
    If (MaxAvail >= ASize) Then Begin
        GetMem(TempP, ASize);
        Word(TempP^):= ASize;
        TempP:= Pointer(LongInt(TempP) + 2);
        CreateBuf:= TempP;
    End
    Else
        OnError(E_CantCreateBuf);
End;

Function ResizeBuf(ABuf: Pointer; ANewSize: Word): Pointer;
Var
    TempP: Pointer;
Begin
    TempP:= CreateBuf(ANewSize);
    If ANewSize >= SizeOfBuf(ABuf) Then
        MoveMem(ABuf, TempP, SizeOfBuf(ABuf))
    Else
        MoveMem(ABuf, TempP, ANewSize);
    ABuf:= DestroyBuf(ABuf);
    ResizeBuf:= TempP;
End;

Function SizeOfBuf(ABuf: Pointer): Word;
Begin
    SizeOfBuf:= Word(Pointer(LongInt(ABuf) - 2)^) - 2;
End;

Function DestroyBuf(ABuf: Pointer): Pointer;
Begin
    ABuf:= TBufferP(LongInt(ABuf) - 2);
    FreeMem(ABuf, Word(Pointer(ABuf)^));
    DestroyBuf:= Nil;
End;

Procedure MoveMem(AFrom, ATo: Pointer; Size: Word); Assembler;
Asm
    push ds
    cmp Size,0
    je @End
    lds si,AFrom
    les di,ATo
    mov cx,Size
    cmp cx,1
    je @CopyLast
    shr cx,1
    rep movsw
    and Size,1
    dec Size
    jnz @end
   @CopyLast:
    mov al,[si]
    mov es:[di],al
    @End:
    pop ds
End;

Procedure FillMem(ASource: Pointer; Value: Byte; Size: Word); Assembler;
Asm
    cmp Size,0
    je @End
    mov al,Value
    mov ah,al
    mov bx,2
    les di,ASource
    mov cx,Size
    cmp cx,1
    je @CopyLast
    shr cx,1
   @Copy:
    mov es:[di],ax
    add di,bx
    dec cx                {Заоптимайзить копирование, глянуть асм команду что то вроде rep mowsw}
    jnz @Copy
    and Size,1
    dec Size
    jnz @End
   @CopyLast:
    mov es:[di],al
   @End:
End;

Function BytesToKB(Bytes: LongInt): LongInt;
Begin
    BytesToKB:= Bytes Div 1024 + LongInt((Bytes Mod 1024) > 0);
End;

Function KBToBytes(KBs: LongInt): LongInt;
Begin
    KBToBytes:= KBs Shl 10;
End;

Procedure OnError(AErr: TErr);
Var
    Msg: String;
Begin
    Msg:= 'LMem - ';
    Case AErr Of
      E_CantCreateBuf:
        Msg:= Msg + ET_CantCreateBuf;
    End;
    WriteLn(Msg);
    Halt(Word(AErr));
End;

End.