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

;-----Транслированный код программы-----
	mov dx,Str1 ;[
	mov ah,40h
	mov bx,2
	mov cx,Str1Len
	int 21h
	mov ax,5 ;push
	mov [Remem],ax ;rem
	mov ax,2 ;push
	call GetVar ;$
	call SetVar ;A
	mov dx,Str2 ;[
	mov ah,40h
	mov bx,2
	mov cx,Str2Len
	int 21h
	mov ax,6 ;push
	mov [Remem],ax ;rem
	mov ax,2 ;push
	call GetVar ;$
	call SetVar ;A
	mov dx,Str3 ;[
	mov ah,40h
	mov bx,2
	mov cx,Str3Len
	int 21h
Lab1:	;U
	mov ax,7 ;push
	mov [Remem],ax ;rem
	xor ax,ax ;push 0
	call SetVar ;A
	mov ax,8 ;push
	mov [Remem],ax ;rem
	mov ax,2 ;push
	call SetVar ;A
	mov ax,9 ;push
	mov [Remem],ax ;rem
	mov ax,5 ;push
	call GetVar ;$
	add di,2 ;^
	mov [di],ax
	mov ax,1 ;push
	sub [di],ax ;-
	mov ax,[di]
	sub di,2
	call SetVar ;A
Lab2:	;D
	mov ax,5 ;push
	call GetVar ;$
	add di,2 ;^
	mov [di],ax
	mov ax,8 ;push
	call GetVar ;$
	xor dx,dx ;%
	mov bx,[di]
	xchg ax,bx
	idiv bx
	mov ax,dx
	sub di,2
	test ax,ax ;|
	jnz short $+5 
	inc ax
	jmp short $+4
	xor ax,ax
	test ax,ax ;#()<N>
	jz Lab3
	mov ax,7 ;push
	mov [Remem],ax ;rem
	mov di,RPSt ;clearSt
	mov ax,1 ;push
	call SetVar ;A
Lab3:	;N
	mov ax,8 ;push
	mov [Remem],ax ;rem
	mov ax,8 ;push
	call GetVar ;$
	add di,2 ;^
	mov [di],ax
	mov ax,1 ;push
	add ax,[di] ;+
	sub di,2
	call SetVar ;A
	mov ax,8 ;push
	call GetVar ;$
	add di,2 ;^
	mov [di],ax
	mov ax,1 ;push
	sub [di],ax ;-
	mov ax,[di] ;^
	mov ax,9 ;push
	call GetVar ;$
	sub [di],ax ;-
	mov ax,[di]
	sub di,2
	test ax,ax ;|
	jnz short $+5 
	inc ax
	jmp short $+4
	xor ax,ax
	test ax,ax ;#()<D>
	jz Lab2
	mov ax,7 ;push
	call GetVar ;$
	add di,2 ;^
	mov [di],ax
	mov ax,1 ;push
	sub [di],ax ;-
	mov ax,[di]
	sub di,2
	test ax,ax ;#()<E>
	jz Lab4
	mov ax,2 ;push
	mov [Remem],ax ;rem
	mov di,RPSt ;clearSt
	mov ax,5 ;push
	call GetVar ;$
	call SetVar ;A
Lab4:	;E
	mov ax,5 ;push
	mov [Remem],ax ;rem
	mov ax,5 ;push
	call GetVar ;$
	add di,2 ;^
	mov [di],ax
	mov ax,1 ;push
	add ax,[di] ;+
	sub di,2
	call SetVar ;A
	mov ax,5 ;push
	call GetVar ;$
	add di,2 ;^
	mov [di],ax
	mov ax,1 ;push
	sub [di],ax ;-
	mov ax,[di] ;^
	mov ax,6 ;push
	call GetVar ;$
	sub [di],ax ;-
	mov ax,[di]
	sub di,2
	test ax,ax ;|
	jnz short $+5 
	inc ax
	jmp short $+4
	xor ax,ax
	test ax,ax ;#()<U>
	jz Lab1
	xor ax,ax ;конец программы
	int 16h
	ret
;-----Подпрограммы-----

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

;-----Текстовые константы-----
SysStr1 DB "Числовое значение введено неверно. Повторите ввод", 13, 10, "$"
InitFailStr DB "Not enough memory to store variables", 13, 10, "$"
Str1 DB "From?", 13, 10
Str1Len = 7
Str2 DB "To?", 13, 10
Str2Len = 5
Str3 DB "Go =)", 13, 10
Str3Len = 7

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
