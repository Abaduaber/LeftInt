Uses 'Graph.SUF'
Define Str1Start='400'
Define PeoR='1000' ;����ࠦ���� ��ࠡ�� ��ப�
Define Sht='1600' ;������ �ࠣ
Define Menok='1800' ;�।��� �ࠣ
Define Shot='2200' ;�����
Define Urg='2260' ;���� ���� �ࠣ =).
Define Star='2730'
Define Star2='2830'
Define Filler='3050' ;��୮� ����ࠦ����. �⮡� �����.

;-----���� ��६���� ��� 㪠����묨 ����ࠬ� �����----
Define Regs='500' ;��� ����� ॣ�����
Define Score='5' 
Define XP='10' ;������ X ��襣� ��ࠡ��
Define YP='11' ;���⢥��⢥���, Y
Define XDir='12' ;���ࠢ����� �� X ��襣� ��ࠡ��
Define CurKey='13' ;᪠� ��� ⥪�饩 ����⮩ ������.
Define EShipC='14' ;���稪 �᫠ �ࠣ��
Define ShotC='15' ;����饥 ������⢮ ᭠�冷�
Define ShotWait='16' ;��࠭��⥫� ��५�� (�⮡� ᫨誮� ��� �� ��५�)
Define EnemyWait='17' ;��࠭��⥫� ������ ����� �ࠣ��.

;������� EnemyPictures: 0 - ���� ��६����� � ���� ����ࠦ����� �ࠣ�, 1 - � ����, 2 - � ���쨬
Define EnemyPictures='18'
;������� StarsPictures: 0 - ���� ��६����� � ��ࢮ� ����ࠦ����� ������, 1 - � ����, �.�.�
Define StarsPictures='21'
Define StarC='30' ;����饥 ������⢮ �����
Define StarWait='31' ;����প� ������ ����� �����
Define StarDrawWait='32' ;����প� ���ᮢ�� �����

;������� EShips: 
	;EShips$. 1 - ������, 2 - �।���, 3 - ����让, 0 - ���.
	;EShips^1+. X ���न���
	;Eships^2+. Y ���न���
	;Eships^3+. ���� ����ࠦ����
	;Eships^4+. - ᫥���騩 ��ࠡ�� �.�.�.

;������� Shots:
	;Shots$. 1 - ᭠�� ����. 0 - ����
	;Shots^1+. X ���न���
	;Shots^2+. Y ���न���
	;Shots^3+ - ᫥���騩 ᭠�� �.�.�

;������� Stars:
	;Stars$. ����� 0 - ������ ����. 0 - ����
	;Stars$^1+. X ���न���
	;Stars$^2+. Y ���न���
	;Stars$^3+. ���� ����ࠦ����
	;Start$^4+ - ᫥�����

Define EShips='50'
Define Shots='150'
Define Stars='250'

;----����⠭��-----
Define Scr13='19'
Define TextMode='3'
Define Speed='1' ;���� ᪮����. ���� �� �ண���, � � ���������� �� �ᥬ ����.
Define PSpeed='2' ;������� ��ࠡ�� ��ப�.
Define MaxEShip='10' ;���ᨬ��쭮� ������⢮ �ࠣ�� �����६����
Define MaxShots='15' ;���ᬠ�쭮� ������⢮ ᭠�冷� �����६����
Define ShotWaitVal='20' ;��࠭��⥫� ��५�� - 祬 ����� �᫮, ⥬ ०� ࠧ�蠥��� ��५���
Define EnemyWaitVal='40' ;���砩��� �᫮ - ��࠭��⥫� ������ ᫥���饣� ��⨢����. ��� ����� - ⥬ ०�.
Define EnemyWaitValInc='40' ;������ ��࠭��⥫� ������ ᫥���饣� ��⨢����. ��� ����� - ⥬ ०�.
Define WinScore='200' ;������⢮ �窮�, ���஥ �㦭� ������ ��� ������ ;)
Define MaxStars='15' ;���ᨬ��쭮� ������⢮ ����� 
Define StarWaitVal='40'; �६� ����প� ��। ������� ����� ������
Define StarDrawWaitVal='3' ;������� �����

