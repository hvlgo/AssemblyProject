.386
.model flat, stdcall
option casemap : none
.stack 4096

include	player.inc

.code
start:
	invoke	GetModuleHandle, NULL
	mov	hInstance, eax
	invoke DialogBoxParamA, hInstance,IDD_MAIN, 0, offset MainProc, 0
	invoke ExitProcess, 0

MainProc proc dialogHandle : DWORD, message : DWORD, wParam : DWORD, lParam : DWORD
	local wc : WNDCLASSEX
	mov eax, message
	.if eax == WM_INITDIALOG
		mov   wc.style, CS_HREDRAW or CS_VREDRAW or CS_DBLCLKS
		invoke RegisterClassEx, addr wc
	.elseif	eax == WM_CLOSE
		invoke	EndDialog, dialogHandle, 0
	.endif
	xor eax, eax
	ret
MainProc endp
end start