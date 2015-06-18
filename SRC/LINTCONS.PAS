{$I-} {$A+} {$R-} {$S-} {$Q-} {$G+} {$N+} {$D-} {$L-} {$Y-} {$X-} {$T+} {$V+}
Unit LIntCons;
Interface
Uses
    LMem;
Type
    {-----------------------Общие типы программы-------------------------}
    T_SVarType = Integer;
    {Стандартный тип переменной.}
    T_SProgLengthType = Word;
    {Стандартный тип, в котором хранится макс длина программы}
    T_SPreProcessErr = (E_PreP_Ok, E_PreP_IdentAwaited,
    E_PreP_EqualAwaited, E_PreP_StrConstAwaited, E_PreP_FileNotExist,
    E_PreP_WrongFileName, E_PreP_LoopUses, E_PreP_NotEnclosedStr, E_PreP_WrongStr,
    E_PreP_StructureTooDeep, E_PreP_BadDefineIdent, E_PreP_BadDefineIdentVal,
    E_PreP_WrongTextStr, E_PreP_EmptyStrNotAllowed, E_PreP_WrongBrSet,
    E_PreP_CSIdAwaited, E_PreP_NotEnoughMem);
    {Тип с ошибками на стадии препроцессинга программы}

    T_SWaitStringErr = (E_WStr_Ok, E_WStr_NotEnclosedStr);
    {Ошибки в процедуре WaitString}

    T_SProcessErr = (E_P_Ok,
    E_P_LabelNotExist, E_P_DublicateLabel, E_P_EOLAwaited, E_P_OpenShBrAwaited,
    E_P_CloseShBrAwaited, E_P_EqualAwaited, E_P_IdentAwaited, E_P_ProgramAwaited,
    E_P_DublicateProgram, E_P_SubAfterEntryPoint, E_P_TooMuchLabels,

    E_P_WrongTextStr, E_P_OpenBrAwaited, E_P_CloseBrAwaited,
    E_P_OpenSqBrAwaited, E_P_CloseSqBrAwaited, E_P_BiggerAwaited,
    E_P_LessAwaited, E_P_CondOrLabelNameAwaited, E_P_ParsOrLabelNameAwaited,
    E_P_UnknownOp, E_P_UnknownIdent, E_P_UnknownChar, E_P_ExpressionAwaited,
    E_P_SubCallAwaited, E_P_NotEnoughMem, E_P_NotEnclosedStr, E_P_CSIdAwaited,
    E_P_ByteCodeTooHuge);
    {Ошибки при компиляции в байт-код}

    T_SIntErr = (E_I_Ok, E_I_StackEmpty, E_I_StackOverflow, E_I_RetStackEmpty,
    E_I_RetStackOverflow, E_I_WrongInputVal, E_I_WrongVar, E_I_UnknownCommand,
    E_I_DivByZero, E_I_WrongModifyOp, E_I_WrongRetAddr, E_I_ParStackEmpty,
    E_I_ParStackOverflow,
    E_I_WrongScrMode, E_I_WrongFileNum, E_I_CantOpenFile, E_I_WrongFileMode,
    E_I_WriteToFileError, E_I_ReadFromFileError, E_I_CloseFileError,
    E_I_CantSeekFile, E_I_UnKnownSpecCmd, E_I_CantInitGraph, E_I_GraphDrvNotExist
    );
    {Ошибки при интерпретации байт-кода}

    T_STransErr = (E_T_Ok, E_T_CodeFileNotExist, E_T_ReqProcNotExist,
    E_T_CodeBlockNotClosed);
    {Ошибки при трансляции в ASM}

    {-----------------------Типы получаемых лексем-----------------------}
    T_TTokType = (T_TNone, T_TUnKnown, T_TAny, T_TEOL, T_TSpace, T_TImmVal,
    T_TIdent, T_TOpenBr, T_TCloseBr, T_TOpenShBr, T_TCloseShBr,
    T_TOpenSqBr, T_TCloseSqBr, T_TIncStack, T_TLet, T_TRandom,
    T_TAdd, T_TSub, T_TMul, T_TDiv, T_TRem, T_TMod, T_TExe, T_TSign,
    T_T10, T_TSqr, T_TPow, T_TBigger, T_TEqual, T_TLess, T_TSpec, T_TCond,
    T_TSQuote, T_TString, T_TSlash, T_TDot, T_TColon);

    {------------------------------Байткод-------------------------------}
    T_BC = (T_BC_WriteStr, T_BC_AssignVar, T_BC_ReadVar, T_BC_IncStack,
    T_BC_PushVal, T_BC_Random, T_BC_Add, T_BC_Sub, T_BC_Mul, T_BC_Div,
    T_BC_Mod, T_BC_Exe, T_BC_Sign, T_BC_10, T_BC_SqR, T_BC_Pow,
    T_BC_PushOp, T_BC_GetOp, T_BC_Spec,   {18}
    T_BC_Jump, T_BC_CondJump, T_BC_NZJump, T_BC_CallSub, T_BC_CondCallSub,
    T_BC_ExitSub, T_BC_PushAllOp, T_BC_PushVars, T_BC_ClearStI, T_BC_Remember,
    T_BC_Nop, T_BC_And, T_BC_Or, T_BC_Not, T_BC_Xor, T_BC_Seg, T_BC_MoveMem,
    T_BC_CopyStr, T_BC_End
    );

