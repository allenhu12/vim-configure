;=====================================================================o
;                   Feng Ruohang's AHK Script                         | 
;                      CapsLock Enhancement                           |
;---------------------------------------------------------------------o
;Description:                                                         |
;    This Script is wrote by Feng Ruohang via AutoHotKey Script. It   |
; Provieds an enhancement towards the "Useless Key" CapsLock, and     |
; turns CapsLock into an useful function Key just like Ctrl and Alt   |
; by combining CapsLock with almost all other keys in the keyboard.   |
;                                                                     |
;Summary:                                                             |
;o----------------------o---------------------------------------------o
;|CapsLock;             | {ESC}  Especially Convient for vim user     |
;|CaspLock + `          | {CapsLock}CapsLock Switcher as a Substituent|
;|CapsLock + hjklwb     | Vim-Style Cursor Mover                      |
;|CaspLock + uiop       | Convient Home/End PageUp/PageDn             |
;|CaspLock + nm,.       | Convient Delete Controller                  |
;|CapsLock + zxcvay     | Windows-Style Editor                        |
;|CapsLock + Direction  | Mouse Move                                  |
;|CapsLock + Enter      | Mouse Click                                 |
;|CaspLock + {F1}~{F6}  | Media Volume Controller                     |
;|CapsLock + qs         | Windows & Tags Control                      |
;|CapsLock + ;'[]       | Convient Key Mapping                        |
;|CaspLock + dfert      | Frequently Used Programs (Self Defined)     |
;|CaspLock + 123456     | Dev-Hotkey for Visual Studio (Self Defined) |
;|CapsLock + 67890-=    | Shifter as Shift                            |
;-----------------------o---------------------------------------------o
;|Use it whatever and wherever you like. Hope it help                 |
;=====================================================================o

;=====================================================================o
;# �Ŵ��� Win ����
;! �Ŵ��� Alt ����
;^ �Ŵ��� Ctrl ����
;+ �Ŵ��� shift ����
;:: ��(����Ӣ��ð��)��ָ����ã�
;run���ǳ����� �� AHK ����֮һ;
;; �Ŵ��� ע�ͺ���һ�����ݣ�
;=====================================================================o


;=====================================================================o
;                       CapsLock Initializer                         ;|
;---------------------------------------------------------------------o
SetCapsLockState, AlwaysOff                                          ;|
;---------------------------------------------------------------------o


;=====================================================================o
;                       CapsLock Switcher:                           ;|
;---------------------------------o-----------------------------------c
;                    CapsLock + ` | {CapsLock}                       ;|
;---------------------------------o-----------------------------------o
CapsLock & `::                                                       ;|
GetKeyState, CapsLockState, CapsLock, T                              ;|
if CapsLockState = D                                                 ;|
    SetCapsLockState, AlwaysOff                                      ;|
else                                                                 ;|
    SetCapsLockState, AlwaysOn                                       ;|
KeyWait, ``                                                          ;|
return                                                               ;|
;---------------------------------------------------------------------o


;=====================================================================o
;                         CapsLock Escaper:                          ;|
;----------------------------------o----------------------------------o
;                        CapsLock  |  {ESC}                          ;|
; since ESC will close the editing window sometimes                  ;|
; instead, we use ctrl+[ to send {ESC}                               ;
;----------------------------------o----------------------------------o
;CapsLock::Send, {ESC}                                                ;|
CapsLock & [:: Send, {ESC}                                            ;|
;---------------------------------------------------------------------o


;=====================================================================o
;                    CapsLock Direction Navigator                    ;|
;-----------------------------------o---------------------------------o
;                      CapsLock + h |  Left                          ;|
;                      CapsLock + j |  Down                          ;|
;                      CapsLock + k |  Up                            ;|
;                      CapsLock + l |  Right                         ;|
;                      Ctrl, Alt Compatible                          ;|
;-----------------------------------o---------------------------------o
CapsLock & h::                                                       ;|
if GetKeyState("control") = 0                                        ;|
{                                                                    ;|
    if GetKeyState("alt") = 0                                        ;|
        Send, {Left}                                                 ;|
    else                                                             ;|
        Send, +{Left}                                                ;|
    return                                                           ;|
}                                                                    ;|
else {                                                               ;|
    if GetKeyState("alt") = 0                                        ;|
        Send, ^{Left}                                                ;|
    else                                                             ;|
        Send, +^{Left}                                               ;|
    return                                                           ;|
}                                                                    ;|
return                                                               ;|
;-----------------------------------o                                ;|
CapsLock & j::                                                       ;|
if GetKeyState("control") = 0                                        ;|
{                                                                    ;|
    if GetKeyState("alt") = 0                                        ;|
        Send, {Down}                                                 ;|
    else                                                             ;|
        Send, +{Down}                                                ;|
    return                                                           ;|
}                                                                    ;|
else {                                                               ;|
    if GetKeyState("alt") = 0                                        ;|
        Send, ^{Down}                                                ;|
    else                                                             ;|
        Send, +^{Down}                                               ;|
    return                                                           ;|
}                                                                    ;|
return                                                               ;|
;-----------------------------------o                                ;|
CapsLock & k::                                                       ;|
if GetKeyState("control") = 0                                        ;|
{                                                                    ;|
    if GetKeyState("alt") = 0                                        ;|
        Send, {Up}                                                   ;|
    else                                                             ;|
        Send, +{Up}                                                  ;|
    return                                                           ;|
}                                                                    ;|
else {                                                               ;|
    if GetKeyState("alt") = 0                                        ;|
        Send, ^{Up}                                                  ;|
    else                                                             ;|
        Send, +^{Up}                                                 ;|
    return                                                           ;|
}                                                                    ;|
return                                                               ;|
;-----------------------------------o                                ;|
CapsLock & l::                                                       ;|
if GetKeyState("control") = 0                                        ;|
{                                                                    ;|
    if GetKeyState("alt") = 0                                        ;|
        Send, {Right}                                                ;|
    else                                                             ;|
        Send, +{Right}                                               ;|
    return                                                           ;|
}                                                                    ;|
else {                                                               ;|
    if GetKeyState("alt") = 0                                        ;|
        Send, ^{Right}                                               ;|
    else                                                             ;|
        Send, +^{Right}                                              ;|
    return                                                           ;|
}                                                                    ;|
return                                                               ;|
;---------------------------------------------------------------------o


;=====================================================================o
;                     CapsLock Home/End Navigator                    ;|
;-----------------------------------o---------------------------------o
;                      CapsLock + 4 |  Home                          ;|
;                      CapsLock + e |  End                           ;|
;                      Ctrl, Alt Compatible                          ;|
;-----------------------------------o---------------------------------o
CapsLock & a::                                                       ;|
if GetKeyState("control") = 0                                        ;|
{                                                                    ;|
    if GetKeyState("alt") = 0                                        ;|
        Send, {Home}                                                 ;|
    else                                                             ;|
        Send, +{Home}                                                ;|
    return                                                           ;|
}                                                                    ;|
else {                                                               ;|
    if GetKeyState("alt") = 0                                        ;|
        Send, ^{Home}                                                ;|
    else                                                             ;|
        Send, +^{Home}                                               ;|
    return                                                           ;|
}                                                                    ;|
return                                                               ;|
;-----------------------------------o                                ;|
CapsLock & e::                                                       ;|
if GetKeyState("control") = 0                                        ;|
{                                                                    ;|
    if GetKeyState("alt") = 0                                        ;|
        Send, {End}                                                  ;|
    else                                                             ;|
        Send, +{End}                                                 ;|
    return                                                           ;|
}                                                                    ;|
else {                                                               ;|
    if GetKeyState("alt") = 0                                        ;|
        Send, ^{End}                                                 ;|
    else                                                             ;|
        Send, +^{End}                                                ;|
    return                                                           ;|
}                                                                    ;|
return                                                               ;|
;---------------------------------------------------------------------o


;=====================================================================o
;                      CapsLock Page Navigator                       ;|
;-----------------------------------o---------------------------------o
;                      CapsLock + u |  PageUp                        ;|
;                      CapsLock + d |  PageDown                      ;|
;                      Ctrl, Alt Compatible                          ;|
;-----------------------------------o---------------------------------o
;;CapsLock & u::                                                       ;|
;;if GetKeyState("control") = 0                                        ;|
;;{                                                                    ;|
;;    if GetKeyState("alt") = 0                                        ;|
;;        Send, {PgUp}                                                 ;|
;;    else                                                             ;|
;;        Send, +{PgUp}                                                ;|
;;    return                                                           ;|
;;}                                                                    ;|
;;else {                                                               ;|
;;    if GetKeyState("alt") = 0                                        ;|
;;        Send, ^{PgUp}                                                ;|
;;    else                                                             ;|
;;        Send, +^{PgUp}                                               ;|
;;    return                                                           ;|
;;}                                                                    ;|
;;return                                                               ;|
;;-----------------------------------o                                ;|
;CapsLock & d::                                                       ;|
;if GetKeyState("control") = 0                                        ;|
;{                                                                    ;|
;    if GetKeyState("alt") = 0                                        ;|
;        Send, {PgDn}                                                 ;|
;    else                                                             ;|
;        Send, +{PgDn}                                                ;|
;    return                                                           ;|
;}                                                                    ;|
;else {                                                               ;|
;    if GetKeyState("alt") = 0                                        ;|
;        Send, ^{PgDn}                                                ;|
;    else                                                             ;|
;        Send, +^{PgDn}                                               ;|
;    return                                                           ;|
;}                                                                    ;|
;return                                                               ;|
;---------------------------------------------------------------------o


;=====================================================================o
;                     CapsLock Mouse Controller                      ;|
;-----------------------------------o---------------------------------o
;                   CapsLock + Up   |  Mouse Up                      ;|
;                   CapsLock + Down |  Mouse Down                    ;|
;                   CapsLock + Left |  Mouse Left                    ;|
;                  CapsLock + Right |  Mouse Right                   ;|
;    CapsLock + Enter(Push Release) |  Mouse Left Push(Release)      ;|
;-----------------------------------o---------------------------------o
CapsLock & Up::    MouseMove, 0, -10, 0, R                           ;|
CapsLock & Down::  MouseMove, 0, 10, 0, R                            ;|
CapsLock & Left::  MouseMove, -10, 0, 0, R                           ;|
CapsLock & Right:: MouseMove, 10, 0, 0, R                            ;|
;Shift & Right::
;mouseClickDrag, L,0,0,50,0,,R
;return
;MouseGetPos, xpos, ypos
;Msgbox, The cursor is at X%xpos% Y%ypos%
;mouseClickDrag, L,0,0,50,0,,R
;return                                           ;|
;-----------------------------------o                                ;|
;CapsLock & Enter::                                                   ;|
;SendEvent {Blind}{LButton down}                                      ;|
;KeyWait Enter                                                        ;|
;SendEvent {Blind}{LButton up}                                        ;|
;return                                                               ;|
;---------------------------------------------------------------------o


;=====================================================================o
;                           CapsLock Deletor                         ;|
;-----------------------------------o---------------------------------o
;                     CapsLock + n  |  Ctrl + Delete (Delete a Word) ;|
;                     CapsLock + m  |  Delete                        ;|
;                     CapsLock + ,  |  BackSpace                     ;|
;                     CapsLock + .  |  Ctrl + BackSpace              ;|	
;-----------------------------------o---------------------------------o
;CapsLock & ,:: Send, {Del}                                           ;|
;CapsLock & .:: Send, ^{Del}                                          ;|
CapsLock & m:: Send, {Del}                                           ;|
CapsLock & n:: Send, {BS}                                             ;|
CapsLock & w:: Send, ^{BS}                                            ;|
CapsLock & u:: Send, +{Home} {Del}                                    ;|
;CapsLock & f:: Send, ^{right}                                        ;|
CapsLock & b:: Send, ^{left}                                          ;|
;CapsLock & k:: Send, +{End}  {Del}                                   ;|
CapsLock & i:: Send, +{Ins}                                           ;|
CapsLock & Enter::Send, {End} {return}
CapsLock & \::
if GetKeyState("control") = 0   
{                               
    if GetKeyState("alt") = 0   
        Send, {Up}              
    else                        
        Send, +{Up}                          
}                               
else {                          
    if GetKeyState("alt") = 0   
        Send, ^{Up}             
    else                        
        Send, +^{Up}                                 
}       
Send, {End} 
Send, {return}
return
;disable the combo shift+return
Shift & Enter:: return
;---------------------------------------------------------------------o

;=====================================================================o
;                            CapsLock + number: win+number            ;|

;-----------------------------------o---------------------------------o
CapsLock & 1:: Send, #1                                               ;|
CapsLock & 2:: Send, #2                                               ;| 
CapsLock & 3:: Send, #3                                               ;|  
CapsLock & 4:: Send, #4                                               ;|  
CapsLock & 5:: Send, #5                                               ;|  
CapsLock & 6:: Send, #6                                               ;|  
CapsLock & 7:: Send, #7                                               ;|
CapsLock & 8:: Send, #8                                               ;|
CapsLock & 9:: Send, #9                                               ;|
CapsLock & 0:: Send, #0                                               ;|
;;CapsLock & a:: Send, ^a                                             ;|
;CapsLock & y:: Send, ^y                                              ;|
;;CapsLock & w:: Send, ^{Right}                                       ;|
;CapsLock & b:: Send, ^{Left}                                         ;|
;;---------------------------------------------------------------------o



;=====================================================================o
;                            CapsLock Editor                         ;|
;-----------------------------------o---------------------------------o
;                     CapsLock + z  |  Ctrl + z (Cancel)             ;|
;                     CapsLock + x  |  Ctrl + x (Cut)                ;|
;                     CapsLock + c  |  Ctrl + c (Copy)               ;|
;                     CapsLock + v  |  Ctrl + z (Paste)              ;|
;                     CapsLock + a  |  Ctrl + a (Select All)         ;|
;                     CapsLock + y  |  Ctrl + z (Yeild)              ;|
;                     CapsLock + w  |  Ctrl + Right(Move as [vim: w]);|
;                     CapsLock + b  |  Ctrl + Left (Move as [vim: b]);|
;-----------------------------------o---------------------------------o
;CapsLock & z:: Send, ^z                                              ;|
;CapsLock & x:: Send, ^x                                              ;|
;CapsLock & c:: Send, ^c                                              ;|
;CapsLock & v:: Send, ^v                                              ;|
;;CapsLock & a:: Send, ^a                                             ;|
;CapsLock & y:: Send, ^y                                              ;|
;;CapsLock & w:: Send, ^{Right}                                       ;|
;CapsLock & b:: Send, ^{Left}                                         ;|
;;---------------------------------------------------------------------o


;=====================================================================o
;                       CapsLock Special character                   ;|
;-----------------------------------o---------------------------------o
;                    CapsLock + F1  |                                ;|
;                    CapsLock + F2  |                                ;|
;                    CapsLock + F3  |  Volume_Up                     ;|
;                    CapsLock + F3  |  Media_Play_Pause              ;|
;                    CapsLock + F5  |  Media_Next                    ;|
;                    CapsLock + F6  |  Media_Stop                    ;|
;-----------------------------------o---------------------------------o
;vim related; %:p will return the full path and name of the file      ;|
;` is the escape sign for %                                           ;|
CapsLock & F1:: SendRaw, `%:p				                          ;|
;vim related; %:p:h will return the path of the file                  ;|
CapsLock & F2:: SendRaw, `%:p:h                                       ;|
;CapsLock & F3:: Send, {Volume_Up}                                    ;|
;CapsLock & F4:: Send, {Media_Play_Pause}                             ;|
;CapsLock & F5:: Send, {Media_Next}                                   ;|
;CapsLock & F6:: Send, {Media_Stop}                                   ;|
;;---------------------------------------------------------------------o


