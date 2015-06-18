{$I-} {$A+} {$R-} {$S-} {$Q-} {$G+} {$N+} {$D-} {$L-} {$Y-} {$X+}
Unit LIntTran;
Interface
Uses
    LIntCons, LMem, LUtils, LIntComp;
Type
    TTranResult = Record
        FIsSuccess: Boolean;
        FErr: T_STransErr;
    End;
    TTranResultP = ^TTranResult;

    {1. Обратить внимание на вычисление корня и степени.}

    Procedure Translate(Var ARes: TTranResultP; AFileName: String; ACIP: TCompInfoP;
                        AParStSize, ALocStSize: Integer);

Implementation
Type
    TLabsPos = Array [1..C_SMaxLabelCount] Of Word;
    TLabsPosP = ^TLabsPos;
Var
    FD, SrcFD: Text;
    {Файловые дескрипторы, выход и файл кода}
    BCP: TBufferP;
    {Буфер с байткодом}
    ResP: TTranResultP;
    {Результат}
    LabsP: TLabelArrP;
    {Указатель на информацию о метках. В байткоде нет информации о
    именах и местах расположения меток, есть информация лишь о адресах
    переходов. Поэтому приходится иметь доступ к найденным еще компилятором
    меткам, чтобы правильно отслеживать, куда и когда пихать очередную метку.}
    LabsPosP: TLabsPosP;

    IsRandomProcUsed, IsExeProcUsed: Boolean;
    IsGetVarProcUsed, IsSetVarProcUsed: Boolean;
    IsPushAProcUsed, IsLocVarsUsed: Boolean;
    IsSpecCmdUsed, IsNeedClearSt: Boolean;
    IsMoveMemCmdUsed, IsCopyStrCmdUsed: Boolean;

    EP, StrI, CStrI, LabI, LabC: Word;
    IsNZJumpActive: Boolean;
    NZJI, ParStSize, LocStSize: Word;
    LastAxVal: Integer;

    Procedure WriteTrans(AEP: Word); Forward;
    Procedure WriteStrings(AEP: Word); Forward;
    Procedure WriteDone; Forward;
    Function WriteProc(AProcNum: Word): Boolean; Forward;
    Procedure ScanLabels; Forward;
    Function FindLabel(ACurP: Word): Word; Forward;
    Function TranslateCmd(AOffs: Word; AIsGenCode: Boolean): Word; Forward;


Procedure Translate(Var ARes: TTranResultP; AFileName: String; ACIP: TCompInfoP;
                    AParStSize, ALocStSize: Integer);
Begin
    ResP:= CreateBuf(SizeOf(ResP^));
    ResP^.FIsSuccess:= True; ResP^.FErr:= E_T_Ok;
    ARes:= ResP;
    If Not IsFileExist(C_Tr_CodeFileName) Then With ResP^ Do Begin
        FIsSuccess:= False; FErr:= E_T_CodeFileNotExist;
        ARes:= ResP; Exit;
    End;

    BCP:= ACIP^.FBCP;
    LabsP:= ACIP^.FLabsP;
    LabC:= ACIP^.FLabsCount;
    EP:= ACIP^.FEP;
    LabsPosP:= CreateBuf(SizeOf(LabsPosP^));

    Inc(AParStSize, AParStSize);
    If AParStSize = 0 Then AParStSize:= C_Tr_StdParStSize;
    Inc(ALocStSize, ALocStSize);
    If ALocStSize = 0 Then ALocStSize:= C_Tr_StdLocStSize;

    IsRandomProcUsed:= False; IsExeProcUsed:= False;
    IsGetVarProcUsed:= False; IsSetVarProcUsed:= False;
    IsPushAProcUsed:= False; IsLocVarsUsed:= False;
    IsSpecCmdUsed:= False; IsNeedClearSt:= False;
    IsNZJumpActive:= False; IsMoveMemCmdUsed:= False;
    IsCopyStrCmdUsed:= False;

    ParStSize:= AParStSize;
    LocStSize:= ALocStSize;
    NZJI:= 0; LastAXVal:= 0;

    Assign(FD, AFileName);
    ReWrite(FD);
    WriteLn(FD, 'Org 256');
    WriteLn(FD, 'Use16');
    WriteLn(FD, 'Start:');

    ScanLabels;
    If IsGetVarProcUsed Or IsSetVarProcUsed Or IsExeProcUsed Or IsSpecCmdUsed Then Begin
        If WriteProc(C_Tr_InitBlock) Then;
        If IsRandomProcUsed Or IsExeProcUsed Then WriteLn(FD, C_TChTab + 'call InitRandom');
    End;
    WriteTrans(EP);
    WriteDone;

    LabsPosP:= DestroyBuf(LabsPosP);
    Close(FD);
