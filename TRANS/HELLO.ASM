Org 256
Use16
Start:
;-----�࠭᫨஢���� ��� �ணࠬ��-----
	mov dx,Str1 ;[
	mov ah,40h
	mov bx,2
	mov cx,Str1Len
	int 21h
	xor ax,ax ;����� �ணࠬ��
	int 16h
	ret
;-----����ணࠬ��-----

;-----����⮢� ����⠭��-----
Str1 DB "Hello world!", 13, 10
Str1Len = 14

