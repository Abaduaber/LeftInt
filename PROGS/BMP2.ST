;BMP View 2.0. ������ ����� =)
;��ࠢ�� ࠡ��� ��� - ⥯��� ���४⭮ �����뢠���� BMP � �� ������ �� X
;(����筮, ���� � ��������� [1..640]). ����� ������� �뢮������ �᪠����묨.
;�ᯮ���� ����� ����� �몠.

Define Width='100'
Define Height='101'
Define BPP='102'
Define CurByte='103'
Define Red='104'
Define Green='105'
Define Blue='106'
Define I='107'
Define EndSign='108'
Define CurX='109'
Define CurY='110'
Define Mod='111'

Define OpenFile='~(10)'
Define CloseFile='~(13)'
Define WriteVal='$(2)'
Define WriteChar='$(1)'
Define PSet='~(2)'

={InpStr}=
?[3]
$(3)(G)
{INP}
$(3$)(1$)
WriteChar(3$$)
$(3)(3$^1+)
#(3$^1-$^13-|)<INP>
$(3$^1-)(0)
WriteChar(10)
**

={ReadByte}=
;��⠥� �� 䠩��, ��� ����஬ ��ࢮ�� ��।������ ��ࠬ���
;���� ��� ����஬ ��ண� ��।������, ����頥� ��� � ��६����� 3 � �����頥� ��
;��࠭�祭��: ����� ���� ���� � ����஬, �ॢ���騬 32767
?[3]
OpenFile(G,G,2)
~(12)(1,3,EndSign)
P(3$)
**

={ReadNextByte}=
?[3]
~(12)(G,3,EndSign)
P(3$)
**

Program
{START}
[BMP name?]
*[4]<InpStr> ;���� ����� ��ப� � ������ 䠩��
OpenFile(4,1,0)

{ReadHeader}
;��⠥� �����, �ਭ� � ����� ����ࠦ����
*[1,18]<ReadByte>
$(Width)(G)
*[1,19]<ReadByte>
$(Width)(Width$^G^256*+)
*[1,22]<ReadByte>
$(Height)(G)
*[1,23]<ReadByte>
$(Height)(Height$^G^256*+)
*[1,28]<ReadByte>
$(BPP)(G)
{Check}
;�஢��塞 �⮡� ��ࠬ���� ����ࠦ���� �뫨 �����⨬묨
#(BPP$^8-|)<WrongBPP>
#(Width$^640-!^1-)<WrongWidth>
#(Height$^480-!^1-)<WrongHeight> 

$(Mod)(4^Width$^4%-)
#(Mod$^4-|)<LoadPal>
$(Mod)(0)

{LoadPal}
;����㦠�� � ��⠭�������� �������
~(1)(1)
$(CurByte)(54)
$(I)(0)
{SetPal}
*[1,CurByte$]<ReadByte>
$(Blue)(G^4/)
*[1,CurByte$^1+]<ReadByte>
$(Green)(G^4/)
*[1,CurByte$^2+]<ReadByte>
$(Red)(G^4/)
~(14)(I$,Red$,Green$,Blue$)
$(CurByte)(CurByte$^4+)
$(I)(I$^1+)
#(I$^256-|)<SetPal>

;�뢮��� ����ࠦ���� �� ��࠭
$(CurX)(1) ;� �㫥��� �� �뢮���, ��稭��� � 1.
$(CurY)(Height$^1+)
OpenFile(1078,1,2)
{DrawImg}
*[1]<ReadNextByte>
PSet(CurX$,CurY$,G)
$(CurX)(CurX$^1+)
#(CurX$^1-^Width$-|)<DrawImg>

$(I)(Mod$)
#(I$)<AfterDec>
{DecAgain}
$(I)(I$^1-)
*[1]<ReadNextByte>
$(Red)(G)
#(I$|)<DecAgain>

{AfterDec}
$(CurX)(1)
$(CurY)(CurY$^1-)
#(CurY$^1-|)<DrawImg>
#<End>

{WrongBPP}
[Image color depth must be 8]
#<End>
{WrongWidth}
[Image width must be in 1..640]
#<End>
{WrongHeight}
[Image height must be in 1..480]
{End}
CloseFile(1)