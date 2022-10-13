; include requirements
include windows.inc
include user32.inc
include kernel32.inc

; function declare
MainProc proto dialogHandle:DWORD,message:DWORD, wParam:DWORD,lParam:DWORD

.const
IDD_MAIN EQU 101
IDB_PLAY EQU 106
IDB_LOCAL EQU 109
.data?
hInstance HINSTANCE ?