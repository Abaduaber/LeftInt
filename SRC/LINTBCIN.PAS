{$I-} {$A+} {$R-} {$S-} {$Q-} {$G+} {$N+} {$D-} {$L-} {$Y-} {$X+}
Unit LIntBCIn;
Interface
Uses
    LIntCons, LUtils, LMem, LTimer, CRT, Graph, Graph256;
Type
    TBCRunResult = Record
        FIsSuccess: Boolean;
        FErr: T_SIntErr;
        FErrByte: Word;
    End;
    TBCRunResultP = ^TBCRunResult;

    Procedure Interpret(Var ARes: TBCRunResultP; ABCP: TBufferP; AEP: Word);
    Procedure DestroyInt;
    Function InitInt: Boolean;

Implementation
Var
    BCP: TBufferP;
    Vars, ParStack: TIBufferP;
    RetStack: TRetStackArrP;
    Files: TFilesP;
    IsGraph: Boolean;
    Error: T_SIntErr;
    OldVMode: Word;
    {Индексы стеков}
    StI, RStI, PStI: Word;
    {Стек ОПЗ но в сегменте данных}
    Stack: Array [1..C_SMaxStackSize] Of T_SVarType;

    Procedure SetVar(AVarI, AVal: Integer); Forward;
    Function GetVar(AVarI: Integer): Integer; Forward;
    Procedure OnError(AErr: T_SIntErr); Forward;
    Procedure ExeSpec(ASpecN: Integer); Forward;

Procedure SetVar(AVarI, AVal: Integer);
Begin
    Case AVarI Of
      1:
        Write(Chr(AVal));
      2:
        WriteLn(AVal); {!!!}
      3..C_SMaxVarCount:
        Vars^[AVarI]:= AVal;
      Else
        OnError(E_I_WrongVar);
    End;
End;

Function GetVar(AVarI: Integer): Integer;
Var
    Code: Integer;
    Res: LongInt;
    TempStr: String;
Begin
    Case AVarI Of
      1:
        GetVar:= Ord(CRT.ReadKey);
      2:
        Repeat
            ReadLn(TempStr);
            Val(TempStr, Res, Code);
            If (Code <> 0) Or (Res < Low(T_SVarType)) Or (Res > High(T_SVarType)) Then Begin
                OnError(E_I_WrongInputVal);
                Error:= E_I_Ok;
                Continue;
            End
            Else Begin
                GetVar:= Res;
                Break;
            End;
        Until False;
      3..C_SMaxVarCount:
        GetVar:= Vars^[AVarI];
      Else
        OnError(E_I_WrongVar);
    End;
End;

Procedure Interpret(Var ARes: TBCRunResultP; ABCP: TBufferP; AEP: Word);
Var
    BI, I, ProgSize, TempW, OffsCorr, VarSeg: Word;
    TempStr: String;
    TempB: Byte;
    Remem: T_SVarType;
    ResP: TBCRunResultP;
