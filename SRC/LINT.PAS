{$I-} {$A+} {$R-} {$S-} {$Q-} {$G+} {$N+} {$D-} {$L-} {$Y-} {$X-} {$T+} {$V+}
{$M 16384, 0, 655360}
Program LInt;
Uses
    LIntCons, LIntPreP, LIntComp, LIntBCIn, LIntTran, LUtils, LMem,
    CRT;
Var
    FName, TempStr, TempStr2: String;
    FKey: Char;
    I: Word;
    LocParCount, LocVarCount: Integer;
    FD: File;

    {D+ везде проверить}
    {При билде выпилить отображение MemAvail}

Function GetWord(Var AFromStr: String; Var AFromPos: Word): String;
Var
    I: Word;
Begin
    I:= AFromPos;
    While (AFromStr[AFromPos] <> ' ') And (AFromPos <= Length(AFromStr)) Do Inc(AFromPos);
    GetWord:= Copy(AFromStr, I, AFromPos - I);
    Inc(AFromPos);
End;

Procedure Run(AFileName: String);
Var
    FD: File;
    PrePRes: TPrePResultP;
    CompRes: TCompResultP;
    RunRes: TBCRunResultP;
Begin
    PrePRes:= LIntPreP.Process(AFileName);
    With PrePRes^ Do Begin
        If Not FIsSuccess Then Begin
            WriteLn(C_TE_PreProcessError, Byte(FErr), ':');
            WriteLn(C_TE_ErrFileNameMsg, FFileName);
            WriteLn(C_TE_ErrStrNumMsg, FErrorLine);
            WriteLn(C_TE_ErrStrMsg, FErrStr);
            WriteLn('  ', C_PrePErrTexts[Byte(FErr)]);
            PrePRes:= DestroyBuf(PrePRes);
            Exit;
        End;
    End;
    PrePRes:= DestroyBuf(PrePRes);

    If Not LIntComp.InitComp Then Begin
        WriteLn(C_TE_InitFail);
        Exit;
    End;
    LIntComp.Process(CompRes, C_DTempFileName);
    DestroyComp;

    With CompRes^ Do Begin
        If Not FIsSuccess Then Begin
            WriteLn(C_TE_CompError, Byte(FErr), ':');
            WriteLn(C_TE_ErrStrNumMsg, FErrorLine);
            WriteLn(C_TE_ErrStrMsg, FErrStr);
            WriteLn('  ', C_CompErrTexts[Byte(FErr)]);
            If FPointer <> Nil Then With FPointer^ Do Begin
                If FBCP <> Nil Then FBCP:= DestroyBuf(FBCP);
                FPointer:= DestroyBuf(FPointer);
            End;
            CompRes:= DestroyBuf(CompRes);
            Exit;
        End
    End;
    WriteLn(C_TE_ProgramProcessingDone);

    With CompRes^.FPointer^ Do Begin
        If Not InitInt Then Begin
            WriteLn(C_TE_InitFail);
            CompRes^.FPointer:= DestroyBuf(CompRes^.FPointer);
            CompRes:= DestroyBuf(CompRes);
            FBCP:= DestroyBuf(FBCP);
            Exit;
        End;
        Interpret(RunRes, FBCP, FEP);
        DestroyInt;
        FBCP:= DestroyBuf(FBCP);
        While KeyPressed Do FEP:= Word(CRT.ReadKey);
    End;
    CompRes^.FPointer:= DestroyBuf(CompRes^.FPointer);
    CompRes:= DestroyBuf(CompRes);

    If RunRes^.FIsSuccess Then
        WriteLn(C_TE_ProgramDone)
    Else
        WriteLn(C_TE_ProgramFail);

    RunRes:= DestroyBuf(RunRes);
End;

Procedure MakeEXE(AFileName: String);
Var
    FD, FD2: File;
    FileBuf: TBufferP;
    I: Word;
    PrePRes: TPrePResultP;
    CompRes: TCompResultP;
