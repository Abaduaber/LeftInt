Org 256
Use16
Start:
;-----Транслированный код программы-----
	mov dx,Str1 ;[
	mov ah,40h
	mov bx,2
	mov cx,Str1Len
	int 21h
	xor ax,ax ;конец программы
	int 16h
	ret
;-----Подпрограммы-----

;-----Текстовые константы-----
Str1 DB "Hello world!", 13, 10
Str1Len = 14

