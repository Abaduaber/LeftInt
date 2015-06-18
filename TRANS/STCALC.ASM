Org 256
Use16
Start:
;-----Блок инициализации-----
	mov di,Text
	xor ax,ax
	mov cx,0FFFFh
	sub cx,Text
	dec cx
	rep stosb
	;FIDS
	mov ax,0FFFFh
	mov cx,15
	mov di,FIDS
	rep stosw
	mov ax,cs
	cmp ax,8000h
	jbe InitVars
	mov ah,9
	mov dx,InitFailStr
	int 21h
	ret
InitVars:
	add ax,1000h
	;--ES: Vars--
	mov es,ax
	;--Обнуление переменных--
	xor ax,ax
	xor di,di
	mov cx,8000h
	rep stosw
	mov di,RPSt
	mov si,ParSt
	mov bp,LocSt

	call InitRandom
;-----Транслированный код программы-----
Lab1:	;START
	mov ax,11 ;push
	mov [Remem],ax ;rem
	mov ax,100 ;push
	call SetVar ;A
	mov ax,12 ;push
	mov [Remem],ax ;rem
	mov ax,20 ;push
	call SetVar ;A
	mov ax,11 ;push
	call GetVar ;$
	mov [Remem],ax ;rem
	xor ax,ax ;push 0
	call SetVar ;A
	mov dx,Str1 ;[
	mov ah,40h
	mov bx,2
	mov cx,Str1Len
	int 21h
Lab2:	;NEXT
	mov ax,8 ;push
	mov [Remem],ax ;rem
	mov ax,1 ;push
	call GetVar ;$
	call SetVar ;A
	mov ax,1 ;push
	mov [Remem],ax ;rem
	mov ax,8 ;push
	call GetVar ;$
	call SetVar ;A
	mov ax,8 ;push
	call GetVar ;$
	add di,2 ;^
	mov [di],ax
	mov ax,47 ;push
	sub [di],ax ;-
	mov ax,[di]
	sub di,2
	test ax,ax ;!
	jg short $+6
	jl short $+9
	jmp short $+10
	mov ax,1
	jmp short $+5
	mov ax,-1
	add di,2 ;^
	mov [di],ax
	mov ax,8 ;push
	call GetVar ;$
	add di,2 ;^
	mov [di],ax
	mov ax,59 ;push
	sub [di],ax ;-
	mov ax,[di]
	sub di,2
	test ax,ax ;!
	jg short $+6
	jl short $+9
	jmp short $+10
	mov ax,1
	jmp short $+5
	mov ax,-1
	add ax,[di] ;+
	sub di,2
	test ax,ax ;#()<TSIFRA>
	jz Lab3
	mov ax,8 ;push
	call GetVar ;$
	add di,2 ;^
	mov [di],ax
	mov ax,41 ;push
	sub [di],ax ;-
	mov ax,[di]
	sub di,2
	test ax,ax ;!
	jg short $+6
	jl short $+9
	jmp short $+10
	mov ax,1
	jmp short $+5
	mov ax,-1
	add di,2 ;^
	mov [di],ax
	mov ax,8 ;push
	call GetVar ;$
	add di,2 ;^
	mov [di],ax
	mov ax,48 ;push
	sub [di],ax ;-
	mov ax,[di]
	sub di,2
	test ax,ax ;!
	jg short $+6
	jl short $+9
	jmp short $+10
	mov ax,1
	jmp short $+5
	mov ax,-1
	add ax,[di] ;+
	sub di,2
	test ax,ax ;#()<ZNAK>
	jz Lab4
	mov ax,8 ;push
	call GetVar ;$
	add di,2 ;^
	mov [di],ax
	mov ax,40 ;push
	sub [di],ax ;-
	mov ax,[di]
	sub di,2
	test ax,ax ;#()<OPENS>
	jz Lab7
	mov ax,8 ;push
	call GetVar ;$
	add di,2 ;^
	mov [di],ax
	mov ax,41 ;push
	sub [di],ax ;-
	mov ax,[di]
	sub di,2
	test ax,ax ;#()<CLOSES>
	jz Lab8
	mov ax,8 ;push
	call GetVar ;$
	add di,2 ;^
	mov [di],ax
	mov ax,27 ;push
	sub [di],ax ;-
	mov ax,[di]
	sub di,2
	test ax,ax ;#()<VIXOD>
	jz Lab10
	mov ax,8 ;push
	call GetVar ;$
	add di,2 ;^
	mov [di],ax
	mov ax,13 ;push
	sub [di],ax ;-
	mov ax,[di]
	sub di,2
	test ax,ax ;#()<RESULT>
	jz Lab9
	jmp Lab2 ;#<NEXT>
Lab3:	;TSIFRA
	mov ax,7 ;push
	mov [Remem],ax ;rem
	mov di,RPSt ;clearSt
	mov ax,8 ;push
	call GetVar ;$
	call SetVar ;A
	call Lab11 ;*<EX1>
	jmp Lab2 ;#<NEXT>
Lab4:	;ZNAK
	mov ax,5 ;push
	mov [Remem],ax ;rem
	mov ax,8 ;push
	call GetVar ;$
	call SetVar ;A
	call Lab15 ;*<PRI>
	mov ax,3 ;push
	mov [Remem],ax ;rem
	mov ax,5 ;push
	call GetVar ;$
	call SetVar ;A
	mov ax,5 ;push
	mov [Remem],ax ;rem
	mov ax,12 ;push
	call GetVar ;$
	call GetVar ;$
	call SetVar ;A
	call Lab15 ;*<PRI>
	mov ax,4 ;push
	mov [Remem],ax ;rem
	mov ax,5 ;push
	call GetVar ;$
	call SetVar ;A
	mov ax,3 ;push
	call GetVar ;$
	add di,2 ;^
	mov [di],ax
	mov ax,4 ;push
	call GetVar ;$
	sub [di],ax ;-
	mov ax,[di]
	sub di,2
	test ax,ax ;!
	jg short $+6
	jl short $+9
	jmp short $+10
	mov ax,1
	jmp short $+5
	mov ax,-1
	add di,2 ;^
	mov [di],ax
	mov ax,1 ;push
	add ax,[di] ;+
	sub di,2
	test ax,ax ;|
	jnz short $+5 
	inc ax
	jmp short $+4
	xor ax,ax
	test ax,ax ;#()<ELSE>
	jz Lab5
	mov ax,7 ;push
	mov [Remem],ax ;rem
	mov di,RPSt ;clearSt
	mov ax,12 ;push
	call GetVar ;$
	call GetVar ;$
	call SetVar ;A
	call Lab11 ;*<EX1>
	mov ax,12 ;push
	call GetVar ;$
	mov [Remem],ax ;rem
	mov ax,8 ;push
	call GetVar ;$
	call SetVar ;A
	jmp Lab6 ;#<ENDIF>
Lab5:	;ELSE
	mov ax,12 ;push
	mov [Remem],ax ;rem
	mov ax,12 ;push
	call GetVar ;$
	add di,2 ;^
	mov [di],ax
	mov ax,1 ;push
	add ax,[di] ;+
	sub di,2
	call SetVar ;A
	mov ax,12 ;push
	call GetVar ;$
	mov [Remem],ax ;rem
	mov ax,8 ;push
	call GetVar ;$
	call SetVar ;A
Lab6:	;ENDIF
	mov ax,7 ;push
	mov [Remem],ax ;rem
	mov ax,94 ;push
	call SetVar ;A
	call Lab11 ;*<EX1>
	jmp Lab2 ;#<NEXT>
Lab7:	;OPENS
	mov ax,12 ;push
	mov [Remem],ax ;rem
	mov ax,12 ;push
	call GetVar ;$
	add di,2 ;^
	mov [di],ax
	mov ax,1 ;push
	add ax,[di] ;+
	sub di,2
	call SetVar ;A
	mov ax,12 ;push
	call GetVar ;$
	mov [Remem],ax ;rem
	mov ax,8 ;push
	call GetVar ;$
	call SetVar ;A
	xor ax,ax ;push 0
	test ax,ax ;#()<NEXT>
	jz Lab2
Lab8:	;CLOSES
	mov ax,7 ;push
	mov [Remem],ax ;rem
	mov ax,12 ;push
	call GetVar ;$
	call GetVar ;$
	call SetVar ;A
	call Lab11 ;*<EX1>
	mov ax,12 ;push
	mov [Remem],ax ;rem
	mov ax,12 ;push
	call GetVar ;$
	add di,2 ;^
	mov [di],ax
	mov ax,1 ;push
	sub [di],ax ;-
	mov ax,[di]
	sub di,2
	call SetVar ;A
	mov ax,12 ;push
	call GetVar ;$
	call GetVar ;$
	add di,2 ;^
	mov [di],ax
	mov ax,40 ;push
	sub [di],ax ;-
	mov ax,[di]
	sub di,2
	test ax,ax ;|
	jnz short $+5 
	inc ax
	jmp short $+4
	xor ax,ax
	add di,2 ;^
	mov [di],ax
	mov ax,12 ;push
	call GetVar ;$
	test ax,ax ;!
	jg short $+6
	jl short $+9
	jmp short $+10
	mov ax,1
	jmp short $+5
	mov ax,-1
	add di,2 ;^
	mov [di],ax
	mov ax,1 ;push
	sub [di],ax ;-
	mov ax,[di]
	sub di,2
	add ax,[di] ;+
	sub di,2
	test ax,ax ;#()<CLOSES>
	jz Lab8
	mov ax,12 ;push
	mov [Remem],ax ;rem
	mov di,RPSt ;clearSt
	mov ax,12 ;push
	call GetVar ;$
	add di,2 ;^
	mov [di],ax
	mov ax,1 ;push
	sub [di],ax ;-
	mov ax,[di]
	sub di,2
	call SetVar ;A
	xor ax,ax ;push 0
	test ax,ax ;#()<NEXT>
	jz Lab2
Lab9:	;RESULT
	mov ax,7 ;push
	mov [Remem],ax ;rem
	mov ax,12 ;push
	call GetVar ;$
	call GetVar ;$
	call SetVar ;A
	call Lab11 ;*<EX1>
	mov ax,12 ;push
	mov [Remem],ax ;rem
	mov ax,12 ;push
	call GetVar ;$
	add di,2 ;^
	mov [di],ax
	mov ax,1 ;push
	sub [di],ax ;-
	mov ax,[di]
	sub di,2
	call SetVar ;A
	mov ax,12 ;push
	call GetVar ;$
	add di,2 ;^
	mov [di],ax
	mov ax,20 ;push
	sub [di],ax ;-
	mov ax,[di]
	sub di,2
	test ax,ax ;|
	jnz short $+5 
	inc ax
	jmp short $+4
	xor ax,ax
	test ax,ax ;#()<RESULT>
	jz Lab9
	mov ax,1 ;push
	mov [Remem],ax ;rem
	mov di,RPSt ;clearSt
	mov ax,10 ;push
	call SetVar ;A
	mov ax,2 ;push
	mov [Remem],ax ;rem
	mov ax,100 ;push
	call GetVar ;$
	call SetVar ;A
Lab10:	;VIXOD
	xor ax,ax ;конец программы
	int 16h
	ret
;-----Подпрограммы-----
Lab11:	;EX1
	mov ax,7 ;push
	call GetVar ;$
	add di,2 ;^
	mov [di],ax
	mov ax,41 ;push
	sub [di],ax ;-
	mov ax,[di]
	sub di,2
	test ax,ax ;!
	jg short $+6
	jl short $+9
	jmp short $+10
	mov ax,1
	jmp short $+5
	mov ax,-1
	add di,2 ;^
	mov [di],ax
	mov ax,7 ;push
	call GetVar ;$
	add di,2 ;^
	mov [di],ax
	mov ax,48 ;push
	sub [di],ax ;-
	mov ax,[di]
	sub di,2
	test ax,ax ;!
	jg short $+6
	jl short $+9
	jmp short $+10
	mov ax,1
	jmp short $+5
	mov ax,-1
	add ax,[di] ;+
	sub di,2
	test ax,ax ;#()<O_AR>
	jz Lab13
	mov ax,7 ;push
	call GetVar ;$
	add di,2 ;^
	mov [di],ax
	mov ax,94 ;push
	sub [di],ax ;-
	mov ax,[di]
	sub di,2
	test ax,ax ;#()<O_UP>
	jz Lab12
	mov ax,7 ;push
	call GetVar ;$
	add di,2 ;^
	mov [di],ax
	mov ax,47 ;push
	sub [di],ax ;-
	mov ax,[di]
	sub di,2
	test ax,ax ;!
	jg short $+6
	jl short $+9
	jmp short $+10
	mov ax,1
	jmp short $+5
	mov ax,-1
	add di,2 ;^
	mov [di],ax
	mov ax,7 ;push
	call GetVar ;$
	add di,2 ;^
	mov [di],ax
	mov ax,59 ;push
	sub [di],ax ;-
	mov ax,[di]
	sub di,2
	test ax,ax ;!
	jg short $+6
	jl short $+9
	jmp short $+10
	mov ax,1
	jmp short $+5
	mov ax,-1
	add ax,[di] ;+
	sub di,2
	test ax,ax ;#()<O_TSI>
	jz Lab14
	ret ;**
Lab12:	;O_UP
	mov ax,11 ;push
	mov [Remem],ax ;rem
	mov di,RPSt ;clearSt
	mov ax,11 ;push
	call GetVar ;$
	add di,2 ;^
	mov [di],ax
	mov ax,1 ;push
	add ax,[di] ;+
	sub di,2
	call SetVar ;A
	mov ax,11 ;push
	call GetVar ;$
	mov [Remem],ax ;rem
	xor ax,ax ;push 0
	call SetVar ;A
	ret ;**
Lab13:	;O_AR
	mov ax,11 ;push
	call GetVar ;$
	add di,2 ;^
	mov [di],ax
	mov ax,1 ;push
	sub [di],ax ;-
	mov ax,[di]
	mov [Remem],ax ;rem
	mov di,RPSt ;clearSt
	mov ax,11 ;push
	call GetVar ;$
	add di,2 ;^
	mov [di],ax
	mov ax,1 ;push
	sub [di],ax ;-
	mov ax,[di]
	sub di,2
	call GetVar ;$
	add di,2 ;^
	mov [di],ax
	mov ax,11 ;push
	call GetVar ;$
	call GetVar ;$
	add di,2 ;^
	mov [di],ax
	mov ax,7 ;push
	call GetVar ;$
	call ExeCmd ;"
	call SetVar ;A
	mov ax,11 ;push
	mov [Remem],ax ;rem
	mov ax,11 ;push
	call GetVar ;$
	add di,2 ;^
	mov [di],ax
	mov ax,1 ;push
	sub [di],ax ;-
	mov ax,[di]
	sub di,2
	call SetVar ;A
	ret ;**
Lab14:	;O_TSI
	mov ax,11 ;push
	call GetVar ;$
	mov [Remem],ax ;rem
	mov ax,11 ;push
	call GetVar ;$
	call GetVar ;$
	add di,2 ;^
	mov [di],ax
	mov ax,10 ;push
	imul word [di] ;*
	mov [di],ax ;^
	mov ax,7 ;push
	call GetVar ;$
	add di,2 ;^
	mov [di],ax
	mov ax,48 ;push
	sub [di],ax ;-
	mov ax,[di]
	sub di,2
	add ax,[di] ;+
	sub di,2
	call SetVar ;A
	ret ;**
Lab15:	;PRI
	mov ax,5 ;push
	mov [Remem],ax ;rem
	mov ax,5 ;push
	call GetVar ;$
	add di,2 ;^
	mov [di],ax
	mov ax,42 ;push
	sub [di],ax ;-
	mov ax,[di]
	sub di,2
	call SetVar ;A
	mov ax,5 ;push
	mov [Remem],ax ;rem
	mov ax,5 ;push
	call GetVar ;$
	test ax,ax ;|
	jnz short $+5 
	inc ax
	jmp short $+4
	xor ax,ax
	add di,2 ;^
	mov [di],ax
	mov ax,3 ;push
	imul word [di] ;*
	mov [di],ax ;^
	mov ax,5 ;push
	call GetVar ;$
	add di,2 ;^
	mov [di],ax
	mov ax,1 ;push
	sub [di],ax ;-
	mov ax,[di]
	sub di,2
	test ax,ax ;|
	jnz short $+5 
	inc ax
	jmp short $+4
	xor ax,ax
	add di,2 ;^
	mov [di],ax
	mov ax,5 ;push
	call GetVar ;$
	add di,2 ;^
	mov [di],ax
	mov ax,3 ;push
	sub [di],ax ;-
	mov ax,[di]
	sub di,2
	test ax,ax ;|
	jnz short $+5 
	inc ax
	jmp short $+4
	xor ax,ax
	add di,2 ;^
	mov [di],ax
	mov ax,2 ;push
	imul word [di] ;*
	mov [di],ax ;^
	mov ax,5 ;push
	call GetVar ;$
	add di,2 ;^
	mov [di],ax
	mov ax,5 ;push
	sub [di],ax ;-
	mov ax,[di]
	sub di,2
	test ax,ax ;|
	jnz short $+5 
	inc ax
	jmp short $+4
	xor ax,ax
	add di,2 ;^
	mov [di],ax
	mov ax,4 ;push
	imul word [di] ;*
	sub di,2
	add ax,[di] ;+
	sub di,2
	add ax,[di] ;+
	sub di,2
	add ax,[di] ;+
	sub di,2
	call SetVar ;A
	ret ;**

;-----Чтение из переменной----- AX = значение переменной
GetVar:
	mov bx,ax
	dec bx
	jz InpChar
	dec bx
	jz InpVal
	add bx,bx
	mov ax,[es:bx]
	ret
InpVal:
	push si
	push di
	push bp
AfterPush:
	mov ah,0ah
	mov dx,BufSize
	mov [BufLen],7
	int 21h
	xor di,di
	xor ax,ax
	mov cl,[BufLen]
	xor ch,ch
	xor bx,bx
	mov si,cx
	mov cl,10
	xor bp,bp
	cmp byte [Text+di],'-'
	jne ConvToBin
	inc bp
	inc di
ConvToBin:
	mov bl,byte [Text+di]
	sub bl,"0"
	jb OneError
	cmp bl,9
	ja OneError
	mul cx
	add ax,bx
	inc di
	cmp di,si
	jb ConvToBin
AfterAll:
	dec bp
	jnz NotNeg
	neg ax
NotNeg:
	mov bx,ax
	mov ah,6
	mov dl,10
	int 21h
	mov ax,bx
	pop bp
	pop di
	pop si
	ret
InpChar:
	xor ax,ax
	int 16h
	xor ah,ah
	ret
OneError:
	mov dx,SysStr1
	mov ah,9
	int 21h
	jmp AfterPush

;-----Запись в переменную----- номер в [Remem], значение на стеке
SetVar:
	dec word [Remem]
	add di,2
	mov [di],ax
	mov dx,di
	mov di,RPSt
SetNextVar:
	inc word [Remem]
	add di,2
	cmp di,dx
	ja SetDone
	mov ax,[di]
	mov bx,[Remem]
	dec bx
	jz OutChar
	dec bx
	jz OutVal
	add bx,bx
	mov [es:bx],ax
	jmp SetNextVar
SetDone:
	mov di,RPSt
	ret
OutVal:
	push si
	push ax
	push dx
	mov si,Text
	test ax,ax
	jns m0
	neg ax
	mov [si],byte '-'
	inc si
m0:
	mov bx,10
	xor cx,cx
m1:
	xor dx,dx
	idiv bx
	push dx
	inc cx
	test ax,ax
	jnz m1
m2:
	pop ax
	add al,"0"
	mov [si],al
	inc si
	loop m2
	mov [si],word 3338
	add si,2
	mov [si],byte '$'
	mov dx,Text
	mov ah,9
	int 21h
	pop dx
	pop ax
	pop si
	jmp SetNextVar
OutChar:
	push ax
	mov ah,0eh
	xor bh,bh
	int 10h
	pop ax
	jmp SetNextVar

;-----Инициализация и генерация случайного числа-----
InitRandom:
	mov ah,2ch
	int 21h
	mov word [RandSeed],cx
	mov word [RandSeed+2],dx
	ret
RandSeed DD ?
RandVal DW 8405h
GetRandom:
	push si
	mov si,ax
	mov ax,word [RandSeed]
	mov bx,word [RandSeed+2]
	mov cx,dx
	mul [RandVal]
	shl cx,3
	add ch,cl
	add dx,cx
	add dx,bx
	shl bx,2
	add dx,bx
	add dh,bl
	shl bx,5
	add dh,bl
	add ax,1
	adc dx,0
	mov word [RandSeed],ax
	mov word [RandSeed+2],dx
	mov cx,dx
	mul si
	mov ax,cx
	mov cx,dx
	mul si
	add ax,cx
	adc dx,0
	mov ax,dx
	pop si
	ret

;-----Выполнение команды модификации (код в AX)-----
ExeCmd:
	mov bl,al
	mov ax,[di]
	sub di,2
	cmp bl,"0"
	jl ExeCmd2
	cmp bl,"9"
	jg ExeCmd2
	jmp ExeValue
ExeCmd2:
	cmp bl,"+"
	je ExeAdd
	cmp bl,"-"
	je ExeSub
	cmp bl,"*"
	je ExeMul
	cmp bl,"/"
	je ExeDiv
	cmp bl,"%"
	je ExeMod
	cmp bl,"^"
	je ExeIncS
	cmp bl,"!"
	je ExeSign
	cmp bl,"|"
	je Exe10
	cmp bl,"@"
	je ExeSqr
	cmp bl,"&"
	je ExePow
	cmp bl,"$"
	je ExeReadVar
	cmp bl,"g"
	je ExeGet
	cmp bl,"G"
	je ExeGet
	cmp bl,"p"
	je ExePut
	cmp bl,"P"
	je ExePut
	cmp bl,"?"
	je ExeRandom
	jmp ExeBad
ExeValue:
	sub bl,"0"
	mov cx,ax
	shl ax,3
	add ax,cx
	add ax,cx
	add ax,bx
	ret
ExeAdd:
	add ax,[di] ;+
	sub di,2
	ret
ExeSub:
	sub [di],ax ;-
	mov ax,[di]
	sub di,2
	ret
ExeMul:
	imul word [di] ;*
	sub di,2
	ret
ExeDiv:
	xor dx,dx ;/
	mov bx,ax
	mov ax,[di]
	sub di,2
	idiv bx
	ret
ExeMod:
	xor dx,dx ;%
	mov bx,ax
	sub ax,[di]
	sub di,2
	idiv bx
	mov ax,dx
	ret
ExeIncS:
	add di,2 ;^
	mov [di],ax
	ret
ExeSign:
	test ax,ax
	jg short $+6
	jl short $+9
	jmp short $+10
	mov ax,1
	jmp short $+5
	mov ax,-1
	ret
Exe10:
	test ax,ax
	jnz short $+5
	inc ax
	jmp short $+4
	xor ax,ax
	ret
ExeSqr:
	mov bx,1
	xor cx,cx
	sub ax,bx
	add bx,2
	inc cx
	cmp ax,bx
	jge short $-8
	mov ax,cx
	ret
ExePow:
	mov cx,ax
	mov ax,1
	mov bx,[di]
	sub di,2
	imul bx
	dec cx
	jnz short $-3
	ret
ExeReadVar:
	call GetVar
	ret
ExeGet:
	mov ax,[si]
	sub si,2
	ret
ExePut:
	add si,2
	mov [si],ax
	ret
ExeRandom:
	call GetRandom
	ret
ExeBad:
	mov dx,SysStr2
	mov ah,9
	int 21h
	xor ax,ax
	int 16h
	int 20h

;-----Текстовые константы-----
SysStr1 DB "Числовое значение введено неверно. Повторите ввод", 13, 10, "$"
InitFailStr DB "Not enough memory to store variables", 13, 10, "$"
SysStr2 DB "Неправильный код команды для выполнения инструкции самомодификации", 13, 10, "$"
Str1 DB "Введите выражение", 13, 10
Str1Len = 19

;-----Буфер, стек ОПЗ, переменные-----
If $ Mod 2 = 1
	nop
End If
Remem DW 0
BufSize DB 6
BufLen DB 0
Text = $
RPSt = $ + 256
ParSt = $ + 512
LocSt = $ + 1536
FIDS = $ + 2560
