; include requirements
include windows.inc
include user32.inc
include kernel32.inc
include gdi32.inc
include winmm.inc
include shlwapi.inc
include Comdlg32.inc


includelib	Comdlg32.lib
includelib winmm.lib
includelib shlwapi.lib
includelib	user32.lib
includelib	kernel32.lib
includelib gdi32.lib
includelib msvcrt.lib

; function declare
printf   proto C :ptr sbyte, :VARARG
mainProc proto dialogHandle:dword,message:dword, wParam:dword,lParam:dword
listProc proto dialogHandle:dword,message:dword, wParam:dword,lParam:dword
dialogInit proto dialogHandle : dword
musicPlayControl proto dialogHandle : dword, state : byte, curSongIndex: dword
playButtonControl proto dialogHandle : dword, state : byte
changeProgressBar proto dialogHandle: dword
displayTime proto dialogHandle: dword, currentPosition: dword
changeTime proto dialogHandle: dword
importSongToList proto dialogHandle: dword
playSong proto dialogHandle: dword, index: dword
listDialogInit proto dialogHandle:dword

;the struct of the song
songStructure STRUCT
	songName BYTE 1000 DUP(0)
	songPath BYTE 1000 DUP(0)
songStructure ends


.const
; sequence id for the ui
IDD_MAIN EQU 101
IDD_LIST EQU 123
IDC_PLAY EQU 1004
IDC_LOCAL EQU 1005
IDC_SONG_LIST EQU 1007
IDC_PROGRESS EQU 1008
IDC_PROSHOW EQU 1111
IDC_PLAY_FOCUSED EQU 1009
IDC_IMPORT EQU 1010
IDC_DELETE EQU 1011
IDC_LIST1 EQU 1007

IDI_PLAY EQU 119
IDI_PAUSE EQU 122

; state for the button
_PAUSE EQU 0
_PLAY EQU 1
_BEGIN EQU 2

; const parm of the icon
ICON_HEIGHT EQU 32
ICON_WIDTH EQU 32

.data
; states of the button
playButtonState byte 0

;song list
songList songStructure 100 dup(<"0", "0">)
;total number of current songs 
currentTotalSongNumber DWORD 0
;current song index
currentSongIndex DWORD 0
;temporarily store the filename
tempName BYTE 1000 dup(0)

;open the file dialog
fileDialog OPENFILENAME<>
lpstrFileNames BYTE 8000 DUP(0)
tempPath BYTE 1000 DUP(0)

; mci command
getPositionCommand byte "status currentSong position", 0	
setPositionCommand byte "seek currentSong to %d", 0			
playSongCommand byte "play currentSong", 0					
pauseSongCommand byte "pause currentSong",0					
resumeSongCommand byte "resume currentSong",0				
getLengthCommand byte "status currentSong length", 0		
openSongCommand byte 'open "%s" alias currentSong type mpegvideo',0

; value
isDraggingProgressBar dword 0		
currentSlider dword ?				
timeScale dword 1000				
timeScaleSec dword 60				
timeMinutePosition dword 0			
timeSecondPosition dword 0			
timeMinuteLength dword 0			
timeSecondLength dword 0			
timeShow byte "%d:%d/%d:%d", 0		
songPosition byte 32 dup(0)			
songLength byte 32 dup(0)			

;handle
mainHandle dword 0

;test
ansMsg BYTE "%d"
changeRowMsg BYTE 0ah, 0dh, 0
strMsg BYTE "%c"

.data?
; the handle of the exec file itself
hInstance HINSTANCE ?
mediaCommand byte ?		;mciSendString