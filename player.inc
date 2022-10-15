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

; mci command
getPositionCommand byte "status currentSong position", 0	;歌曲当前播放位置命令
setPositionCommand byte "seek currentSong to %d", 0			;设置歌曲当前播放位置命令
playSongCommand byte "play currentSong", 0					;播放歌曲命令

; value
songPosition byte 32 dup(0)			;当前播放进度 (ms)
isDraggingProgressBar dword 0		;是否正在拖动进度条，0-否，1-是
currentSlider dword ?				;当前发送消息的slider
timeScale dword 1000				;用于进度显示
timeScaleSec dword 60				;用于进度显示
timeMinutePosition dword 0			;当前歌曲位置 min
timeSecondPosition dword 0			;当前歌曲位置 sec
timeMinuteLength dword 0			;当前歌曲长度 min
timeSecondLength dword 0			;当前歌曲长度 sec
timeShow byte "%d:%d/%d:%d", 0		;用于进度显示

.data?
; the handle of the exec file itself
hInstance HINSTANCE ?
mediaCommand byte ?		;mciSendString