End;

Procedure WriteTrans(AEP: Word);
Var
    I, LI: Word;
Begin
    WriteLn(FD, ';-----Транслированный код программы-----');
    I:= AEP; StrI:= 1; LabI:= 1; CStrI:= 1;
    While I <= SizeOfBuf(BCP) Do Begin
        LI:= FindLabel(I);
        If LI <> 0 Then Begin
            WriteLn(FD, 'Lab' + IntToStr(LabI) + ':' + C_TChTab + ';' + LabsP^[LI]^.FName);
            LabsPosP^[LI]:= LabI; {!!!}
            Inc(LabI);
        End;
        I:= TranslateCmd(I, True);
    End;
    WriteLn(FD, C_TChTab + 'xor ax,ax ;конец программы');
    WriteLn(FD, C_TChTab + 'int 16h');
    WriteLn(FD, C_TChTab + 'ret');

    WriteLn(FD, ';-----Подпрограммы-----');
    I:= 1; StrI:= 1;
    While I < EP Do Begin
        LI:= FindLabel(I);
        If LI <> 0 Then Begin
            WriteLn(FD, 'Lab' + IntToStr(LabI) + ':' + C_TChTab + ';' + LabsP^[LI]^.FName);
            LabsPosP^[LI]:= LabI; {!!!}
            Inc(LabI);
        End;
        I:= TranslateCmd(I, True);
    End;
End;

Procedure ScanLabels;
Var
    LI, CurPos, LabI: Word;
Begin
    CurPos:= EP; LabI:= 1;
    While CurPos <= SizeOfBuf(BCP) Do Begin
        LI:= FindLabel(CurPos);
        If LI <> 0 Then Begin
            LabsPosP^[LI]:= LabI; {!!!}
            Inc(LabI);
        End;
        CurPos:= TranslateCmd(CurPos, False);
    End;
    CurPos:= 1;
    While CurPos < EP Do Begin
        LI:= FindLabel(CurPos);
        If LI <> 0 Then Begin
            LabsPosP^[LI]:= LabI; {!!!}
            Inc(LabI);
        End;
        CurPos:= TranslateCmd(CurPos, False);
    End;
End;

Function FindLabel(ACurP: Word): Word;
Var
    I: Integer;
Begin
    For I:= 1 To LabC Do Begin
        If LabsP^[I]^.FPos = ACurP Then Begin
            FindLabel:= I;
            Exit;
        End;
    End;
    FindLabel:= 0;
End;

Function TranslateCmd(AOffs: Word; AIsGenCode: Boolean): Word;
Var
    TempB: Byte;
    LI: Word;
    TempStr: String;
