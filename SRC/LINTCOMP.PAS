{$I-} {$A+} {$R-} {$S-} {$Q-} {$G+} {$N+} {$D-} {$L-} {$Y-} {$X+}
Unit LIntComp;
Interface
Uses
    LMem, LUtils, LIntCons;
Type
    TLabel = Record
        FName: T_SIdentStr;
        FPos: Word;
    End;
    TLabelP = ^TLabel;
    {Метка}
    TLabelArr = Array [1..C_SMaxLabelCount] Of TLabelP;
    TLabelArrP = ^TLabelArr;

    {Запись для байткода с FEP}
    TCompInfo = Record
        FBCP: TBufferP;
        FEP: Word;
        FLabsP: TLabelArrP;
        FLabsCount: Word;
    End;
    TCompInfoP = ^TCompInfo;

    TCompResult = Record
        FIsSuccess: Boolean;
        FErrorLine: T_SProgLengthType;
        FErrStr: T_DStr;
        FErr: T_SProcessErr;
        FPointer: TCompInfoP;
    End;
    TCompResultP = ^TCompResult;

    TGetTokenResult = Record
        FTokType: T_TTokType;
        FTokVal: T_SVarType;
        FTokValErr: Integer;
        FTokStr: String[C_SMaxIdentLen];
    End;
    TGetTokenResultP = ^TGetTokenResult;
    {Представляет результат работы процедуры GetToken}

    TWaitStringResult = Record
        FResultStr: String;
        FErr: T_SWaitStringErr;
    End;
    TWaitStringResultP = ^TWaitStringResult;
    {Представляет результат работы функции WaitString}

    TCalcResult = Record
        FIsSuccess: Boolean;
        FErr: T_SProcessErr;
        FErrChar: Byte;
        FCode: TBufferP;
    End;
    TCalcResultP = ^TCalcResult;

    Procedure Process(Var ARes: TCompResultP; AFileName: String);
    {Интерфейсная функция для компиляции AFileName}
    Function InitComp: Boolean;
    {Размещение структур данных компилятора в памяти}
    Procedure DestroyComp;
    {Освобождение памяти после компиляции}

    Procedure GetToken(ARes: TGetTokenResultP; ASrcStr: String; Var AIndex: Integer);
    Function WaitToken(ARes: TGetTokenResultP; ASrcStr: String;
                       Var AIndex: Integer; ATokType: T_TTokType): Boolean;
    Function WaitString(ARes: TWaitStringResultP; ASrcStr: String;
                        Var AIndex: Integer; ACloseCh: Char): Boolean;
    Function IsReservedIdent(ASrcStr: String): Boolean;

Implementation
Var
    FileName: String;    {Имя файла, с которым будем работать}
    Labels: TLabelArrP;  {Метки}
    LI: Integer;         {Индексы меток}
    CBI: Word;           {Индекс байт-кода.}
    BCP: TBufferP;       {Байт-код}
    EP: Word;            {Точка входа в программу}

    CurWaitStrP: TWaitStringResultP;   {Текущая строка в ограничителях}
    CurTokP: TGetTokenResultP;        {Текущая лексема}

    Function ScanLabels: TCompResultP; Forward; {Сканирует метки}
    Function CompileToBC: TCompResultP; Forward; {Компилирует в байткод}
    Procedure LinkBC; Forward;
    {Корректирует в сгенерированном байткоде адреса переходов}
    Procedure CompileSubCalls(AResP: TCompResultP; ACalcResP: TCalcResultP;
                              ASrcStr: String; Var ASI: Integer); Forward;
    {Компилирует вызовы процедур}
    Function FindLabel(ALabelName: T_SIdentStr): Integer; Forward;
    {Компилирует выражение}
    Procedure Calc(Var AResP: TCalcResultP; AExpr: String); Forward;

{-------------Общие для компилятора и препроцессора функции--------------}

Procedure GetToken(ARes: TGetTokenResultP; ASrcStr: String; Var AIndex: Integer);
{Сканирует строку-источник начиная с индекса AIndex и возвращает
тип полученной лексемы}
Var
    BegI: Integer;
    Temp: Integer;
Begin
    If AIndex > Length(ASrcStr) Then Begin
        ARes^.FTokType:= T_TEOL; ARes^.FTokStr:= C_EOL;
        Exit;
    End;
    BegI:= AIndex;
    With ARes^ Do Case ASrcStr[AIndex] Of
     C_ChSpace:
        Begin
            FTokType:= T_TSpace; FTokStr:= C_ChSpace;
        End;
      C_ChZero..C_ChNine:
        Begin
            FTokType:= T_TImmVal;
            While ASrcStr[AIndex] In C_SDigits Do Inc(AIndex);
            FTokStr:= Copy(ASrcStr, BegI, AIndex - BegI);
            Val(FTokStr, FTokVal, FTokValErr);
            Dec(AIndex);
        End;
      C_ChUC_A..C_ChUC_Z, C_ChDC_a..C_ChDC_z, C_ChUC_RusA..C_ChUC_RusZ,
      C_ChDC_Rusa..C_ChDC_Rusp, C_ChDC_Rusr..C_ChDC_Rusz, C_ChUnderline:
        Begin
            FTokType:= T_TIdent;
            While (ASrcStr[AIndex] In C_SIdentChars)
            And (AIndex - BegI < C_SMaxIdentLen)
            And (AIndex <= Length(ASrcStr)) Do Inc(AIndex);

            FTokStr:= Copy(ASrcStr, BegI, AIndex - BegI);
            Dec(AIndex);
        End;
      C_ChOpenBr:
        Begin
            FTokType:= T_TOpenBr; FTokStr:= C_ChOpenBr;
        End;
      C_ChCloseBr:
        Begin
            FTokType:= T_TCloseBr; FTokStr:= C_ChCloseBr;
        End;
      C_ChOpenShBr:
        Begin
            FTokType:= T_TOpenShBr; FTokStr:= C_ChOpenShBr;
        End;
      C_ChCloseShBr:
        Begin
            FTokType:= T_TCloseShBr; FTokStr:= C_ChCloseShBr;
        End;
      C_ChOpenSqBr:
        Begin
            FTokType:= T_TOpenSqBr; FTokStr:= C_ChOpenSqBr;
        End;
      C_ChCloseSqBr:
        Begin
            FTokType:= T_TCloseSqBr; FTokStr:= C_ChCloseSqBr;
        End;
      C_ChIncStack, C_ChIncStack2:
        Begin
            FTokType:= T_TIncStack; FTokStr:= ASrcStr[AIndex];
        End;
      C_ChLet:
        Begin
            FTokType:= T_TLet; FTokStr:= C_ChLet;
        End;
      C_ChRandom:
        Begin
            FTokType:= T_TRandom; FTokStr:= C_ChRandom;
        End;
      C_ChAdd:
        Begin
            FTokType:= T_TAdd; FTokStr:= C_ChAdd;
        End;
      C_ChSub:
        Begin
            FTokType:= T_TSub; FTokStr:= C_ChSub;
        End;
      C_ChMul:
        Begin
            FTokType:= T_TMul; FTokStr:= C_ChMul;
        End;
      C_ChDiv:
        Begin
            FTokType:= T_TDiv; FTokStr:= C_ChDiv;
        End;
      C_ChMod:
        Begin
            FTokType:= T_TMod; FTokStr:= C_ChMod;
        End;
      C_ChRem:
        Begin
            FTokType:= T_TRem; FTokStr:= C_ChRem;
        End;
      C_ChExe:
        Begin
            FTokType:= T_TExe; FTokStr:= C_ChExe;
        End;
      C_ChSQuote:
        Begin
            FTokType:= T_TSQuote; FTokStr:= C_ChSQuote;
        End;
      C_ChSign:
        Begin
            FTokType:= T_TSign; FTokStr:= C_ChSign;
        End;
      C_Ch10:
        Begin
            FTokType:= T_T10; FTokStr:= C_Ch10;
        End;
      C_ChSqr:
        Begin
            FTokType:= T_TSqr; FTokStr:= C_ChSqr;
        End;
      C_ChPow:
        Begin
            FTokType:= T_TPow; FTokStr:= C_ChPow;
        End;
      C_ChBigger:
        Begin
            FTokType:= T_TBigger; FTokStr:= C_ChBigger;
        End;
      C_ChEqual:
        Begin
            FTokType:= T_TEqual; FTokStr:= C_ChEqual;
        End;
      C_ChLess:
        Begin
            FTokType:= T_TLess; FTokStr:= C_ChLess;
        End;
      C_ChSpec:
        Begin
            FTokType:= T_TSpec; FTokStr:= C_ChSpec;
        End;
      C_ChCond:
        Begin
            FTokType:= T_TCond; FTokStr:= C_ChCond;
        End;
      C_ChSlash:
        Begin
            FTokType:= T_TSlash; FTokStr:= C_ChSlash;
        End;
      C_ChDot:
        Begin
            FTokType:= T_TDot; FTokStr:= C_ChDot;
        End;
      C_ChColon:
        Begin
            FTokType:= T_TColon; FTokStr:= C_ChColon;
        End;
      C_TChTab:
        Begin
            FTokType:= T_TSpace; FTokStr:= C_TChTab;
        End;
      Else
        Begin
            FTokType:= T_TUnKnown; FTokStr:= ASrcStr[AIndex];
        End;
    End;
    Inc(AIndex);