Begin
    ResP:= CreateBuf(SizeOf(ResP^));   {Буфер для результата}
    BCP:= ABCP; BI:= AEP;        {BI - точка входа}
    IsGraph:= False;             {Не в граф-режиме пока}
    Randomize;
    StI:= 1; Stack[1]:= 0;       {Первая ячейка стека обнуляется}
    RStI:= 1; RetStack^[1].FVal:= 0;   {Стек возврата тоже}
    PStI:= 1; ParStack^[1]:= 0;        {И параметров}
    ProgSize:= SizeOfBuf(BCP);         {Размер байткода проги в байтах}
    FillChar(Vars^, C_SMaxVarCount * SizeOf(T_SVarType), 0);
    {Обнулили переменные}
    OffsCorr:= Ofs(Vars^) - 2;   {Коррекция смещения для сегмента переменных}
    VarSeg:= Seg(Vars^);
    OldVMode:= Byte(Ptr($40, $49)^);
    {Запомнили номер старого режима. Если он будет изменен программой,
    то можно будет вернуть все в зад ;)}
    While KeyPressed Do CRT.ReadKey;
    Error:= E_I_Ok;

    With ResP^ Do Begin
        FIsSuccess:= True; FErrByte:= 0;
        FErr:= E_I_Ok;
    End;

    With ResP^ Do Repeat
        Case T_BC(BCP^[BI]) Of
          T_BC_WriteStr:
            Begin
                Inc(BI);
                TempStr[0]:= Char(BCP^[BI]);
                MoveMem(@BCP^[BI + 1], @TempStr[1], BCP^[BI]);
                Inc(BI, BCP^[BI] + 1);
                WriteLn(TempStr);
            End;
          T_BC_AssignVar:
            Begin
                Inc(BI);
                If StI < 1 Then Begin
                    OnError(E_I_StackEmpty);
                    Break;
                End;
                For TempB:= 1 To StI Do Begin
                    SetVar(Remem, Stack[TempB]);
                    If Error <> E_I_Ok Then Break;
                    Inc(Remem);
                End;
                If Error <> E_I_Ok Then Break;
                StI:= 1; Stack[1]:= 0;
            End;
          T_BC_ReadVar:
            Begin
                Inc(BI);
                If StI < 1 Then Begin
                    OnError(E_I_StackEmpty);
                    Break;
                End;
                Stack[StI]:= GetVar(Stack[StI]);
                If Error <> E_I_Ok Then Break;
            End;
          T_BC_IncStack:
            Begin
                Inc(BI); Inc(StI); Stack[StI]:= 0;
            End;
          T_BC_PushVal:
            Begin
                Stack[StI]:= Word((Pointer(PChar(@BCP^[BI]) + 1))^);
                Inc(BI, 3);
            End;
          T_BC_Random:
            Begin
                Inc(BI);
                If StI < 1 Then Begin
                    OnError(E_I_StackEmpty);
                    Break;
                End;
                Stack[StI]:= Random(Stack[StI]);
            End;
          T_BC_Add:
            Begin
                Inc(BI);
                If StI < 2 Then Begin
                    OnError(E_I_StackEmpty);
                    Break;
                End;
                Dec(StI);
                Inc(Stack[StI], Stack[StI + 1]);
            End;
          T_BC_Sub:
            Begin
                Inc(BI);
                If StI < 2 Then Begin
                    OnError(E_I_StackEmpty);
                    Break;
                End;
                Dec(StI);
                Dec(Stack[StI], Stack[StI + 1]);
            End;
          T_BC_Mul:
            Begin
                Inc(BI);
                If StI < 2 Then Begin
                    OnError(E_I_StackEmpty);
                    Break;
                End;
                Dec(StI);
                Stack[StI]:= Stack[StI] * Stack[StI + 1];
            End;
          T_BC_Div:
            Begin
                Inc(BI);
                If StI < 2 Then Begin
                    OnError(E_I_StackEmpty);
                    Break;
                End;
                If Stack[StI] = 0 Then Begin
                    OnError(E_I_DivByZero);
                    Break;
                End;
                Dec(StI);
                Stack[StI]:= Stack[StI] Div Stack[StI + 1];
            End;
          T_BC_Mod:
            Begin
                Inc(BI);
                If StI < 2 Then Begin
                    OnError(E_I_StackEmpty);
                    Break;
                End;
                If Stack[StI] = 0 Then Begin
                    OnError(E_I_DivByZero);
                    Break;
                End;
                Dec(StI);
                Stack[StI]:= Stack[StI] Mod Stack[StI + 1];
            End;
          T_BC_Exe:
            Begin
                If StI < 1 Then Begin
                    OnError(E_I_StackEmpty);
                    Break;
                End;
                TempB:= Lo(Stack[StI]);
                Dec(StI);
                Inc(BI);
                BCP^[BI + 1]:= Byte(T_BC_Nop);
                BCP^[BI + 2]:= Byte(T_BC_Nop);
                If IOResult <> 0 Then;
                Case Char(TempB) Of
                  C_ChZero..C_ChNine:
                    Begin
                        BCP^[BI]:= Byte(T_BC_PushVal);
                        Word((Pointer(PChar(@BCP^[BI + 1])))^):= TempB - 48;
                    End;
                  C_ChIncStack, C_ChIncStack2:
                    BCP^[BI]:= Byte(T_BC_IncStack);
                  C_ChAdd:
                    BCP^[BI]:= Byte(T_BC_Add);
                  C_ChSub:
                    BCP^[BI]:= Byte(T_BC_Sub);
                  C_ChMul:
                    BCP^[BI]:= Byte(T_BC_Mul);
                  C_ChDiv:
                    BCP^[BI]:= Byte(T_BC_Div);
                  C_ChMod:
                    BCP^[BI]:= Byte(T_BC_Mod);
                  C_Ch10:
                    BCP^[BI]:= Byte(T_BC_10);
                  C_ChSqr:
                    BCP^[BI]:= Byte(T_BC_Sqr);
                  C_ChPow:
                    BCP^[BI]:= Byte(T_BC_Pow);
                  C_ChSign:
                    BCP^[BI]:= Byte(T_BC_Sign);
                  C_ChRandom:
                    BCP^[BI]:= Byte(T_BC_Random);
                  C_ChLet:
                    BCP^[BI]:= Byte(T_BC_ReadVar);
                  C_SPushIdent:
                    BCP^[BI]:= Byte(T_BC_PushOp);
                  C_SGetIdent:
                    BCP^[BI]:= Byte(T_BC_GetOp);
                  Else
                    Begin
                        OnError(E_I_WrongModifyOp);
                        Break;
                    End;
                End;
            End;
          T_BC_Sign:
            Begin
                Inc(BI);
                If StI < 1 Then Begin
                    OnError(E_I_StackEmpty);
                    Break;
                End;
                If Stack[StI] > 0 Then
                    Stack[StI]:= 1
                Else
                    If Stack[StI] < 0 Then Stack[StI]:= -1;
            End;
          T_BC_10:
            Begin
                Inc(BI);
                If StI < 1 Then Begin
                    OnError(E_I_StackEmpty);
                    Break;
                End;
                Stack[StI]:= Integer(Stack[StI] = 0);
            End;
          T_BC_SqR:
            Begin
                Inc(BI);
                If StI < 1 Then Begin
                    OnError(E_I_StackEmpty);
                    Break;
                End;
                If Stack[StI] < 0 Then Begin
                    OnError(E_I_DivByZero);
                    Break;
                End;
                Stack[StI]:= Round(SqRt(Stack[StI]));
            End;
          T_BC_Pow:
            Begin
                Inc(BI);
                If StI < 2 Then Begin
                    OnError(E_I_StackEmpty);
                    Break;
                End;
                Dec(StI);
                Stack[StI]:= IntPower(Stack[StI + 1], Stack[StI]); {!!!}
            End;
          T_BC_PushOp:
            Begin
                If StI < 1 Then Begin
                    OnError(E_I_StackEmpty);
                    Break;
                End;
                If PStI + 1 > C_SMaxParStackSize Then Begin
                    OnError(E_I_ParStackOverflow);
                    Break;
                End;
                Inc(BI); Inc(PStI); ParStack^[PStI]:= Stack[StI];
            End;
          T_BC_GetOp:
            Begin
                If StI < 1 Then Begin
                    OnError(E_I_StackEmpty);
                    Break;
                End;
                If PStI < 2 Then Begin
                    OnError(E_I_ParStackEmpty);
                    Break;
                End;
                Inc(BI); Stack[StI]:= ParStack^[PStI]; Dec(PStI);
            End;
          T_BC_Spec:
            Begin
                Inc(BI);
                {Проверка на правильность кода команды}
                If (Remem < 1) Or (Remem > C_CSF_Count) Then Begin
                    OnError(E_I_UnknownSpecCmd); Break;
                End;
                {Проверка на доступность всех аргументов}
                If StI < C_CSF_Args[Remem] Then Begin
                    OnError(E_I_StackEmpty); Break;
                End;
                ExeSpec(Remem);
                If Error <> E_I_Ok Then Break;
                StI:= 1; Stack[1]:= 0;
            End;
          T_BC_Jump:
            Begin
                BI:= Word((Pointer(PChar(@BCP^[BI + 1])))^);
                StI:= 1; Stack[1]:= 0;
            End;
          T_BC_CondJump:
            Begin
                Inc(BI);
                If Stack[StI] = 0 Then
                    BI:= Word((Pointer(PChar(@BCP^[BI])))^)
                Else
                    Inc(BI, 2);
                StI:= 1; Stack[1]:= 0;
            End;
          T_BC_NZJump:
            Begin
                Inc(BI);
                If Stack[StI] <> 0 Then
                    BI:= Word((Pointer(PChar(@BCP^[BI])))^)
                Else
                    Inc(BI, 2);
                StI:= 1; Stack[1]:= 0;
            End;
          T_BC_CallSub:
            Begin
                Inc(RStI);
                If RStI > C_SMaxRetStackSize Then Begin
                    OnError(E_I_RetStackOverflow);
                    Break;
                End;
                If RStI < 1 Then Begin
                    OnError(E_I_RetStackEmpty);
                    Break;
                End;
                Inc(BI);
                RetStack^[RStI].FType:= T_RS_RetAddr;
                RetStack^[RStI].FVal:= BI + 2;
                BI:= Word((Pointer(PChar(@BCP^[BI])))^);
                StI:= 1; Stack[1]:= 0;
            End;
          T_BC_CondCallSub:
            Begin
                If RStI > C_SMaxRetStackSize Then Begin
                    OnError(E_I_RetStackOverflow);
                    Break;
                End;
                If RStI < 1 Then Begin
                    OnError(E_I_RetStackEmpty);
                    Break;
                End;
                Inc(BI);
                If Stack[StI] = 0 Then Begin
                    Inc(RStI);
                    RetStack^[RStI].FType:= T_RS_RetAddr;
                    RetStack^[RStI].FVal:= BI + 2;
                    BI:= Word((Pointer(PChar(@BCP^[BI])))^);
                End
                Else
                    Inc(BI, 2);
                StI:= 1; Stack[1]:= 0;
            End;
          T_BC_ExitSub:
            Begin
                If RStI < 1 Then Begin
                    OnError(E_I_RetStackEmpty);
                    Break;
                End;
                While RetStack^[RStI].FType = T_RS_VarI Do Begin
                    SetVar(RetStack^[RStI].FVal, RetStack^[RStI - 1].FVal);
                    If Error <> E_I_Ok Then Break;
                    Dec(RStI, 2);
                End;
                If (RetStack^[RStI].FVal < 1) Or (RetStack^[RStI].FVal > ProgSize) Then Begin
                    OnError(E_I_WrongRetAddr);
                    Break;
                End;
                BI:= RetStack^[RStI].FVal;
                Dec(RStI);
                StI:= 1; Stack[1]:= 0;
            End;
          T_BC_PushAllOp:
            Begin
                Inc(BI);
                If PStI + StI > C_SMaxParStackSize Then Begin
                    OnError(E_I_ParStackOverflow);
                    Break;
                End;
                If PStI < 1 Then Begin
                    OnError(E_I_ParStackEmpty);
                    Break;
                End;
                For I:= 1 To StI Do Begin
                    Inc(PStI);
                    ParStack^[PStI]:= Stack[I];
                End;
                StI:= 1; Stack[1]:= 0;   {!!!}
            End;
          T_BC_PushVars:
            Begin
                Inc(BI);
                If RStI + (StI + StI) > C_SMaxRetStackSize Then Begin
                    OnError(E_I_RetStackOverflow);
                    Break;
                End;
                For StI:= StI DownTo 1 Do Begin
                    Inc(RStI);
                    RetStack^[RStI].FType:= T_RS_VarVal;
                    RetStack^[RStI].FVal:= GetVar(Stack[StI]);
                    If Error <> E_I_Ok Then Break;
                    Inc(RStI);
                    RetStack^[RStI].FType:= T_RS_VarI;
                    RetStack^[RStI].FVal:= Stack[StI];
                End;
                Stack[1]:= 0;    {!!!}
            End;
          T_BC_ClearStI:
            Begin
                StI:= 1; Stack[1]:= 0; Inc(BI);
            End;
          T_BC_Remember:
            Begin
                Inc(BI); Remem:= Stack[StI];
            End;
          T_BC_Nop:
            Inc(BI);
          T_BC_And:
            Begin
                Inc(BI);
                If StI < 2 Then Begin
                    OnError(E_I_StackEmpty);
                    Break;
                End;
                Dec(StI);
                Stack[StI]:= Stack[StI] And Stack[StI + 1];
            End;
          T_BC_Or:
            Begin
                Inc(BI);
                If StI < 2 Then Begin
                    OnError(E_I_StackEmpty);
                    Break;
                End;
                Dec(StI);
                Stack[StI]:= Stack[StI] Or Stack[StI + 1];
            End;
          T_BC_Not:
            Begin
                Inc(BI);
                If StI < 1 Then Begin
                    OnError(E_I_StackEmpty);
                    Break;
                End;
                Stack[StI]:= Not Stack[StI];
            End;
          T_BC_Xor:
            Begin
                Inc(BI);
                If StI < 2 Then Begin
                    OnError(E_I_StackEmpty);
                    Break;
                End;
                Dec(StI);
                Stack[StI]:= Stack[StI] Xor Stack[StI + 1];
            End;
          T_BC_Seg:
            Begin
                Inc(BI);
                If StI < 1 Then Begin
                    OnError(E_I_StackEmpty);
                    Break;
                End;
                Stack[StI]:= VarSeg;
            End;
          T_BC_MoveMem:
            Begin
                Inc(BI);
                If StI < 5 Then Begin
                    OnError(E_I_StackEmpty);
                    Break;
                End;
                If Stack[StI - 2] = VarSeg Then Inc(Stack[StI - 1], OffsCorr);
                If Stack[StI - 4] = VarSeg Then Inc(Stack[StI - 3], OffsCorr);
                MoveMeM(Ptr(Stack[StI - 2], Stack[StI - 1]),
                    Ptr(Stack[StI - 4], Stack[StI - 3]), Stack[StI]);
                StI:= 1; Stack[1]:= 0;
            End;
          T_BC_CopyStr:
            Begin
                Inc(BI);
                TempStr[0]:= Char(BCP^[BI]);
                MoveMem(@BCP^[BI + 1], @TempStr[1], BCP^[BI]);
                Inc(BI, BCP^[BI] + 1);
                For TempB:= 1 To Length(TempStr) Do Begin
                    Stack[StI]:= Byte(TempStr[TempB]);
                    Inc(StI);
                End;
                Dec(StI);
            End;
          T_BC_End:
            Break;
          Else
            Begin
                OnError(E_I_UnknownCommand);
                Break;
            End;
        End;
    Until False;

    {После исполнения нужно проверить, если граф режим
    не сбросили, то сделать это самому}
    If IsGraph Then Begin
        Sleep; CloseGraph;
    End;
    If Byte(Ptr($40, $49)^) <> OldVMode Then TextMode(OldVMode);
    {А потом закрыть все незакрытые файлы}
    For I:= 1 To C_SMaxFileCount Do Begin
        If Files^[I].FOpened Then Begin
            Close(Files^[I].FFile);
            If IOResult <> 0 Then;
            Files^[I].FOpened:= False;
        End;
    End;

    If Error <> E_I_Ok Then With ResP^ Do Begin
        FErrByte:= BI; FIsSuccess:= False; FErr:= Error;
    End;
    ARes:= ResP;
