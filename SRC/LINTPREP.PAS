{$I-} {$A+} {$R-} {$S-} {$Q-} {$G+} {$N+} {$D-} {$L-} {$Y-} {$X-}
Unit LIntPreP;
Interface
Uses
    LMem, LUtils, LIntCons, LIntComp;
Type
    TDefDataP = ^TDefData;
    {�।�⠢��� ����� � ��।������ ����� ��� ��४⨢� DEFINE
    ����� ����砥� � ᥡ� ��뫪� �� ᫥���騩 �����}
    TDefData = Record
        FDef: T_SIdentStr;
        FDefVal: T_SIdentStr;
        FNext: TDefDataP;
    End;

    TPrePResultP = ^TPrePResult;
    TPrePResult = Record
        FIsSuccess: Boolean;
        {�ᯥ譮 ��?}
        FErrorLine: T_SProgLengthType;
        {����� ��ப� � �訡���}
        FErr: T_SPreProcessErr;
        {��� �訡��}
        FErrStr: T_DStr;
        {����� ��ப�, � ���ன �����㦥�� �訡��}
        FFileName: String[C_DMaxFileNameLen];
        {��� 䠩�� � ����� ࠡ�⠥�}
        FPred: TPrePResultP;
        {�����⥫� �� ��뢠���� ��������}
    End;

    Function Process(AFileName: String): TPrePResultP;

Implementation
Var
    SrcF, DstF: Text;
    {���ਯ��� 䠩��� - ���筨�� � �ਥ�����}
    CurStr, TempStr: T_DStr;
    {�६���� ��ப�}
    CurTok: TGetTokenResult;
    {������ ��ࠡ��뢠���� ���ᥬ�}
    CurWaitStr: TWaitStringResult;
    {������� ࠡ��� �㭪樨 WaitString}
    NestI: Word;
    {�஢��� ���������� �맮��� ProcessFile}

    Function IsAbleToAddDefIdent(ADefsP: TDefDataP; AIdent: T_SIdentStr): Boolean; Forward;
    Function IsExistDefIdent(ADefsP: TDefDataP; AIdent: T_SIdentStr): TDefDataP; Forward;
    Function ProcessDefs(Var AResP: TPrePResultP; ADefsP: TDefDataP; AStr: T_DStr): T_DStr; Forward;

    Function ProcessFile(ACaller: TPrePResultP; AFileName: String): TPrePResultP; Forward;

Function Process(AFileName: String): TPrePResultP;
Var
    Res: TPrePResult;
Begin
    {���뢠�� �६����� 䠩� - �ਥ����}
    Assign(DstF, C_DTempFileName);
    ReWrite(DstF);
    {�� ���� �맮� ProcessFile, ᫥����⥫쭮, Uses �� �� �뫮,
    � FPred ������ ���� Nil, � NestI:= 0}
    Res.FPred:= Nil; NestI:= 0;
    {��ࠡ��뢠�� 䠩�}
    Process:= ProcessFile(@Res, AFileName);
    {��᫥ ��ࠡ�⪨ �஥�� ����뢠�� 䠩� �����祭��}
    Close(DstF);
End;

Function ProcessFile(ACaller: TPrePResultP; AFileName: String): TPrePResultP;
Var
    ResP, RetResP, TempResP: TPrePResultP;
    {�࠭�� � ᥡ� १���� ࠡ��� �㭪樨 ��� 䠩��� AFileName}
    HeadDefP, CurDefP: TDefDataP;
    {�����⥫� �� ��ࢮ� � �� ⥪�饥 ��।������ Define}
    SI, LI, I: Integer;
    {������ ᨬ���� � ��ப�, ������ ⥪�饩 ��ப�, �६����� ������}
