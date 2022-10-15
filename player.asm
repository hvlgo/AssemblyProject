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
	.elseif eax == WM_TIMER					
		.if playButtonState == _PLAY		
			invoke changeProgressBar, dialogHandle		
		.endif
	.elseif eax == WM_HSCROLL
		invoke GetDlgCtrlID, lParam
		mov currentSlider, eax
		mov ax, WORD PTR wParam			
		.if currentSlider == IDC_PROGRESS
			.if ax == SB_ENDSCROLL					
				mov isDraggingProgressBar, 0
				;invoke SendDlgItemMessage, dialogHandle, IDC_SongMenu, LB_GETCURSEL, 0, 0	
				.if eax != -1				
					invoke changeTime, dialogHandle	
				.endif
			.elseif ax == SB_THUMBTRACK
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

	invoke SetTimer, dialogHandle, 1, 500, NULL
	ret
dialogInit endp

musicPlayControl proc dialogHandle : dword, state : byte ; TODO: play the music in the music file data struct
	.if state == _BEGIN
		;invoke playButtonControl, dialogHandle, _PLAY
		;---------------------------
		invoke SendDlgItemMessage, dialogHandle, IDC_LIST1, LB_SETCURSEL, currentSongIndex, 0
		invoke playSong, dialogHandle, currentSongIndex;
		invoke mciSendString, addr playSongCommand, NULL, 0, NULL
		
		invoke mciSendString, addr getLengthCommand, addr songLength, 32, NULL	
		invoke StrToInt, addr songLength
		invoke SendDlgItemMessage, dialogHandle, IDC_PROGRESS, TBM_SETRANGEMAX, 0, eax
		
		invoke StrToInt, addr songLength
		mov edx, 0
		div timeScale
	
		mov edx, 0
		div timeScaleSec
		mov timeMinuteLength, eax
		mov timeSecondLength, edx
	.elseif state == _PAUSE
		invoke playButtonControl, dialogHandle, _PLAY
		invoke mciSendString, addr resumeSongCommand, NULL, 0, NULL
	.else
		invoke playButtonControl, dialogHandle, _PAUSE
		invoke mciSendString, addr pauseSongCommand, NULL, 0, NULL
	.endif

	ret
musicPlayControl endp

playButtonControl proc dialogHandle : dword, state : byte
	.if state == _PAUSE
		mov eax, IDI_PLAY
		mov playButtonState, _PAUSE
	.else
		mov eax, IDI_PAUSE
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
		.if	eax == IDC_IMPORT
			invoke importSongToList, dialogHandle
			mov eax, wParam
		.elseif eax == IDC_DELETE
			;#############
			;TODO
			;#############
		.elseif eax == IDC_PLAY_FOCUSED
			;#############
			;TODO
			;#############
		.endif
	.elseif	eax == WM_CLOSE
		invoke	EndDialog, dialogHandle, 0
	.endif
	xor eax, eax
	ret
listProc endp

changeProgressBar proc dialogHandle: dword
	local temp: dword
	.if playButtonState == _PLAY		
		invoke mciSendString, addr getPositionCommand, addr songPosition, 32, NULL
		invoke StrToInt, addr songPosition	
		;add eax, 1000
		mov temp, eax
		.if isDraggingProgressBar == 0	
			invoke SendDlgItemMessage, dialogHandle, IDC_PROGRESS, TBM_SETPOS, 1, temp
		.endif
		invoke displayTime, dialogHandle, temp
	.endif
	ret
changeProgressBar endp

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

changeTime proc dialogHandle: dword
	invoke SendDlgItemMessage, dialogHandle, IDC_PROGRESS, TBM_GETPOS, 0, 0		
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

playSong proc dialogHandle: dword, index: dword
	
	Ret
playSong endp

;import a single song
importSongToList proc dialogHandle: dword
	invoke	RtlZeroMemory,addr fileDialog,sizeof fileDialog
	mov	fileDialog.lStructSize,sizeof fileDialog
	push	dialogHandle
	pop	fileDialog.hwndOwner
	mov	fileDialog.lpstrFile,offset lpstrFileNames
	mov	fileDialog.nMaxFile,SIZEOF lpstrFileNames
	mov	fileDialog.Flags,OFN_FILEMUSTEXIST or OFN_PATHMUSTEXIST
	invoke	GetOpenFileName,addr fileDialog

	.if eax
		;get the parent path and the true path of the selected file(in turn)
		invoke lstrcpyn, ADDR tempPath, ADDR lpstrFileNames, fileDialog.nFileOffset

		mov esi,OFFSET lpstrFileNames
		mov ebx,0
		mov bx,fileDialog.nFileOffset		;not the same size,should change to the same
		add esi,ebx							;now file name stored in the esi(beginning address)
		invoke lstrcpy, ADDR tempPath, esi	;now file name stored in the tempPath

		;print the file name
		invoke SendDlgItemMessage, dialogHandle, IDC_SONG_LIST, LB_ADDSTRING, 0, esi

		mov edi, OFFSET songList
		mov ebx, SIZEOF songStructure
		imul ebx, currentTotalSongNumber
		add edi, ebx					;the  beginning address of the new song
		invoke lstrcpy, ADDR (songStructure PTR [edi]).songName, ADDR tempPath
		invoke lstrcpy, ADDR (songStructure PTR [edi]).songPath, ADDR lpstrFileNames

		;total number ++
		add currentTotalSongNumber,1
	.endif

	ret
importSongToList endp

end start