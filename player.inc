; include requirements
include windows.inc
include user32.inc
include kernel32.inc
include gdi32.inc


; function declare
mainProc proto dialogHandle:DWORD,message:DWORD, wParam:DWORD,lParam:DWORD
listProc proto dialogHandle:DWORD,message:DWORD, wParam:DWORD,lParam:DWORD
dialogInit proto dialogHandle : dword
musicPlayControl proto dialogHandle : dword, state : byte
playButtonControl proto dialogHandle : dword, state : byte


;the struct of the song
songStructure STRUCT
	songName BYTE 100 DUP(0)
	songPath BYTE 100 DUP(0)
songStructure ends


.const
; sequence id for the ui
IDD_MAIN EQU 101
IDD_LIST EQU 123
IDC_PLAY EQU 1004
IDC_LOCAL EQU 1005
IDC_PROGRESS EQU 1008
IDC_PLAY_FOCUSED EQU 1009
IDC_IMPORT EQU 1010
IDC_DELETE EQU 1011

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
;current song index
currentSongIndex DWORD 0

.data?
; the handle of the exec file itself
hInstance HINSTANCE ?
