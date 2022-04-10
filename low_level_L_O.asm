TITLE Designing low-level I/O Procedures   (Proj6_rabelosr.asm)

; Author: Riley Rabelos
; Last Modified: 03/13/2022
; OSU email address: rabelosr@oregonstate.edu
; Course number/section: CS271 Section 400
; Project Number: Project 6     Due Date: 03/13/2022
; Description: This file introduces the programmer and program to the user and then has them enter 10 signed numbers as strings. It then converts these strings to integers. From there it will
; calculate both the sum and the average of the numbers entered by the user. The numbers are then converted back to strings and displayed as a list of number. The average and sum are also
; displayed alongside the list of the numbers entered.

INCLUDE Irvine32.inc
; Name: mGetString
;
; Displays a prompt and gets a string from the user. 
;
; Preconditions: None
;
; Recieves:
;	text_prompt		= array address
;	input_loc		= empty array address
;	max_length		= number for max length of a string
;	num_bytes_read	= address to store number of bytes that were inputted
;
; Returns: 
;	input_loc		= String entered by user
;	num_bytes_read	= length of the string

mGetString		MACRO	text_prompt, input_loc, max_length, num_bytes_read
	pushad	
	mov		EDX, text_prompt
	call	WriteString
	mov		ECX, max_length
	mov		EDX, input_loc
	call	ReadString
	mov		[num_bytes_read], EAX
	popad
	ENDM

; Name: mDisplayString
;
; Displays a string.
;
; Preconditions: None
;
; Recieves:
;	string_address	= array address
;
; Returns: None

mDisplayString	MACRO	string_address
	push	EDX
	mov		EDX, string_address
	call	WriteString
	pop		EDX
	ENDM

NUM_OF_NUMS = 10

.data
intro		BYTE	"PROGRAMMING ASSIGNMENT 6: Designing low-level I/O procedures", 13, 10, 0
intro_2		BYTE	"Written by: Riley Rabelos", 13, 10, 13, 10, 0
instruct	BYTE	"Please provide 10 signed decimal integers.", 13, 10, 0
instruct_2	BYTE	"Each number neets to be small enough to fit inside a 32 bit register. After you have finished inputting the raw numbers I will display a list of the integers, their sum, and their average.", 13, 10, 13, 10, 0
prompt_1	BYTE	"Please enter a signed number: ", 0
error		BYTE	"ERROR: You did not enter a signed number or your number was too big",13, 10, 0
try_again	BYTE	"Please try again: ", 0
num_display BYTE	"You entered the following numbers: ", 13, 10, 0
num_sum		BYTE	"The sum of these numbers is: ", 0
trun_avg	BYTE	"The truncated average is: ", 0
goodbye		BYTE	"Thanks for playing!", 0
user_num	BYTE	33 DUP(0)
max_size	DWORD	32 
user_bytes	DWORD	?
str_to_num	DWORD	?
num_to_str	BYTE	33 DUP(0)
actual_str	BYTE	33 DUP(0)
num_array	SDWORD	NUM_OF_NUMS DUP(?)
sep_str		BYTE	", ", 0
sum_num		SDWORD	?
avg_num		SDWORD	?
zero_str	BYTE	"0", 0

.code
main PROC
	push	OFFSET	intro
	push	OFFSET	intro_2
	push	OFFSET	instruct
	push	OFFSET	instruct_2
	call	Introduction
	
	mov		ECX, NUM_OF_NUMS
	mov		EDI, OFFSET num_array

	; Loops through the procedure NUM_OF_NUMS times
_entryLoop:
	mov		str_to_num, 0
	push	OFFSET	try_again
	push	OFFSET	error
	push	OFFSET	str_to_num
	push	OFFSET	user_bytes
	push	max_size
	push	OFFSET	user_num
	push	OFFSET	prompt_1
	call	ReadVal

	mov		EAX, str_to_num
	mov		[EDI], EAX
	add		EDI, 4
	loop	_entryLoop

	mDisplayString	OFFSET num_display

	mov		ECX, NUM_OF_NUMS
	mov		ESI, OFFSET num_array

	; Loops through the array of numbers and converts and displays them.
_changeLoop:
	mov		EAX, [ESI]
	add		ESI, 4
	mov		str_to_num, EAX

	push	OFFSET	zero_str
	push	OFFSET	num_to_str
	push	OFFSET	str_to_num
	call	WriteVal

	; Checks to see if it is the last number in order to see if it needs to display a comma
	_checkSpace:
	cmp		ECX, 1
	je		_endChangeLoop
	mDisplayString	OFFSET sep_str

