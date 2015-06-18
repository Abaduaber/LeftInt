{$I-} {$A+} {$R-} {$S-} {$Q-} {$G+} {$N+} {$D-} {$L-} {$Y-} {$X-}
Unit LIntPreP;
Interface
Uses
    LMem, LUtils, LIntCons, LIntComp;
Type
    TDefDataP = ^TDefData;
    {Представляет идент и определение идента для директивы DEFINE
    Также включает в себя ссылку на следующий идент}
    TDefData = Record
        FDef: T_SIdentStr;
        FDefVal: T_SIdentStr;
        FNext: TDefDataP;
    End;

    TPrePResultP = ^TPrePResult;
    TPrePResult = Record
        FIsSuccess: Boolean;
        {Успешно ли?}
        FErrorLine: T_SProgLengthType;
        {Номер строки с ошибкой}
        FErr: T_SPreProcessErr;
        {Тип ошибки}
        FErrStr: T_DStr;
        {Текст строки, в которой обнаружена ошибка}
        FFileName: String[C_DMaxFileNameLen];
        {Имя файла с которым работаем}
        FPred: TPrePResultP;
        {Указатель на вызывающую структуру}
    End;

    Function Process(AFileName: String): TPrePResultP;

Implementation
Var
    SrcF, DstF: Text;
    {Дескрипторы файлов - источника и приемника}
    CurStr, TempStr: T_DStr;
    {Временные строки}
    CurTok: TGetTokenResult;
    {Текущая обрабатываемая лексема}
    CurWaitStr: TWaitStringResult;
    {Результат работы функции WaitString}
    NestI: Word;
    {Уровень вложенности вызовов ProcessFile}

    Function IsAbleToAddDefIdent(ADefsP: TDefDataP; AIdent: T_SIdentStr): Boolean; Forward;
    Function IsExistDefIdent(ADefsP: TDefDataP; AIdent: T_SIdentStr): TDefDataP; Forward;
    Function ProcessDefs(Var AResP: TPrePResultP; ADefsP: TDefDataP; AStr: T_DStr): T_DStr; Forward;

    Function ProcessFile(ACaller: TPrePResultP; AFileName: String): TPrePResultP; Forward;

Function Process(AFileName: String): TPrePResultP;
Var
    Res: TPrePResult;
Begin
    {Открываем временной файл - приемник}
    Assign(DstF, C_DTempFileName);
    ReWrite(DstF);
    {Это первый вызов ProcessFile, следовательно, Uses еще не было,
    и FPred должен быть Nil, а NestI:= 0}
    Res.FPred:= Nil; NestI:= 0;
    {Обрабатываем файл}
    Process:= ProcessFile(@Res, AFileName);
    {После обработки проекта закрываем файл назначения}
    Close(DstF);
End;

Function ProcessFile(ACaller: TPrePResultP; AFileName: String): TPrePResultP;
Var
    ResP, RetResP, TempResP: TPrePResultP;
    {Хранит в себе результат работы функции над файлом AFileName}
    HeadDefP, CurDefP: TDefDataP;
    {Указатели на первое и на текущее определение Define}
    SI, LI, I: Integer;
    {Индекс символа в строке, индекс текущей строки, временной индекс}
