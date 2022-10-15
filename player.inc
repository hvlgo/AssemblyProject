; include requirements
include windows.inc
include user32.inc
include kernel32.inc
include gdi32.inc
include winmm.inc
include shlwapi.inc

includelib winmm.lib
includelib shlwapi.lib
INCLUDELIB	user32.lib
INCLUDELIB	kernel32.lib
INCLUDELIB gdi32.lib

; function declare
mainProc proto dialogHandle:dword,message:dword, wParam:dword,lParam:dword
listProc proto dialogHandle:dword,message:dword, wParam:dword,lParam:dword
dialogInit proto dialogHandle : dword
musicPlayControl proto dialogHandle : dword, state : byte
playButtonControl proto dialogHandle : dword, state : byte
changeProgressBar proto dialogHandle: dword
displayTime proto dialogHandle: dword, currentPosition: dword
changeTime proto dialogHandle: dword

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
IDC_PROSHOW EQU 1111
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

; mci command
getPositionCommand byte "status currentSong position", 0	;������ǰ����λ������
setPositionCommand byte "seek currentSong to %d", 0			;���ø�����ǰ����λ������
playSongCommand byte "play currentSong", 0					;���Ÿ�������

; value
songPosition byte 32 dup(0)			;��ǰ���Ž��� (ms)
isDraggingProgressBar dword 0		;�Ƿ������϶���������0-��1-��
currentSlider dword ?				;��ǰ������Ϣ��slider
timeScale dword 1000				;���ڽ�����ʾ
timeScaleSec dword 60				;���ڽ�����ʾ
timeMinutePosition dword 0			;��ǰ����λ�� min
timeSecondPosition dword 0			;��ǰ����λ�� sec
timeMinuteLength dword 0			;��ǰ�������� min
timeSecondLength dword 0			;��ǰ�������� sec
timeShow byte "%d:%d/%d:%d", 0		;���ڽ�����ʾ

.data?
; the handle of the exec file itself
hInstance HINSTANCE ?
mediaCommand byte ?		;mciSendString