_endChangeLoop:
	loop	_changeLoop
	call	crlf


	push	OFFSET sum_num
	push	OFFSET num_array
	call	FindSum

	mDisplayString OFFSET num_sum		;Displays the sum of all the numbers
	push	OFFSET	zero_str
	push	OFFSET	num_to_str
	push	OFFSET	sum_num
	call	WriteVal
	call	crlf

	push	OFFSET avg_num
	push	sum_num
	call	FindAvg

	mDisplayString OFFSET trun_avg		;Displays truncated average
	push	OFFSET	zero_str
	push	OFFSET	num_to_str
	push	OFFSET	avg_num
	call	WriteVal
	call	crlf

	push	OFFSET	goodbye
	call	Farewell
	Invoke ExitProcess,0	; exit to operating system
main ENDP


; Name: Introduction
;
; Introduces the program and programmer to the user
;
; Preconditions: intro, intro_2, instruct, and instruct_2 are strings that introduce the programmer and explain the rules of the program	
;
; Postconditions: None
;
; Recieves:	
;	[EBP+20] = A string introducing the program
;	[EBP+16] = A string introducing the programmer
;	[EBP+12] = A string providing instructions to the user
;	[EBP+8]	 = A string providing instructions to the user
;
; Returns: None
;	
Introduction PROC
	push			EBP
	mov				EBP, ESP
	pushad

	mDisplayString	[EBP+20]
	mDisplayString	[EBP+16]
	mDisplayString	[EBP+12]
	mDisplayString	[EBP+8]

	popad
	pop				EBP
	ret				16
Introduction ENDP

; Name: ReadVal
;
; Gets a string from the user and if the string is a number it converts it into SDWORD otherwise it allows them to enter a new string. 
;
; Preconditions: Prompt_1 is a string telling the user what to do. user_num has to be an empty string.  max_size is the maximum size of the string. user_bytes has to be a DWORD.
;	str_to_num has to be a DWORD and set to 0. Error is a string that displays an error to the user. try_again is a string that lets the user try to enter a new number. 
;
; Postconditions: None
;
; Recieves:	
;	[EBP+32] = A string prompting the user to try again if they entered a wrong number
;	[EBP+28] = A displaying an error message
;	[EBP+24] = An emptry DWORD
;	[EBP+20] = An empty DWORD
;	[EBP+16] = A DWORD describing the maximum size of the number
;	[EBP+12] = An empty string 
;	[EBP+8]	 = A string prompting the user for a number
;
; Returns: The users string as an SDWORD stored in str_to_num
;	
ReadVal PROC
	local			power:DWORD, multiplicand:DWORD, sign:DWORD, bytes:DWORD
	pushad
	mov				sign, 0

_original:	
	mov				EDI, [EBP+20]
	mGetString		[EBP+8], [EBP+12], [EBP+16], EDI
	jmp				_start

	; If the user enters an inavlid number it will jump to here 
_tryAgain:
	mov				sign, 0						; value that will determine if the enter number is negative or not
	mov				EAX, [EDI]
	sub				[EDI], EAX
	mov				EDI, [EBP+20]
	mGetString		[EBP+32], [EBP+12], [EBP+16], EDI

_start:
	mov				power, 0					; the factor of 10 to multiply by
	mov				EDI, [EBP+20]
	mov				EAX, [EDI]
	mov				bytes, EAX					; used to verify that + or - is at the beginning
	add				power, EAX
	dec				power

	mov				EDI, [EBP+20]
	mov				ECX, [EDI]
	mov				EDI, [EBP+24]
	mov				ESI, [EBP+12]

_getByte:
	cld				
	lodsb			
	movzx			EAX, AL
	cmp				EAX, 45						; acsii value for a negative sign
	je				_nSign
	cmp				EAX, 43						; acsii value for a positive sign
	je				_pSign
	sub				EAX, 48

	cmp				EAX, 0
	jl				_error
	cmp				EAX, 9
	jg				_error

	pushad
	mov				ECX, power
	cmp				ECX, 0
	je				_zeroPower
	mov				multiplicand, 1				; the number that each character is being multiplied by
	mov				EAX, multiplicand
	mov				EBX, 10

_getTenFactor:
	mul				EBX
	jo				_errorAfterPush
	loop			_getTenFactor

	mov				multiplicand, EAX
	popad
	jmp				_calculate

_zeroPower:
	mov				multiplicand, 1
	popad

_calculate:
	mul				multiplicand
	add				[EDI], EAX
	jo				_error

	dec				power
	loop			_getByte

	cmp				sign, 1
	jne				_stop

	mov				EAX, [EDI]
	neg				EAX
	mov				[EDI], EAX
	jmp				_stop

_error:
	mDisplayString	[EBP+28]
	jmp				_tryagain

_errorAfterPush:
	popad
	mDisplayString	[EBP+28]
	jmp				_tryagain

	; If user imputs a number with a negative sign this makes it nor result in an error if the plus sign is at the beginning of a number
_nSign:
	cmp				ECX, bytes
	jne				_error
	mov				sign, 1
	dec				ECX
	dec				power
	jmp				_getByte

	; If user imputs a number with a plus sign this makes it nor result in an error if the plus sign is at the beginning of a number
_pSign:
	cmp				ECX, bytes
	jne				_error
	mov				sign, 0
	dec				ECX
	dec				power
	jmp				_getByte

