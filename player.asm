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

;######################################################
;the main dialog callback function
;param:
;	dialogHandle: the handle of the main dialog
;	message: the user message sent to the dialog
;	wParam: the addtional info of the message
;	lParam: the addtional info of the message
;######################################################
mainProc proc dialogHandle : dword, message : dword, wParam : dword, lParam : dword
	local wc : WNDCLASSEX
	mov eax,dialogHandle
	mov mainHandle,eax
	mov eax, message

	.if eax == WM_INITDIALOG
		mov   wc.style, CS_HREDRAW or CS_VREDRAW or CS_DBLCLKS
		invoke RegisterClassEx, addr wc
		invoke dialogInit, dialogHandle

	.elseif eax == WM_COMMAND
		mov	eax, wParam
		.if	eax == IDC_PLAY
			.if currentTotalSongNumber != 0
				invoke musicPlayControl, dialogHandle, playButtonState, 0
			.endif
		.elseif eax == IDC_LOCAL
			invoke DialogBoxParam, hInstance, IDD_LIST, 0, offset listProc, 0
			;mov eax, 2 ; TODO: select the file and manage relative data struct
		.elseif eax == IDC_VOLBUTTON
			.if hasSound == 1
				mov hasSound, 0
			.else
				mov hasSound, 1
			.endif
			invoke changeVolume, dialogHandle
		.endif
	.elseif eax == WM_TIMER	
		.if playButtonState == _PLAY		
			invoke changeProgressBar, dialogHandle
			invoke checkPlay, dialogHandle	; check if finished
		.endif
	.elseif eax == WM_HSCROLL
		invoke GetDlgCtrlID, lParam
		mov currentSlider, eax
		mov ax, WORD PTR wParam			
		; move progress bar
		.if currentSlider == IDC_PROGRESS
			; end move bar
			.if ax == SB_ENDSCROLL					
				mov isDraggingProgressBar, 0
				; song exist
				.if currentTotalSongNumber != 0				
					invoke changeTime, dialogHandle	
				.endif
			.elseif ax == SB_THUMBTRACK
				mov isDraggingProgressBar, 1
			.endif
		; move volume bar
		.elseif currentSlider == IDC_VOLUME
			.if currentTotalSongNumber != 0
				mov hasSound, 1
				invoke SendDlgItemMessage, dialogHandle, IDC_VOLUME, TBM_GETPOS, 0, 0
				mov currentVol, eax
				invoke changeVolume, dialogHandle
			.endif
		.endif
	.elseif	eax == WM_CLOSE
		invoke	EndDialog, dialogHandle, 0
	.endif
	xor eax, eax
	ret
mainProc endp

;######################################################
;the main dialog init function, prepare the relative variables
;param:
;	dialogHandle: the handle of the main dialog
;######################################################
dialogInit proc dialogHandle : dword
	invoke playButtonControl, dialogHandle, _PAUSE
	mov playButtonState, _BEGIN
	mov currentSongIndex, 0

	mov hasSound, 1
	; set volume slider
	invoke SendDlgItemMessage, dialogHandle, IDC_VOLUME, TBM_SETRANGEMIN, 0, 0
	invoke SendDlgItemMessage, dialogHandle, IDC_VOLUME, TBM_SETRANGEMAX, 0, volumeSize
	mov edx, 0
	mov eax, volumeSize
	mov ebx, 2
	div ebx
	mov currentVol, eax
	invoke SendDlgItemMessage, dialogHandle, IDC_VOLUME, TBM_SETPOS, 1, eax
	;invoke SendDlgItemMessage, dialogHandle, IDC_VOLUME, TBM_SETPOS, 1, volumeSize
	invoke changeVolume, dialogHandle

	; set timer
	invoke SetTimer, dialogHandle, 1, 500, NULL
	ret
dialogInit endp

;######################################################
;the music play control function
;param:
;	dialogHandle: the handle of the main dialog
;	state: the state of the music (with currentSongIndex) before the button pushed
;	curSongIndex: the index of the music in the list
;######################################################
musicPlayControl proc dialogHandle : dword, state : byte, curSongIndex: dword ; TODO: play the music in the music file data struct
	.if state == _BEGIN
		invoke closeSong, dialogHandle
		invoke playButtonControl, dialogHandle, _PLAY
		invoke playSong, dialogHandle, curSongIndex;

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