End;

Function WaitToken(ARes: TGetTokenResultP; ASrcStr: String;
                   Var AIndex: Integer; ATokType: T_TTokType): Boolean;
{Проматывает все пробелы, получает лексему и возвращает True если тип
лексемы соответствует запрошенному в ATokType или если ATokType = T_TAny}
Begin
    Repeat GetToken(ARes, ASrcStr, AIndex) Until ARes^.FTokType <> T_TSpace;
    WaitToken:= (ARes^.FTokType = ATokType) Or (ATokType = T_TAny);
End;

Function WaitString(ARes: TWaitStringResultP; ASrcStr: String;
                    Var AIndex: Integer; ACloseCh: Char): Boolean;
{Получает строку, записанную в ограничителе ACloseCh, проверяя на ошибку
при записи
Если ошибки не было, возвращает True, иначе False и ARes^.FErr - код ошибки}
Var
    BegI: Word;
Begin
    BegI:= AIndex; ARes^.FResultStr:= ''; ARes^.FErr:= E_WStr_Ok;
    While Not (ASrcStr[AIndex] = ACloseCh) And
    (AIndex < Length(ASrcStr)) Do Inc(AIndex);
    If (AIndex = Length(ASrcStr)) And (ASrcStr[AIndex] <> ACloseCh) Then
        ARes^.FErr:= E_WStr_NotEnclosedStr
    Else
        ARes^.FResultStr:= Copy(ASrcStr, BegI, AIndex - BegI);
    WaitString:= ARes^.FErr = E_WStr_Ok;
    Inc(AIndex)
End;

Function IsReservedIdent(ASrcStr: String): Boolean;
Var
    I: Integer;
Begin
    IsReservedIdent:= False;
    For I:= 1 To C_DMaxReservedIdents Do Begin
        If C_DReservedIdents[I] = ASrcStr Then Begin
            IsReservedIdent:= True;
            Break;
        End;
    End;
End;

{--------------------Функции и процедуры компилятора--------------------}
Procedure Process(Var ARes: TCompResultP; AFileName: String);
Var
    ScanLabelsRes: TCompResultP;
    I: Word;
    FD: File; {!!!}
Begin
    FileName:= AFileName;
    ScanLabelsRes:= ScanLabels;
    With ScanLabelsRes^ Do Begin
        If Not FIsSuccess Then Begin
            ARes:= ScanLabelsRes;
            ARes^.FPointer:= Nil;
            Exit;
        End;
    End;
    ScanLabelsRes:= DestroyBuf(ScanLabelsRes);

    ARes:= CompileToBC;
    ARes^.FPointer:= CreateBuf(SizeOf(ARes^.FPointer^));

    ARes^.FPointer^.FBCP:= BCP;
    ARes^.FPointer^.FEP:= LIntComp.EP;
    ARes^.FPointer^.FLabsP:= Labels;
    ARes^.FPointer^.FLabsCount:= LI;
    LinkBC;

    If Not ARes^.FIsSuccess Then Exit;
End;

Function FindLabel(ALabelName: T_SIdentStr): Integer;
Var
    I: Integer;
Begin
    For I:= 1 To LI Do Begin
        If Labels^[I]^.FName = ALabelName Then Begin
            FindLabel:= I;
            Exit;
        End;
    End;
    FindLabel:= 0;
End;

Function ScanLabels: TCompResultP;
{Сканирует и заполняет таблицы с метками и подпрограммами}
Var
    {индексы текущей строки и номер строки}
    SI, CLI: Integer;
    {Результат, результат для функции Calc}
    ResP, CalcResP: TCompResultP;
    {Текущая обрабатываемая строка}
    CurStr: String;
    {Флаг, отображающий то, был ли встречен идентификатор Program}
    IsInProgram: Boolean;
    {Файловый дескриптор}
    FD: Text;