={CreateStar}= ;������� ����� ������
	?[3]
	#(StarC$^MaxStars-)<AfterCreateStar> 
	$(3)(Stars^4-)
	{CheckNextStar}
		$(3)(3$^4+)
		#(Stars^MaxStars^4*+^3$-)<AfterCreateStar>
		#(3$$|)<CheckNextStar>
		$(3$)(2?^1+)
		$(3$^1+)(310?,1,3$$^StarsPictures+^1-$)
		$(StarC)(StarC$^1+) 
		$(StarWait)(StarWaitVal)
	{AfterCreateStar}	
**

={DrawStars}= ;�뢮��� �� ������
	?[3]
	$(3)(Stars^4-)
	{CheckDNextStar}
		$(3)(3$^4+)
		#(Stars^MaxStars^4*+^3$-)<AfterDrawStars>
		#(3$$)<CheckDNextStar>
		#(199^3$^2+$^3$^3+$^1+$+- !^1+)<DestroyStar> ;�᫨ ����⥫� �� �ࠩ ��࠭�, � ��ᨬ
		*[3$^1+$,3$^2+$,3$^3+$]<Draw> ;���㥬 ������
		$(3$^2+)(3$^2+$^Speed+) ;������ ���� ����
		#<CheckDNextStar>
	{DestroyStar}
		$(3$)(0)
		$(StarC)(StarC$^1-)
		$(Filler)(3$^3+$$,3$^3+$^1+$) ;;���塞 ��ࠬ���� 䨫���
		*[3$^1+$,3$^2+$,Filler]<Draw> 
		#<CheckDNextStar>	
	{AfterDrawStars}
	$(StarDrawWait)(StarDrawWaitVal)	
**

={CreateShot}= ;"����५�����" ���� ᭠��
	?[3]
	#(ShotC$^MaxShots-)<AfterCreateShot> ;�᫨ ᭠�冷� ᫨誮� �����, � �� ᮧ������ ����
	$(3)(Shots^3-) ;��筥� � �।-��ࢮ�� ᭠�鸞
	{CheckNextShot}
		$(3)(3$^3+) ;��३��� � ᫥���饬� ᭠���
		;�஢�ਬ, �� �����稫�� �� ��� ᢮���ࠧ�� "���ᨢ"?
		#(Shots^MaxShots^3*+^3$-)<AfterCreateShot>
		#(3$$|)<CheckNextShot> ;�᫨ ᭠�� ����, � ��३��� � ᫥���饬�
		;�᫨ �� ᭠�鸞 ��� ���, � ����� ᮧ���� ����.
		;����� ����, X - �� 業��� ��襣� ��ࠡ��, Y - ���� ��� ��襣� ��ࠡ��
		$(3$)(1,XP$^PeoR$^2/+^Shot$^2/-,YP$^Shot^1+$-)
		$(ShotC)(ShotC$^1+) ;�����稬 ���稪 ᭠�冷� �� 1.
		$(ShotWait)(ShotWaitVal) ;�������� �� ᫥���饣� ����५�
	{AfterCreateShot}
**

={DrawShots}= ;����� �� ᭠��� �� ��࠭�, ��६�頥� �� ��᫥ �뢮��. ������ ����⥢訥 �� �ࠩ ��࠭� ᭠���.
	?[3]
	$(3)(Shots^3-) ;��筥� � �।-��ࢮ�� ᭠�鸞
	{CheckDNextShot}
		$(3)(3$^3+) ;��३��� � ᫥���饬� ᭠���
		;�஢�ਬ, �� �����稫�� �� ��� ᢮���ࠧ�� "���ᨢ"?
		#(Shots^MaxShots^3*+^3$-)<AfterDrawShot>
		#(3$$)<CheckDNextShot> ;�᫨ ᭠�鸞 ���, � ��३��� � ᫥���饬�.
		;���� ������ �஢�ન
		#(3$^2+$)<DestroyShot> ;�� 㫥⥫ �� ᫨誮� ��᮪�?
		*[3$^1+$,3$^2+$,Shot]<Draw> ;���㥬 ᭠��
		$(3$^2+)(3$^2+$^Speed-) ;����� ���� �����
		#<CheckDNextShot>
	{DestroyShot}
		$(3$)(0) ;����塞 ᭠�� �� ���ᨢ�
		$(ShotC)(ShotC$^1-) ;�����蠥� ���稪 ᭠�冷�.
		$(Score)(Score$^1-) ;���塞 �窨
		$(Filler)(Shot$^Shot^1+$) ;���塞 ��ࠬ���� 䨫���
		*[3$^1+$,3$^2+$,Filler]<Draw> ;��ࠥ� ���� ᭠��
		#<CheckDNextShot>	
	{AfterDrawShot}