Begin
    Inc(NestI);
    {Создаем буфер для результата работы функции}
    ResP:= CreateBuf(SizeOf(ResP^));
    RetResP:= Nil;
    HeadDefP:= Nil; CurDefP:= Nil;

    {Все хорошо, до тех пор, пока программа не заметит обратного ;)}
    With ResP^ Do Begin
        FIsSuccess:= True; FErrorLine:= 0;
        FErr:= E_PreP_Ok; FFileName:= AFileName;
        FErrStr:= ''; FPred:= ACaller;
        {Теперь мы знаем все о файле, из которого нас вызвали с Uses =)
        Эта информация пригодится, когда будем делать проверку на циклические
        uses.}
    End;

    {Открываем файл-источник}
    Assign(SrcF, AFileName);
    Reset(SrcF);
    {Начинаем чтение с первой строки файла}
    LI:= 0;
    While Not EOF(SrcF) Do With ResP^, CurTok Do Begin
        Inc(LI); SI:= 1;
        ReadLn(SrcF, CurStr);
        FErrorLine:= LI; FErrStr:= CurStr;

        If WaitToken(@CurTok, CurStr, SI, T_TIdent) Then Begin
            TempStr:= UpperCase(FTokStr);
            {Если это директива DEFINE то...}
            If (TempStr = C_DDefine) Then Begin
                {Пытаемся получить идент. Если не он, то...}
                If Not WaitToken(@CurTok, CurStr, SI, T_TIdent) Then Begin
                    FIsSuccess:= False; FErr:= E_PreP_IdentAwaited; Break;
                End;
                {Если идентификатор некорректен то...}
                If Not (IsAbleToAddDefIdent(HeadDefP, FTokStr)) Then Begin
                    FIsSuccess:= False; FErr:= E_PreP_BadDefineIdent; Break;
                End;
                {...если ок, то создаем под него буфер,
                 куда записываем его имя}
                If MaxAvail < SizeOf(CurDefP^) + 2 Then Begin
                    FIsSuccess:= False; FErr:= E_PreP_NotEnoughMem; Break;
                End;
                CurDefP:= CreateBuf(SizeOf(CurDefP^));
                CurDefP^.FDef:= UpperCase(FTokStr);
                {Если не получили символ = то...}
                If Not WaitToken(@CurTok, CurStr, SI, T_TEqual) Then Begin
                    FIsSuccess:= False; FErr:= E_PreP_EqualAwaited; Break;
                End;
                {Пытаемся получить энкейсер для текстовой строки}
                If WaitToken(@CurTok, CurStr, SI, T_TAny) Then;
                If Not (FTokStr = C_DDefineValEncaser) Then Begin
                    FIsSuccess:= False; FErr:= E_PreP_StrConstAwaited; Break;
                End;
                {Если не он, тогда так не пойдет}
                If Not WaitString(@CurWaitStr, CurStr, SI, C_DDefineValEncaser)
                Then Begin
                    FIsSuccess:= False; FErr:= E_PreP_NotEnclosedStr; Break;
                End;
                {Если после строки не комментарий и не конец строки то...}
                If WaitToken(@CurTok, CurStr, SI, T_TAny) Then;
                If Not ((FTokStr = C_ChRem) Or (FTokStr = C_EOL)) Then Begin
                    FIsSuccess:= False; FErr:= E_PreP_WrongStr; Break;
                End;
                {Если все хорошо - записываем значение идентификатора}
                CurDefP^.FDefVal:= UpperCase(CurWaitStr.FResultStr);
                CurDefP^.FNext:= HeadDefP;
                HeadDefP:= CurDefP;
                CurDefP:= Nil;
            End
            Else If (TempStr = C_DUses) Then Begin
                {Если строка...}
                If Not (WaitToken(@CurTok, CurStr, SI, T_TAny)
                And (FTokStr = C_DDefineValEncaser)) Then Begin
                    FIsSuccess:= False; FErr:= E_PreP_StrConstAwaited; Break;
                End;
                {Если строка с именем файла записана некорректно то...}
                If Not WaitString(@CurWaitStr, CurStr, SI, C_DDefineValEncaser)
                Then Begin
                    FIsSuccess:= False; FErr:= E_PreP_NotEnclosedStr; Break;
                End;
                {Если после строки не комментарий и не конец строки то...}
                If WaitToken(@CurTok, CurStr, SI, T_TAny) Then;
                If Not ((FTokStr = C_ChRem) Or (FTokStr = C_EOL)) Then Begin
                    FIsSuccess:= False; FErr:= E_PreP_WrongStr; Break;
                End;
                {Если строка вообще пуста, то тоже не катит}
                If (CurWaitStr.FResultStr = '') Or
                (Length(CurWaitStr.FResultStr) > C_DMaxFileNameLen) Then
                With ResP^ Do Begin
                    FIsSuccess:= False; FErr:= E_PreP_WrongFileName; Break;
                End;

                TempStr:= CurWaitStr.FResultStr;
                {Если указанного файла не существует...}
                If Not IsFileExist(TempStr) Then Begin
                    FIsSuccess:= False; FErr:= E_PreP_FileNotExist; Break;
                End;
                {Проверяем на циклические ссылки}
                TempResP:= ResP;
                Repeat
                    If TempResP^.FFileName = TempStr Then Begin
                        FIsSuccess:= False; FErr:= E_PreP_LoopUses; Break;
                    End
                    Else
                        TempResP:= TempResP^.FPred;
                Until (TempResP = Nil);  {!!!}
                If Not FIsSuccess Then Break;
                {Проверяем, не зашкаливает ли уровень вложенности Uses.}
                If NestI + 1 > C_DMaxNestSize Then Begin
                    FIsSuccess:= False; FErr:= E_PreP_StructureTooDeep; Break;
                End;
                {Вроде все хорошо. Можно закрыть файл-источник, и вызывать
                рекурсивно ProcessFIle}
                Close(SrcF);
                RetResP:= ProcessFile(ResP, TempStr);
                {RetResP отныне хранит результат обработки файла
                Проверяем, если файл был обработан с ошибкой, то
                требуется выйти из всех ProcessFile, сохраняя статус ошибки}
                If RetResP^.FErr <> E_PreP_Ok Then Begin
                    ResP^:= RetResP^; Break;
                End;
                {Если все хорошо, то можно снова открывать старый файл
                источник и восстанавливать его позицию}
                Assign(SrcF, AFileName);
                Reset(SrcF);
                For I:= 1 To LI Do ReadLn(SrcF, TempStr);
                RetResP:= DestroyBuf(RetResP);
            End
            {Иначе, сканируем все идентификаторы, где нужно, делаем
            подстановки define и записываем полученную строку в файл}
            Else Begin
                CurStr:= ProcessDefs(ResP, HeadDefP, CurStr);
                If FErr <> E_PreP_Ok Then Break;
                WriteLn(DstF, CurStr);
            End;
            Continue;
        End;

        {Если мы словили символ комментария, то не делаем вообще ничего}
        If CurTok.FTokType = T_TRem Then Continue;
        {Иначе, если мы получили оператор вывода строки, то замены в нем
        делать не стоит, поэтому просто получаем строку и
        записываем ее в выход, не записывая возможный после нее комментарий}
        If CurTok.FTokType = T_TOpenSqBr Then Begin
            If Not WaitString(@CurWaitStr, CurStr, SI, C_SStrEncaser) Then Begin
                FIsSuccess:= False; FErr:= E_PreP_WrongTextStr; Break;
            End;
            WriteLn(DstF, C_ChOpenSqBr + CurWaitStr.FResultStr + C_ChCloseSqBr);
            Continue;
        End;
        {Если не идент, не комментарий и не вывод строки, то просто обрабатываем
        подстановки}
        CurStr:= ProcessDefs(ResP, HeadDefP, CurStr);
        If FErr <> E_PreP_Ok Then Break;
        If CurStr <> '' Then WriteLn(DstF, CurStr);
    End;

    Close(SrcF);
    If IOResult <> 0 Then;
    ProcessFile:= ResP;

    {В случае, если препроцессором была обнаружена ошибка,
    может остаться лишний мусор в динамической памяти после
    break. Его проще проверить вне цикла и один раз}
    If RetResP <> Nil Then RetResP:= DestroyBuf(RetResP);
    If CurDefP <> Nil Then CurDefP:= DestroyBuf(CurDefP);
    {Уничтожаем все созданные определения Define}
    CurDefP:= HeadDefP;
    While CurDefP <> Nil Do Begin
        HeadDefP:= CurDefP^.FNext;
        CurDefP:= DestroyBuf(CurDefP);
        CurDefP:= HeadDefP;
    End;
