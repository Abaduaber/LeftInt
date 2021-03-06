{$I-} {$A+} {$R-} {$S-} {$Q-} {$G+} {$N+} {$D-} {$L-} {$Y-} {$X-} {$T+} {$V+}
Unit LIntCons;
Interface
Uses
    LMem;
Type
    {-----------------------��騥 ⨯� �ணࠬ��-------------------------}
    T_SVarType = Integer;
    {�⠭����� ⨯ ��६�����.}
    T_SProgLengthType = Word;
    {�⠭����� ⨯, � ���஬ �࠭���� ���� ����� �ணࠬ��}
    T_SPreProcessErr = (E_PreP_Ok, E_PreP_IdentAwaited,
    E_PreP_EqualAwaited, E_PreP_StrConstAwaited, E_PreP_FileNotExist,
    E_PreP_WrongFileName, E_PreP_LoopUses, E_PreP_NotEnclosedStr, E_PreP_WrongStr,
    E_PreP_StructureTooDeep, E_PreP_BadDefineIdent, E_PreP_BadDefineIdentVal,
    E_PreP_WrongTextStr, E_PreP_EmptyStrNotAllowed, E_PreP_WrongBrSet,
    E_PreP_CSIdAwaited, E_PreP_NotEnoughMem);
    {��� � �訡���� �� �⠤�� �९���ᨭ�� �ணࠬ��}

    T_SWaitStringErr = (E_WStr_Ok, E_WStr_NotEnclosedStr);
    {�訡�� � ��楤�� WaitString}

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
    {�訡�� �� �������樨 � ����-���}

    T_SIntErr = (E_I_Ok, E_I_StackEmpty, E_I_StackOverflow, E_I_RetStackEmpty,
    E_I_RetStackOverflow, E_I_WrongInputVal, E_I_WrongVar, E_I_UnknownCommand,
    E_I_DivByZero, E_I_WrongModifyOp, E_I_WrongRetAddr, E_I_ParStackEmpty,
    E_I_ParStackOverflow,
    E_I_WrongScrMode, E_I_WrongFileNum, E_I_CantOpenFile, E_I_WrongFileMode,
    E_I_WriteToFileError, E_I_ReadFromFileError, E_I_CloseFileError,
    E_I_CantSeekFile, E_I_UnKnownSpecCmd, E_I_CantInitGraph, E_I_GraphDrvNotExist
    );
    {�訡�� �� ������樨 ����-����}

    T_STransErr = (E_T_Ok, E_T_CodeFileNotExist, E_T_ReqProcNotExist,
    E_T_CodeBlockNotClosed);
    {�訡�� �� �࠭��樨 � ASM}

    {-----------------------���� ����砥��� ���ᥬ-----------------------}
    T_TTokType = (T_TNone, T_TUnKnown, T_TAny, T_TEOL, T_TSpace, T_TImmVal,
    T_TIdent, T_TOpenBr, T_TCloseBr, T_TOpenShBr, T_TCloseShBr,
    T_TOpenSqBr, T_TCloseSqBr, T_TIncStack, T_TLet, T_TRandom,
    T_TAdd, T_TSub, T_TMul, T_TDiv, T_TRem, T_TMod, T_TExe, T_TSign,
    T_T10, T_TSqr, T_TPow, T_TBigger, T_TEqual, T_TLess, T_TSpec, T_TCond,
    T_TSQuote, T_TString, T_TSlash, T_TDot, T_TColon);

    {------------------------------���⪮�-------------------------------}
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
    {--------------------����ன�� ��������------------------------}
    C_LIntVer = '3.041';
    {����� ��������}
    C_SMaxGetMemSize = CMaxBuf;
    {����쪮 ���ᨬ��쭮 ����� 堯���� ����� � ���� 㪠��⥫�}
    C_SMaxStrLen = 255;
    {���ᨬ��쭠� ����� ��室��� ��ப�}
    C_SMaxStrCount = High(T_SProgLengthType);
    {���ᨬ��쭮� ����� ��ப �ணࠬ��}
    C_SMaxLabelCount = 2048;
    {���ᨬ��쭮� ����� ��⮪ � ����ணࠬ�}
    C_SMaxVarCount = C_SMaxGetMemSize Div SizeOf(T_SVarType);
    {���ᨬ��쭮� �᫮ ��६����� ����㯭�� �ணࠬ��}
    C_SMaxStackSize = 128;
    {���ᨬ���� ࠧ��� �⥪� ��� � �祩��� (�⠭���⭮�� ⨯� ��६�����)}
    C_SMaxRetStackSize = 10240;
    {���ᨬ���� ࠧ��� �⥪� ������ � �祩��� (�⠭���⭮�� ⨯� ��६�����)}
    C_SMaxParStackSize = 10240;
    {���ᨬ���� ࠧ��� �⥪� ��ࠬ��஢ � �祩��� (�⠭���⭮�� ⨯� ��६�����)}
    C_SMaxFileCount = 15;
    {���ᨬ��쭮� ������⢮ 䠩���}
    C_SMaxIdentLen = 20;
    {���ᨬ��쭠� ����� �����䨪���}

    {��१�ࢨ஢���� �����䨪���� �몠}
    C_SProgramIdent = 'PROGRAM';
    C_SPushIdent = 'P';   {����� ��� ������� ��⠫������� � �⥪ ��ࠬ��஢}
    C_SGetIdent = 'G';    {����� ��� ������� �����祭�� �� �⥪� ��ࠬ��஢}
    C_SSegIdent = 'S'; C_SMoveMemIdent = 'M'; {Seg, MoveMem}
    {� �� - ���}
    C_SBinIdent = 'B'; C_SHexIdent = 'H'; {BIN, HEX}

    {----------------------------�������-------------------------------}
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
    C_ChUC_RusA = '�';
    C_ChUC_RusZ = '�';
    C_ChDC_Rusa = '�';
    C_ChDC_Rusp = '�';
    C_ChDC_Rusr = '�';
    C_ChDC_Rusz = '�';

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

    {-----------------------���� ᯥ樠���� �㭪権---------------------}
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
    {����쪮 ������ �� ᯥ樠���� �㭪権 �ॡ�� ��ࠬ��஢ �� �⥪�}
    C_CSF_Args: Array [1..C_CSF_Count] Of Byte = (
        1, 3, 5, 4, 3, 1, 2, 2, 2, 3, 2, 3, 1, 4, 1, 1, 4, 5, 5, 5
    );

    {---------------------������� ������ ���⪮��---------------------}
    C_BCSize: Array [Ord(T_BC_WriteStr)..Ord(T_BC_End)] Of Byte = (
        1, 1, 1, 1, 3, 1, 1, 1, 1, 1, 1, 4, 1, 1, 1, 1, 1, 1, 1, 3, 3,
        3, 3, 3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
    );

    {--------------------����⠭�� �࠭����---------------------------}
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


    {------------------------���ᠭ�� �訡��--------------------------}
    {�訡�� �९�����}
    C_PrePErrTexts: Array [Ord(E_PreP_Ok)..Ord(E_PreP_NotEnoughMem)] Of String[66] = (
        'OK',
        '�������� �����䨪���',
        '�������� ᨬ��� "="',
        '��������� ��ப���� ����⠭�',
        '�������� 䠩� �� �������',
        '��� 䠩�� ����ᠭ� ����୮',
        '������᪨� ��뫪� �� �ᯮ�짮����� ��४⨢� "USES"',
        '��ப���� ����⠭� �� ������ ᨬ����� "''"',
        '��ப���� ����⠭� ����ᠭ� ����୮',
        '�஢��� ���������� "USES" ᫨誮� �����',
        '�㡫����騩 �����䨪��� ��� ��४⨢� "DEFINE"',
        '����� �������� ���⮥ ��।������ ��� "DEFINE" ',
        '����ୠ� ⥪�⮢�� ��ப� ��� ������ �뢮�� "["',
        '�� ���������� �ᯮ�짮���� ����� ��ப�',
        '����୮ ���⠢���� ᪮���',
        '�������� �����䨪��� ��⥬� ��᫥��� (H, B)',
        '�९������ �� 墠⠥� ����� ��� ��ࠡ�⪨ �ணࠬ��'
    );
    {�訡�� ���������}
    C_CompErrTexts: Array [Ord(E_P_Ok)..Ord(E_P_ByteCodeTooHuge)] Of String[56] = (
        'OK',
        '��⪠ � 㪠����� ������ �� �������',
        '��⪠ � 㪠����� ������ 㦥 �������',
        '�������� ����� ��ப�, �� ������� ��譨� ᨬ����',
        '�������� ᨬ��� "{"',
        '�������� ᨬ��� "}"',
        '�������� ᨬ��� "="',
        '�������� �����䨪���',
        '�������� �����䨪��� "PROGRAM", �� ⠪ � �� �� ������',
        '������ ��譨� �����䨪��� "PROGRAM"',
        '����ணࠬ�� ���ᠭ� ��᫥ �窨 �室� (PROGRAM)',
        '���⨣��� �।�� ������⢠ ��⮪ � ����ணࠬ�',
        '����⮢�� ����⠭� ����ᠭ� ����୮',
        '�������� ᨬ��� "("',
        '�������� ᨬ��� ")"',
        '�������� ᨬ��� "["',
        '�������� ᨬ��� "]"',
        '�������� ᨬ��� ">"',
        '�������� ᨬ��� "<"',
        '��������� �᫮���, ��� ��� ��⪨',
        '�������� ᯨ᮪ ��ࠬ��஢, ��� ��� ��⪨',
        '������ ��������� ������',
        '������ ��������� �����䨪���',
        '�����㦥� ��������� ᨬ���',
        '��������� ��ࠦ����',
        '�������� �맮� ��楤���',
        '���������� �� 墠⠥� ����� ��� ��ࠡ�⪨ �ணࠬ��',
        '��ப���� ����⠭� �� ������ ᨬ����� "''"',
        '�������� �����䨪��� ��⥬� ��᫥��� (H, B)',
        '�ணࠬ�� ᫨誮� ������, �⮡� ���� ᪮�����஢�����'
    );
    {�訡�� ������樨}
    C_IntErrTexts: Array [Ord(E_I_Ok)..Ord(E_I_GraphDrvNotExist)] Of String[73] = (
        'OK',
        '� �⥪� �� 墠⠥� ���࠭��� ��� �믮������ ⥪�饩 ������樨',
        '�⥪ ��९�����',
        '� �⥪� ������ �� 墠⠥� ���࠭��� ��� �믮������ ⥪�饩 ������樨',
        '�⥪ ������ ��९�����',
        '��᫮��� ���祭�� ������� ����୮. ������ ����',
        '����⪠ �������� � ���������饩 ��६�����',
        '����祭� �������⭠� ��������',
        '����⪠ ������� �� 0 (����樨 "/", "%", "@")',
        '���ࠢ���� ��� ������� ��� �믮������ ������樨 ᠬ�����䨪�樨',
        '������ ���� ������ �� ��楤���',
        '� �⥪� ��ࠬ��஢ �� 墠⠥� ���࠭��� ��� �믮������ ⥪�饩 ������樨',
        '�⥪ ��ࠬ��஢ ��९�����',
        '����⪠ ��⠭����� ��������� ��࠭�� ०�� �������� ~(1)',
        '����⪠ �������� � ���������饬� 䠩��',
        '�訡�� ������ 䠩��',
        '������ ������ ०�� ࠡ��� � 䠩���',
        '�訡�� ����� � 䠩�',
        '�訡�� �⥭�� �� 䠩��',
        '�訡�� ������� 䠩��',
        '�訡�� �� �믮������ ������樨 SEEK ��� 䠩��',
        '����⪠ �맢��� ���������� ᯥ樠���� ������� (������ "~")',
        '�� 㤠���� ���樠����஢��� ����᪨� ०��',
        '�� ������ 䠩� SVGA256.BGI, ����室��� ��� �ᯮ�짮����� ��䨪�'
    );
    {�訡�� �࠭��樨}
    C_TransErrTexts: Array [Ord(E_T_Ok)..Ord(E_T_CodeBlockNotClosed)] Of String[62] = (
        'OK',
        '��������� 䠩� ����ணࠬ� ' + C_Tr_CodeFileName,
        '�� ������ ���� ���ᠭ�� �ॡ㥬�� ����ணࠬ�� � 䠩�� ' + C_Tr_CodeFileName,
        '�� ������ ���� ���� � 䠩�� ' + C_Tr_CodeFileName
    );

    {--------------------��।������ ��� �९�����-------------------}

    C_DDefine = 'DEFINE';
    {����� ��४⨢� DEFINE}
    C_DUses = 'USES';
    {����� ��४⨢� USES}
    C_DDefineValSeparator = C_ChEqual;
    {������, ࠧ�����騩 ��� ��।������ � ��� ⥪��}
    C_DDefineValEncaser = C_ChSQuote;
    {������, �������騩 � ᥡ� �����䨪���}
    C_DMaxStrLen = 255;
    {���ᨬ��쭠� ����� ��ࠡ��뢠���� �९����஬ ��ப�}
    C_DMaxNestSize = 30;
    {���ᨬ��쭮� ����� �஢��� ���������⥩ uses-include 䠩���,
    ���஥ ����� ��ࠡ���� �९�����}
    C_DMaxFileNameLen = 255;
    {���ᨬ��쭠� ����� ����� 䠩��}
    C_DTempFileName = 'temp.tmp';
    {��� �६������ 䠩��}
    C_DMaxReservedIdents = 7;
    {���ᨬ��쭮� ������⢮ ��१�ࢨ஢����� �����䨪��஢, �����
    ����� �ᯮ�짮���� � �ணࠬ��}

    {--------------------�ᯮ��㥬� ⥪�⮢� ����⠭��-------------------}
    C_TError = '�訡��: ';
    C_T_InpChar = '>';
    C_T_CompKey = 'C';
    C_T_TransKey = 'T';
    C_T_StubName = 'INT';
    C_T_StubCreated = 'EXE 䠩� ᮧ��� �ᯥ譮';
    C_T_StubFailed = '�� 㤠���� ᮧ���� EXE 䠩�';
    C_T_AsmCreated = '�ᯥ譮 ᮧ��� ���⨭� ';
    C_T_EasterEgg = 'MLP';
    C_T_RusName = 'RKS.COM';
    C_T_HelpText = 'LInt V' + C_LIntVer + ':'
    + C_EOL + '���_䠩�� - �믮����� 䠩�.'
    + C_EOL + '���_䠩�� ' + C_T_CompKey + ' - ᮧ���� EXE (���⪮�)'
    + C_EOL + '���_䠩�� ' + C_T_TransKey + ' [�᫮] [�᫮]  - �࠭᫨஢��� � ASM'
    + C_EOL + '����� ��ப� - ��室';
    C_TE_FileNotExist = '���� � ⠪�� ������ �� ������';
    C_TE_ProgramDone = '�ணࠬ�� �ᯥ譮 �믮�����';
    C_TE_ProgramFail = '�믮������ �ணࠬ�� ��ࢠ��';
    C_TE_InitFail = '�� 墠⠥� ����� ��� ࠧ��饭�� ������� ������ ��������';
    C_TE_ProgramProcessing = '��ࠡ�⪠ �ணࠬ��... ';
    C_TE_ProgramProcessingDone = '[OK]';

    C_TE_PreProcessError = '�訡�� �।��ࠡ�⪨ �ணࠬ�� #';
    C_TE_CompError = '�訡�� �������樨 �ணࠬ�� #';
    C_TE_ErrFileNameMsg = '  ��� 䠩��: ';
    C_TE_ErrStrNumMsg = '  ����� ��ப�: ';
    C_TE_ErrStrMsg = '  ��ப�: ';

    C_TE_StubNotExist = '���� �������� ��� ���� ���⪮�� �� ������';
    C_TE_TransImpossible = ', �࠭���� ����������';
    C_TE_GodBlessYa = '���� ᪠��� ������, �� �� ࠧ������';

    C_SStrEncaser = C_ChCloseSqBr;
    {������, �������騩 � ᥡ� ⥪�⮢�� ��ப�}

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
    {����誠 =)}

Type
    {��� �⥪� ������}
    T_RS_Type = (T_RS_RetAddr, T_RS_VarVal, T_RS_VarI);
    T_RS = Record
        FType: T_RS_Type;
        FVal: Word;
    End;
    TRetStackArr = Array [1..C_SMaxRetStackSize] Of T_RS;
    TRetStackArrP = ^TRetStackArr;

    {�������� ������: ���ਯ�� � �㫥�� �� 䠪� ������}
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