Begin
    If Not IsFileExist(C_T_StubName) Then Begin
        WriteLn(C_TE_StubNotExist);
        Exit;
    End;

    PrePRes:= LIntPreP.Process(AFileName);
    With PrePRes^ Do Begin
        If Not FIsSuccess Then Begin
            WriteLn(C_TE_PreProcessError, Byte(FErr), ':');
            WriteLn(C_TE_ErrFileNameMsg, FFileName);
            WriteLn(C_TE_ErrStrNumMsg, FErrorLine);
            WriteLn(C_TE_ErrStrMsg, FErrStr);
            WriteLn('  ', C_PrePErrTexts[Byte(FErr)]);
            PrePRes:= DestroyBuf(PrePRes);
            Exit;
        End;
    End;
    PrePRes:= DestroyBuf(PrePRes);

    If Not LIntComp.InitComp Then Begin
        WriteLn(C_TE_InitFail);
        Exit;
    End;
    LIntComp.Process(CompRes, C_DTempFileName);
    DestroyComp;

    With CompRes^ Do Begin
        If Not FIsSuccess Then Begin
            WriteLn(C_TE_CompError, Byte(FErr), ':');
            WriteLn(C_TE_ErrStrNumMsg, FErrorLine);
            WriteLn(C_TE_ErrStrMsg, FErrStr);
            WriteLn('  ', C_CompErrTexts[Byte(FErr)]);
            If FPointer <> Nil Then With FPointer^ Do Begin
                If FBCP <> Nil Then FBCP:= DestroyBuf(FBCP);
                FPointer:= DestroyBuf(FPointer);
            End;
            CompRes:= DestroyBuf(CompRes);
            Exit;
        End
    End;
    WriteLn(C_TE_ProgramProcessingDone);

    For I:= 1 To Length(AFileName) Do Begin
        If (AFileName[I] = '.') Then Begin
            Dec(I); Break;
        End;
    End;

    With CompRes^.FPointer^ Do Begin
        Assign(FD2, Copy(AFileName, 1, I) + '.exe');
        ReWrite(FD2, 1);;
        Assign(FD, C_T_StubName);
        Reset(FD, 1);
        FileBuf:= CreateBuf(FileSize(FD));
        BlockRead(FD, FileBuf^, FileSize(FD));
        BlockWrite(FD2, FileBuf^, FileSize(FD));
        BlockWrite(FD2, FBCP^, SizeOfBuf(FBCP));
        BlockWrite(FD2, FEP, 2);
        I:= SizeOfBuf(FBCP);
        BlockWrite(FD2, I, 2);
        Close(FD);
        Close(FD2);
        FileBuf:= DestroyBuf(FileBuf);

        FBCP:= DestroyBuf(FBCP);
        CompRes^.FPointer:= DestroyBuf(CompRes^.FPointer);
        CompRes:= DestroyBuf(CompRes);
    End;
    If IOResult = 0 Then
        WriteLn(C_T_StubCreated)
    Else
        WriteLn(C_T_StubFailed);
End;

Procedure Trans(AFileName: String);
Var
    FD: File;
    I: Word;
    PrePRes: TPrePResultP;
    CompRes: TCompResultP;
    TranRes: TTranResultP;