;######################################################
;the play button icon control function
;param:
;	dialogHandle: the handle of the main dialog
;	state: the state of the music (with currentSongIndex) you wish after the button pushed
;######################################################
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


;######################################################
;the list dialog callback function
;param:
;	dialogHandle: the handle of the music list dialog
;	message: the user message sent to the dialog
;	wParam: the addtional info of the message
;	lParam: the addtional info of the message
;######################################################
listProc proc dialogHandle : dword, message : dword, wParam : dword, lParam : dword
	local wc : WNDCLASSEX
	mov eax, message

	.if eax == WM_INITDIALOG
		mov   wc.style, CS_HREDRAW or CS_VREDRAW or CS_DBLCLKS
		invoke RegisterClassEx, addr wc
		invoke listDialogInit, dialogHandle
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
		.elseif ax == IDC_SONG_LIST
			shr eax,16
			.if ax == LBN_SELCHANGE	;选中项发生改变
				invoke SendDlgItemMessage, dialogHandle, IDC_SONG_LIST, LB_GETCURSEL, 0, 0	;get the index
				mov currentSongIndex, eax
				invoke musicPlayControl, mainHandle, _BEGIN, eax   ;change the song
				invoke	EndDialog, dialogHandle, 0
			.endif
		.endif
	.elseif	eax == WM_CLOSE
		invoke	EndDialog, dialogHandle, 0
	.endif
	xor eax, eax
	ret
listProc endp

;######################################################
;print the music list
;param:
;	dialogHandle: the handle of the music list dialog
;######################################################
listDialogInit proc dialogHandle: dword
	mov ebx,0
	mov ecx,currentTotalSongNumber
	.WHILE ecx != 0
		mov edi, OFFSET songList
		mov edx, SIZEOF songStructure
		imul edx, ebx
		add edi, edx
		pushad
		invoke SendDlgItemMessage, dialogHandle, IDC_SONG_LIST, LB_ADDSTRING, 0, ADDR (songStructure PTR [edi]).songName
		popad
		add ebx,1
		sub ecx,1
	.ENDW
	ret
listDialogInit endp

;######################################################
;the Progress Bar control function, change the progess bar after the timer event
;param:
;	dialogHandle: the handle of the music list dialog
;######################################################
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

;######################################################
;the time display control function, change the time text according to time
;param:
;	dialogHandle: the handle of the music list dialog
;	currentPosition: the time of the music now
;######################################################
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

;######################################################
;the time control function, change the time after the bar scolled
;param:
;	dialogHandle: the handle of the music list dialog
;######################################################
changeTime proc dialogHandle: dword
	invoke SendDlgItemMessage, dialogHandle, IDC_PROGRESS, TBM_GETPOS, 0, 0		
	invoke wsprintf, addr mediaCommand, addr setPositionCommand, eax
	invoke mciSendString, addr mediaCommand, NULL, 0, NULL

	.if playButtonState == _PLAY	
		invoke mciSendString, addr playSongCommand, NULL, 0, NULL
	.elseif playButtonState == _PAUSE
		invoke mciSendString, addr playSongCommand, NULL, 0, NULL
		invoke mciSendString, addr pauseSongCommand, NULL, 0, NULL
	.endif
	ret
changeTime endp


;######################################################
;the volume control function, change the volume by slider
;param:
;	dialogHandle: the handle of the music list dialog
;######################################################
changeVolume proc dialogHandle: dword
	; get the pos of the vol slider
	;.if currentVol == 0
	;	mov hasSound, 0
	;.else
	;	mov hasSound, 1
	;.endif

	.if hasSound == 1
		invoke SendDlgItemMessage, dialogHandle, IDC_VOLUME, TBM_SETPOS, 1, currentVol
		invoke wsprintf, addr mediaCommand, addr adjustVolumeCommand, currentVol
		.if currentVol == 0
			invoke changeVolumeIcon, dialogHandle, _MUTE
		.elseif currentVol <= 33
			invoke changeVolumeIcon, dialogHandle, _LOW
		.elseif currentVol > 66
			invoke changeVolumeIcon, dialogHandle, _LOUD
		.else
			invoke changeVolumeIcon, dialogHandle, _MID
		.endif
	.else
		invoke wsprintf, addr mediaCommand, addr adjustVolumeCommand, 0
		invoke changeVolumeIcon, dialogHandle, _MUTE
	.endif
	invoke mciSendString, addr mediaCommand, NULL, 0, NULL
	invoke displayVolume, dialogHandle
	
	ret