Begin
    LI:= 0; IsInProgram:= False;
    ResP:= CreateBuf(SizeOf(ResP^));
    {Будет считаться, что все хорошо}
    With ResP^ Do Begin
        FIsSuccess:= True; FErr:= E_P_Ok;
        FErrorLine:= 0; FErrStr:= '';
        FPointer:= Nil;
    End;

    CLI:= 0;
    Assign(FD, FileName);
    Reset(FD);
    While Not EOF(FD) Do With CurTokP^, ResP^ Do Begin
        Inc(CLI); SI:= 1;
        ReadLn(FD, CurStr);
        If WaitToken(CurTokP, CurStr, SI, T_TAny) Then;
        Case FTokType Of
          T_TEqual:
            Begin
                {Проверяем, если мы уже перемахнули через Program
                то объявлению процедуры там делать нечего}
                If IsInProgram Then Begin
                    FIsSuccess:= False; FErr:= E_P_SubAfterEntryPoint;
                    FErrorLine:= CLI; FErrStr:= CurStr;
                    Break;
                End;
                {По всем правилам, после = следует открывающая фигурная скобка}
                GetToken(CurTokP, CurStr, SI);
                If FTokType <> T_TOpenShBr Then Begin
                    FIsSuccess:= False; FErr:= E_P_OpenShBrAwaited;
                    FErrorLine:= CLI; FErrStr:= CurStr;
                    Break;
                End;
                {Пытаемся получить индентификатор, и ругаемся, если не выходит}
                GetToken(CurTokP, CurStr, SI);
                If FTokType <> T_TIdent Then Begin
                    FIsSuccess:= False; FErr:= E_P_IdentAwaited;
                    FErrorLine:= CLI; FErrStr:= CurStr;
                    Break;
                End;
                {Если имя такой процедуры уже присутствует в таблицах, то
                выдать ошибку}
                If FindLabel(FTokStr) <> 0 Then Begin
                    FIsSuccess:= False; FErr:= E_P_DublicateLabel;
                    FErrorLine:= CLI; FErrStr:= CurStr;
                    Break;
                End;
                {Проверяем, не достигнуто ли максимально позволенное кол-во
                процедур}
                Inc(LI);
                If LI > C_SMaxLabelCount Then Begin
                    FIsSuccess:= False; FErr:= E_P_TooMuchLabels;
                    FErrorLine:= CLI; FErrStr:= CurStr;
                    Break;
                End;
                {Записываем имя новой процедуры}
                If MaxAvail < SizeOf(Labels^[LI]^) + 2 Then Begin
                    FIsSuccess:= False; FErr:= E_P_NotEnoughMem;
                    FErrorLine:= CLI; FErrStr:= CurStr;
                    Break;
                End;
                Labels^[LI]:= CreateBuf(SizeOf(Labels^[LI]^));
                Labels^[LI]^.FName:= FTokStr;
                {Ждем закрывающую фигурную скобку}
                GetToken(CurTokP, CurStr, SI);
                If FTokType <> T_TCloseShBr Then Begin
                    FIsSuccess:= False; FErr:= E_P_CloseShBrAwaited;
                    FErrorLine:= CLI; FErrStr:= CurStr;
                    Break;
                End;
                {Ждем закрывающий =}
                GetToken(CurTokP, CurStr, SI);
                If FTokType <> T_TEqual Then Begin
                    FIsSuccess:= False; FErr:= E_P_EqualAwaited;
                    FErrorLine:= CLI; FErrStr:= CurStr;
                    Break;
                End;
                {Ожидается сугубо конец строки или пробелы,
                т.к комментарии уже выпилены препроцессором}
                If WaitToken(CurTokP, CurStr, SI, T_TAny) Then;
                If FTokType <> T_TEOL Then Begin
                    FIsSuccess:= False; FErr:= E_P_EOLAwaited;
                    FErrorLine:= CLI; FErrStr:= CurStr;
                    Break;
                End;
            End;
          T_TMul:
            Begin
                {Пытаемся получить второй знак умножения}
                GetToken(CurTokP, CurStr, SI);
                If FTokType = T_TMul Then Begin
                    {Проверить на конец строки}
                    If WaitToken(CurTokP, CurStr, SI, T_TAny) Then;
                    If FTokType <> T_TEOL Then Begin
                        FIsSuccess:= False; FErr:= E_P_EOLAwaited;
                        FErrorLine:= CLI; FErrStr:= CurStr;
                        Break;
                    End;
                End;
            End;
          T_TOpenShBr:
            Begin
                {Аналогично с разобором процедуры, с соответствующими
                изменениями}
                GetToken(CurTokP, CurStr, SI);
                If FTokType <> T_TIdent Then Begin
                    FIsSuccess:= False; FErr:= E_P_IdentAwaited;
                    FErrorLine:= CLI; FErrStr:= CurStr;
                    Break;
                End;
                If FindLabel(FTokStr) <> 0 Then Begin
                    FIsSuccess:= False; FErr:= E_P_DublicateLabel;
                    FErrorLine:= CLI; FErrStr:= CurStr;
                    Break;
                End;
                Inc(LI);
                If LI > C_SMaxLabelCount Then Begin
                    FIsSuccess:= False; FErr:= E_P_TooMuchLabels;
                    FErrorLine:= CLI; FErrStr:= CurStr;
                    Break;
                End;
                If MaxAvail < SizeOf(Labels^[LI]^) + 2 Then Begin
                    FIsSuccess:= False; FErr:= E_P_NotEnoughMem;
                    FErrorLine:= CLI; FErrStr:= CurStr;
                    Break;
                End;
                Labels^[LI]:= CreateBuf(SizeOf(Labels^[LI]^));
                Labels^[LI]^.FName:= FTokStr;
                GetToken(CurTokP, CurStr, SI);
                If FTokType <> T_TCloseShBr Then Begin
                    FIsSuccess:= False; FErr:= E_P_CloseShBrAwaited;
                    FErrorLine:= CLI; FErrStr:= CurStr;
                    Break;
                End;
                If WaitToken(CurTokP, CurStr, SI, T_TAny) Then;
                If FTokType <> T_TEOL Then Begin
                    FIsSuccess:= False; FErr:= E_P_EOLAwaited;
                    FErrorLine:= CLI; FErrStr:= CurStr;
                    Break;
                End;
            End;
          T_TIdent:
            Begin
                {Проверяем, если первый идент "програм" то устанавливаем флаг
                и проверяем, не в программе ли мы уже, а то коллапс}
                If FTokStr = C_SProgramIdent Then Begin
                    If IsInProgram Then Begin
                        FIsSuccess:= False; FErr:= E_P_DublicateProgram;
                        FErrorLine:= CLI; FErrStr:= CurStr;
                        Break;
                    End;
                    IsInProgram:= True;
                End;
            End;
        End;
    End;
    Close(FD);
    {Если идентификатор Program так и не был обнаружен, то точки входа нет
    а так быть не должно}
    If (Not IsInProgram) And ResP^.FIsSuccess Then With ResP^ Do Begin
        FIsSuccess:= False; FErr:= E_P_ProgramAwaited;
        FErrorLine:= CLI; FErrStr:= CurStr;
    End;
    ScanLabels:= ResP;
End;

Procedure Calc(Var AResP: TCalcResultP; AExpr: String);
Var
    BI, SI, TempI: Integer;
    NotIncrease: Boolean;
Begin
    {Компилирует выражение в байткод}
    With AResP^ Do Begin
        FIsSuccess:= True; FErrChar:= 0; FErr:= E_P_Ok;
        If FCode <> Nil Then FCode:= DestroyBuf(FCode);
        FCode:= CreateBuf(256);
    End;
    BI:= 1; SI:= 1; NotIncrease:= False;
    CurTokP^.FTokType:= T_TNone;
    While CurTokP^.FTokType <> T_TEOL Do With CurTokP^, AResP^ Do Begin
        If WaitToken(CurTokP, AExpr, SI, T_TAny) Then;
        Case FTokType Of
          T_TImmVal:
            Begin
                FCode^[BI]:= Byte(T_BC_PushVal);
                Word((Pointer(PChar(@FCode^[BI]) + 1))^):= FTokVal;
            End;
          T_TIncStack:
            FCode^[BI]:= Byte(T_BC_IncStack);
          T_TLet:
            FCode^[BI]:= Byte(T_BC_ReadVar);
          T_TRandom:
            FCode^[BI]:= Byte(T_BC_Random);
          T_TAdd:
            FCode^[BI]:= Byte(T_BC_Add);
          T_TSub:
            FCode^[BI]:= Byte(T_BC_Sub);
          T_TMul:
            FCode^[BI]:= Byte(T_BC_Mul);
          T_TDiv:
            FCode^[BI]:= Byte(T_BC_Div);
          T_TMod:
            FCode^[BI]:= Byte(T_BC_Mod);
          T_TExe:
            Begin
                FCode^[BI]:= Byte(T_BC_Exe);
                FCode^[BI + 1]:= Byte(T_BC_Nop);
                FCode^[BI + 2]:= Byte(T_BC_Nop);
                FCode^[BI + 3]:= Byte(T_BC_Nop);
            End;
          T_TSign:
            FCode^[BI]:= Byte(T_BC_Sign);
          T_T10:
            FCode^[BI]:= Byte(T_BC_10);
          T_TSqR:
            FCode^[BI]:= Byte(T_BC_SqR);
          T_TPow:
            FCode^[BI]:= Byte(T_BC_Pow);
          T_TSlash:
            FCode^[BI]:= Byte(T_BC_Or);
          T_TDot:
            FCode^[BI]:= Byte(T_BC_And);
          T_TColon:
            FCode^[BI]:= Byte(T_BC_Not);
          T_TCond:
            FCode^[BI]:= Byte(T_BC_Xor);
          T_TSQuote:
            Begin
                If Not WaitString(CurWaitStrP, AExpr, SI, C_DDefineValEncaser)
                Then Begin
                    FIsSuccess:= False; FErrChar:= SI; {!!!}
                    FErr:= E_P_NotEnclosedStr;
                    FCode:= DestroyBuf(FCode);
                    Break;
                End;
                If Length(CurWaitStrP^.FResultStr) > 0 Then Begin
                    FCode^[BI]:= Byte(T_BC_CopyStr);
                    TempI:= Length(CurWaitStrP^.FResultStr);
                    FCode^[BI + 1]:= TempI;
                    Inc(BI, 2);
                    MoveMem(@CurWaitStrP^.FResultStr[1], @FCode^[BI], TempI);
                    Inc(BI, TempI);
                    NotIncrease:= True;
                End;
            End;
          T_TSpec:
            Begin
                GetToken(CurTokP, AExpr, SI);
                If (FTokType = T_TIdent) And (UpCase(FTokStr[1]) = C_SBinIdent) Then Begin
                    Dec(SI, Length(FTokStr) - 1);
                    TempI:= SI;
                    While AExpr[SI] In C_SBinDigits Do Inc(SI);
                    FCode^[BI]:= Byte(T_BC_PushVal);
                    Word((Pointer(PChar(@FCode^[BI]) + 1))^):=
                        Word(BinToDec(Copy(AExpr, TempI, SI - TempI)));
                End
                Else If (FTokType = T_TIdent) And (UpCase(FTokStr[1]) = C_SHexIdent) Then Begin
                    Dec(SI, Length(FTokStr) - 1);
                    TempI:= SI;
                    While AExpr[SI] In C_SHexDigits Do Inc(SI);
                    FCode^[BI]:= Byte(T_BC_PushVal);
                    Word((Pointer(PChar(@FCode^[BI]) + 1))^):=
                        Word(HexToDec(Copy(AExpr, TempI, SI - TempI)));
                End
                Else Begin
                    FIsSuccess:= False; FErrChar:= SI;
                    FErr:= E_P_CSIdAwaited; FCode:= DestroyBuf(FCode);
                    Break;
                End;
            End;
          T_TIdent:
            Begin
                If FTokStr = C_SPushIdent Then
                    FCode^[BI]:= Byte(T_BC_PushOp)
                Else If FTokStr = C_SGetIdent Then
                    FCode^[BI]:= Byte(T_BC_GetOp)
                Else If FTokStr = C_SSegIdent Then
                    FCode^[BI]:= Byte(T_BC_Seg)
                Else Begin
                    FIsSuccess:= False; FErrChar:= SI;
                    FErr:= E_P_UnknownIdent; FCode:= DestroyBuf(FCode);
                    Break;
                End;
            End;
          T_TEOL:
            Break;
          Else
            Begin
                FIsSuccess:= False; FErrChar:= SI;
                FErr:= E_P_UnknownOp; FCode:= DestroyBuf(FCode);
                Break;
            End;
        End;
        If Not NotIncrease Then
            Inc(BI, C_BCSize[FCode^[BI]])
        Else
            NotIncrease:= False;
    End;
    If AResP^.FIsSuccess Then Begin
        AResP^.FCode:= ResizeBuf(AResP^.FCode, BI - 1);
    End
    Else
        If AResP^.FCode <> Nil Then AResP^.FCode:= DestroyBuf(AResP^.FCode);