Const
    {--------------------Настройки интерпретатора------------------------}
    C_LIntVer = '3.041';
    {Версия интерпретатора}
    C_SMaxGetMemSize = CMaxBuf;
    {Сколько максимально можем хапнуть памяти в один указатель}
    C_SMaxStrLen = 255;
    {Максимальная длина выходной строки}
    C_SMaxStrCount = High(T_SProgLengthType);
    {Максимальное колво строк программы}
    C_SMaxLabelCount = 2048;
    {Максимальное колво меток и подпрограмм}
    C_SMaxVarCount = C_SMaxGetMemSize Div SizeOf(T_SVarType);
    {Максимальное число переменных доступных программе}
    C_SMaxStackSize = 128;
    {Максимальный размер стека ОПЗ в ячейках (стандартного типа переменной)}
    C_SMaxRetStackSize = 10240;
    {Максимальный размер стека возврата в ячейках (стандартного типа переменной)}
    C_SMaxParStackSize = 10240;
    {Максимальный размер стека параметров в ячейках (стандартного типа переменной)}
    C_SMaxFileCount = 15;
    {Максимальное количество файлов}
    C_SMaxIdentLen = 20;
    {Максимальная длина идентификатора}

    {Зарезервированные идентификаторы языка}
    C_SProgramIdent = 'PROGRAM';
    C_SPushIdent = 'P';   {идент для команды заталкивания в стек параметров}
    C_SGetIdent = 'G';    {идент для команды извлечения из стека параметров}
    C_SSegIdent = 'S'; C_SMoveMemIdent = 'M'; {Seg, MoveMem}
    {А эти - нет}
    C_SBinIdent = 'B'; C_SHexIdent = 'H'; {BIN, HEX}

    {----------------------------Символы-------------------------------}
    C_ChLF = Chr(10);
    C_ChCR = Chr(13);
    C_ChSpace = ' ';
    C_ChSign = '!';
    C_ChExe = '"';
    C_ChCond = '#';
    C_ChLet = '$';
    C_ChMod = '%';
    C_ChPow = '&';
    C_ChSQuote = '''';
    C_ChOpenBr = '(';
    C_ChCloseBr = ')';
    C_ChMul = '*';
    C_ChAdd = '+';
    C_ChIncStack2 = ',';
    C_ChSub = '-';
    C_ChDot = '.';
    C_ChDiv = '/';
    C_ChRem = ';';
    C_ChZero = '0';
    C_ChOne = '1';
    C_ChNine = '9';
    C_ChColon = ':';
    C_ChSemiColon = ';';
    C_ChLess = '<';
    C_ChEqual = '=';
    C_ChBigger = '>';
    C_ChRandom = '?';
    C_ChSqr = '@';
    C_ChUC_A = 'A';
    C_ChUC_F = 'F';
    C_ChUC_Z = 'Z';
    C_ChOpenSqBr = '[';
    C_ChSlash = '\';
    C_ChCloseSqBr = ']';
    C_ChIncStack = '^';
    C_ChUnderline = '_';
    C_ChDC_a = 'a';
    C_ChDC_f = 'f';
    C_ChDC_z = 'z';
    C_ChOpenShBr = '{';
    C_Ch10 = '|';
    C_ChCloseShBr = '}';
    C_ChSpec = '~';
    C_ChUC_RusA = 'А';
    C_ChUC_RusZ = 'Я';
    C_ChDC_Rusa = 'а';
    C_ChDC_Rusp = 'п';
    C_ChDC_Rusr = 'р';
    C_ChDC_Rusz = 'я';

    C_EOL = C_ChCR + C_ChLF;

    C_SFirstIdentChar:
        Set Of Char = [C_ChUnderline, C_ChUC_A..C_ChUC_Z,
        C_ChDC_a..C_ChDC_z, C_ChUC_RusA..C_ChUC_RusZ,
        C_ChDC_Rusa..C_ChDC_Rusp, C_ChDC_Rusr..C_ChDC_Rusz];
    C_SIdentChars:
        Set Of Char = [C_ChZero..C_ChNine, C_ChUnderline, C_ChUC_A..C_ChUC_Z,
        C_ChDC_a..C_ChDC_z, C_ChUC_RusA..C_ChUC_RusZ,
        C_ChDC_Rusa..C_ChDC_Rusp, C_ChDC_Rusr..C_ChDC_Rusz];
    C_SDigits:
        Set Of Char = [C_ChZero..C_ChNine];
    C_SHexDigits:
        Set Of Char = [C_ChZero..C_ChNine, C_ChUC_A..C_ChUC_F, C_ChDC_a..C_ChDC_f];
    C_SBinDigits:
        Set Of Char = [C_ChZero..C_ChOne];

    {-----------------------Коды специальных функций---------------------}
    C_CSF_None = 0;
    C_CSF_ScreenMode = 1;
    C_CSF_PSet = 2;
    C_CSF_Line = 3;
    C_CSF_Circle = 4;
    C_CSF_GetPixelColor = 5;
    C_CSF_Sound = 6;
    C_CSF_WritePort = 7;
    C_CSF_ReadPort = 8;
    C_CSF_Int = 9;
    C_CSF_OpenFile = 10;
    C_CSF_WriteFile = 11;
    C_CSF_ReadFile = 12;
    C_CSF_CloseFile = 13;
    C_CSF_SetPalColor = 14;
    C_CSF_Pause = 15;
    C_CSF_ClS = 16;
    C_CSF_Fill = 17;
    C_CSF_WriteTextGraph = 18;
    C_CSF_WriteValGraph = 19;
    C_CSF_WriteCharGraph = 20;

    C_CSF_Count = 20;
    {Сколько каждая из специальных функций требует параметров на стеке}
    C_CSF_Args: Array [1..C_CSF_Count] Of Byte = (
        1, 3, 5, 4, 3, 1, 2, 2, 2, 3, 2, 3, 1, 4, 1, 1, 4, 5, 5, 5
    );

    {---------------------Размеры команд байткода---------------------}
    C_BCSize: Array [Ord(T_BC_WriteStr)..Ord(T_BC_End)] Of Byte = (
        1, 1, 1, 1, 3, 1, 1, 1, 1, 1, 1, 4, 1, 1, 1, 1, 1, 1, 1, 3, 3,
        3, 3, 3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
    );

    {--------------------Константы транслятора---------------------------}
    C_TChTab = Chr(9);
    C_TChDTab = Chr(9) + Chr(9);
    C_Tr_StdParStSize = 1024;
    C_Tr_StdLocStSize = 1024;
    C_Tr_StdTextBufSize = 256;
    C_Tr_RPStBufSize = C_SMaxStackSize * 2;

    C_Tr_InitBlock = 1; C_Tr_GetVarBlock = 2; C_Tr_SetVarBlock = 3;
    C_Tr_PushAllOpBlock = 4; C_Tr_PushVarsBlock = 5;
    C_Tr_InitRandomBlock = 6; C_Tr_ExeCmdBlock = 7;
    C_Tr_RunSpecCmdBlock = 8; C_Tr_MoveMemBlock = 9;
    C_Tr_CopyStrBlock = 10; C_Tr_JTableBlock = 11;
    C_Tr_ProcBlockTable: Array [1..11] Of String[16] = (
        'INITBLOCK', 'GETVARBLOCK', 'SETVARBLOCK',
        'PUSHALLOPBLOCK', 'PUSHVARSBLOCK',
        'INITRANDOMBLOCK', 'EXECMDBLOCK', 'RUNSPECCMDBLOCK',
        'MOVEMEMBLOCK', 'COPYSTRBLOCK', 'JUMPTABLEBLOCK'
    );
    C_Tr_CodeFileName = 'TR.DAT';
    C_Tr_BlockStart = ' START';
    C_Tr_BlockEnd = ' END';
    C_Tr_NotReqDecStI: Set Of T_BC = [T_BC_Remember, T_BC_ClearStI];


    {------------------------Описания ошибок--------------------------}
    {Ошибки препроцессора}
    C_PrePErrTexts: Array [Ord(E_PreP_Ok)..Ord(E_PreP_NotEnoughMem)] Of String[66] = (
        'OK',
        'Ожидался идентификатор',
        'Ожидался символ "="',
        'Ожидалась строковая константа',
        'Указанный файл не существует',
        'Имя файла записано неверно',
        'Циклические ссылки при использовании директивы "USES"',
        'Строковая константа не закрыта символом "''"',
        'Строковая константа записана неверно',
        'Уровень вложенности "USES" слишком велик',
        'Дублирующий идентификатор для директивы "DEFINE"',
        'Нельзя задавать пустое определение для "DEFINE" ',
        'Неверная текстовая строка для оператора вывода "["',
        'Не позволяется использовать пустые строки',
        'Неверно расставлены скобки',
        'Ожидался идентификатор системы счисления (H, B)',
        'Препроцессору не хватает памяти для обработки программы'
    );
    {Ошибки компилятора}
    C_CompErrTexts: Array [Ord(E_P_Ok)..Ord(E_P_ByteCodeTooHuge)] Of String[56] = (
        'OK',
        'Метка с указанным именем не существует',
        'Метка с указанным именем уже существует',
        'Ожидался конец строки, но найдены лишние символы',
        'Ожидался символ "{"',
        'Ожидался символ "}"',
        'Ожидался символ "="',
        'Ожидался идентификатор',
        'Ожидался идентификатор "PROGRAM", но так и не был найден',
        'Найден лишний идентификатор "PROGRAM"',
        'Подпрограмма описана после точки входа (PROGRAM)',
        'Достигнут предел количества меток и подпрограмм',
        'Текстовая константа записана неверно',
        'Ожидался символ "("',
        'Ожидался символ ")"',
        'Ожидался символ "["',
        'Ожидался символ "]"',
        'Ожидался символ ">"',
        'Ожидался символ "<"',
        'Ожидалось условие, или имя метки',
        'Ожидался список параметров, или имя метки',
        'Найден неизвестный оператор',
        'Найден неизвестный идентификатор',
        'Обнаружен неизвестный символ',
        'Ожидалось выражение',
        'Ожидался вызов процедуры',
        'Компилятору не хватает памяти для обработки программы',
        'Строковая константа не закрыта символом "''"',
        'Ожидался идентификатор системы счисления (H, B)',
        'Программа слишком большая, чтобы быть скомпилированной'
    );
    {Ошибки интерпретации}
    C_IntErrTexts: Array [Ord(E_I_Ok)..Ord(E_I_GraphDrvNotExist)] Of String[73] = (
        'OK',
        'В стеке не хватает операндов для выполнения текущей инструкции',
        'Стек переполнен',
        'В стеке возврата не хватает операндов для выполнения текущей инструкции',
        'Стек возврата переполнен',
        'Числовое значение введено неверно. Повторите ввод',
        'Попытка обратиться к несуществующей переменной',
        'Встречена неизвестная инструкция',
        'Попытка деления на 0 (операции "/", "%", "@")',
        'Неправильный код команды для выполнения инструкции самомодификации',
        'Неверный адрес возврата из процедуры',
        'В стеке параметров не хватает операндов для выполнения текущей инструкции',
        'Стек параметров переполнен',
        'Попытка установить неизвестный экранный режим командой ~(1)',
        'Попытка обратиться к несуществующему файлу',
        'Ошибка открытия файла',
        'Указан неверный режим работы с файлом',
        'Ошибка записи в файл',
        'Ошибка чтения из файла',
        'Ошибка закрытия файла',
        'Ошибка при выполнении инструкции SEEK для файла',
        'Попытка вызвать неизвестную специальную команду (оператор "~")',
        'Не удалось инициализировать графический режим',
        'Не найден файл SVGA256.BGI, необходимый для использования графики'
    );
    {Ошибки трансляции}
    C_TransErrTexts: Array [Ord(E_T_Ok)..Ord(E_T_CodeBlockNotClosed)] Of String[62] = (
        'OK',
        'Отсутствует файл подпрограмм ' + C_Tr_CodeFileName,
        'Не найден блок описания требуемой подпрограммы в файле ' + C_Tr_CodeFileName,
        'Не закрыт блок кода в файле ' + C_Tr_CodeFileName
    );

    {--------------------Определения для препроцессора-------------------}

    C_DDefine = 'DEFINE';
    {Идент директивы DEFINE}
    C_DUses = 'USES';
    {Идент директивы USES}
    C_DDefineValSeparator = C_ChEqual;
    {Символ, разделяющий имя определения и его текст}
    C_DDefineValEncaser = C_ChSQuote;
    {Символ, заключающий в себе идентификатор}
    C_DMaxStrLen = 255;
    {Максимальная длина обрабатываемой препроцессором строки}
    C_DMaxNestSize = 30;
    {Максимальное колво уровней вложенностей uses-include файлов,
    которое может обработать препроцессор}
    C_DMaxFileNameLen = 255;
    {Максимальная длина имени файла}
    C_DTempFileName = 'temp.tmp';
    {Имя временного файла}
    C_DMaxReservedIdents = 7;
    {Максимальное количество зарезервированных идентификаторов, которые
    нельзя использовать в программе}

    {--------------------Используемые текстовые константы-------------------}
    C_TError = 'Ошибка: ';
    C_T_InpChar = '>';
    C_T_CompKey = 'C';
    C_T_TransKey = 'T';
    C_T_StubName = 'INT';
    C_T_StubCreated = 'EXE файл создан успешно';
    C_T_StubFailed = 'Не удалось создать EXE файл';
    C_T_AsmCreated = 'Успешно создан листинг ';
    C_T_EasterEgg = 'MLP';
    C_T_RusName = 'RKS.COM';
    C_T_HelpText = 'LInt V' + C_LIntVer + ':'
    + C_EOL + 'Имя_файла - выполнить файл.'
    + C_EOL + 'Имя_файла ' + C_T_CompKey + ' - создать EXE (байткод)'
    + C_EOL + 'Имя_файла ' + C_T_TransKey + ' [число] [число]  - транслировать в ASM'
    + C_EOL + 'Пустая строка - выход';
    C_TE_FileNotExist = 'Файл с таким именем не найден';
    C_TE_ProgramDone = 'Программа успешно выполнена';
    C_TE_ProgramFail = 'Выполнение программы прервано';
    C_TE_InitFail = 'Не хватает памяти для размещения структур данных интерпретатора';
    C_TE_ProgramProcessing = 'Обработка программы... ';
    C_TE_ProgramProcessingDone = '[OK]';

    C_TE_PreProcessError = 'Ошибка предобработки программы #';
    C_TE_CompError = 'Ошибка компиляции программы #';
    C_TE_ErrFileNameMsg = '  Имя файла: ';
    C_TE_ErrStrNumMsg = '  Номер строки: ';
    C_TE_ErrStrMsg = '  Строка: ';

    C_TE_StubNotExist = 'Файл интерпретатора для вшития байткода не найден';
    C_TE_TransImpossible = ', трансляция невозможна';
    C_TE_GodBlessYa = 'Просто скажите Абадяберу, что он раздолбай';

    C_SStrEncaser = C_ChCloseSqBr;
    {Символ, заключающий в себе текстовую строку}

    C_EEImg: Array [1..23] Of String[50] = (
        '   . c@@@@@@@@O.   o.                             ',
        '  .8@@@@@@@@@@@@@o@@@:                            ',
        ' coc@@@@@@@@@@Ooo@@@8O         .                  ',
        '  .@@@@@@O@Oo@@@@@@O@C@c   :.8@8   :Oo            ',
        '  O@@@8oOoooo8Oc@@@@@CO .8@o@@O :8@@O             ',
        ' c@O:Oo@OC 8C.@@oO@@oc.8@@o@@Cc@@@8               ',
        '     :o@@. C@.O@@@@O8o@@@:o@C@@@8                 ',
        '    .C@@@O   c@@@@C88 C@oc@8CoO8@@@@@::.o8@8c     ',
        '    o@8@@@@8@@@OoO8@. OC@C@C@@o@@CoO@@@@@8.O8@C   ',
        '      .oO888CoO@@o8. ::o.@@@OOoC@@@@@@@@@@@oco .  ',
        '             o@@oo  .OC@@@@@o@@:   :@@@@@@@@:C:   ',
        '   Rainbow   o@O    8o@@@@Oo:CO      O@@@@@@O.O   ',
        '    Dash     :@O CoC@o@@@@@@OC@.      @@@@@@@ 8   ',
        '   requires   C@c@@C8O@@@@@O@8@       CO@@@@@.O:  ',
        '    LInt       .8@@8cO@@@@O8@@o       co@@@@@.Oo  ',
        '     to         c@Oc@@@c.@O8@@o.       o@@@@@ cO  ',
        '     be         c@@O@@@8 c@C@@@@.      :@@@@@  o  ',
        '    about       C@@C@@@@: @@C@@@8       @o8@@     ',
        '     20%        @@@o@@@@C 8@o@@@@:      co 8@:    ',
        '    cooler     c@@@o@@@@O @@o@@@@o       .  c8    ',
        '    zxD)))     @@@8O@@@@Oo@@C@@@@C                ',
        '              @@@@o@@@@@C@@o@@@@@C                ',
        '                 :@@@@@@:  oOOOOo                 '
    );
    {Поняшка =)}

Type
    {Тип стека возврата}
    T_RS_Type = (T_RS_RetAddr, T_RS_VarVal, T_RS_VarI);
    T_RS = Record
        FType: T_RS_Type;
        FVal: Word;
    End;
    TRetStackArr = Array [1..C_SMaxRetStackSize] Of T_RS;
    TRetStackArrP = ^TRetStackArr;

    {Файловая запись: дескриптор и булеан на факт открытия}
    TFile = Record
        FFile: File Of Byte;
        FOpened: Boolean;
    End;
    TFiles = Array [1..C_SMaxFileCount] Of TFile;
    TFilesP = ^TFiles;

    T_SIdentStr = String[C_SMaxIdentLen];
    T_SIdentStrP = ^T_SIdentStr;

    T_DStr = String[C_DMaxStrLen];
    T_DStrP = ^T_DStr;

    T_DReservedIdentsArr = Array [1..C_DMaxReservedIdents] Of T_SIdentStr;
Const
    C_DReservedIdents: T_DReservedIdentsArr = (
        C_DDefine, C_DUses, C_SProgramIdent, C_SPushIdent, C_SGetIdent,
        C_SSegIdent, C_SMoveMemIdent
    );
Implementation
End.