End;

Procedure ExeSpec(ASpecN: Integer);
Var
    TempI, TempII: Integer;
    TempStr: String;
    TempB: Byte;
    Regs: TRegs;
Begin
    Case ASpecN Of
      C_CSF_ScreenMode:
        Case Stack[StI] Of
          0:
            Begin
                CloseGraph;
                IsGraph:= False;
            End;
          1:
            Begin
                If Not IsFileExist('SVGA256.BGI') Then Begin
                    OnError(E_I_GraphDrvNotExist);
                    Exit;
                End;
                TempI:= InstallUserDriver('SVGA256', Nil);
                If TempI = GrError Then Begin
                    OnError(E_I_CantInitGraph);
                    Exit;
                End;
                TempII:= 2; {640x480x8bit}
                InitGraph(TempI, TempII, '');
                IsGraph:= True;
            End;
          Else
            OnError(E_I_WrongScrMode);
        End;
      C_CSF_PSet:
        Begin
            If IsGraph Then PutPixel(Stack[StI - 2], Stack[StI - 1], Stack[StI]);
            Dec(StI, 2);
        End;
      C_CSF_Line:
        Begin
            SetColor(Stack[StI]);
            Dec(StI);
            If IsGraph Then Line(Stack[StI - 3], Stack[StI - 2], Stack[StI - 1], Stack[StI]);
            Dec(StI, 4);
        End;
      C_CSF_Circle:
        Begin
            SetColor(Stack[StI]);
            Dec(StI);
            If IsGraph Then Circle(Stack[StI - 2], Stack[StI - 1], Stack[StI]);
            Dec(StI, 2);
        End;
      C_CSF_GetPixelColor:
        Begin
            If IsGraph Then SetVar(Stack[StI], GetPixel(Stack[StI - 2], Stack[StI - 1]));
            Dec(StI, 2);
        End;
      C_CSF_Sound:
        Begin
            If Stack[StI] > 0 Then
                Sound(Stack[StI])
            Else
                NoSound;
        End;
      C_CSF_WritePort:
        Begin
            Port[Stack[StI - 1]]:= Stack[StI];
            Dec(StI);
        End;
      C_CSF_ReadPort:
        Begin
            SetVar(Stack[StI], Port[Stack[StI - 1]]);
            Dec(StI);
        End;
      C_CSF_Int:
        Begin
            TempI:= Stack[StI - 1];
            With Regs Do Begin
                AH:= Lo(GetVar(Stack[StI]));
                AL:= Lo(GetVar(Stack[StI] + 1));
                BH:= Lo(GetVar(Stack[StI] + 2));
                BL:= Lo(GetVar(Stack[StI] + 3));
                CH:= Lo(GetVar(Stack[StI] + 4));
                CL:= Lo(GetVar(Stack[StI] + 5));
                DH:= Lo(GetVar(Stack[StI] + 6));
                DL:= Lo(GetVar(Stack[StI] + 7));
                ES:= GetVar(Stack[StI] + 8);
                DS:= GetVar(Stack[StI] + 9);
                SI:= GetVar(Stack[StI] + 10);
                DI:= GetVar(Stack[StI] + 11);
                BP:= GetVar(Stack[StI] + 12);
            End;
            CallInt(TempI, Regs);
            SetVar(Stack[StI], Regs.AH);
            SetVar(Stack[StI] + 1, Regs.AL);
            SetVar(Stack[StI] + 2, Regs.BH);
            SetVar(Stack[StI] + 3, Regs.BL);
            SetVar(Stack[StI] + 4, Regs.CH);
            SetVar(Stack[StI] + 5, Regs.CL);
            SetVar(Stack[StI] + 6, Regs.DH);
            SetVar(Stack[StI] + 7, Regs.DL);
            SetVar(Stack[StI] + 8, Regs.ES);
            SetVar(Stack[StI] + 9, Regs.DS);
            SetVar(Stack[StI] + 10, Regs.SI);
            SetVar(Stack[StI] + 11, Regs.DI);
            SetVar(Stack[StI] + 12, Regs.BP);
            Dec(StI);
            {А эта строчка необходима, чтобы снять прямой вывод WriteLn
            И Write в видеопамять, и заставить их вместо этого пользоваться
            стандартными функциями вывода BIOS. Это сработает лишь
            в случае, если экранный режим был изменен программой, посредством,
            например, вызова прерывания BIOS.}
            If Byte(Ptr($40, $49)^) <> OldVMode Then DirectVideo:= False;
        End;
      C_CSF_OpenFile:
        Begin
            If Stack[StI] < 2 Then Begin
                TempStr:= ''; TempI:= 1;
                While (TempI < 100) And (GetVar(TempI + Stack[StI - 2] - 1) <> 0) Do Begin
                    TempStr:= TempStr + Char(GetVar(TempI + Stack[StI - 2] - 1));
                    Inc(TempI);
                End;
                If (Stack[StI - 1] < 1) Or (Stack[StI - 1] > C_SMaxFileCount) Then Begin
                    OnError(E_I_WrongFileNum); Exit;
                End;
                Assign(Files^[Stack[StI - 1]].FFile, TempStr);
            End;
            Case Stack[StI] Of
              0:
                Begin
                    Reset(Files^[Stack[StI - 1]].FFile);
                    If IOResult <> 0 Then Begin
                        OnError(E_I_CantOpenFile);
                        Exit;
                    End;
                    Files^[Stack[StI - 1]].FOpened:= True;
                End;
              1:
                Begin
                    ReWrite(Files^[Stack[StI - 1]].FFile);
                    If IOResult <> 0 Then Begin
                        OnError(E_I_CantOpenFile); Exit;
                    End;
                    Files^[Stack[StI - 1]].FOpened:= True;
                End;
              2:
                Begin
                    Seek(Files^[Stack[StI - 1]].FFile, Stack[StI - 2]);
                    If IOResult <> 0 Then Begin
                        OnError(E_I_CantSeekFile); Exit;
                    End;
                End;
              Else
                OnError(E_I_WrongFileMode);
            End;
            Dec(StI, 2);
        End;
      C_CSF_WriteFile:
        Begin
            If (Stack[StI - 1] < 1) Or (Stack[StI - 1] > C_SMaxFileCount) Then Begin
                OnError(E_I_WrongFileNum); Exit;
            End;
            Write(Files^[Stack[StI - 1]].FFile, Byte(Stack[StI]));
            If IOResult <> 0 Then OnError(E_I_WriteToFileError);
            Dec(StI)
        End;
      C_CSF_ReadFile:
        Begin
            If (Stack[StI - 2] < 1) Or (Stack[StI - 2] > C_SMaxFileCount) Then Begin
                OnError(E_I_WrongFileNum); Exit;
            End;
            Read(Files^[Stack[StI - 2]].FFile, TempB);
            If IOResult <> 0 Then Begin
                OnError(E_I_ReadFromFileError); Exit;
            End;
            SetVar(Stack[StI - 1], TempB);
            If Error <> E_I_Ok Then Exit;
            SetVar(Stack[StI], Byte(Not EOF(Files^[Stack[StI - 2]].FFile)));
            If IOResult <> 0 Then OnError(E_I_ReadFromFileError);
            Dec(StI, 2);
        End;
      C_CSF_CloseFile:
        Begin
            If (Stack[StI] < 1) Or (Stack[StI] > C_SMaxFileCount) Then OnError(E_I_WrongFileNum);
            Close(Files^[Stack[StI]].FFile);
            If IOResult <> 0 Then OnError(E_I_CloseFileError);
            Files^[Stack[StI]].FOpened:= False;
        End;
      C_CSF_SetPalColor:
        Begin
            If IsGraph Then SetRGBPalette(Stack[StI - 3], Stack[StI - 2], Stack[StI - 1], Stack[StI]);
            Dec(StI, 3);
        End;
      C_CSF_Pause:
        LTimer.Delay(Stack[StI] * 10);    {!!!}
      C_CSF_ClS:
        If IsGraph Then
            ClearDevice
        Else
            CRT.ClrScr;
      C_CSF_Fill:
        Begin
            If IsGraph Then Begin
                SetFillStyle(1, Stack[StI - 1]);
                FloodFill(Stack[StI - 3], Stack[StI - 2], Stack[StI]);
            End;
            Dec(StI, 3);
        End;
      C_CSF_WriteTextGraph:
        Begin
            TempI:= 1;
            TempStr:= '';
            While (TempI < 100) And (GetVar(TempI + Stack[StI] - 1) <> 0) Do Begin
                TempStr:= TempStr + Char(GetVar(TempI + Stack[StI] - 1));
                Inc(TempI);
            End;
            If IsGraph Then Begin
                SetTextStyle(0, 0, Stack[StI - 3]);
                SetColor(Stack[StI - 4]);
                OutTextXY(Stack[StI - 2], Stack[StI - 1], TempStr);
            End
            Else Begin
                TextColor(Stack[StI - 4]);
                GoToXY(Stack[StI - 2], Stack[StI - 1]);
                Write(TempStr);
            End;
            Dec(StI, 4);
        End;
      C_CSF_WriteValGraph:
        Begin
            TempStr:= IntToStr(Stack[StI]);
            If IsGraph Then Begin
                SetTextStyle(0, 0, Stack[StI - 3]);
                SetColor(Stack[StI - 4]);
                OutTextXY(Stack[StI - 2], Stack[StI - 1], TempStr);
            End
            Else Begin
                TextColor(Stack[StI - 4]);
                GoToXY(Stack[StI - 2], Stack[StI - 1]);
                Write(TempStr);
            End;
            Dec(StI, 4);
        End;
      C_CSF_WriteCharGraph:
        Begin
            If IsGraph Then Begin
                SetTextStyle(0, 0, Stack[StI - 3]);
                SetColor(Stack[StI - 4]);
                OutTextXY(Stack[StI - 2], Stack[StI - 1], Char(Stack[StI]));
            End
            Else Begin
                TextColor(Stack[StI - 4]);
                GoToXY(Stack[StI - 2], Stack[StI - 1]);
                Write(Char(Stack[StI]));
            End;
            Dec(StI, 4);
        End;
      Else
        Begin
            OnError(E_I_UnKnownSpecCmd);
        End;
    End;