**

={CreateEnemy}= ;������� ������ �ࠣ� � ��砩�묨 ���न��⠬�
	?[3]
	#(EShipC$^MaxEShip-)<AfterCreateEnemy> ;�᫨ �ࠣ�� ᫨誮� �����, � �� ᮧ������ ������
	$(3)(EShips^4-) ;��筥� � �।-��ࢮ�� ��ࠡ��
	{CheckNextEnemy}
		$(3)(3$^4+) ;��३��� � ᫥���饩 �祩��.
		;�஢�ਬ, �� �����稫�� �� ��� ᢮���ࠧ�� "���ᨢ"?
		#(EShips^MaxEShip^4*+^3$-)<AfterCreateEnemy>
		#(3$$|)<CheckNextEnemy> ;�᫨ ��ࠡ�� ��� ����, � ��३��� � ᫥���饬�
	{CreateNewEnemy}
		$(3$)(3?^1+) ;������� ��砩�� ��ࠡ��, � ���� ��� ����室���� ����ࠦ����
		$(3$^1+)(260?^10+,2,3$$^EnemyPictures+^1-$) ;���砩��� ���न��� �� X, � 2 �� Y, ����ࠦ���� �� ���ᨢ�
		$(EShipC)(EShipC$^1+) ;� 㢥��稬 ���稪 �ࠣ�� �� 1.
		$(EnemyWait)(EnemyWaitVal?^EnemyWaitValInc+) ;������騩 �ࠣ ����� ���� �����.
	{AfterCreateEnemy}
**

={DrawEnemy}= ;����� ��� �ࠣ�� �� ��࠭�
	?[3]
	$(3)(EShips^4-) ;��筥� � �।-��ࢮ�� ��ࠡ��
	{CheckDNextEnemy}
		$(3)(3$^4+) ;��३��� � ᫥���饬� ��ࠡ��.
		;�஢�ਬ, �� �����稫�� �� ��� ᢮���ࠧ�� "���ᨢ"?
		#(EShips^MaxEShip^4*+^3$-)<AfterDrawEnemy>
		#(3$$)<CheckDNextEnemy> ;�᫨ ��ࠡ�� ��� ���������, � ��३��� � ᫥���饬�
		;���� ��稭��� �஢�ન
		#(199^PeoR^1+$-^3$^2+$^3$^3+$^1+$+-)<DestroyEnemy> ;�᫨ ����⥫ �� �ࠩ ��࠭�, � ���㡠��
		*[3$^1+$,3$^2+$,3$^3+$]<Draw> ;���㥬 ��ࠡ��
		$(3$^2+)(3$^2+$^Speed+) ;��ࠡ�� ���� ����
		#<CheckDNextEnemy> ;��३��� � ᫥���饬� ��ࠡ��
	{DestroyEnemy}
		$(Score)(Score$^3$$-) ;���塞 �窨 - �� ����让 ��ࠡ�� �����, �� ������ �����.
		$(3$)(0) ;����塞 ��ࠡ�� �� ���ᨢ�
		$(EShipC)(EShipC$^1-) ;�����蠥� ���稪 �ࠣ��.
		$(Filler)(3$^3+$$,3$^3+$^1+$) ;;���塞 ��ࠬ���� 䨫���
		*[3$^1+$,3$^2+$,Filler]<Draw> ;��ࠥ� �ࠣ�
		#<CheckDNextEnemy> ;��३��� � ᫥���饬� ��ࠡ��.	
	{AfterDrawEnemy}
**