Begin
    If T_BC(BCP^[AOffs]) = T_BC_WriteStr Then Begin
        Inc(AOffs);
        If AIsGenCode Then Begin
            WriteLn(FD, C_TChTab + 'mov dx,Str', StrI, ' ;[');
            WriteLn(FD, C_TChTab + 'mov ah,40h');
            WriteLn(FD, C_TChTab + 'mov bx,2');
            WriteLn(FD, C_TChTab + 'mov cx,Str', StrI, 'Len');
            WriteLn(FD, C_TChTab + 'int 21h');
        End;
        Inc(AOffs, BCP^[AOffs] + 1);
        Inc(StrI);
    End
    Else If T_BC(BCP^[AOffs]) = T_BC_CopyStr Then Begin
        IsCopyStrCmdUsed:= True;
        Inc(AOffs);
        If AIsGenCode Then Begin
            WriteLn(FD, C_TChTab + 'mov bx,CStr', CStrI, ' ;''''');
            WriteLn(FD, C_TChTab + 'call CopyStr');
        End;
        Inc(AOffs, BCP^[AOffs] + 1);
        Inc(CStrI);
    End
    Else If Not AIsGenCode Then Begin
        Case T_BC(BCP^[AOffs]) Of
          T_BC_AssignVar:
            IsSetVarProcUsed:= True;
          T_BC_ReadVar:
            IsGetVarProcUsed:= True;
          T_BC_Random:
            IsRandomProcUsed:= True;
          T_BC_Exe:
            IsExeProcUsed:= True;
          T_BC_PushAllOp:
            IsPushAProcUsed:= True;
          T_BC_PushVars:
            IsLocVarsUsed:= True;
          T_BC_Spec:
            IsSpecCmdUsed:= True;
          T_BC_MoveMem:
            IsMoveMemCmdUsed:= True;
          T_BC_CopyStr:
            IsCopyStrCmdUsed:= True;
        End;
        Inc(AOffs, C_BCSize[BCP^[AOffs]]);
    End
    Else Case T_BC(BCP^[AOffs]) Of
      T_BC_AssignVar:
        Begin
            WriteLn(FD, C_TChTab + 'call SetVar ;A');
            IsNeedClearSt:= False;  {!!!}
            Inc(AOffs);
        End;
      T_BC_ReadVar:
        Begin
            WriteLn(FD, C_TChTab + 'call GetVar ;$');
            Inc(AOffs);
        End;
        T_BC_IncStack:
        Begin
            IsNeedClearSt:= True;
            WriteLn(FD, C_TChTab + 'add di,2 ;^');
            WriteLn(FD, C_TChTab + 'mov [di],ax');
            Inc(AOffs);
        End;
      T_BC_PushVal:
        Begin
            If T_BC(BCP^[AOffs + 3]) = T_BC_IncStack Then Begin
                WriteLn(FD, C_TChTab + 'add di,2 ;^');
                WriteLn(FD, C_TChTab + 'mov [di],word ' +
                IntToStr(Integer((Pointer(PChar(@BCP^[AOffs]) + 1))^)) + ' ;push');
                IsNeedClearSt:= True;
                Inc(AOffs, 4);
            End
            Else Begin
                If Integer((Pointer(PChar(@BCP^[AOffs]) + 1))^) = 0 Then Begin
                    WriteLn(FD, C_TChTab + 'xor ax,ax ;push 0');
                End
                Else Begin
                    WriteLn(FD, C_TChTab + 'mov ax,' +
                    IntToStr(Integer((Pointer(PChar(@BCP^[AOffs]) + 1))^)) + ' ;push');
                End;
                Inc(AOffs, 3);
            End;
        End;
      T_BC_Random:
        Begin
            WriteLn(FD, C_TChTab + 'call GetRandom ;?');
            Inc(AOffs);
        End;
      T_BC_Add:
        Begin
            WriteLn(FD, C_TChTab + 'add ax,[di] ;+' );
            If T_BC(BCP^[AOffs + 1]) = T_BC_IncStack Then Begin
                WriteLn(FD, C_TChTab + 'mov [di],ax ;^' );
                Inc(AOffs, 2);
            End
            Else Begin
                If Not (T_BC(BCP^[AOffs + 1]) In C_Tr_NotReqDecStI) Then
                    WriteLn(FD, C_TChTab + 'sub di,2' );
                Inc(AOffs);
            End;
        End;
      T_BC_Sub:
        Begin
            WriteLn(FD, C_TChTab + 'sub [di],ax ;-');
            If T_BC(BCP^[AOffs + 1]) = T_BC_IncStack Then Begin
                WriteLn(FD, C_TChTab + 'mov ax,[di] ;^');
                Inc(AOffs, 2);
            End
            Else Begin
                WriteLn(FD, C_TChTab + 'mov ax,[di]');
                If Not (T_BC(BCP^[AOffs + 1]) In C_Tr_NotReqDecStI) Then
                    WriteLn(FD, C_TChTab + 'sub di,2' );
                Inc(AOffs);
            End;
        End;
      T_BC_Mul:
        Begin
            WriteLn(FD, C_TChTab + 'imul word [di] ;*');
            If T_BC(BCP^[AOffs + 1]) = T_BC_IncStack Then Begin
                WriteLn(FD, C_TChTab + 'mov [di],ax ;^');
                Inc(AOffs, 2);
            End
            Else Begin
                If Not (T_BC(BCP^[AOffs + 1]) In C_Tr_NotReqDecStI) Then
                    WriteLn(FD, C_TChTab + 'sub di,2' );
                Inc(AOffs);
            End;
        End;
      T_BC_Div:
        Begin
            WriteLn(FD, C_TChTab + 'xor dx,dx ;/');
            WriteLn(FD, C_TChTab + 'mov bx,[di]');
            WriteLn(FD, C_TChTab + 'xchg ax,bx');
            WriteLn(FD, C_TChTab + 'idiv bx');
            If T_BC(BCP^[AOffs + 1]) = T_BC_IncStack Then Begin
                WriteLn(FD, C_TChTab + 'mov [di],ax ;^');
                Inc(AOffs, 2);
            End
            Else Begin
                If Not (T_BC(BCP^[AOffs + 1]) In C_Tr_NotReqDecStI) Then
                    WriteLn(FD, C_TChTab + 'sub di,2' );
                Inc(AOffs);
            End;
        End;
      T_BC_Mod:
        Begin
            WriteLn(FD, C_TChTab + 'xor dx,dx ;%');
            WriteLn(FD, C_TChTab + 'mov bx,[di]');
            WriteLn(FD, C_TChTab + 'xchg ax,bx');
            WriteLn(FD, C_TChTab + 'idiv bx');
            WriteLn(FD, C_TChTab + 'mov ax,dx');
            If T_BC(BCP^[AOffs + 1]) = T_BC_IncStack Then Begin
                WriteLn(FD, C_TChTab + 'mov [di],ax ;^');
                Inc(AOffs, 2);
            End
            Else Begin
                If Not (T_BC(BCP^[AOffs + 1]) In C_Tr_NotReqDecStI) Then
                    WriteLn(FD, C_TChTab + 'sub di,2' );
                Inc(AOffs);
            End;
        End;
      T_BC_Exe:
        Begin
            WriteLn(FD, C_TChTab + 'call ExeCmd ;"');
            Inc(AOffs, 4);
        End;
      T_BC_Sign:
        Begin
            WriteLn(FD, C_TChTab + 'test ax,ax ;!');
            WriteLn(FD, C_TChTab + 'jg short $+6');
            WriteLn(FD, C_TChTab + 'jl short $+9');
            WriteLn(FD, C_TChTab + 'jmp short $+10');
            WriteLn(FD, C_TChTab + 'mov ax,1');
            WriteLn(FD, C_TChTab + 'jmp short $+5');
            WriteLn(FD, C_TChTab + 'mov ax,-1');
            Inc(AOffs);
        End;
      T_BC_10:
        Begin
            WriteLn(FD, C_TChTab + 'test ax,ax ;|');
            WriteLn(FD, C_TChTab + 'jnz short $+5 ');
            WriteLn(FD, C_TChTab + 'inc ax');
            WriteLn(FD, C_TChTab + 'jmp short $+4');
            WriteLn(FD, C_TChTab + 'xor ax,ax');
            Inc(AOffs);
        End;
      T_BC_Sqr:
        Begin
            WriteLn(FD, C_TChTab + 'mov bx,1 ;@');
            WriteLn(FD, C_TChTab + 'xor cx,cx');
            WriteLn(FD, C_TChTab + 'sub ax,bx');
            WriteLn(FD, C_TChTab + 'add bx,2');
            WriteLn(FD, C_TChTab + 'inc cx');
            WriteLn(FD, C_TChTab + 'cmp ax,bx');
            WriteLn(FD, C_TChTab + 'jge short $-8');
            WriteLn(FD, C_TChTab + 'mov ax,cx');
            Inc(AOffs);
        End;
      T_BC_Pow:
        Begin
            WriteLn(FD, C_TChTab + 'mov cx,[di] ;&');
            WriteLn(FD, C_TChTab + 'sub di,2');
            WriteLn(FD, C_TChTab + 'mov bx,ax');
            WriteLn(FD, C_TChTab + 'mov ax,1');
            WriteLn(FD, C_TChTab + 'imul bx');
            WriteLn(FD, C_TChTab + 'dec cx');
            WriteLn(FD, C_TChTab + 'jnz short $-3');
            Inc(AOffs);
        End;
      T_BC_PushOp:
        Begin
            WriteLn(FD, C_TChTab + 'add si,2 ;P');
            WriteLn(FD, C_TChTab + 'mov [si],ax');
            Inc(AOffs);
        End;
      T_BC_GetOp:
        Begin
            WriteLn(FD, C_TChTab + 'mov ax,[si] ;G');
            WriteLn(FD, C_TChTab + 'sub si,2');
            Inc(AOffs);
        End;
      T_BC_Spec:
        Begin
            WriteLn(FD, C_TChTab + 'call RunSpec ;~');
            Inc(AOffs);
        End;
      T_BC_Jump:
        Begin
            LI:= FindLabel(Word((Pointer(PChar(@BCP^[AOffs]) + 1))^));
            WriteLn(FD, C_TChTab + 'jmp Lab' + IntToStr(LabsPosP^[LI]) +
             ' ;#<' + LabsP^[LI]^.FName + '>');
            Inc(AOffs, 3);
        End;
      T_BC_CondJump:
        Begin
            LI:= FindLabel(Word((Pointer(PChar(@BCP^[AOffs]) + 1))^));
            WriteLn(FD, C_TChTab + 'test ax,ax' +
             ' ;#()<' + LabsP^[LI]^.FName + '>');
            WriteLn(FD, C_TChTab + 'jz Lab' + IntToStr(LabsPosP^[LI]));
            Inc(AOffs, 3);
        End;
      T_BC_NZJump:
        Begin
            Inc(NZJI); IsNZJumpActive:= True;
            WriteLn(FD, C_TChTab + 'test ax,ax ;NZJump');
            WriteLn(FD, C_TChTab + 'jnz NZ' + IntToStr(NZJI));
            Inc(AOffs, 3);
        End;
      T_BC_CallSub:
        Begin
            LI:= FindLabel(Word((Pointer(PChar(@BCP^[AOffs]) + 1))^));
            If IsLocVarsUsed Then Begin
                WriteLn(FD, C_TChTab + 'add bp,2' + ' ;*<' + LabsP^[LI]^.FName + '>');
                WriteLn(FD, C_TChTab + 'mov [bp],word 0');
                WriteLn(FD, C_TChTab + 'call Lab' + IntToStr(LabsPosP^[LI]));
            End
            Else
                WriteLn(FD, C_TChTab + 'call Lab' + IntToStr(LabsPosP^[LI]) +
                ' ;*<' + LabsP^[LI]^.FName + '>');
            {T_BC_CallSub замыкает блок условного вызова процедуры с
            передачей параметров. Если булева переменная установлена в
            True, то после команды T_BC_CallSub нужно установить метку
            для ненулевого перехода}
            If IsNZJumpActive Then Begin
                IsNZJumpActive:= False;
                WriteLn(FD, C_TChTab + 'NZ', NZJI, ':');
            End;
            Inc(AOffs, 3);
        End;
      T_BC_CondCallSub:
        Begin
            LI:= FindLabel(Word((Pointer(PChar(@BCP^[AOffs]) + 1))^));
            WriteLn(FD, C_TChTab + 'test ax,ax' +
             ' ;*()<' + LabsP^[LI]^.FName + '>');
            If IsLocVarsUsed Then Begin
                WriteLn(FD, C_TChTab + 'jnz $+11');
                WriteLn(FD, C_TChTab + 'add bp,2');
                WriteLn(FD, C_TChTab + 'mov [bp],ax');
            End
            Else
                WriteLn(FD, C_TChTab + 'jnz $+5');
            WriteLn(FD, C_TChTab + 'call Lab' + IntToStr(LabsPosP^[LI]));
            Inc(AOffs, 3);
        End;
      T_BC_ExitSub:
        Begin
            If IsLocVarsUsed Then Begin
                WriteLn(FD, C_TChTab + 'call RestoreVars ;**');
                WriteLn(FD, C_TChTab + 'ret');
            End
            Else
                WriteLn(FD, C_TChTab + 'ret ;**');
            Inc(AOffs);
        End;
      T_BC_PushAllOp:
        Begin
            WriteLn(FD, C_TChTab + 'call PushAllOp ;PushAOp');
            Inc(AOffs);
        End;
      T_BC_PushVars:
        Begin
            WriteLn(FD, C_TChTab + 'call PushVars ;PushV');
            Inc(AOffs);
        End;
      T_BC_ClearStI:
        Begin
            If IsNeedClearSt Then Begin
                If (T_BC(BCP^[AOffs + 1]) = T_BC_PushVal) And
                (T_BC(BCP^[AOffs + 4]) = T_BC_IncStack) Then Begin
                    WriteLn(FD, C_TChTab + 'mov di,RPSt+2 ;^ --> push' );
                    WriteLn(FD, C_TChTab + 'mov [di],word ',
                        IntToStr(Integer((Pointer(PChar(@BCP^[AOffs]) + 2))^)));
                    Inc(AOffs, 4);
                End
                Else
                    WriteLn(FD, C_TChTab + 'mov di,RPSt ;clearSt');
                IsNeedClearSt:= False;
            End;
            Inc(AOffs);
        End;
      T_BC_Remember:
        Begin
            WriteLn(FD, C_TChTab + 'mov [Remem],ax ;rem');
            Inc(AOffs);
        End;
      T_BC_Nop:
        Inc(AOffs);
      T_BC_And:
        Begin
            WriteLn(FD, C_TChTab + 'and ax,[di] ;and' );
            If T_BC(BCP^[AOffs + 1]) = T_BC_IncStack Then Begin
                WriteLn(FD, C_TChTab + 'mov [di],ax ;^' );
                Inc(AOffs, 2);
            End
            Else Begin
                If Not (T_BC(BCP^[AOffs + 1]) In C_Tr_NotReqDecStI) Then
                    WriteLn(FD, C_TChTab + 'sub di,2' );
                Inc(AOffs);
            End;
        End;
      T_BC_Or:
        Begin
            WriteLn(FD, C_TChTab + 'or ax,[di] ;or' );
            If T_BC(BCP^[AOffs + 1]) = T_BC_IncStack Then Begin
                WriteLn(FD, C_TChTab + 'mov [di],ax ;^' );
                Inc(AOffs, 2);
            End
            Else Begin
                If Not (T_BC(BCP^[AOffs + 1]) In C_Tr_NotReqDecStI) Then
                    WriteLn(FD, C_TChTab + 'sub di,2' );
                Inc(AOffs);
            End;
        End;
      T_BC_Not:
        Begin
            WriteLn(FD, C_TChTab + 'not ax ;not');
            Inc(AOffs);
        End;
      T_BC_Xor:
        Begin
            WriteLn(FD, C_TChTab + 'xor ax,[di] ;xor' );
            If T_BC(BCP^[AOffs + 1]) = T_BC_IncStack Then Begin
                WriteLn(FD, C_TChTab + 'mov [di],ax ;^' );
                Inc(AOffs, 2);
            End
            Else Begin
                If Not (T_BC(BCP^[AOffs + 1]) In C_Tr_NotReqDecStI) Then
                    WriteLn(FD, C_TChTab + 'sub di,2' );
                Inc(AOffs);
            End;
        End;
      T_BC_Seg:
        Begin
            WriteLn(FD, C_TChTab + 'mov ax,es ;seg');
            Inc(AOffs);
        End;
      T_BC_MoveMem:
        Begin
            WriteLn(FD, C_TChTab + 'call MoveMem');
            Inc(AOffs);
        End;
      T_BC_CopyStr:;
      T_BC_End:
        Begin
            Inc(AOffs);
        End;
      Else
        Begin
            WriteLn(C_TE_GodBlessYa);
            Halt;
        End;
    End;
    TranslateCmd:= AOffs;
End;

Procedure WriteStrings(AEP: Word);
Var
    I: Word;
    TempStr: String;
Begin
    WriteLn(FD, ';-----Текстовые константы-----');
    If IsGetVarProcUsed Or IsSetVarProcUsed Or IsSpecCmdUsed Then Begin
        WriteLn(FD, 'SysStr1 DB "' + C_IntErrTexts[Byte(E_I_WrongInputVal)] + '", 13, 10, "$"');
        WriteLn(FD, 'InitFailStr DB "Not enough memory to store variables", 13, 10, "$"');
    End;
    If IsExeProcUsed Then WriteLn(FD, 'SysStr2 DB "' +
        C_IntErrTexts[Byte(E_I_WrongModifyOp)] + '", 13, 10, "$"');
    If IsSpecCmdUsed Then Begin
        WriteLn(FD, 'OpenFileErrStr DB "',
         C_IntErrTexts[Byte(E_I_CantOpenFile)], '", 13, 10, "$"');
        WriteLn(FD, 'SeekFileErrStr DB "',
         C_IntErrTexts[Byte(E_I_CantSeekFile)], '", 13, 10, "$"');
        WriteLn(FD, 'ReadFileErrStr DB "',
         C_IntErrTexts[Byte(E_I_ReadFromFileError)], '", 13, 10, "$"');
        WriteLn(FD, 'WriteFileErrStr DB "',
         C_IntErrTexts[Byte(E_I_WriteToFileError)], '", 13, 10, "$"');
        WriteLn(FD, 'CloseFileErrStr DB "',
         C_IntErrTexts[Byte(E_I_CloseFileError)], '", 13, 10, "$"');
        WriteLn(FD, 'WrongFileIDErrStr DB "',
         C_IntErrTexts[Byte(E_I_WrongFileNum)], '", 13, 10, "$"');
    End;
    I:= AEP; StrI:= 1; CStrI:= 1;
    While I <= SizeOfBuf(BCP) Do Begin
        Case T_BC(BCP^[I]) Of
          T_BC_WriteStr:
            Begin
                Inc(I);
                TempStr[0]:= Chr(BCP^[I]);
                MoveMem(@BCP^[I + 1], @TempStr[1], BCP^[I]);
                WriteLn(FD, 'Str', StrI, ' DB "', TempStr, '", ', '13, 10');
                WriteLn(FD, 'Str', StrI, 'Len = ', Length(TempStr) + 2);
                Inc(I, BCP^[I] + 1);
                Inc(StrI);
            End;
          T_BC_CopyStr:
            Begin
                Inc(I);
                TempStr[0]:= Chr(BCP^[I]);
                MoveMem(@BCP^[I + 1], @TempStr[1], BCP^[I]);
                WriteLn(FD, 'CStr', CStrI, ' DB "', TempStr, '", 0');
                Inc(I, BCP^[I] + 1);
                Inc(CStrI);
            End;
          Else
              I:= TranslateCmd(I, False);
        End;
    End;
    I:= 1;
    While I < AEP Do Begin
        Case T_BC(BCP^[I]) Of
          T_BC_WriteStr:
            Begin
                Inc(I);
                TempStr[0]:= Chr(BCP^[I]);
                MoveMem(@BCP^[I + 1], @TempStr[1], BCP^[I]);
                WriteLn(FD, 'Str', StrI, ' DB "', TempStr, '", ', '13, 10');
                WriteLn(FD, 'Str', StrI, 'Len = ', Length(TempStr) + 2);
                Inc(I, BCP^[I] + 1);
                Inc(StrI);
            End;
          T_BC_CopyStr:
            Begin
                Inc(I);
                TempStr[0]:= Chr(BCP^[I]);
                MoveMem(@BCP^[I + 1], @TempStr[1], BCP^[I]);
                WriteLn(FD, 'CStr', CStrI, ' DB "', TempStr, '", 0');
                Inc(I, BCP^[I] + 1);
                Inc(CStrI);
            End;
          Else
              I:= TranslateCmd(I, False);
        End;
    End;
    WriteLn(FD, '');
End;

Function WriteProc(AProcNum: Word): Boolean;
Var
    CurStr: String;
Begin
    Assign(SrcFD, C_Tr_CodeFileName);
    Reset(SrcFD);
    While Not EOF(SrcFD) Do Begin
        ReadLn(SrcFD, CurStr);
        CurStr:= UpperCase(CurStr);
        If CurStr = C_Tr_ProcBlockTable[AProcNum] + C_Tr_BlockStart Then Begin
            While Not EOF(SrcFD) Do Begin
                ReadLn(SrcFD, CurStr);
                If UpperCase(CurStr) = C_Tr_ProcBlockTable[AProcNum] + C_Tr_BlockEnd Then
                    Break
                Else
                    WriteLn(FD, CurStr);
            End;
            If EOF(SrcFD) Then Begin
                ResP^.FIsSuccess:= False; ResP^.FErr:= E_T_CodeBlockNotClosed;
                WriteProc:= False; Close(SrcFD); Exit;
            End;
            Break;
        End;
    End;
    If EOF(SrcFD) Then Begin
        ResP^.FIsSuccess:= False; ResP^.FErr:= E_T_ReqProcNotExist;
        WriteProc:= False; Close(SrcFD); Exit;
    End;
    Close(SrcFD);
    WriteProc:= True;
End;

Procedure WriteDone;
Begin
    WriteLn(FD, '');
    If IsGetVarProcUsed Or IsExeProcUsed Or IsSpecCmdUsed Then Begin
        If Not WriteProc(C_Tr_GetVarBlock) Then Exit;
    End;
    If IsSetVarProcUsed Or IsSpecCmdUsed Then If Not WriteProc(C_Tr_SetVarBlock) Then Exit;
    If IsPushAProcUsed Then If Not WriteProc(C_Tr_PushAllOpBlock) Then Exit;
    If IsLocVarsUsed Then If Not WriteProc(C_Tr_PushVarsBlock) Then Exit;
    If IsRandomProcUsed Or IsExeProcUsed Then
        If Not WriteProc(C_Tr_InitRandomBlock) Then Exit;
    If IsCopyStrCmdUsed Then If Not WriteProc(C_Tr_CopyStrBlock) Then Exit;
    If IsMoveMemCmdUsed Then If Not WriteProc(C_Tr_MoveMemBlock) Then Exit;
    If IsExeProcUsed Then If Not WriteProc(C_Tr_ExeCmdBlock) Then Exit;
    If IsSpecCmdUsed Then If Not WriteProc(C_Tr_RunSpecCmdBlock) Then Exit;

    WriteStrings(EP);
    If IsGetVarProcUsed Or IsSetVarProcUsed Or IsExeProcUsed Or IsSpecCmdUsed Then Begin
        WriteLn(FD, ';-----Буфер, стек ОПЗ, переменные-----');
        WriteLn(FD, 'If $ Mod 2 = 1');
        WriteLn(FD, C_TChTab + 'nop');
        WriteLn(FD, 'End If');
        If IsSpecCmdUsed Then If Not WriteProc(C_Tr_JTableBlock) Then Exit;
        WriteLn(FD, 'Remem DW 0');
        WriteLn(FD, 'BufSize DB 6');
        WriteLn(FD, 'BufLen DB 0');
        WriteLn(FD, 'Text = $');
        WriteLn(FD, 'RPSt = $ + ', C_Tr_StdTextBufSize);
        WriteLn(FD, 'ParSt = $ + ', C_Tr_RPStBufSize + C_Tr_StdTextBufSize);
        WriteLn(FD, 'LocSt = $ + ', ParStSize + C_Tr_StdTextBufSize + C_Tr_RPStBufSize);
        WriteLn(FD, 'FIDS = $ + ', LocStSize + ParStSize + C_Tr_StdTextBufSize + C_Tr_RPStBufSize);
    End;
End;

End.