;=====================================================================o
;                      CapsLock Window Controller                    ;|
;-----------------------------------o---------------------------------o
;                     CapsLock + s  |  Ctrl + Tab (Swith Tag)        ;|
;                     CapsLock + q  |  Ctrl + W   (Close Tag)        ;|
;   (Disabled)  Alt + CapsLock + s  |  AltTab     (Switch Windows)   ;|
;               Alt + CapsLock + q  |  Ctrl + Tab (Close Windows)    ;|
;                     CapsLock + g  |  AppsKey    (Menu Key)         ;|
;-----------------------------------o---------------------------------o
;CapsLock & s::Send, ^{Tab}                                           ;|
;;-----------------------------------o                                ;|
;CapsLock & q::                                                       ;|
;if GetKeyState("alt") = 0                                            ;|
;{                                                                    ;|
;    Send, ^w                                                         ;|
;}                                                                    ;|
;else {                                                               ;|
;    Send, !{F4}                                                      ;|
;    return                                                           ;|
;}                                                                    ;|
;return                                                               ;|
;;-----------------------------------o                                ;|
;CapsLock & g:: Send, {AppsKey}                                       ;|
;;---------------------------------------------------------------------o

;=====================================================================o
;                      CapsLock Window Controller                    ;|
;                      CapsLock + f / Win+Tab (Switch windows)       ;|
;                      CapsLock + r / Alt+Tab (Switch windows)       ;|
;-----------------------------------o---------------------------------o
CapsLock & r::Send, !{Tab}
CapsLock & f::Send, {LWin Down}{Tab}{LWinUp}