Begin
    Inc(NestI);
    {������� ���� ��� १���� ࠡ��� �㭪樨}
    ResP:= CreateBuf(SizeOf(ResP^));
    RetResP:= Nil;
    HeadDefP:= Nil; CurDefP:= Nil;

    {�� ���, �� �� ���, ���� �ணࠬ�� �� ������ ���⭮�� ;)}
    With ResP^ Do Begin
        FIsSuccess:= True; FErrorLine:= 0;
        FErr:= E_PreP_Ok; FFileName:= AFileName;
        FErrStr:= ''; FPred:= ACaller;
        {������ �� ����� �� � 䠩��, �� ���ண� ��� �맢��� � Uses =)
        �� ���ଠ�� �ਣ������, ����� �㤥� ������ �஢��� �� 横���᪨�
        uses.}
    End;

    {���뢠�� 䠩�-���筨�}
    Assign(SrcF, AFileName);
    Reset(SrcF);
    {��稭��� �⥭�� � ��ࢮ� ��ப� 䠩��}
    LI:= 0;
    While Not EOF(SrcF) Do With ResP^, CurTok Do Begin
        Inc(LI); SI:= 1;
        ReadLn(SrcF, CurStr);
        FErrorLine:= LI; FErrStr:= CurStr;

        If WaitToken(@CurTok, CurStr, SI, T_TIdent) Then Begin
            TempStr:= UpperCase(FTokStr);
            {�᫨ �� ��४⨢� DEFINE �...}
            If (TempStr = C_DDefine) Then Begin
                {��⠥��� ������� �����. �᫨ �� ��, �...}
                If Not WaitToken(@CurTok, CurStr, SI, T_TIdent) Then Begin
                    FIsSuccess:= False; FErr:= E_PreP_IdentAwaited; Break;
                End;
                {�᫨ �����䨪��� �����४⥭ �...}
                If Not (IsAbleToAddDefIdent(HeadDefP, FTokStr)) Then Begin
                    FIsSuccess:= False; FErr:= E_PreP_BadDefineIdent; Break;
                End;
                {...�᫨ ��, � ᮧ���� ��� ���� ����,
                 �㤠 �����뢠�� ��� ���}
                If MaxAvail < SizeOf(CurDefP^) + 2 Then Begin
                    FIsSuccess:= False; FErr:= E_PreP_NotEnoughMem; Break;
                End;
                CurDefP:= CreateBuf(SizeOf(CurDefP^));
                CurDefP^.FDef:= UpperCase(FTokStr);
                {�᫨ �� ����稫� ᨬ��� = �...}
                If Not WaitToken(@CurTok, CurStr, SI, T_TEqual) Then Begin
                    FIsSuccess:= False; FErr:= E_PreP_EqualAwaited; Break;
                End;
                {��⠥��� ������� ������� ��� ⥪�⮢�� ��ப�}
                If WaitToken(@CurTok, CurStr, SI, T_TAny) Then;
                If Not (FTokStr = C_DDefineValEncaser) Then Begin
                    FIsSuccess:= False; FErr:= E_PreP_StrConstAwaited; Break;
                End;
                {�᫨ �� ��, ⮣�� ⠪ �� ������}
                If Not WaitString(@CurWaitStr, CurStr, SI, C_DDefineValEncaser)
                Then Begin
                    FIsSuccess:= False; FErr:= E_PreP_NotEnclosedStr; Break;
                End;
                {�᫨ ��᫥ ��ப� �� �������਩ � �� ����� ��ப� �...}
                If WaitToken(@CurTok, CurStr, SI, T_TAny) Then;
                If Not ((FTokStr = C_ChRem) Or (FTokStr = C_EOL)) Then Begin
                    FIsSuccess:= False; FErr:= E_PreP_WrongStr; Break;
                End;
                {�᫨ �� ��� - �����뢠�� ���祭�� �����䨪���}
                CurDefP^.FDefVal:= UpperCase(CurWaitStr.FResultStr);
                CurDefP^.FNext:= HeadDefP;
                HeadDefP:= CurDefP;
                CurDefP:= Nil;
            End
            Else If (TempStr = C_DUses) Then Begin
                {�᫨ ��ப�...}
                If Not (WaitToken(@CurTok, CurStr, SI, T_TAny)
                And (FTokStr = C_DDefineValEncaser)) Then Begin
                    FIsSuccess:= False; FErr:= E_PreP_StrConstAwaited; Break;
                End;
                {�᫨ ��ப� � ������ 䠩�� ����ᠭ� �����४⭮ �...}
                If Not WaitString(@CurWaitStr, CurStr, SI, C_DDefineValEncaser)
                Then Begin
                    FIsSuccess:= False; FErr:= E_PreP_NotEnclosedStr; Break;
                End;
                {�᫨ ��᫥ ��ப� �� �������਩ � �� ����� ��ப� �...}
                If WaitToken(@CurTok, CurStr, SI, T_TAny) Then;
                If Not ((FTokStr = C_ChRem) Or (FTokStr = C_EOL)) Then Begin
                    FIsSuccess:= False; FErr:= E_PreP_WrongStr; Break;
                End;
                {�᫨ ��ப� ����� ����, � ⮦� �� ����}
                If (CurWaitStr.FResultStr = '') Or
                (Length(CurWaitStr.FResultStr) > C_DMaxFileNameLen) Then
                With ResP^ Do Begin
                    FIsSuccess:= False; FErr:= E_PreP_WrongFileName; Break;
                End;

                TempStr:= CurWaitStr.FResultStr;
                {�᫨ 㪠������� 䠩�� �� �������...}
                If Not IsFileExist(TempStr) Then Begin
                    FIsSuccess:= False; FErr:= E_PreP_FileNotExist; Break;
                End;
                {�஢��塞 �� 横���᪨� ��뫪�}
                TempResP:= ResP;
                Repeat
                    If TempResP^.FFileName = TempStr Then Begin
                        FIsSuccess:= False; FErr:= E_PreP_LoopUses; Break;
                    End
                    Else
                        TempResP:= TempResP^.FPred;
                Until (TempResP = Nil);  {!!!}
                If Not FIsSuccess Then Break;
                {�஢��塞, �� ��誠������ �� �஢��� ���������� Uses.}
                If NestI + 1 > C_DMaxNestSize Then Begin
                    FIsSuccess:= False; FErr:= E_PreP_StructureTooDeep; Break;
                End;
                {�த� �� ���. ����� ������� 䠩�-���筨�, � ��뢠��
                ४��ᨢ�� ProcessFIle}
                Close(SrcF);
                RetResP:= ProcessFile(ResP, TempStr);
                {RetResP ��뭥 �࠭�� १���� ��ࠡ�⪨ 䠩��
                �஢��塞, �᫨ 䠩� �� ��ࠡ�⠭ � �訡���, �
                �ॡ���� ��� �� ��� ProcessFile, ��࠭�� ����� �訡��}
                If RetResP^.FErr <> E_PreP_Ok Then Begin
                    ResP^:= RetResP^; Break;
                End;
                {�᫨ �� ���, � ����� ᭮�� ���뢠�� ���� 䠩�
                ���筨� � ����⠭�������� ��� ������}
                Assign(SrcF, AFileName);
                Reset(SrcF);
                For I:= 1 To LI Do ReadLn(SrcF, TempStr);
                RetResP:= DestroyBuf(RetResP);
            End
            {����, ᪠���㥬 �� �����䨪����, ��� �㦭�, ������
            ����⠭���� define � �����뢠�� ����祭��� ��ப� � 䠩�}
            Else Begin
                CurStr:= ProcessDefs(ResP, HeadDefP, CurStr);
                If FErr <> E_PreP_Ok Then Break;
                WriteLn(DstF, CurStr);
            End;
            Continue;
        End;

        {�᫨ �� ᫮���� ᨬ��� ���������, � �� ������ ����� ��祣�}
        If CurTok.FTokType = T_TRem Then Continue;
        {����, �᫨ �� ����稫� ������ �뢮�� ��ப�, � ������ � ���
        ������ �� �⮨�, ���⮬� ���� ����砥� ��ப� �
        �����뢠�� �� � ��室, �� �����뢠� �������� ��᫥ ��� �������਩}
        If CurTok.FTokType = T_TOpenSqBr Then Begin
            If Not WaitString(@CurWaitStr, CurStr, SI, C_SStrEncaser) Then Begin
                FIsSuccess:= False; FErr:= E_PreP_WrongTextStr; Break;
            End;
            WriteLn(DstF, C_ChOpenSqBr + CurWaitStr.FResultStr + C_ChCloseSqBr);
            Continue;
        End;
        {�᫨ �� �����, �� �������਩ � �� �뢮� ��ப�, � ���� ��ࠡ��뢠��
        ����⠭����}
        CurStr:= ProcessDefs(ResP, HeadDefP, CurStr);
        If FErr <> E_PreP_Ok Then Break;
        If CurStr <> '' Then WriteLn(DstF, CurStr);
    End;

    Close(SrcF);
    If IOResult <> 0 Then;
    ProcessFile:= ResP;

    {� ��砥, �᫨ �९����஬ �뫠 �����㦥�� �訡��,
    ����� ������� ��譨� ���� � �������᪮� ����� ��᫥
    break. ��� ��� �஢���� ��� 横�� � ���� ࠧ}
    If RetResP <> Nil Then RetResP:= DestroyBuf(RetResP);
    If CurDefP <> Nil Then CurDefP:= DestroyBuf(CurDefP);
    {����⮦��� �� ᮧ����� ��।������ Define}
    CurDefP:= HeadDefP;
    While CurDefP <> Nil Do Begin
        HeadDefP:= CurDefP^.FNext;
        CurDefP:= DestroyBuf(CurDefP);
        CurDefP:= HeadDefP;
    End;