Begin
    PrePRes:= LIntPreP.Process(AFileName);
    With PrePRes^ Do Begin
        If Not FIsSuccess Then Begin
            WriteLn(C_TE_PreProcessError, Byte(FErr), ':');
            WriteLn(C_TE_ErrFileNameMsg, FFileName);
            WriteLn(C_TE_ErrStrNumMsg, FErrorLine);
            WriteLn(C_TE_ErrStrMsg, FErrStr);
            WriteLn('  ', C_PrePErrTexts[Byte(FErr)]);
            PrePRes:= DestroyBuf(PrePRes);
            Exit;
        End;
    End;
    PrePRes:= DestroyBuf(PrePRes);

    If Not LIntComp.InitComp Then Begin
        WriteLn(C_TE_InitFail);
        Exit;
    End;
    LIntComp.Process(CompRes, C_DTempFileName);

    With CompRes^ Do Begin
        If Not FIsSuccess Then Begin
            WriteLn(C_TE_CompError, Byte(FErr), ':');
            WriteLn(C_TE_ErrStrNumMsg, FErrorLine);
            WriteLn(C_TE_ErrStrMsg, FErrStr);
            WriteLn('  ', C_CompErrTexts[Byte(FErr)]);
            If FPointer <> Nil Then With FPointer^ Do Begin
                If FBCP <> Nil Then FBCP:= DestroyBuf(FBCP);
                FPointer:= DestroyBuf(FPointer);
            End;
            CompRes:= DestroyBuf(CompRes);
            DestroyComp;
            Exit;
        End
    End;
    WriteLn(C_TE_ProgramProcessingDone);

    For I:= 1 To Length(AFileName) Do Begin
        If (AFileName[I] = '.') Then Begin
            Dec(I); Break;
        End;
    End;
    AFileName:= Copy(AFileName, 1, I) + '.asm';
    Translate(TranRes, AFileName, CompRes^.FPointer, LocParCount, LocVarCount);
    DestroyComp;
    If TranRes^.FIsSuccess Then
        WriteLn(C_T_AsmCreated, AFileName)
    Else Begin
        Assign(FD, AFileName);
        Erase(FD);
        If IOResult <> 0 Then;
        WriteLn(C_TransErrTexts[Byte(TranRes^.FErr)], C_TE_TransImpossible);
    End;

    CompRes^.FPointer^.FBCP:= DestroyBuf(CompRes^.FPointer^.FBCP);
    CompRes^.FPointer:= DestroyBuf(CompRes^.FPointer);
    CompRes:= DestroyBuf(CompRes);
    TranRes:= DestroyBuf(TranRes);
End;

Procedure RunLInt;
Begin
    FName:= ParamStr(1);
    LocParCount:= StrToInt(ParamStr(3));
    LocVarCount:= StrToInt(ParamStr(4));

    If (FName <> '') And IsFileExist(FName) Then Begin
        Write(C_TE_ProgramProcessing);
        If UpperCase(ParamStr(2)) = C_T_CompKey Then
            MakeExe(FName)
        Else If UpperCase(ParamStr(2)) = C_T_TransKey Then
            Trans(FName)
        Else
            Run(FName);
        If IsFileExist(C_DTempFileName) Then Begin
            Assign(FD, C_DTempFileName);
            Erase(FD);
        End;
    End
    Else
        If FName <> '' Then WriteLn(C_TE_FileNotExist);

    FName:= '';
    WriteLn(C_T_HelpText);
    Repeat
        Write(C_T_InpChar);
        ReadLn(FName);
        If UpperCase(FName) = C_T_EasterEgg Then Begin
            For I:= 1 To 23 Do WriteLn(C_EEImg[I]);
            Continue;
        End;
        I:= 1;
        TempStr:= UpperCase(GetWord(FName, I));
        TempStr2:= UpperCase(GetWord(FName, I));
        LocParCount:= StrToInt(GetWord(FName, I));
        LocVarCount:= StrToInt(GetWord(FName, I));

        If (IsFileExist(TempStr)) And (TempStr <> '') Then Begin
            Write(C_TE_ProgramProcessing);
            If TempStr2 = C_T_CompKey Then
                MakeExe(TempStr)
            Else If TempStr2 = C_T_TransKey Then
                Trans(TempStr)
            Else Begin
                Run(TempStr);
            End;
            If IsFileExist(C_DTempFileName) Then Begin
                Assign(FD, C_DTempFileName);
                Erase(FD);
            End;
        End
        Else
            If TempStr <> '' Then WriteLn(C_TE_FileNotExist);
    Until FName = '';
End;

Begin
    RunLInt;
End.