changeVolume endp


;######################################################
;the volume display function, show the volume by text
;param:
;	dialogHandle: the handle of the music list dialog
;######################################################
displayVolume proc dialogHandle: dword
	invoke SendDlgItemMessage, dialogHandle, IDC_VOLUME, TBM_GETPOS, 0, 0
	invoke wsprintf, addr mediaCommand, addr int2str, eax
	invoke SendDlgItemMessage, dialogHandle, IDC_VOLSHOW, WM_SETTEXT, 0, addr mediaCommand
	ret
displayVolume endp


;######################################################
;the volume icon function, change the vol icon by volume
;param:
;	dialogHandle: the handle of the music list dialog
;	state: the status of volume
;######################################################
changeVolumeIcon proc dialogHandle: dword, state: byte
	.if state == _MUTE
		mov eax, IDI_MUTE
	.elseif state == _LOW
		mov eax, IDI_LOW
	.elseif state == _MID
		mov eax, IDI_MID
	.else
		mov eax, IDI_LOUD
	.endif

	invoke LoadImage, hInstance, eax, IMAGE_ICON, ICON_WIDTH, ICON_HEIGHT, LR_DEFAULTCOLOR
	invoke SendDlgItemMessage, dialogHandle, IDC_VOLBUTTON, BM_SETIMAGE, IMAGE_ICON, eax

	ret
changeVolumeIcon endp

;######################################################
;the play control function, open the music of the index given
;param:
;	dialogHandle: the handle of the music list dialog
;	index: the index of the music of list
;######################################################
playSong proc dialogHandle: dword, index: dword
	; accept path to open the song
	mov edi, OFFSET songList
	mov ebx, SIZEOF songStructure
	imul ebx, index
	add edi, ebx					

	invoke wsprintf, addr mediaCommand, addr openSongCommand, addr (songStructure PTR [edi]).songPath
	invoke mciSendString, addr mediaCommand, NULL, 0, NULL

	ret
playSong endp

;######################################################
;the play control function, close the current music
;param:
;	dialogHandle: the handle of the music list dialog
;######################################################
closeSong proc uses eax dialogHandle: dword
	invoke mciSendString, ADDR closeSongCommand, NULL, 0, NULL
	
	ret
closeSong endp

;######################################################
;the play control function, change music when the current music is over
;param:
;	dialogHandle: the handle of the music list dialog
;	newSongIndex: the index of the next music of list
;######################################################
changeSong proc dialogHandle: dword, newSongIndex: dword
	invoke closeSong, dialogHandle	; close the song before

	mov eax, newSongIndex
	mov currentSongIndex, eax	
	invoke playSong, dialogHandle, currentSongIndex	
	invoke mciSendString, ADDR playSongCommand, NULL, 0, NULL
	
	; set song length
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
	ret
changeSong endp

;######################################################
;check the music over or not, call after the timer event
;param:
;	dialogHandle: the handle of the music list dialog
;	newSongIndex: the index of the next music of list
;######################################################
checkPlay proc dialogHandle: dword
	local temp: dword

	.if playButtonState == _PLAY
		invoke StrToInt, addr songLength
		mov temp, eax
		invoke StrToInt, addr songPosition
		.if eax >= temp		; the song is over
		; TODO add different play mode
		; TODO need new index
			inc currentSongIndex
			mov ebx, currentSongIndex
			.if ebx > currentTotalSongNumber
				mov currentSongIndex, 0
			.endif
			invoke changeSong, dialogHandle, currentSongIndex
		.endif
	.endif
	Ret
checkPlay endp

;######################################################
;add a music to the list after the import button pushed
;param:
;	dialogHandle: the handle of the music list dialog
;######################################################
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