={CheckHits}= ;�஢���� �� �⮫�������� ����� ᭠�冷� � ��ࠡ���.
	?[3,4] ;3 - ������ ᭠�鸞, 4 - ������ ��ࠡ��.
	$(3)(Shots^3-) ;��筥� � �।-��ࢮ�� ᭠�鸞
	{CheckNextHit}
		$(3)(3$^3+) ;��३��� � ᫥���饬� ᭠���
		#(Shots^MaxShots^3*+^3$-)<AfterCheckHit> ;�஢�ਬ, �� ���稫��� �� �� ᭠���?
		#(3$$|)<CheckNextCollision> ;�᫨ ᭠�� ����, � ���室�� � �஢�થ
		#<CheckNextHit> ;���� ��६�� �� ᫥���騩 ᭠��
	{CheckNextCollision}
		$(4)(EShips^4-) ;��筥� � �।-��ࢮ�� ��ࠡ��
		{CheckNextShipCol}
			$(4)(4$^4+) ;��३��� � ᫥���饬� ��ࠡ��
			;�஢�ਬ, �� �����稫�� �� ��� ᢮���ࠧ�� "���ᨢ"?
			#(EShips^MaxEShip^4*+^4$-)<CheckNextHit>
			#(4$$|)<CheckNextShipXY> ;�᫨ �� �� ���� ���� ��ࠡ��, � �஢�ਬ ��� ���न����
			#<CheckNextShipCol> ;���� �஢�ਬ ᫥���騩 ��ࠡ��
		{CheckNextShipXY}
			;�᫨ ���न��� ᭠�鸞 �� Y < 祬 �㬬� ���न���� ��ࠡ�� �� Y � ��� ����� � �⮫�������� ���.
			#(3$^2+$^4$^2+$^4$^3+$^1+$+-!^1+|)<CheckNextShipCol>
			;���� �᫨ ���न��� 業�� ᭠�鸞 �����, 祬 ���न��� ��ࠡ�� �� X, �� �����, 祬
			;�㬬� ���न���� ��ࠡ�� �� X � ��� ����� � �窠�, ����� �� ������.
			;���� �஢��塞 ᫥���騩 ��ࠡ��.
			#(3$^1+$^Shot$^2/+,4$^1+$-!^1+,3$^1+$^Shot$^2/+^4$^1+$^4$^3+$$+-!^1-.)<CheckNextShipCol>
		{IncScore}
			;����⮦��� ��ࠡ��, ��ࠥ� ᭠��, � ����塞 �窨 ;).
			$(Score)(Score$^4$$^4--)
			$(Filler)(4$^3+$$,4$^3+$^1+$) ;;���塞 ��ࠬ���� 䨫���
			*[4$^1+$,4$^2+$,Filler]<Draw> ;��ࠥ� �ࠣ�
			$(Filler)(Shot$^Shot^1+$) ;���塞 ��ࠬ���� 䨫���
			*[3$^1+$,3$^2+$,Filler]<Draw> ;��ࠥ� ���� ᭠��
			$(ShotC)(ShotC$^1-) ;����冷� �����
			$(EShipC)(EShipC$^1-) ;�ࠣ�� ⮦� ;)
			$(3$)(0) ;����鸞 ����� ���
			$(4$)(0) ;��ࠡ�� ⮦�
			#<CheckNextHit> ;� � ᫥���饬� ᭠��� - �⮣� ����� ���
	{AfterCheckHit} 
**

Program
*[Regs,Scr13]<Scr> ;��⠭�������� ��࠭�� ०�� 320x200x256
;����㦠�� ���⨭��, ������ � ᢮� ������� �����.
$(Str1Start)('sh.bmp',0)
*[Str1Start,PeoR,1]<BMPLoad> ;������� ��⠭�������� ⮫쪮 ��� ��ࢮ� - ��� ���� ��� ���.
$(Str1Start)('ts.bmp',0)
*[Str1Start,Sht,0]<BMPLoad>
$(Str1Start)('km.bmp',0)
*[Str1Start,Menok,0]<BMPLoad>
$(Str1Start)('r.bmp',0)
*[Str1Start,Shot,0]<BMPLoad>
$(Str1Start)('ku.bmp',0)
*[Str1Start,Urg,0]<BMPLoad>
$(Str1Start)('star.bmp',0)
*[Str1Start,Star,0]<BMPLoad>
$(Str1Start)('star2.bmp',0)
*[Str1Start,Star2,0]<BMPLoad>

;����㥬 � 業�� ��࠭�, ���ࠢ����� ���� ���, �ࠣ�� ���, �� ��५﫨,
;��५��� ����� �ࠧ�, ����প� ��। ������� �ࠣ�, ���� ��� ����ࠦ����
$(XP)(135,198^PeoR^1+$-,0,0,0,0,0,EnemyWaitVal?^EnemyWaitValInc+,Sht,Menok,Urg,Star,Star2)
$(Score)(50) ;��稭��� � 50 �窠��.
$(StarC)(0,0,3) ;������ ����� �ࠧ�, �� ���� �� ����� ���

;��� ����� ��� ������, �� !!!

{DirDown}
$(XDir)(0) ;��ࠡ��稪 ������ ������ ����. ��⠭����������.
#<Loop2>
{DirLeft} ;�᫨ �����, � ���塞 ���ࠢ����� �� �����
$(XDir)(0^PSpeed-)
#<Loop2>
{DirRight} ;�᫨ ��ࠢ�, � ���塞 �� �ࠢ�
$(XDir)(PSpeed)
#<Loop2>

{ScanLoop} ;���� ���������� �ந�室�� ������ ���. ������㥬 �� ��५��, Ctrl � ESC
~(8)(~H60,CurKey)
#(CurKey$^80-)<DirDown>
#(CurKey$^75-)<DirLeft>
#(CurKey$^77-)<DirRight>
*(CurKey$^29-^ShotWait$-)<CreateShot> ;�᫨ ������ ��५��, � ����� ��५���, � ��५塞
#(CurKey$^1-)<EndPrg>

;�᭮���� 横� - ��㥬 ���⨭�� � ᫥���, �⮡� ��ࠡ��� �� 㡥��� �� �।��� ��࠭�
{Loop2}
$(1)('S')
$(1)('c')
$(1)('o')
$(1)('r')
$(1)('e')
$(1)(':')
$(1)(32, Score$)
*[0,0]<GoToXY>

$(StarWait)(StarWait$^StarWait$!-) ;�����蠥� �������� ᫥���饩 ������, �� ⮫쪮 �᫨ �� 0
*(StarWait$)<CreateStar> ;�᫨ ���, � ᮧ���� ����� ������.
$(ShotWait)(ShotWait$^ShotWait$!-) ;�����蠥� �������� ᫥���饣� ����५�, �� ⮫쪮 �᫨ ��� �� ����
*(EnemyWait$)<CreateEnemy> ;�᫨ ���, � ᮧ���� ������ �ࠣ�
$(EnemyWait)(EnemyWait$^1-) ;�����蠥� �������� ᫥���饩 �����樨 �ࠣ�

*<WaitR> ;���� ���⨪��쭮�� ���⭮�� 室� ���.
$(StarDrawWait)(StarDrawWait$^StarDrawWait$!-)
*(StarC$|^StarDrawWait$+)<DrawStars> ;���㥬 ������, �� �᫨ ⮫쪮 ⠪�� ����, � �᫨ �� ��⥪�� ����প�.
*(EShipC$|)<DrawEnemy> ;���㥬 �ࠣ��, �� ⮫쪮 �᫨ ���� ����
*[XP$,YP$,PeoR]<Draw> ;��㥬 ��ࠡ�� ��ப�
*(ShotC$|)<DrawShots> ;���㥬 ᭠���, �� �᫨ ��� ����.
*(ShotC$|)<CheckHits> ;�஢��塞 �� �⮫�������� ᭠�冷� � �ࠣ���, �� ⮫쪮 �᫨ ᭠��� ����. 
$(XP)(XP$^XDir$+) ;��६�頥� ��ࠡ��
#(315^XP$^PeoR$+-!^1+)<StopRight> ;�᫨ ������ � �ࠢ�� �࠭�� ��࠭�, � ��⠭�������.
#(XP$^7-!^1+)<StopLeft> ;�᫨ � �����, � ⮦�
#(Score$^WinScore-!^1-)<Win> ;���ࠫ� ���� �窮�? ������, ��� =)
#(Score$!^1+)<Lose> ;����﫨 ��? ���, �� ;(

#<ScanLoop>

{StopRight}
$(XDir)(0)
$(XP)(XP$^PSpeed-)
#<ScanLoop>
{StopLeft}
$(XDir)(0)
$(XP)(XP$^PSpeed+)
#<ScanLoop>



{Win}
[You won zxD)))]
[Anyway, all your base are belong to us.]
#<WaitForKey>
{Lose}
[Game over, God bless you]
{WaitForKey}
$(3)(2$)
;����� �ணࠬ��, ���� ������ �� ���� �������, � ���뢠�� ���. ०��
{EndPrg}
*[Regs,TextMode]<Scr>
{GlobalEnd}