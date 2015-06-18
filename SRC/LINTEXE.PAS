{$I-} {$A+} {$R-} {$S-} {$Q-} {$G+} {$N+} {$D-} {$L-} {$Y-} {$X+} {$T+} {$V+}
{$M 16384, 0, 655360}
Program LIntEXE;
Uses LIntCons, LIntBCIn, LMem, CRT;
Var
    FD: File;
    ProgSize, EP: Word;
    BCP: TBufferP;
    ResP: TBCRunResultP;
    TempCh: Char;
Begin
    Assign(FD, ParamStr(0));
    Reset(FD, 1);
    Seek(FD, FileSize(FD) - 2);
    BlockRead(FD, ProgSize, 2);
    Seek(FD, FileSize(FD) - 4);
    BlockRead(FD, EP, 2);
    BCP:= CreateBuf(ProgSize);
    Seek(FD, FileSize(FD) - 4 - ProgSize);
    BlockRead(FD, BCP^[1], ProgSize);
    Close(FD);

    If Not InitInt Then Begin
        WriteLn(C_TE_InitFail);
        BCP:= DestroyBuf(BCP);
        Halt;
    End;
    Interpret(ResP, BCP, EP);
    While KeyPressed Do TempCh:= ReadKey;
    Asm
        xor ax,ax
        int 16h
    End;
    DestroyInt;
End.