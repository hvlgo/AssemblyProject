.386
.model flat, stdcall
option casemap : none
.stack 4096

include	player.inc

.code
start:
	invoke GetModuleHandle, NULL
	mov	hInstance, eax
	invoke DialogBoxParam, hInstance,IDD_MAIN, 0, offset mainProc, 0
	invoke ExitProcess, 0

mainProc proc dialogHandle : dword, message : dword, wParam : dword, lParam : dword
	local wc : WNDCLASSEX
	mov eax, message

	.if eax == WM_INITDIALOG
		mov   wc.style, CS_HREDRAW or CS_VREDRAW or CS_DBLCLKS
		invoke RegisterClassEx, addr wc
		invoke dialogInit, dialogHandle
	.elseif eax == WM_COMMAND
		mov	eax, wParam
		.if	eax == IDC_PLAY
			invoke musicPlayControl, dialogHandle, playButtonState
		.elseif eax == IDC_LOCAL
			invoke DialogBoxParam, hInstance, IDD_LIST, 0, offset listProc, 0
			mov eax, 2 ; TODO: select the file and manage relative data struct
		.endif
	; ��ʱ����Ϣ
	.elseif eax == WM_TIMER					
		.if playButtonState == _PLAY		; ����״̬��Ҫ�ػ滬��
			invoke changeProgressBar, dialogHandle		
		.endif
	;slider��Ϣ
	.elseif eax == WM_HSCROLL
		;��ȡ������Ϣ��Slider�Ŀؼ��Ų�����curSlider������
		invoke GetDlgCtrlID, lParam
		mov currentSlider, eax
		mov ax, WORD PTR wParam			;��ȡ��Ϣ���
		; ��������Ϣ
		.if currentSlider == IDC_PROGRESS
			.if ax == SB_ENDSCROLL					;��������
				mov isDraggingProgressBar, 0
				;invoke SendDlgItemMessage, dialogHandle, IDC_SongMenu, LB_GETCURSEL, 0, 0	;��ȡ��ѡ�е��±�
				.if eax != -1				;��ǰ�и�����ѡ�У�����mcisendstring�����������
					invoke changeTime, dialogHandle	
				.endif
			.elseif ax == SB_THUMBTRACK;������Ϣ
				mov isDraggingProgressBar, 1
			.endif
		.endif
	.elseif	eax == WM_CLOSE
		invoke	EndDialog, dialogHandle, 0
	.endif
	xor eax, eax
	ret
mainProc endp

dialogInit proc dialogHandle : dword
	invoke playButtonControl, dialogHandle, _PAUSE

	;���ü�ʱ����ÿ0.5s����һ�μ�ʱ����Ϣ
	invoke SetTimer, dialogHandle, 1, 500, NULL
	ret
dialogInit endp

musicPlayControl proc dialogHandle : dword, state : byte ; TODO: play the music in the music file data struct
	.if state == _BEGIN
		invoke playButtonControl, dialogHandle, _PLAY

	.elseif state == _PAUSE
		invoke playButtonControl, dialogHandle, _PLAY

	.else
		invoke playButtonControl, dialogHandle, _PAUSE

	.endif

	ret
musicPlayControl endp

playButtonControl proc dialogHandle : dword, state : byte
	.if state == _PAUSE
		mov eax, IDI_PAUSE
		mov playButtonState, _PAUSE
	.else
		mov eax, IDI_PLAY
		mov playButtonState, _PLAY
	.endif

	invoke LoadImage, hInstance, eax, IMAGE_ICON, ICON_WIDTH, ICON_HEIGHT, LR_DEFAULTCOLOR
	invoke SendDlgItemMessage, dialogHandle, IDC_PLAY, BM_SETIMAGE, IMAGE_ICON, eax
	
	ret
playButtonControl endp


listProc proc dialogHandle : dword, message : dword, wParam : dword, lParam : dword
	local wc : WNDCLASSEX
	mov eax, message

	.if eax == WM_INITDIALOG
		mov   wc.style, CS_HREDRAW or CS_VREDRAW or CS_DBLCLKS
		invoke RegisterClassEx, addr wc
	.elseif eax == WM_COMMAND
		mov	eax, wParam
	.elseif	eax == WM_CLOSE
		invoke	EndDialog, dialogHandle, 0
	.endif
	xor eax, eax
	ret
listProc endp

; �ı������λ��
changeProgressBar proc dialogHandle: dword
	local temp: dword
	.if playButtonState == _PLAY		;����ǰΪ����״̬
		invoke mciSendString, addr getPositionCommand, addr songPosition, 32, NULL;��ȡ��ǰ����λ��
		invoke StrToInt, addr songPosition	;��ǰ����ת��int����eax��
		;add eax, 1000
		mov temp, eax
		.if isDraggingProgressBar == 0	;����ǰ�û�û����ʱ������ôʵʱ���½�����λ��
			invoke SendDlgItemMessage, dialogHandle, IDC_PROGRESS, TBM_SETPOS, 1, temp
		.endif
		invoke displayTime, dialogHandle, temp
	.endif
	ret
changeProgressBar endp

;������ʾ����
displayTime proc dialogHandle: dword, currentPosition: dword
	mov eax, currentPosition
	mov edx, 0
	div timeScale
	
	mov edx, 0
	div timeScaleSec
	mov timeMinutePosition, eax
	mov timeSecondPosition, edx
	invoke wsprintf, addr mediaCommand, addr timeShow, timeMinutePosition, timeSecondPosition, timeMinuteLength, timeSecondLength
	invoke SendDlgItemMessage, dialogHandle, IDC_PROSHOW, WM_SETTEXT, 0, addr mediaCommand
	ret
displayTime endp

; ���ݽ�����λ�øı䲥��ʱ��
changeTime proc dialogHandle: dword
	invoke SendDlgItemMessage, dialogHandle, IDC_PROGRESS, TBM_GETPOS, 0, 0		;TBM_GETPOS��ȡ������λ�õ�eax
	invoke wsprintf, addr mediaCommand, addr setPositionCommand, eax
	invoke mciSendString, addr mediaCommand, NULL, 0, NULL
	.if playButtonState == _PLAY	
		invoke mciSendString, addr playSongCommand, NULL, 0, NULL
	.elseif playButtonState == _PAUSE
		invoke mciSendString, addr playSongCommand, NULL, 0, NULL
		mov playButtonState, _PLAY
	.endif
	ret
changeTime endp

end start