End;

Function ProcessDefs(Var AResP: TPrePResultP; ADefsP: TDefDataP; AStr: T_DStr): T_DStr;
{Обрабатывает входную строку, заменяя идентификаторы-определения define
на замещающий их текст и возвращает уже обработанную строку.}
Var
    SI, StartSI: Integer;
    ResStr: T_DStr;
    CurDefP: TDefDataP;
    IsOpenBr: Boolean;
Begin
    SI:= 1; ResStr:= ''; IsOpenBr:= False;
    With CurTok Do Repeat
        GetToken(@CurTok, AStr, SI);
        {Проверяем на откр. скобку}
        If FTokType = T_TOpenBr Then Begin
            If IsOpenBr Then With AResP^ Do Begin
                FIsSuccess:= False; FErr:= E_PreP_WrongBrSet; Exit;
            End;
            IsOpenBr:= True;
        End;
        {И на закр. скобку}
        If FTokType = T_TCloseBr Then Begin
            If Not IsOpenBr Then With AResP^ Do Begin
                FIsSuccess:= False; FErr:= E_PreP_WrongBrSet; Exit;
            End;
            IsOpenBr:= False;
        End;
        {Если словили кавычку, то никаких замен и апперкейсов внутри них}
        If FTokType = T_TSQuote Then Begin
            TempStr:= FTokStr;
            If Not WaitString(@CurWaitStr, CurStr, SI, C_DDefineValEncaser)
            Then With AResP^ Do Begin
                FIsSuccess:= False; FErr:= E_PreP_NotEnclosedStr; Exit;
            End;
            If Length(CurWaitStr.FResultStr) > 0 Then Begin
                ResStr:= ResStr + TempStr + CurWaitStr.FResultStr;
            End
            Else With AResP^ Do Begin
                FIsSuccess:= False; FErr:= E_PreP_EmptyStrNotAllowed; Exit;
            End;
        End;
        {Если споймали идентификатор специальных команд, то требуется
        уточнить систему счисления, после чего просто прокрутить все символы,
        которые вписываются в указанную систему счисления, не забыв записать
        их в выходной поток. Преобразованием займется компилятор}
        If (FTokType = T_TSpec) And IsOpenBr Then Begin
            GetToken(@CurTok, AStr, SI);
            If (FTokType = T_TIdent) And (UpCase(FTokStr[1]) = C_SBinIdent) Then Begin
                Dec(SI, Length(FTokStr) - 1);
                StartSI:= SI;
                While AStr[SI] In C_SBinDigits Do Inc(SI);
                ResStr:= ResStr + '~B' + Copy(AStr, StartSI, SI - StartSI);
                FTokType:= T_TSpace;
            End
            Else If (FTokType = T_TIdent) And (UpCase(FTokStr[1]) = C_SHexIdent) Then Begin
                Dec(SI, Length(FTokStr) - 1);
                StartSI:= SI;
                While AStr[SI] In C_SHexDigits Do Inc(SI);
                ResStr:= ResStr + '~H' + UpperCase(Copy(AStr, StartSI, SI - StartSI));
                FTokType:= T_TSpace;
            End
            Else With AResP^ Do Begin
                FIsSuccess:= False; FErr:= E_PreP_CSIdAwaited; Exit;
            End;
        End;

        If FTokType = T_TIdent Then Begin
            CurDefP:= IsExistDefIdent(ADefsP, FTokStr);
            If CurDefP <> Nil Then
                ResStr:= ResStr + CurDefP^.FDefVal
            Else
                ResStr:= ResStr + UpperCase(FTokStr);
        End
        Else Begin
            If FTokType = T_TRem Then Break;
            If Not (FTokType In [T_TEOL, T_TSpace]) Then
                ResStr:= ResStr + FTokStr;
        End;
    Until CurTok.FTokType = T_TEOL;
    ProcessDefs:= ResStr;