_stop:
	popad
	ret				28
ReadVal ENDP

; Name: WriteVal
;
; Converts the integer entered by the user to ascii bytes
;
; Preconditions: There must be an integer to convert to ascii. There also must be a place to store the string once converted. There must be a string that just contains 0.
;
; Postconditions: None
;
; Recieves:	
;		[EBP+16] = Address of a string containing 0
;		[EBP+12] = Address of a string
;		[EBP+8]  = An integer
;	
; Returns: Changes string to hold converted value
;	
WriteVal PROC
	local	quotient:DWORD, sign:DWORD, leading_zero:DWORD, nums_done:DWORD, all_zeros:DWORD
	pushad
	mov			all_zeros, 1				; Used in the special case that the user enters zero
	mov			EDI, [EBP+12]
	mov			ESI, [EBP+8]
	mov			EAX, [ESI]
	mov			quotient, EAX				; Number that is being divided
	mov			ECX, 32
	cmp			EAX, 0
	jl			_isNeg

	mov			sign, 0						; value that will determine if the enter number is negative or not
	jmp			_loopStart

_isNeg:
	mov			sign, 1
	neg			EAX
	mov			quotient, EAX

_loopStart:
	cmp			quotient, 0
	je			_checkAddNSign

	cmp			quotient, 0
	je			_zeroPad

	mov			all_zeros, 0		
	mov			EAX, quotient
	mov			EBX, 10
	mov			EDX, 0
	div			EBX
	mov			quotient, EAX

	add			EDX, 48
	mov			EAX, EDX

_writeHex:
	push		EAX
	loop		_loopStart

	mov			ECX, 32
	mov			EDI, [EBP+12]
	mov			leading_zero, 1				; Used to determine which zeros are leading zeros and which are apart of the number
	mov			nums_done, 0				; The number of numbers that have been converted

_fillLoop:
	pop			EAX
	cmp			EAX, 0
	je			_checkZero

_fillNum:
	inc			nums_done
	cld
	stosb
	mov			leading_zero, 0

_endFillLoop:
	loop		_fillLoop

	mov			ECX, 32
	sub			ECX, nums_done

_fillZero:
	mov			EAX, 0
	cld
	stosb
	loop		_fillZero
	cmp			all_zeros, 1
	je			_showZero

_showString:
	mDisplayString		[EBP+12]
	jmp					_stop

_showZero:
	mDisplayString		[EBP+16]
	jmp					_stop

_checkZero:
	cmp			leading_zero, 1
	je			_endFillLoop
	jmp			_fillNum

_checkAddNSign:
	cmp			sign, 0
	je			_zeroPad
	mov			EAX, 45
	mov			sign, 0
	jmp			_writeHex

_zeroPad:
	mov			EAX, 0
	jmp			_writeHex

_stop:
	popad
	ret			12
WriteVal ENDP

; Name: FindSum
;
; Finds the sum of all of the numbers entered by the user
;
; Preconditions: num_array must be the length of the NUM_OF_NUMS constant and contain SDWORD values. sum_num has to be a SDWORD
;
; Postconditions: None
;
; Recieves:	
;	[EBP+12]	=  A SDWORD where the sum of the numbers will be stored
;	[EBP+8]		=  The array
;
; Returns: The sum of all of the numbers entered by the user
;	
FindSum PROC
	push		EBP
	mov			EBP, ESP

	mov			ESI, [EBP+8]
	mov			ECX, NUM_OF_NUMS
	mov			EDI, [EBP+12]

_addNums:
	cld
	lodsd
	add			[EDI], EAX
	loop		_addNums

    

	pop		EBP
	ret		8
FindSum	ENDP

; Name: FindAvg
;
; Finds the average of the numbers entered by the user
;
; Preconditions: Must have the sum of the numbers entered by the user. avg_num must be an SDWORD
;
; Postconditions: None
;
; Recieves:	
;	[EBP+12]	=  A SDWORD where the average will be stored
;	[EBP+8]		=  The sum of the numbers entered by the user
;
; Returns: The average of the numbers entered by the user.
;	
FindAvg PROC
	push		EBP
	mov			EBP, ESP
	mov			EAX, [EBP+8]
	mov			EDI, [EBP+12]
	mov			EBX, NUM_OF_NUMS     
	mov			EDX, 0
	cdq
	idiv		EBX

	mov			[EDI], EAX


	pop			EBP
	ret			8
FindAvg ENDP

; Name: Farewell
;
; Says goodbye to the user at the end of the programs
;
; Preconditions: None	
;
; Postconditions: None
;
; Recieves:	[EBP+8] = A string that says goodbye to the user
;	
; Returns: None
;	
Farewell PROC
	push			EBP
	mov				EBP, ESP
	pushad

	call			crlf
	mDisplayString	[EBP+8]

	popad
	pop				EBP
	ret				4
Farewell ENDP

; (insert additional procedures here)

END main