End;

Procedure OnError(AErr: T_SIntErr);
Var
    Tex: String;
Begin
    If IsGraph Then CloseGraph;
    If Byte(Ptr($40, $49)^) <> OldVMode Then TextMode(OldVMode);
    If IOResult <> 0 Then;
    Error:= AErr;
    Tex:= C_TError;
    Case AErr Of
      E_I_Ok:
        Exit;
      Else
        Tex:= Tex + C_IntErrTexts[Byte(AErr)];
    End;
    WriteLn(Tex);
End;

Function InitInt: Boolean;
Begin
    BCP:= Nil;
    If MaxAvail < C_SMaxVarCount * SizeOf(T_SVarType) + 2 Then Begin
        InitInt:= False; Exit;
    End;
    Vars:= CreateBuf(C_SMaxVarCount * SizeOf(T_SVarType));

    If MaxAvail < C_SMaxRetStackSize * SizeOf(T_RS) + 2 Then Begin
        Vars:= DestroyBuf(Vars);
        InitInt:= False; Exit;
    End;
    RetStack:= CreateBuf(C_SMaxRetStackSize * SizeOf(T_RS));

    If MaxAvail < C_SMaxParStackSize * SizeOf(T_SVarType) + 2 Then Begin
        Vars:= DestroyBuf(Vars);
        RetStack:= DestroyBuf(RetStack);
        InitInt:= False; Exit;
    End;
    ParStack:= CreateBuf(C_SMaxParStackSize * SizeOf(T_SVarType));

    If MaxAvail < SizeOf(Files^) + 2 Then Begin
        Vars:= DestroyBuf(Vars);
        RetStack:= DestroyBuf(RetStack);
        ParStack:= DestroyBuf(ParStack);
        InitInt:= False; Exit;
    End;
    Files:= CreateBuf(SizeOf(Files^));
    InitInt:= True;
End;

Procedure DestroyInt;
Begin
    Vars:= DestroyBuf(Vars);
    RetStack:= DestroyBuf(RetStack);
    ParStack:= DestroyBuf(ParStack);
    Files:= DestroyBuf(Files);
End;

End.