{$I-} {$A+} {$R-} {$S-} {$Q-} {$G+} {$N+} {$D-} {$L-} {$Y+} {$X-}
Unit LUtils;
Interface
Uses
    LMem, CRT;
Type
    TRegs = Record
      Case Integer Of
        0:
          (AX, BX, CX, DX, ES, DS, SI, DI, BP, Flags: Word);
        1:
          (AL, AH, BL, BH, CL, CH, DL, DH: Byte);
    End;

    {CP866}
    Function UpperCase(AStr: String): String;
    Function DownCase(AStr: String): String;
    Function IntToStr(AInt: LongInt): String;
    Function StrToInt(AStr: String): LongInt;  {0 если ошибка}
    Function GetPasStrFromASCIZ(AFrom: Pointer): String;
    Function IsFileExist(AFileName: String): Boolean;
    Function IntPower(X, I: LongInt): LongInt;
    Procedure CallInt(IntNum: Byte; Var Regs: TRegs);
    Function BinToDec(ABinStr: String): LongInt;
    Function HexToDec(AHexStr: String): LongInt;

    Procedure Sleep;

Implementation
{Стоит использовать команду XLAT и 2 таблицы для более быстрого перевода}
Function UpperCase(AStr: String): String;
Var
    I: Word;
Begin
    For I:= 1 To Length(AStr) Do Begin
        If Byte(AStr[I]) >= 128 Then Begin
            Case Byte(AStr[I]) Of
              160..175:
                AStr[I]:= Char(Byte(AStr[I]) - 32);
              224..239:
                AStr[I]:= Char(Byte(AStr[I]) - 80);
            End;
        End
        Else Begin
            AStr[I]:= UpCase(AStr[I]);
        End;
    End;
    UpperCase:= AStr;
End;

Function DownCase(AStr: String): String;
Var
    I: Word;
Begin
    For I:= 1 To Length(AStr) Do Begin
        If Byte(AStr[I]) >= 128 Then Begin
            Case Byte(AStr[I]) Of
              128..143:
                AStr[I]:= Char(Byte(AStr[I]) + 32);
              144..159:
                AStr[I]:= Char(Byte(AStr[I]) + 80);
            End;
        End
        Else Begin
            Case Byte(AStr[I]) Of
              65..90:
                AStr[I]:= Char(Byte(AStr[I]) + 32);
            End;
        End;
    End;
    DownCase:= AStr;
End;

Function IntToStr(AInt: LongInt): String;
Var
    S: String[11];
Begin
    Str(AInt, S);
    IntToStr:= S;
End;

Function StrToInt(AStr: String): LongInt;
Var
    I: LongInt;
    Code: Integer;
Begin
    Val(AStr, I, Code);
    If Code = 0 Then
        StrToInt:= I
    Else
        StrToInt:= 0; {!!!}
End;

Function GetPasStrFromASCIZ(AFrom: Pointer): String;
Var
    Tex: String;
    I: Word;
Begin
    For I:= 1 To 255 Do If TBufferP(AFrom)^[I] = 0 Then Break;
    MoveMem(AFrom, @Tex[1], I);
    Tex[0]:= Char(I);
    GetPasStrFromASCIZ:= Tex;
End;

Function IsFileExist(AFileName: String): Boolean;
Var
    FD: File;
Begin
    Assign(FD, AFileName);
    Reset(FD);
    If IOResult <> 0 Then
        IsFileExist:= False
    Else Begin
        Close(FD);
        IsFileExist:= True;
    End;
End;

Function IntPower(X, I: LongInt): LongInt;
Var
    Res: LongInt;
Begin
    Res:= 1;
    While I > 0 Do Begin
        If (I And 1 = 1) Then Res:= Res * X;
        X:= X * X;
        I:= I Shr 1;
    End;
    IntPower:= Res;
End;

Function BinToDec(ABinStr: String): LongInt;
Var
    I: Integer;
    Modifyer, Result: LongInt;
Begin
    Modifyer:= 1; Result:= 0;
    For I:= Length(ABinStr) DownTo 1 Do Begin
        Inc(Result, Modifyer * Byte(ABinStr[I] = '1'));
        Inc(Modifyer, Modifyer);
    End;
    BinToDec:= Result;
End;

Function HexToDec(AHexStr: String): LongInt;
Var
    I, II: Integer;
    Modifyer, Result: LongInt;
    HexDigits: String;
Begin
    HexDigits:= '0123456789ABCDEF';
    Modifyer:= 1; Result:= 0;
    For I:= Length(AHexStr) DownTo 1 Do Begin
        For II:= 1 To 16 Do Begin
            If AHexStr[I] = HexDigits[II] Then Begin
                Result:= Result + Modifyer * (II - 1);
                Modifyer:= Modifyer * 16;
                Break;
            End;
        End;
    End;
    HexToDec:= Result;
End;

Procedure CallInt(IntNum: Byte; Var Regs: TRegs); Assembler;
Asm
    jmp @OverRegs
   @RegsLivesHereXDD:
    dd 0
   @OverRegs:
    mov al,IntNum
    mov byte ptr cs:[@CallInt+1],al

    push bp
    push ds

    les di,Regs
    mov ax,es
    mov word ptr cs:[@RegsLivesHereXDD],ax
    mov word ptr cs:[@RegsLivesHereXDD + 2],di

    mov al,es:[di]
    mov ah,es:[di+1]
    mov bl,es:[di+2]
    mov bh,es:[di+3]
    mov cl,es:[di+4]
    mov ch,es:[di+5]
    mov dl,es:[di+6]
    mov dh,es:[di+7]    {!!!}

    push word ptr es:[di+8]
    push word ptr es:[di+10]
    push word ptr es:[di+12]
    push word ptr es:[di+14]
    push word ptr es:[di+16]
    push word ptr es:[di+18]

    popf
    pop bp
    pop di
    pop si
    pop ds
    pop es

   @CallInt:
    dw 0CDh

    push ax
    push bx
    push cx
    push dx
    push es
    push ds
    push di
    push si
    push bp

    mov ax,word ptr cs:[@RegsLivesHereXDD]
    mov es,ax
    mov di,word ptr cs:[@RegsLivesHereXDD+2]

    pop word ptr es:[di+16]
    pop word ptr es:[di+14]
    pop word ptr es:[di+12]
    pop word ptr es:[di+10]
    pop word ptr es:[di+8]
    pop word ptr es:[di+6]
    pop word ptr es:[di+4]
    pop word ptr es:[di+2]
    pop word ptr es:[di]

    pop ds
    pop bp
End;

Procedure Sleep; Assembler;
Asm
    xor ax,ax
    int 16h
End;

End.