End;

Procedure CompileSubCalls(AResP: TCompResultP; ACalcResP: TCalcResultP;
                              ASrcStr: String; Var ASI: Integer);
Var
    TempStr: String;
    Temp, Temp2: Word;
Begin
    GetToken(CurTokP, ASrcStr, ASI);
    With AResP^ Do Begin
        FIsSuccess:= True; FErr:= E_P_Ok;
        FErrorLine:= 0; FErrStr:= '';
    End;

    With CurTokP^, AResP^ Do
    Case FTokType Of
      T_TMul:
      {Обработка выхода из процедуры}
        Begin
            BCP^[CBI]:= Byte(T_BC_ExitSub);
            Inc(CBI);
        End;
      T_TLess:
      {Обработка безусловного вызова процедуры без параметров}
        Begin
            {Пытаемся получить имя процедуры}
            If Not WaitString(CurWaitStrP, ASrcStr, ASI, C_ChBigger) Then Begin
                FIsSuccess:= False; FErr:= E_P_BiggerAwaited;
                FErrStr:= ASrcStr; Exit;
            End;
            {Проверяем, присутствует ли процедура с таким именем}
            Temp:= FindLabel(CurWaitStrP^.FResultStr);
            If Temp = 0 Then Begin
                FIsSuccess:= False; FErr:= E_P_LabelNotExist;
                FErrStr:= ASrcStr; Exit;
            End;
            {А теперь в байткод нужно вставить команду
            безусловного вызова процедуры + 2 байта на адрес}
            BCP^[CBI]:= Byte(T_BC_CallSub);
            Inc(CBI);
            {Следующие 2 байта займет номер метки в таблице - по нему
            потом LinkBC восстановит реальный номер байта на который
            нужно будет делать переход}
            Word((Pointer(PChar(@BCP^[CBI])))^):= Temp;
            Inc(CBI, 2);
            {ClearStI не нужен - безусловный вызов процедуры сам очищает стек}
        End;
      T_TOpenSqBr:
        {Обработка безусловного вызова процедуры с передачей параметров}
        Begin
            {Пытаемся получить выражение.}
            If Not WaitString(CurWaitStrP, ASrcStr, ASI, C_ChCloseSqBr)
            Then Begin
                FIsSuccess:= False; FErr:= E_P_CloseSqBrAwaited;
                FErrStr:= ASrcStr; Exit;
            End;
            {Записываем выражение во временную строку}
            TempStr:= CurWaitStrP^.FResultStr;
            {Проверяем длину выражения}
            If Length(TempStr) < 1 Then Begin
                FIsSuccess:= False;
                FErr:= E_P_ExpressionAwaited;
                FErrStr:= ASrcStr; Exit;
            End;
            {Компилируем выражение}
            Calc(ACalcResP, TempStr);
            If Not ACalcResP^.FIsSuccess Then Begin
                FIsSuccess:= False; FErr:= ACalcResP^.FErr;
                FErrStr:= ASrcStr; Exit;
            End;
            MoveMem(@ACalcResP^.FCode^, @BCP^[CBI], SizeOfBuf(ACalcResP^.FCode));
            Inc(CBI, SizeOfBuf(ACalcResP^.FCode));
            {А теперь в байткод нужно вставить команду заталкивания параметров}
            BCP^[CBI]:= Byte(T_BC_PushAllOp);
            Inc(CBI);
            {А затем попытаемся получить имя процедуры}
            GetToken(CurTokP, ASrcStr, ASI);
            If FTokType <> T_TLess Then Begin
                FIsSuccess:= False; FErr:= E_P_LessAwaited;
                FErrStr:= ASrcStr; Exit
            End;
            If Not WaitString(CurWaitStrP, ASrcStr, ASI, C_ChBigger) Then Begin
                FIsSuccess:= False; FErr:= E_P_BiggerAwaited;
                FErrStr:= ASrcStr; Exit;
            End;
            {Проверяем, присутствует ли процедура с таким именем}
            Temp:= FindLabel(CurWaitStrP^.FResultStr);
            If Temp = 0 Then Begin
                FIsSuccess:= False; FErr:= E_P_LabelNotExist;
                FErrStr:= ASrcStr; Exit;
            End;
            {А теперь в байткод нужно вставить команду
            безусловного вызова процедуры + 2 байта на адрес}
            BCP^[CBI]:= Byte(T_BC_CallSub);
            Word((Pointer(PChar(@BCP^[CBI]) + 1))^):= Temp;
            Inc(CBI, 3);
            {Команду ClearStI вставлять смысла нет, т.к все что нужно сделает
            PushAllOp}
        End;
      T_TOpenBr:
        {Обработка условных вызовов процедур с\без передачи параметров}
        Begin
            {Получаем условие}
            If Not WaitString(CurWaitStrP, ASrcStr, ASI, C_ChCloseBr)
            Then Begin
                FIsSuccess:= False; FErr:= E_P_CloseBrAwaited;
                FErrStr:= ASrcStr; Exit;
            End;
            {Записываем выражение во временную строку}
            TempStr:= CurWaitStrP^.FResultStr;
            {Проверяем длину выражения}
            If Length(TempStr) < 1 Then Begin
                FIsSuccess:= False;
                FErr:= E_P_ExpressionAwaited;
                FErrStr:= ASrcStr; Exit;
            End;
            {Компилируем выражение}
            Calc(ACalcResP, TempStr);
            If Not ACalcResP^.FIsSuccess Then Begin
                FIsSuccess:= False; FErr:= ACalcResP^.FErr;
                FErrStr:= ASrcStr; Exit;
            End;
            {И записываем его в байткод}
            MoveMem(@ACalcResP^.FCode^, @BCP^[CBI], SizeOfBuf(ACalcResP^.FCode));
            Inc(CBI, SizeOfBuf(ACalcResP^.FCode));
            {Получаем следующую лексему}
            GetToken(CurTokP, ASrcStr, ASI);
            {Если это < то настраиваемся на получение имени метки}
            If FTokType = T_TLess Then Begin
                {Условный вызов без параметров}
                If Not WaitString(CurWaitStrP, ASrcStr, ASI, C_ChBigger) Then Begin
                    FIsSuccess:= False; FErr:= E_P_BiggerAwaited;
                    FErrStr:= ASrcStr; Exit;
                End;
                {Проверяем, присутствует ли процедура с таким именем}
                Temp:= FindLabel(CurWaitStrP^.FResultStr);
                If Temp = 0 Then Begin
                    FIsSuccess:= False; FErr:= E_P_LabelNotExist;
                    FErrStr:= ASrcStr; Exit;
                End;
                {А теперь в байткод нужно вставить команду
                условного вызова процедуры + 2 байта на адрес}
                BCP^[CBI]:= Byte(T_BC_CondCallSub);
                Word((Pointer(PChar(@BCP^[CBI]) + 1))^):= Temp;
                Inc(CBI, 3);
            End
            {Иначе, если это [ то нужно получить блок параметров}
            Else If FTokType = T_TOpenSqBr Then Begin
                {Условный вызов с передачей параметров}
                {Устанавливаем не нулевой переход}
                BCP^[CBI]:= Byte(T_BC_NZJump); Inc(CBI);
                Temp2:= CBI; Inc(CBI, 2);
                {Вставляем в байткод инструкцию ClearStI, чтобы очистить
                стек от могущих остаться в нем параметров от условия}
                BCP^[CBI]:= Byte(T_BC_ClearStI); Inc(CBI);
                {Пытаемся получить выражение.}
                If Not WaitString(CurWaitStrP, ASrcStr, ASI, C_ChCloseSqBr)
                Then Begin
                    FIsSuccess:= False; FErr:= E_P_CloseSqBrAwaited;
                    FErrStr:= ASrcStr; Exit;
                End;
                {Записываем выражение во временную строку}
                TempStr:= CurWaitStrP^.FResultStr;
                {Проверяем длину выражения}
                If Length(TempStr) < 1 Then Begin
                    FIsSuccess:= False;
                    FErr:= E_P_ExpressionAwaited;
                    FErrStr:= ASrcStr; Exit;
                End;
                {Компилируем выражение}
                Calc(ACalcResP, TempStr);
                If Not ACalcResP^.FIsSuccess Then Begin
                    FIsSuccess:= False; FErr:= ACalcResP^.FErr;
                    FErrStr:= ASrcStr; Exit;
                End;
                MoveMem(@ACalcResP^.FCode^, @BCP^[CBI], SizeOfBuf(ACalcResP^.FCode));
                Inc(CBI, SizeOfBuf(ACalcResP^.FCode));
                {А теперь в байткод нужно вставить команду заталкивания параметров}
                BCP^[CBI]:= Byte(T_BC_PushAllOp); Inc(CBI);
                {А затем попытаемся получить имя процедуры}
                GetToken(CurTokP, ASrcStr, ASI);
                If FTokType <> T_TLess Then Begin
                    FIsSuccess:= False; FErr:= E_P_LessAwaited;
                    FErrStr:= ASrcStr; Exit;
                End;
                If Not WaitString(CurWaitStrP, ASrcStr, ASI, C_ChBigger) Then Begin
                    FIsSuccess:= False; FErr:= E_P_BiggerAwaited;
                    FErrStr:= ASrcStr; Exit;
                End;
                {Проверяем, присутствует ли процедура с таким именем}
                Temp:= FindLabel(CurWaitStrP^.FResultStr);
                If Temp = 0 Then Begin
                    FIsSuccess:= False; FErr:= E_P_LabelNotExist;
                    FErrStr:= ASrcStr; Exit;
                End;
                {А теперь в байткод нужно вставить команду
                безусловного (т.к нулевой уже позаботился об условии)
                вызова процедуры + 2 байта на адрес}
                BCP^[CBI]:= Byte(T_BC_CallSub);
                Word((Pointer(PChar(@BCP^[CBI]) + 1))^):= Temp;
                Inc(CBI, 3);
                {Осталось лишь прописать адрес ненулевого перехода
                Такой переход нужен, если не сработает условие для
                вызова процедуры, в котором передаются параметры
                Тогда ненулевой переход пропустит блок передачи параметров}
                Word((Pointer(PChar(@BCP^[Temp2])))^):= CBI;
            End
            Else Begin
                FIsSuccess:= False; FErr:= E_P_ParsOrLabelNameAwaited;
                FErrStr:= ASrcStr; Exit;
            End;
        End;
      Else
        Begin
            FIsSuccess:= False; FErr:= E_P_SubCallAwaited;
            FErrStr:= ASrcStr; Exit;
        End;
    End;
End;

Function CompileToBC: TCompResultP;
{Компилирует программу в байт код}
Var
    {индексы текущей строки и номер строки}
    SI, CLI: Integer;
    {Результат, временной результат}
    ResP, TempResP: TCompResultP;
    {Результат функции Calc}
    CalcResP: TCalcResultP;
    {Текущая обрабатываемая строка, временные строки}
    CurStr, TempStr, TempStr2: String;
    {Временный Word}
    Temp: Word;
    {Файловый дескриптор}
    FD: Text;
Begin
    ResP:= CreateBuf(SizeOf(ResP^));
    If MaxAvail < SizeOf(TempResP^) + 2 Then With ResP^ Do Begin
         FIsSuccess:= False; FErr:= E_P_NotEnoughMem;
         FErrorLine:= CLI; FErrStr:= CurStr;
         CompileToBC:= ResP; Exit;
    End;
    TempResP:= CreateBuf(SizeOf(TempResP^));
    If MaxAvail < SizeOf(BCP^) + 2 Then With ResP^ Do Begin
         FIsSuccess:= False; FErr:= E_P_NotEnoughMem;
         FErrorLine:= CLI; FErrStr:= CurStr; CompileToBC:= ResP;
         TempResP:= DestroyBuf(TempResP); Exit;
    End;
    BCP:= CreateBuf(SizeOf(BCP^));
    If MaxAvail < SizeOf(CalcResP^) + 2 Then With ResP^ Do Begin
         FIsSuccess:= False; FErr:= E_P_NotEnoughMem;
         FErrorLine:= CLI; FErrStr:= CurStr; CompileToBC:= ResP;
         TempResP:= DestroyBuf(TempResP);
         BCP:= DestroyBuf(BCP);
         Exit;
    End;
    CalcResP:= CreateBuf(SizeOf(CalcResP^));
    CalcResP^.FCode:= Nil;

    With ResP^ Do Begin
        FIsSuccess:= True; FErr:= E_P_Ok;
        FErrorLine:= 0; FErrStr:= '';
    End;

    Assign(FD, FileName);
    Reset(FD);
    CLI:= 0; CBI:= 1;
    While Not EOF(FD) Do With CurTokP^, ResP^ Do Begin
        Inc(CLI); SI:= 1;
        ReadLn(FD, CurStr);
        If CBI > SizeOf(BCP^) - 256 Then Begin
            FIsSuccess:= False; FErrorLine:= CLI;
            FErr:= E_P_ByteCodeTooHuge;
            FErrStr:= CurStr;
            Break;
        End;
        If WaitToken(CurTokP, CurStr, SI, T_TAny) Then;
        Case FTokType Of
          T_TMul:
            {Обработка операторов выхода из процедуры, и вызова
            процедуры}
            Begin
                CompileSubCalls(TempResP, CalcResP, CurStr, SI); {var SI !!!}
                If Not TempResP^.FIsSuccess Then Begin
                    ResP^:= TempResP^;
                    ResP^.FErrorLine:= CLI;
                    Break;
                End;
                {Проверяем на мусор после имени процедуры}
                If Not WaitToken(CurTokP, CurStr, SI, T_TEOL) Then Begin
                    FIsSuccess:= False; FErrorLine:= CLI;
                    FErr:= E_P_EOLAwaited;
                    FErrStr:= CurStr;
                    Break;
                End;
            End;
          T_TCond:
            {Обработка операторов вызова метки}
            Begin
                GetToken(CurTokP, CurStr, SI);
                If FTokType = T_TOpenBr Then Begin
                    {Условный переход:}
                    {Пытаемся получить выражение.}
                    If Not WaitString(CurWaitStrP, CurStr, SI, C_ChCloseBr)
                    Then Begin
                        FIsSuccess:= False; FErrorLine:= CLI;
                        FErr:= E_P_CloseBrAwaited;
                        FErrStr:= CurStr;
                        Break;
                    End;
                    {Записываем выражение во временную строку}
                    TempStr:= CurWaitStrP^.FResultStr;
                    {Проверяем выражение на длину}
                    If Length(TempStr) < 1 Then Begin
                        FIsSuccess:= False; FErrorLine:= CLI;
                        FErr:= E_P_ExpressionAwaited;
                        FErrStr:= CurStr;
                        Break;
                    End;
                    {Пытаемся получить имя метки}
                    GetToken(CurTokP, CurStr, SI);
                    If FTokType <> T_TLess Then Begin
                        FIsSuccess:= False; FErrorLine:= CLI;
                        FErr:= E_P_LessAwaited;
                        FErrStr:= CurStr;
                        Break;
                    End;
                    If Not WaitString(CurWaitStrP, CurStr, SI, C_ChBigger)
                    Then Begin
                        FIsSuccess:= False; FErrorLine:= CLI;
                        FErr:= E_P_BiggerAwaited;
                        FErrStr:= CurStr;
                        Break;
                    End;
                    {Проверяем, присутствует ли метка с таким именем}
                    Temp:= FindLabel(CurWaitStrP^.FResultStr);
                    If Temp = 0 Then Begin
                        FIsSuccess:= False; FErrorLine:= CLI;
                        FErr:= E_P_LabelNotExist;
                        FErrStr:= CurStr;
                        Break;
                    End;
                    {Проверяем на мусор после имени метки}
                    If Not WaitToken(CurTokP, CurStr, SI, T_TEOL) Then Begin
                        FIsSuccess:= False; FErrorLine:= CLI;
                        FErr:= E_P_EOLAwaited; FErrStr:= CurStr;
                        Break;
                    End;
                    {Компилируем выражение}
                    Calc(CalcResP, TempStr);
                    If Not CalcResP^.FIsSuccess Then Begin
                        ResP^.FIsSuccess:= False;
                        ResP^.FErrorLine:= CLI;
                        ResP^.FErr:= CalcResP^.FErr;
                        ResP^.FErrStr:= CurStr;
                        Break;
                    End;
                    MoveMem(@CalcResP^.FCode^, @BCP^[CBI], SizeOfBuf(CalcResP^.FCode));
                    Inc(CBI, SizeOfBuf(CalcResP^.FCode));
                    {А теперь в байткод нужно вставить команду
                    условного перехода по метке + 2 байта на адрес}
                    BCP^[CBI]:= Byte(T_BC_CondJump);
                    Word((Pointer(PChar(@BCP^[CBI]) + 1))^):= Temp;
                    Inc(CBI, 3);
                End
                Else If FTokType = T_TLess Then Begin
                    {Безусловный переход}
                    {Пытаемся получить имя метки}
                    If Not WaitString(CurWaitStrP, CurStr, SI, C_ChBigger)
                    Then Begin
                        FIsSuccess:= False; FErrorLine:= CLI;
                        FErr:= E_P_BiggerAwaited;
                        FErrStr:= CurStr;
                        Break;
                    End;
                    {Проверяем, присутствует ли метка с таким именем}
                    Temp:= FindLabel(CurWaitStrP^.FResultStr);
                    If Temp = 0 Then Begin
                        FIsSuccess:= False; FErrorLine:= CLI;
                        FErr:= E_P_LabelNotExist;
                        FErrStr:= CurStr;
                        Break;
                    End;
                    {Проверяем на мусор после имени метки}
                    If Not WaitToken(CurTokP, CurStr, SI, T_TEOL) Then Begin
                        FIsSuccess:= False; FErrorLine:= CLI;
                        FErr:= E_P_EOLAwaited; FErrStr:= CurStr;
                        Break;
                    End;
                    {А теперь в байткод нужно вставить команду
                    безусловного перехода по метке + 2 байта на адрес}
                    BCP^[CBI]:= Byte(T_BC_Jump);
                    Word((Pointer(PChar(@BCP^[CBI]) + 1))^):= Temp;
                    Inc(CBI, 3);
                End
                {Если ошибка при записи}
                Else Begin
                    FIsSuccess:= False; FErrorLine:= CLI;
                    FErr:= E_P_CondOrLabelNameAwaited;
                    FErrStr:= CurStr;
                    Break;
                End;
            End;
          T_TEqual:
            {Установка адресов в байт-коде для процедур}
            Begin
                GetToken(CurTokP, CurStr, SI);
                GetToken(CurTokP, CurStr, SI);
                Labels^[FindLabel(FTokStr)]^.FPos:= CBI;
            End;
          T_TOpenShBr:
            {Установка адресов в байт-коде для меток}
            Begin
                {Нет смысла проверять, на то, существует ли метка,
                и закрыта ли она, т.к это уже проверено ProcessLabels}
                GetToken(CurTokP, CurStr, SI);
                Labels^[FindLabel(FTokStr)]^.FPos:= CBI;
            End;
          T_TRandom:
            {Обработка команды резервирования локальных переменных - ?}
            Begin
                {Пытаемся получить открывающую квадратную скобку}
                GetToken(CurTokP, CurStr, SI);
                If FTokType <> T_TOpenSqBr Then Begin
                    FIsSuccess:= False; FErrorLine:= CLI;
                    FErr:= E_P_OpenSqBrAwaited;
                    FErrStr:= CurStr;
                    Break;
                End;
                {Пытаемся получить выражение.}
                If Not WaitString(CurWaitStrP, CurStr, SI, C_ChCloseSqBr)
                Then Begin
                    FIsSuccess:= False; FErrorLine:= CLI;
                    FErr:= E_P_CloseSqBrAwaited;
                    FErrStr:= CurStr;
                    Break;
                End;
                {Проверяем на конец строки, другого мы не ждем}
                If Not WaitToken(CurTokP, CurStr, SI, T_TEOL) Then Begin
                    FIsSuccess:= False; FErrorLine:= CLI;
                    FErr:= E_P_EOLAwaited; FErrStr:= CurStr;
                    Break;
                End;
                {Записываем выражение во временную строку}
                TempStr:= CurWaitStrP^.FResultStr;
                {Проверяем выражение на длину}
                If Length(TempStr) < 1 Then Begin
                    FIsSuccess:= False; FErrorLine:= CLI;
                    FErr:= E_P_ExpressionAwaited;
                    FErrStr:= CurStr;
                    Break;
                End;
                {Компилируем выражение}
                Calc(CalcResP, TempStr);
                If Not CalcResP^.FIsSuccess Then Begin
                    ResP^.FIsSuccess:= False; ResP^.FErrorLine:= CLI;
                    ResP^.FErr:= CalcResP^.FErr; ResP^.FErrStr:= CurStr;
                    Break;
                End;
                MoveMem(@CalcResP^.FCode^, @BCP^[CBI], SizeOfBuf(CalcResP^.FCode));
                Inc(CBI, SizeOfBuf(CalcResP^.FCode));
                {А теперь в байткод нужно вставить команду
                сохранения переменных}
                BCP^[CBI]:= Byte(T_BC_PushVars);
                Inc(CBI);
                {команда очистки стека ОПЗ не нужна - PushVars будет чистить все сама}
                {BCP^[CBI]:= Byte(T_BC_ClearStI);
                Inc(CBI);}
            End;
          T_TLet:
            {Обработка оператора присваивания - $}
            Begin
                {Пытаемся получить открывающую скобку}
                GetToken(CurTokP, CurStr, SI);
                If FTokType <> T_TOpenBr Then Begin
                    FIsSuccess:= False; FErrorLine:= CLI;
                    FErr:= E_P_OpenBrAwaited;
                    FErrStr:= CurStr;
                    Break;
                End;
                {Пытаемся получить первое выражение.}
                If Not WaitString(CurWaitStrP, CurStr, SI, C_ChCloseBr)
                Then Begin
                    FIsSuccess:= False; FErrorLine:= CLI;
                    FErr:= E_P_CloseBrAwaited;
                    FErrStr:= CurStr;
                    Break;
                End;
                {Записываем первое выражение во временную строку}
                TempStr:= CurWaitStrP^.FResultStr;
                {Проверяем длину выражения}
                If Length(TempStr) < 1 Then Begin
                    FIsSuccess:= False; FErrorLine:= CLI;
                    FErr:= E_P_ExpressionAwaited;
                    FErrStr:= CurStr;
                    Break;
                End;
                {Пытаемся получить откр. скобку второго выражения}
                GetToken(CurTokP, CurStr, SI);
                If FTokType <> T_TOpenBr Then Begin
                    FIsSuccess:= False; FErrorLine:= CLI;
                    FErr:= E_P_OpenBrAwaited;
                    FErrStr:= CurStr;
                    Break;
                End;
                {Пытаемся получить второе выражение.}
                If Not WaitString(CurWaitStrP, CurStr, SI, C_ChCloseBr)
                Then Begin
                    FIsSuccess:= False; FErrorLine:= CLI;
                    FErr:= E_P_CloseBrAwaited;
                    FErrStr:= CurStr;
                    Break;
                End;
                {Записываем второе выражение во временную строку}
                TempStr2:= CurWaitStrP^.FResultStr;
                {Проверяем длину выражения}
                If Length(TempStr2) < 1 Then Begin
                    FIsSuccess:= False; FErrorLine:= CLI;
                    FErr:= E_P_ExpressionAwaited;
                    FErrStr:= CurStr;
                    Break;
                End;
                {Проверяем на мусор после второго выражения}
                If Not WaitToken(CurTokP, CurStr, SI, T_TEOL) Then Begin
                    FIsSuccess:= False; FErrorLine:= CLI;
                    FErr:= E_P_EOLAwaited; FErrStr:= CurStr;
                    Break;
                End;
                {Считаем первое выражение и записываем выходной байткод}
                Calc(CalcResP, TempStr); {TempStr2!}
                If Not CalcResP^.FIsSuccess Then Begin
                    ResP^.FIsSuccess:= False; ResP^.FErrorLine:= CLI;
                    ResP^.FErr:= CalcResP^.FErr; ResP^.FErrStr:= CurStr;
                    Break;
                End;
                MoveMem(@CalcResP^.FCode^, @BCP^[CBI], SizeOfBuf(CalcResP^.FCode));
                Inc(CBI, SizeOfBuf(CalcResP^.FCode));
                {А теперь в байткод нужно вставить команду запоминания
                содержимого верхушки стека. Это потребуется, чтобы не
                потерять номер переменной, которой нужно будет присваивать
                значение, если второе выражение оставит после себя лишние
                операнды на стеке. Вообще команда T_BC_Remember не очень
                естественна для стекового языка, но иного выхода я не вижу
                на данный момент. Такая же тактика работает и с оператором ~(T_TSpec)}
                BCP^[CBI]:= Byte(T_BC_Remember); Inc(CBI);
                {А теперь в байткод нужно вставить команду очистки стека}
                BCP^[CBI]:= Byte(T_BC_ClearStI); Inc(CBI);
                {Считаем номер переменной, которой будем присваивать,
                и записываем выходной байткод}
                Calc(CalcResP, TempStr2);  {TempStr}
                If Not CalcResP^.FIsSuccess Then Begin
                    ResP^.FIsSuccess:= False; ResP^.FErrorLine:= CLI;
                    ResP^.FErr:= CalcResP^.FErr; ResP^.FErrStr:= CurStr;
                    Break;
                End;
                MoveMem(@CalcResP^.FCode^, @BCP^[CBI], SizeOfBuf(CalcResP^.FCode));
                Inc(CBI, SizeOfBuf(CalcResP^.FCode));
                {А теперь в байткод нужно вставить команду присвоения}
                BCP^[CBI]:= Byte(T_BC_AssignVar);
                Inc(CBI);
                {ClearStI не нужен - AssignVar приведет индекс стека на место}
            End;
          T_TSpec:
            Begin
                {Пытаемся получить открывающую скобку}
                GetToken(CurTokP, CurStr, SI);
                If FTokType <> T_TOpenBr Then Begin
                    FIsSuccess:= False; FErrorLine:= CLI;
                    FErr:= E_P_OpenBrAwaited;
                    FErrStr:= CurStr;
                    Break;
                End;
                {Пытаемся получить первое выражение.}
                If Not WaitString(CurWaitStrP, CurStr, SI, C_ChCloseBr)
                Then Begin
                    FIsSuccess:= False; FErrorLine:= CLI;
                    FErr:= E_P_CloseBrAwaited;
                    FErrStr:= CurStr;
                    Break;
                End;
                {Записываем первое выражение во временную строку}
                TempStr:= CurWaitStrP^.FResultStr;
                {Проверяем длину выражения}
                If Length(TempStr) < 1 Then Begin
                    FIsSuccess:= False; FErrorLine:= CLI;
                    FErr:= E_P_ExpressionAwaited;
                    FErrStr:= CurStr;
                    Break;
                End;
                {Пытаемся получить откр. скобку второго выражения}
                GetToken(CurTokP, CurStr, SI);
                If FTokType <> T_TOpenBr Then Begin
                    FIsSuccess:= False; FErrorLine:= CLI;
                    FErr:= E_P_OpenBrAwaited;
                    FErrStr:= CurStr;
                    Break;
                End;
                {Пытаемся получить второе выражение.}
                If Not WaitString(CurWaitStrP, CurStr, SI, C_ChCloseBr)
                Then Begin
                    FIsSuccess:= False; FErrorLine:= CLI;
                    FErr:= E_P_CloseBrAwaited;
                    FErrStr:= CurStr;
                    Break;
                End;
                {Записываем второе выражение во временную строку}
                TempStr2:= CurWaitStrP^.FResultStr;
                {Проверяем длину выражения}
                If Length(TempStr2) < 1 Then Begin
                    FIsSuccess:= False; FErrorLine:= CLI;
                    FErr:= E_P_ExpressionAwaited;
                    FErrStr:= CurStr;
                    Break;
                End;
                {Проверяем на мусор после второго выражения}
                If Not WaitToken(CurTokP, CurStr, SI, T_TEOL) Then Begin
                    FIsSuccess:= False; FErrorLine:= CLI;
                    FErr:= E_P_EOLAwaited; FErrStr:= CurStr;
                    Break;
                End;
                {Считаем выражение с параметрами, и
                Затем записываем выходной байткод}
                Calc(CalcResP, TempStr);   {TempStr2 !!!}
                If Not CalcResP^.FIsSuccess Then Begin
                    ResP^.FIsSuccess:= False; ResP^.FErrorLine:= CLI;
                    ResP^.FErr:= CalcResP^.FErr; ResP^.FErrStr:= CurStr;
                    Break;
                End;
                MoveMem(@CalcResP^.FCode^, @BCP^[CBI], SizeOfBuf(CalcResP^.FCode));
                Inc(CBI, SizeOfBuf(CalcResP^.FCode));
                {А теперь в байткод нужно вставить команду запоминания
                содержимого верхушки стека}
                BCP^[CBI]:= Byte(T_BC_Remember); Inc(CBI);
                {А теперь в байткод нужно вставить команду очистки
                индекса стека}
                BCP^[CBI]:= Byte(T_BC_ClearStI); Inc(CBI);
                {Считаем номер функции, которую будем вызывать,
                и записываем его в выходной байткод}
                Calc(CalcResP, TempStr2);   {TempStr !!!}
                If Not CalcResP^.FIsSuccess Then Begin
                    ResP^.FIsSuccess:= False; ResP^.FErrorLine:= CLI;
                    ResP^.FErr:= CalcResP^.FErr; ResP^.FErrStr:= CurStr;
                    Break;
                End;
                MoveMem(@CalcResP^.FCode^, @BCP^[CBI], SizeOfBuf(CalcResP^.FCode));
                Inc(CBI, SizeOfBuf(CalcResP^.FCode));
                {А теперь в байткод нужно вставить команду вызова спец-функции}
                BCP^[CBI]:= Byte(T_BC_Spec);
                Inc(CBI);
                {ClearSTI сделает сама команда вызова СФ, поэтому он не нужен}
            End;
          T_TOpenSqBr:
            {Обработка оператора вывода строки - [}
            Begin
                {Пытаемся получить текстовую строку. Если что то не так -
                сообщаем об ошибке}
                If Not WaitString(CurWaitStrP, CurStr, SI, C_SStrEncaser)
                Then Begin
                    FIsSuccess:= False; FErrorLine:= CLI;
                    FErr:= E_P_WrongTextStr;
                    FErrStr:= CurStr;
                    Break;
                End;
                {Проверяем, не находится ли после строки какой либо мусор}
                If Not WaitToken(CurTokP, CurStr, SI, T_TEOL) Then Begin
                    FIsSuccess:= False; FErrorLine:= CLI;
                    FErr:= E_P_EOLAwaited; FErrStr:= CurStr;
                    Break;
                End;
                {Записываем полученный байт-код}
                BCP^[CBI]:= Byte(T_BC_WriteStr);
                BCP^[CBI + 1]:= Length(CurWaitStrP^.FResultStr);
                Inc(CBI, 2);
                {Только если строка не нулевой длины, записываем и ее тоже}
                If BCP^[CBI - 1] > 0 Then Begin
                    MoveMem(@CurWaitStrP^.FResultStr[1], @BCP^[CBI], BCP^[CBI - 1]);
                    Inc(CBI, BCP^[CBI - 1]);
                End;
            End;
          T_TIdent:
            {Обработка идентификаторов Program, P и M}
            Begin
                If FTokStr = C_SProgramIdent Then Begin
                    LIntComp.EP:= CBI;
                End
                Else If FTokStr = C_SPushIdent Then Begin
                    {Пытаемся получить открывающую скобку}
                    GetToken(CurTokP, CurStr, SI);
                    If FTokType <> T_TOpenBr Then Begin
                        FIsSuccess:= False; FErrorLine:= CLI;
                        FErr:= E_P_OpenBrAwaited;
                        FErrStr:= CurStr;
                        Break;
                    End;
                    {Пытаемся получить выражение.}
                    If Not WaitString(CurWaitStrP, CurStr, SI, C_ChCloseBr)
                    Then Begin
                        FIsSuccess:= False; FErrorLine:= CLI;
                        FErr:= E_P_CloseBrAwaited;
                        FErrStr:= CurStr;
                        Break;
                    End;
                    {Записываем выражение во временную строку}
                    TempStr:= CurWaitStrP^.FResultStr;
                    {Проверяем выражение на длину}
                    If Length(TempStr) < 1 Then Begin
                        FIsSuccess:= False; FErrorLine:= CLI;
                        FErr:= E_P_ExpressionAwaited;
                        FErrStr:= CurStr;
                        Break;
                    End;
                    {Компилируем выражение}
                    Calc(CalcResP, TempStr);
                    If Not CalcResP^.FIsSuccess Then Begin
                        ResP^.FIsSuccess:= False; ResP^.FErrorLine:= CLI;
                        ResP^.FErr:= CalcResP^.FErr; ResP^.FErrStr:= CurStr;
                        Break;
                    End;
                    MoveMem(@CalcResP^.FCode^, @BCP^[CBI], SizeOfBuf(CalcResP^.FCode));
                    Inc(CBI, SizeOfBuf(CalcResP^.FCode));
                    {А теперь в байткод нужно вставить команду заталкивания параметров}
                    BCP^[CBI]:= Byte(T_BC_PushAllOp);
                    Inc(CBI);
                    {команда очистки стека ОПЗ не нужна - PushAllOp все очистит}
                    {BCP^[CBI]:= Byte(T_BC_ClearStI);
                    Inc(CBI);}
                End
                Else If FTokStr = C_SMoveMemIdent Then Begin
                    GetToken(CurTokP, CurStr, SI);
                    If FTokType <> T_TOpenBr Then Begin
                        FIsSuccess:= False; FErrorLine:= CLI;
                        FErr:= E_P_OpenBrAwaited;
                        FErrStr:= CurStr;
                        Break;
                    End;
                    If Not WaitString(CurWaitStrP, CurStr, SI, C_ChCloseBr)
                    Then Begin
                        FIsSuccess:= False; FErrorLine:= CLI;
                        FErr:= E_P_CloseBrAwaited;
                        FErrStr:= CurStr;
                        Break;
                    End;
                    TempStr:= CurWaitStrP^.FResultStr;
                    If Length(TempStr) < 1 Then Begin
                        FIsSuccess:= False; FErrorLine:= CLI;
                        FErr:= E_P_ExpressionAwaited;
                        FErrStr:= CurStr;
                        Break;
                    End;
                    Calc(CalcResP, TempStr);
                    If Not CalcResP^.FIsSuccess Then Begin
                        ResP^.FIsSuccess:= False; ResP^.FErrorLine:= CLI;
                        ResP^.FErr:= CalcResP^.FErr; ResP^.FErrStr:= CurStr;
                        Break;
                    End;
                    MoveMem(@CalcResP^.FCode^, @BCP^[CBI], SizeOfBuf(CalcResP^.FCode));
                    Inc(CBI, SizeOfBuf(CalcResP^.FCode));
                    {А теперь в байткод нужно вставить команду MoveMem,
                    она же и стек почистит}
                    BCP^[CBI]:= Byte(T_BC_MoveMem);
                    Inc(CBI);
                End
                Else Begin
                    {Если идентификатор не известен}
                    FIsSuccess:= False; FErrorLine:= CLI;
                    FErr:= E_P_UnknownIdent; FErrStr:= CurStr;
                    Break;
                End;
                {Проверяем на мусор после выражения\Program}
                If Not WaitToken(CurTokP, CurStr, SI, T_TEOL) Then Begin
                    FIsSuccess:= False; FErrorLine:= CLI;
                    FErr:= E_P_EOLAwaited; FErrStr:= CurStr;
                    Break;
                End;
            End;
          T_TEOL:
            Begin
                BCP^[CBI]:= Byte(T_BC_ClearStI);
                Inc(CBI);
            End;
          Else
            Begin
                {Тут ругаемся на неизвестную инструкцию}
                FIsSuccess:= False; FErrorLine:= CLI;
                FErr:= E_P_UnknownChar; FErrStr:= CurStr;
                Break;
            End;
        End;
    End;
    Close(FD);
    BCP^[CBI]:= Byte(T_BC_End);
    BCP:= ResizeBuf(BCP, CBI);

    With CalcResP^ Do Begin
        If FCode <> Nil Then FCode:= DestroyBuf(FCode);
        CalcResP:= DestroyBuf(CalcResP);
    End;
    If TempResP <> Nil Then TempResP:= DestroyBuf(TempResP);

    CompileToBC:= ResP;
End;

Procedure LinkBC;
Var
    BI: Word;
Begin
    BI:= 1;
    While BI <= CBI Do Begin
        Case T_BC(BCP^[BI]) Of
          T_BC_WriteStr:
            Begin
                Inc(BI); Inc(BI, BCP^[BI] + 1);
            End;
          T_BC_AssignVar..T_BC_Spec:
            Inc(BI, C_BCSize[BCP^[BI]]);
          T_BC_Jump..T_BC_CondJump:
            Begin
                Inc(BI);
                Word((Pointer(PChar(@BCP^[BI])))^):=
                Labels^[Word((Pointer(PChar(@BCP^[BI])))^)]^.FPos;
                Inc(BI, 2);
            End;
          T_BC_NZJump:
            Inc(BI, 3);
          T_BC_CallSub, T_BC_CondCallSub:
            Begin
                Inc(BI);
                Word((Pointer(PChar(@BCP^[BI])))^):=
                Labels^[Word((Pointer(PChar(@BCP^[BI])))^)]^.FPos;
                Inc(BI, 2);
            End;
          T_BC_ExitSub..T_BC_MoveMem:
            Inc(BI);
          T_BC_CopyStr:
            Begin
                Inc(BI); Inc(BI, BCP^[BI] + 1);
            End;
          T_BC_End:
            Inc(BI);
          Else
            Begin
                WriteLn(C_TE_GodBlessYa);
                ReadLn;
                Halt;  {!!!}
            End;
        End;
    End;
End;

Function InitComp: Boolean;
Begin
    If MaxAvail < SizeOf(Labels^) + 2 Then Begin
        InitComp:= False; Exit;
    End;
    Labels:= CreateBuf(SizeOf(Labels^));

    If MaxAvail < SizeOf(CurTokP^) + 2 Then Begin
        Labels:= DestroyBuf(Labels);
        InitComp:= False; Exit;
    End;
    CurTokP:= CreateBuf(SizeOf(CurTokP^));

    If MaxAvail < SizeOf(CurWaitStrP^) + 2 Then Begin
        Labels:= DestroyBuf(Labels);
        CurTokP:= DestroyBuf(CurTokP);
        InitComp:= False; Exit;
    End;
    CurWaitStrP:= CreateBuf(SizeOf(CurWaitStrP^));

    BCP:= Nil; FileName:= '';
    InitComp:= True;
End;

Procedure DestroyComp;
Var
    I: Integer;
Begin
    For I:= LI DownTo 1 Do Labels^[I]:= DestroyBuf(Labels^[I]);
    Labels:= DestroyBuf(Labels);
    CurTokP:= DestroyBuf(CurTokP);
    CurWaitStrP:= DestroyBuf(CurWaitStrP);
End;

End.