;=====================================================================o
;                        CapsLock Self Defined Area                  ;|
;-----------------------------------o---------------------------------o
;                     CapsLock + d  |  Alt + d(Dictionary)           ;|
;                     CapsLock + f  |  Alt + f(Search via Everything);|
;                     CapsLock + e  |  Open Search Engine            ;|
;                     CapsLock + r  |  Open Shell                    ;|
;                     CapsLock + t  |  Open Text Editor              ;|
;-----------------------------------o---------------------------------o
;CapsLock & d:: Send, !d                                              ;|
;CapsLock & f:: Send, !f                                              ;|
;CapsLock & e:: Run http://cn.bing.com/                               ;|
;CapsLock & r:: Run Powershell                                        ;|
;CapsLock & t:: Run C:\Program Files (x86)\Notepad++\notepad++.exe    ;|
;---------------------------------------------------------------------o


;=====================================================================o
;                        CapsLock Char Mapping                       ;|
;-----------------------------------o---------------------------------o
;                     CapsLock + ;  |  tmux prefix = ctrl + b        ;|
;                     CapsLock + '  |  =                             ;|
;                     CapsLock + [  |  Back         (Visual Studio)  ;|
;                     CapsLock + ]  |  Goto Define  (Visual Studio)  ;|
;                     CapsLock + /  |  Comment      (Visual Studio)  ;|
;                     CapsLock + \  |  Uncomment    (Visual Studio)  ;|
;                     CapsLock + 1  |  Build and Run(Visual Studio)  ;|
;                     CapsLock + 2  |  Debuging     (Visual Studio)  ;|
;                     CapsLock + 3  |  Step Over    (Visual Studio)  ;|
;                     CapsLock + 4  |  Step In      (Visual Studio)  ;|
;                     CapsLock + 5  |  Stop Debuging(Visual Studio)  ;|
;                     CapsLock + 6  |  Shift + 6     ^               ;|
;                     CapsLock + 7  |  Shift + 7     &               ;|
;                     CapsLock + 8  |  Shift + 8     *               ;|
;                     CapsLock + 9  |  Shift + 9     (               ;|
;                     CapsLock + 0  |  Shift + 0     )               ;|
;-----------------------------------o---------------------------------o
 CapsLock & `;:: Send, ^b
;CapsLock & `;:: Send, {Enter}                                        ;|
;CapsLock & ':: Send, =                                               ;|
;CapsLock & [:: Send, ^-                                              ;|
;CapsLock & ]:: Send, {F12}                                           ;|
;;-----------------------------------o                                ;|
;CapsLock & /::                                                       ;|
;Send, ^e                                                             ;|
;Send, c                                                              ;|
;return                                                               ;|
;;-----------------------------------o                                ;|
;CapsLock & \::                                                       ;|
;Send, ^e                                                             ;|
;Send, u                                                              ;|
;return                                                               ;|
;;-----------------------------------o                                ;|
;CapsLock & 1:: Send,^{F5}                                            ;|
;CapsLock & 2:: Send,{F5}                                             ;|
;CapsLock & 3:: Send,{F10}                                            ;|
;CapsLock & 4:: Send,{F11}                                            ;|
;CapsLock & 5:: Send,+{F5}                                            ;|
;;-----------------------------------o                                ;|
;CapsLock & 6:: Send,+6                                               ;|
;CapsLock & 7:: Send,+7                                               ;|
;CapsLock & 8:: Send,+8                                               ;|
;CapsLock & 9:: Send,+9                                               ;|
;CapsLock & 0:: Send,+0                                               ;|
;;---------------------------------------------------------------------o

;=====================================================================o
;                        CapsLock Char for clipmate                   |
;                        (only apply in climate)                      |
;-----------------------------------o---------------------------------o
;                     CapsLock + f  |  F8 to select collections      ;|
;-----------------------------------o---------------------------------o
CapsLock & ':: Send, ^'
#IfWinActive, ClipMate Classic
CapsLock & f:: Send, {f8}
#IfWinActive, ClipMate Explorer
CapsLock & f:: Send, {f8}
#IfWinActive
