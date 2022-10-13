; include requirements
include windows.inc
include user32.inc
include kernel32.inc
include msvcrt.inc

; function declare
MainProc proto dialogHandle:DWORD,message:DWORD, wParam:DWORD,lParam:DWORD

.const
IDD_MAIN EQU 101

.data?
hInstance HINSTANCE ?