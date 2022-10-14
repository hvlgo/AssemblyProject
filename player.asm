.386
.model flat, stdcall
option casemap : none
.stack 4096

include	player.inc

.code
start:
	invoke GetModuleHandle, NULL
	mov	hInstance, eax
	invoke DialogBoxParamA, hInstance,IDD_MAIN, 0, offset mainProc, 0
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
			mov eax, 2
		.endif
	.elseif	eax == WM_CLOSE
		invoke	EndDialog, dialogHandle, 0
	.endif
	xor eax, eax
	ret
mainProc endp

dialogInit proc dialogHandle : dword
	invoke playButtonControl, dialogHandle, _PAUSE
	ret
dialogInit endp

musicPlayControl proc dialogHandle : dword, state : byte
	.if state == _PAUSE
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

end start