End;

Function ProcessDefs(Var AResP: TPrePResultP; ADefsP: TDefDataP; AStr: T_DStr): T_DStr;
{��ࠡ��뢠�� �室��� ��ப�, ������� �����䨪����-��।������ define
�� ������騩 �� ⥪�� � �����頥� 㦥 ��ࠡ�⠭��� ��ப�.}
Var
    SI, StartSI: Integer;
    ResStr: T_DStr;
    CurDefP: TDefDataP;
    IsOpenBr: Boolean;
Begin
    SI:= 1; ResStr:= ''; IsOpenBr:= False;
    With CurTok Do Repeat
        GetToken(@CurTok, AStr, SI);
        {�஢��塞 �� ���. ᪮���}
        If FTokType = T_TOpenBr Then Begin
            If IsOpenBr Then With AResP^ Do Begin
                FIsSuccess:= False; FErr:= E_PreP_WrongBrSet; Exit;
            End;
            IsOpenBr:= True;
        End;
        {� �� ����. ᪮���}
        If FTokType = T_TCloseBr Then Begin
            If Not IsOpenBr Then With AResP^ Do Begin
                FIsSuccess:= False; FErr:= E_PreP_WrongBrSet; Exit;
            End;
            IsOpenBr:= False;
        End;
        {�᫨ ᫮���� ������, � ������� ����� � ����થ�ᮢ ����� ���}
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
        {�᫨ ᯮ����� �����䨪��� ᯥ樠���� ������, � �ॡ����
        ��筨�� ��⥬� ��᫥���, ��᫥ 祣� ���� �ப����� �� ᨬ����,
        ����� ����뢠���� � 㪠������ ��⥬� ��᫥���, �� ���� �������
        �� � ��室��� ��⮪. �८�ࠧ������� �������� ���������}
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
{����頥� True � ��砥, �᫨ �����䨪��� � ������ AIdent ����� ����
�������� � ᯨ᮪ ��।������ Define (�� �㡫���� ��१�ࢨ஢����
�����䨪��� �몠, � �� �㡫���� 㦥 �������饥 ��।������ Define)
� False � ��⨢��� ��砥}
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
{��� �����䨪���-��।������ define � 㪠����� ������, � �����頥�
㪠��⥫� �� �祩��, � ��砥 �᫨ �� ������, � Nil, �᫨ ���}
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