End;

Function IsAbleToAddDefIdent(ADefsP: TDefDataP; AIdent: T_SIdentStr): Boolean;
{Вовращает True в случае, если идентификатор с именем AIdent может быть
добавлен в список определений Define (не дублирует зарезервированный
идентификатор языка, и не дублирует уже существующее определение Define)
и False в противном случае}
Var
    IdStr: T_SIdentStr;
    CurDefP: TDefDataP;
Begin
    IsAbleToAddDefIdent:= True;
    IdStr:= UpperCase(AIdent);
    If IsReservedIdent(IdStr) Then
        IsAbleToAddDefIdent:= False
    Else Begin
        CurDefP:= ADefsP;
        While CurDefP <> Nil Do Begin
            If CurDefP^.FDef = IdStr Then Begin
                IsAbleToAddDefIdent:= False; Exit;
            End;
            CurDefP:= CurDefP^.FNext;
        End;
    End;
End;

Function IsExistDefIdent(ADefsP: TDefDataP; AIdent: T_SIdentStr): TDefDataP;
Var
    CurDefP: TDefDataP;
{Ищет идентификатор-определение define с указанным именем, и возвращает
указатель на ячейку, в случае если он найден, и Nil, если нет}
Begin
    AIdent:= UpperCase(AIdent);
    CurDefP:= ADefsP;
    While CurDefP <> Nil Do Begin
        If CurDefP^.FDef = AIdent Then Begin
            IsExistDefIdent:= CurDefP; Exit;
        End;
        CurDefP:= CurDefP^.FNext;
    End;
    IsExistDefIdent:= Nil;
End;

End.