;=====================================================================o
;                   Feng Ruohang's AHK Script                   
;                      CapsLock Enhancement                     
;---------------------------------------------------------------------o
;Description:                                                     
;    This Script is wrote by Feng Ruohang via AutoHotKey Script. It 
; Provieds an enhancement towards the "Useless Key" CapsLock, and 
; turns CapsLock into an useful function Key just like Ctrl and Alt   
; by combining CapsLock with almost all other keys in the keyboard.
;                                                               
;Summary:                                                       
;o----------------------o---------------------------------------------o
;|CapsLock;             | {ESC}  Especially Convient for vim user    
;|CaspLock + `          | {CapsLock}CapsLock Switcher as a Substituent
;|CapsLock + hjklwb     | Vim-Style Cursor Mover                    
;|CaspLock + uiop       | Convient Home/End PageUp/PageDn         
;|CaspLock + nm,.       | Convient Delete Controller                  
;|CapsLock + zxcvay     | Windows-Style Editor                       
;|CapsLock + Direction  | Mouse Move                               
;|CapsLock + Enter      | Mouse Click                               
;|CaspLock + {F1}~{F6}  | Media Volume Controller                    
;|CapsLock + qs         | Windows & Tags Control                   
;|CapsLock + ;'[]       | Convient Key Mapping                      
;|CaspLock + dfert      | Frequently Used Programs (Self Defined)     
;|CaspLock + 123456     | Dev-Hotkey for Visual Studio (Self Defined) 
;|CapsLock + 67890-=    | Shifter as Shift                            
;-----------------------o---------------------------------------------o
;|Use it whatever and wherever you like. Hope it help                
;=====================================================================o

;=====================================================================o
;# 号代表 Win 键；
;! 号代表 Alt 键；
;^ 号代表 Ctrl 键；
;+ 号代表 shift 键；
;:: 号(两个英文冒号)起分隔作用；
;run，非常常用 的 AHK 命令之一;
;; 号代表 注释后面一行内容；
;=====================================================================o


;=====================================================================o
;                       CapsLock Initializer                         
;---------------------------------------------------------------------o
SetCapsLockState, AlwaysOff                                         
;---------------------------------------------------------------------o


;=====================================================================o
;                       CapsLock Switcher:                         
;---------------------------------o-----------------------------------c
;                    CapsLock + ` | {CapsLock}                     
;---------------------------------o-----------------------------------o
CapsLock & `::                                                     
GetKeyState, CapsLockState, CapsLock, T                             
if CapsLockState = D                                               
    SetCapsLockState, AlwaysOff                                    
else                                                              
    SetCapsLockState, AlwaysOn                                     
KeyWait, ``                                                        
return                                                            
;---------------------------------------------------------------------o

;=====================================================================o
;                         CapsLock Escaper:                          ;|
;----------------------------------o----------------------------------o
;                        CapsLock  |  {ESC}                          ;|
;----------------------------------o----------------------------------o
CapsLock::Send, {ESC}                                                ;|
;---------------------------------------------------------------------o

;=====================================================================o
;                       CapsLock Switcher:                                           
;
; CapsLock + space | Left Alt + shift (switch input method for Windows 10)
;
;=====================================================================o
CapsLock & Space::
Send, {LAlt Down}
Send, {Shift}
Send, {LAlt Up}
Return

;=====================================================================o
;                         CapsLock switcher for textexpander:                       
;----------------------------------o----------------------------------o
;                                                                        
;----------------------------------o----------------------------------o
;CapsLock::Send, {ESC}                                             
CapsLock & e:: Send, ^+e                                       
;---------------------------------------------------------------------o

;=====================================================================o
;                       CapsLock Switcher:                           
;---------------------------------o-----------------------------------c
;                    ALT + SPACE | {Listary}                         
;                    simuate 2 Ctrls                                 
;---------------------------------o-----------------------------------o
;!Space::

;---------------------------------------------------------------------o


;=====================================================================o
;                         CapsLock Escaper:                       
;----------------------------------o----------------------------------o
;                        CapsLock  |  {ESC}                       
; since ESC will close the editing window sometimes                 
; instead, we use ctrl+[ to send {ESC}                              
;----------------------------------o----------------------------------o
;CapsLock::Send, {ESC}                                             
CapsLock & [:: Send, {ESC}                                         
;---------------------------------------------------------------------o


;=====================================================================o
;                    CapsLock Direction Navigator             
;-----------------------------------o---------------------------------o
;                      CapsLock + h |  Left                  
;                      CapsLock + j |  Down                 
;                      CapsLock + k |  Up                   
;                      CapsLock + l |  Right                  
;                      Ctrl, Alt Compatible                    
;-----------------------------------o---------------------------------o
CapsLock & h::                                               
if GetKeyState("control") = 0                                  
{                                                           
    if GetKeyState("alt") = 0                                  
        Send, {Left}                                          
    else                                                     
        Send, +{Left}                                        
    return                                                   
}                                                           
else {                                                       
    if GetKeyState("alt") = 0                                  
        Send, ^{Left}                                        
    else                                                     
        Send, +^{Left}                                       
    return                                                   
}                                                           
return                                                       
;-----------------------------------o                              
CapsLock & j::                                               
if GetKeyState("control") = 0                                  
{                                                           
    if GetKeyState("alt") = 0                                  
        Send, {Down}                                        
    else                                                     
        Send, +{Down}                                       
    return                                                   
}                                                           
else {                                                       
    if GetKeyState("alt") = 0                                  
        Send, ^{Down}                                       
    else                                                     
        Send, +^{Down}                                      
    return                                                   
}                                                           
return                                                
;-----------------------------------o                            
CapsLock & k::                                        
if GetKeyState("control") = 0                           
{                                                     
    if GetKeyState("alt") = 0                           
        Send, {Up}                                    
    else                                              
        Send, +{Up}                                   
    return                                            
}                                                     
else {                                                 
    if GetKeyState("alt") = 0                           
        Send, ^{Up}                                   
    else                                              
        Send, +^{Up}                                  
    return                                            
}                                                     
return                                                
;-----------------------------------o                            
CapsLock & l::                                         
if GetKeyState("control") = 0                                  
{                                                           
    if GetKeyState("alt") = 0                                  
        Send, {Right}                                        
    else                                                     
        Send, +{Right}                                       
    return                                                   
}                                                           
else {                                                       
    if GetKeyState("alt") = 0                                  
        Send, ^{Right}                                       
    else                                                     
        Send, +^{Right}                                      
    return                                                   
}                                                           
return                                                       
;---------------------------------------------------------------------o


;=====================================================================o
;                     CapsLock Home/End Navigator          
;-----------------------------------o---------------------------------o
;                      CapsLock + 4 |  Home                
;                      CapsLock + e |  End                  
;                      Ctrl, Alt Compatible                   
;-----------------------------------o---------------------------------o
;CapsLock & a::                                              
;if GetKeyState("control") = 0                                 
;{                                                           
;    if GetKeyState("alt") = 0                                 
;        Send, {Home}                                       
;    else                                                    
;        Send, +{Home}                                      
;    return                                                  
;}                                                           
;else {                                                       
;    if GetKeyState("alt") = 0                                 
;        Send, ^{Home}                                      
;    else                                                    
;        Send, +^{Home}                                     
;    return                                                  
;}                                                           
return                                                      
;-----------------------------------o                               
;CapsLock & e::                                              
;if GetKeyState("control") = 0                                 
;{                                                           
;    if GetKeyState("alt") = 0                                 
;        Send, {End}                                         
;    else                                                    
;        Send, +{End}                                        
;    return                                                  
;}                                                           
;else {                                                       
;    if GetKeyState("alt") = 0                                 
;        Send, ^{End}                                        
;    else                                                    
;        Send, +^{End}                                       
;    return                                                  
;}                                                           
;return                                                      
;---------------------------------------------------------------------o


;=====================================================================o
;                      CapsLock Page Navigator           
;-----------------------------------o---------------------------------o
;                      CapsLock + u |  PageUp            
;                      CapsLock + d |  PageDown         
;                      Ctrl, Alt Compatible                
;-----------------------------------o---------------------------------o
;;CapsLock & u::                                          
;;if GetKeyState("control") = 0                             
;;{                                                       
;;    if GetKeyState("alt") = 0                             
;;        Send, {PgUp}                                    
;;    else                                                
;;        Send, +{PgUp}                                   
;;    return                                              
;;}                                                       
;;else {                                                   
;;    if GetKeyState("alt") = 0                             
;;        Send, ^{PgUp}                                   
;;    else                                                
;;        Send, +^{PgUp}                                 
;;    return                                              
;;}                                                       
;;return                                                  
;;-----------------------------------o                              
;CapsLock & d::                                           
;if GetKeyState("control") = 0                              
;{                                                       
;    if GetKeyState("alt") = 0                              
;        Send, {PgDn}                                    
;    else                                                 
;        Send, +{PgDn}                                   
;    return                                               
;}                                                       
;else {                                                   
;    if GetKeyState("alt") = 0                              
;        Send, ^{PgDn}                                   
;    else                                                 
;        Send, +^{PgDn}                                  
;    return                                               
;}                                                       
;return                                                   
;---------------------------------------------------------------------o


;=====================================================================o
;                     CapsLock Mouse Controller                    
;-----------------------------------o---------------------------------o
;                   CapsLock + Up   |  Mouse Up                  
;                   CapsLock + Down |  Mouse Down               
;                   CapsLock + Left |  Mouse Left                  
;                  CapsLock + Right |  Mouse Right                 
;    CapsLock + Enter(Push Release) |  Mouse Left Push(Release)      
;-----------------------------------o---------------------------------o
CapsLock & Up::    MouseMove, 0, -10, 0, R                         
CapsLock & Down::  MouseMove, 0, 10, 0, R                         
CapsLock & Left::  MouseMove, -10, 0, 0, R                          
CapsLock & Right:: MouseMove, 10, 0, 0, R                          
Shift & Right::
mouseClickDrag, L,0,0,50,0,,R
return
MouseGetPos, xpos, ypos
Msgbox, The cursor is at X%xpos% Y%ypos%
mouseClickDrag, L,0,0,50,0,,R
return  

#IfWinActive, ahk_exe MobaXterm.exe ; determined by the AHK tools window spy
CapsLock & R::
MouseMove, 1355, 150
if vPosY2 < 720
{
Click Right
MouseMove, 10, 0, 0, R
MouseMove, 0, 300, 0, R 
mouseClickDrag, L,0,0,50,0,,R
}
else
{
Click Right
MouseMove, 10, 0, 0, R
MouseMove, 0, -250, 0, R 
mouseClickDrag, L,0,0,50,0,,R
}
MouseMove, 1355, 0
return
#IfWinActive                            
;-----------------------------------o                       
;CapsLock & Enter::                                                 
;SendEvent {Blind}{LButton down}                                    
;KeyWait Enter                                                     
;SendEvent {Blind}{LButton up}                                      
;return                                                            
;---------------------------------------------------------------------o


;=====================================================================o
;                           CapsLock Deletor                        
;-----------------------------------o---------------------------------o
;                     CapsLock + n  |  Ctrl + Delete (Delete a Word) 
;                     CapsLock + m  |  Delete                       
;                     CapsLock + ,  |  BackSpace                    
;                     CapsLock + .  |  Ctrl + BackSpace              	
;-----------------------------------o---------------------------------o
CapsLock & ,:: Send, ^{BS}                                           
CapsLock & .:: Send, ^{Del}                                          
CapsLock & m:: Send, {Del}                                          
CapsLock & n:: Send, {BS}                                           
;CapsLock & w:: Send, ^{BS}                                         
CapsLock & u:: Send, +{Home} {Del}                                  
;CapsLock & f:: Send, ^{right}                                        
CapsLock & b:: Send, ^{left}                                         
;CapsLock & k:: Send, +{End}  {Del}                                  
CapsLock & i:: Send, +{Ins}                                          
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
;                            CapsLock + number: win+number       
;-----------------------------------o---------------------------------o
CapsLock & 1:: Send, #1                                            
CapsLock & 2:: Send, #2                                            
CapsLock & 3:: Send, #3                                            
CapsLock & 4:: Send, #4                                            
CapsLock & 5:: Send, #5                                            
CapsLock & 6:: Send, #6                                            
CapsLock & 7:: Send, #7                                            
CapsLock & 8:: Send, #8                                            
CapsLock & 9:: Send, #9                                            
CapsLock & 0:: Send, #0                                            
;;CapsLock & a:: Send, ^a                                           
;CapsLock & y:: Send, ^y                                           
;;CapsLock & w:: Send, ^{Right}                                      
;CapsLock & b:: Send, ^{Left}                                        
;;---------------------------------------------------------------------o



;=====================================================================o
;                            CapsLock Editor                     
;-----------------------------------o---------------------------------o
;                     CapsLock + z  |  Ctrl + z (Cancel)           
;                     CapsLock + x  |  Ctrl + x (Cut)             
;                     CapsLock + c  |  Ctrl + c (Copy)            
;                     CapsLock + v  |  Ctrl + z (Paste)           
;                     CapsLock + a  |  Ctrl + a (Select All)        
;                     CapsLock + y  |  Ctrl + z (Yeild)            
;                     CapsLock + w  |  Ctrl + Right(Move as [vim: w]);|
;                     CapsLock + b  |  Ctrl + Left (Move as [vim: b]);|
;-----------------------------------o---------------------------------o
;CapsLock & z:: Send, ^z                                            
;CapsLock & x:: Send, ^x                                            
;CapsLock & c:: Send, ^c                                            
;CapsLock & v:: Send, ^v                                            
;;CapsLock & a:: Send, ^a                                            
;CapsLock & y:: Send, ^y                                            
;;CapsLock & w:: Send, ^{Right}                                      
;CapsLock & b:: Send, ^{Left}                                        
;;---------------------------------------------------------------------o


;=====================================================================o
;                       CapsLock Special character                
;-----------------------------------o---------------------------------o
;                    CapsLock + F1  |                            
;                    CapsLock + F2  |                            
;                    CapsLock + F3  |  Volume_Up                
;                    CapsLock + F3  |  Media_Play_Pause          
;                    CapsLock + F5  |  Media_Next               
;                    CapsLock + F6  |  Media_Stop                
;-----------------------------------o---------------------------------o
;vim related; %:p will return the full path and name of the file     
;` is the escape sign for %                                       
CapsLock & F1:: SendRaw, `%:p				                    
;vim related; %:p:h will return the path of the file                  
CapsLock & F2:: SendRaw, `%:p:h                                  
;CapsLock & F3:: Send, {Volume_Up}                               
;CapsLock & F4:: Send, {Media_Play_Pause}                         
;CapsLock & F5:: Send, {Media_Next}                               
;CapsLock & F6:: Send, {Media_Stop}                               
;;---------------------------------------------------------------------o


;=====================================================================o
;                      CapsLock Window Controller                   
;-----------------------------------o---------------------------------o
;                     CapsLock + s  |  Ctrl + Tab (Swith Tag)        
;                     CapsLock + q  |  Ctrl + W   (Close Tag)        
;   (Disabled)  Alt + CapsLock + s  |  AltTab     (Switch Windows)  
;               Alt + CapsLock + q  |  Ctrl + Tab (Close Windows)    
;                     CapsLock + g  |  AppsKey    (Menu Key)       
;-----------------------------------o---------------------------------o
;CapsLock & s::Send, ^{Tab}                                          
;;-----------------------------------o                                
;CapsLock & q::                                                 
;if GetKeyState("alt") = 0                                        
;{                                                               
;    Send, ^w                                                  
;}                                                               
;else {                                                           
;    Send, !{F4}                                                  
;    return                                                      
;}                                                               
;return                                                          
;;-----------------------------------o                                
;CapsLock & g:: Send, {AppsKey}                                      
;;---------------------------------------------------------------------o

;===========================================================================================
;                      CapsLock Window Controller                                        
;                      CapsLock + f / ctrl+Shift+Space (Switch windows in switcheroo)       ;
;                      CapsLock + r / Alt+Tab (Switch windows)                            
;-----------------------------------o-------------------------------------------------------
CapsLock & r::Send, !{Tab}
;CapsLock & f::Send, {LWin Down}{Tab}{LWinUp}
CapsLock & f::Send, ^+{Space}


;=====================================================================o
;                        CapsLock Self Defined Area                
;-----------------------------------o---------------------------------o
;                     CapsLock + d  |  Alt + d(Dictionary)          
;                     CapsLock + f  |  Alt + f(Search via Everything)
;                     CapsLock + e  |  Open Search Engine         
;                     CapsLock + r  |  Open Shell                  
;                     CapsLock + t  |  Open Text Editor            
;-----------------------------------o---------------------------------o
;CapsLock & d:: Send, !d                                           
;CapsLock & f:: Send, !f                                            
;CapsLock & e:: Run http://cn.bing.com/                             
;CapsLock & r:: Run Powershell                                      
;CapsLock & t:: Run C:\Program Files (x86)\Notepad++\notepad++.exe  
;---------------------------------------------------------------------o


;=====================================================================o
;                        CapsLock Char Mapping                    
;-----------------------------------o---------------------------------o
;                     CapsLock + ;  |  tmux prefix = ctrl + b        
;                     CapsLock + '  |  =                           
;                     CapsLock + [  |  Back         (Visual Studio)  
;                     CapsLock + ]  |  Goto Define  (Visual Studio) 
;                     CapsLock + /  |  Comment      (Visual Studio) 
;                     CapsLock + \  |  Uncomment    (Visual Studio) 
;                     CapsLock + 1  |  Build and Run(Visual Studio)  
;                     CapsLock + 2  |  Debuging     (Visual Studio)  
;                     CapsLock + 3  |  Step Over    (Visual Studio)  
;                     CapsLock + 4  |  Step In      (Visual Studio) 
;                     CapsLock + 5  |  Stop Debuging(Visual Studio)  
;                     CapsLock + 6  |  Shift + 6     ^             
;                     CapsLock + 7  |  Shift + 7     &             
;                     CapsLock + 8  |  Shift + 8     *              
;                     CapsLock + 9  |  Shift + 9     (              
;                     CapsLock + 0  |  Shift + 0     )              
;-----------------------------------o---------------------------------o
 CapsLock & `;:: Send, ^b
;CapsLock & `;:: Send, {Enter}                             
;CapsLock & ':: Send, =                                   
;CapsLock & [:: Send, ^-                                  
;CapsLock & ]:: Send, {F12}                               
;;-----------------------------------o                             
;CapsLock & /::                                          
;Send, ^e                                                
;Send, c                                                 
;return                                                  
;;-----------------------------------o                             
;CapsLock & \::                                          
;Send, ^e                                                
;Send, u                                                 
;return                                                  
;;-----------------------------------o                             
;CapsLock & 1:: Send,^{F5}                                
;CapsLock & 2:: Send,{F5}                                 
;CapsLock & 3:: Send,{F10}                                
;CapsLock & 4:: Send,{F11}                                
;CapsLock & 5:: Send,+{F5}                                
;;-----------------------------------o                             
;CapsLock & 6:: Send,+6                                  
;CapsLock & 7:: Send,+7                                  
;CapsLock & 8:: Send,+8                                  
;CapsLock & 9:: Send,+9                                  
;CapsLock & 0:: Send,+0                                  
;;---------------------------------------------------------------------o

;=====================================================================o
;                        CapsLock Char for clipmate              
;                        (only apply in climate)                  
;-----------------------------------o---------------------------------o
;                     CapsLock + f  |  F8 to select collections     
;-----------------------------------o---------------------------------o
CapsLock & ':: Send, ^'
#IfWinActive, ClipMate Classic  ;Begin the Special APP
CapsLock & f:: Send, {f8}
#IfWinActive, ClipMate Explorer
CapsLock & f:: Send, {f8}
#IfWinActive  ; End the Special APP

;=============================================================================o
;                        CapsLock Char for Firefox                         
;                        (only apply in firefox)                             
;-----------------------------------o-----------------------------------------o
;                     CapsLock + p  | Ctrl+Shift+E to trigger Tab group     
;                     CapsLock + p  | Ctrl+Shift+E to trigger Tab group     
;-----------------------------------o-----------------------------------------o
;#IfWinActive, Vimperator
;CapsLock & o::
;{
;MouseGetPos, xpos, ypos 
;Msgbox, The cursor is at X%xpos% Y%ypos%. 
;mouseclick, left, 2539, 322, Screen

;}
;return
;#IfWinActive

;=============================================================================o
;
;			CapsLock Char for Firefox
;-----------------------------------o-----------------------------------------o
#IfWinActive, ahk_exe firefox.exe ; determined by the AHK tools window spy
CapsLock & t:: Send, +t  ; plugin vimium, "T" list tabs
return
#IfWinActive

;=============================================================================o
;                        CapsLock Char for Evernote                   
;                        (only apply in Evernote)                      
;-----------------------------------o-----------------------------------------o
; Press ` 3 times to send ctrl+shift+l, that is to insert the code format   
;-----------------------------------o-----------------------------------------o
#IfWinActive, ahk_exe Evernote.exe ; determined by the AHK tools window spy
~`::RapidHotkey("^+l", 3)          ;Press ` 3 times to send ctrl+shift+l, that is to insert the code format  
return
#IfWinActive ; This closes the IfWinActive condition, only needed if more code is after

;=============================================================================o
;                        CapsLock Char for chrome                       
;                        (only apply in chrome)                          
;-----------------------------------o-----------------------------------------o
; CapsLock + \   |  show toomanytabs windows                            
;-----------------------------------o-----------------------------------------o
;=============================================================================o
;#IfWinActive, ahk_exe chrome.exe
;CapsLock & \:: Send, ^q
;return
;#IfWinActive

#IfWinActive, ahk_exe chrome.exe
CapsLock & t:: Send, +t  ; plugin vimium, "T" list tabs
return
#IfWinActive

;                     Helper Function: RapidHotkey
; Key::RapidHotkey("keystrokes", times, delay, IsLabel)

;"keystrokes"    ;Enter keystrokes here. E.g.: "^o"
; times          ;optional. The number of times the key must be pressed to execute.  E.g.: 3
; delay          ;optional. How quick the key must be pressed to execute. E.g.: 0.2
; IsLabel        ;optional. specify 1 to indicate that parameter 1 is a label.

;E.g. 
;~o::RapidHotkey("^o") ;open file dialog if o pressed twice

;To specify several actions , use " as separator and leave times parameter empty.
;If press times parameter is omitted, first action would be triggered on 2 presses.
;~e::RapidHotkey("#r""#e""#f") ; #r if pressed twice, #e 3 times and so on
;You can specify also one (can be also 1) or separated value for times
;~s::RapidHotkey("^s""{F12}""^+s", 5) ;so pressing 5 times = ^s, 6 times = {F12} and so on
;You can also specify separated times value
;$x::RapidHotkey("x""#r""#e", "1""5""3")

;use same separator for delay and islabel parameter

;~+::RapidHotkey("Plus")
;~h::RapidHotkey("{Raw}Hello World!", 3) ;Press h 3 times rapidly to send Hello World!
;~o::RapidHotkey("^o", 4, 0.2) ;be careful, if you use this hotkey, above will not work properly
;~Esc::RapidHotkey("exit", 4, 0.2, 1) ;Press Esc 4 times rapidly to exit this script
;~LControl::RapidHotkey("!{TAB}",2) ;Press LControl rapidly twice to AltTab
;~RControl::RapidHotkey("+!{TAB}",2) ;Press RControl rapidly twice to ShiftAltTab
;~LShift::RapidHotkey("^{TAB}", 2) ;Switch back in internal windows
;~RShift::RapidHotkey("^+{TAB}", 2) ;Switch between internal windows
;~e::RapidHotkey("#e""#r",3) ;Run Windows Explorer
;~^!7::RapidHotkey("{{}{}}{Left}", 2)

;~a::RapidHotkey("test", 2, 0.3, 1) ;You Can also specify a Label to be launched
;test:
;MsgBox, Test
;Return

;Exit:
;ExitApp

;~LButton & RButton::RapidHotkey("Menu1""Menu2""Menu3",1,0.3,1)
;Menu1:
;Menu2:
;Menu3:
;MsgBox % A_ThisLabel
;Return

;==============================================================================
RapidHotkey(keystroke, times="2", delay=0.2, IsLabel=0)
{
	Pattern := Morse(delay*1000)
	If (StrLen(Pattern) < 2 and Chr(Asc(times)) != "1")
		Return
	If (times = "" and InStr(keystroke, """"))
	{
		Loop, Parse, keystroke,""	
			If (StrLen(Pattern) = A_Index+1)
				continue := A_Index, times := StrLen(Pattern)
	}
	Else if (RegExMatch(times, "^\d+$") and InStr(keystroke, """"))
	{
		Loop, Parse, keystroke,""
			If (StrLen(Pattern) = A_Index+times-1)
				times := StrLen(Pattern), continue := A_Index
	}
	Else if InStr(times, """")
	{
		Loop, Parse, times,""
			If (StrLen(Pattern) = A_LoopField)
				continue := A_Index, times := A_LoopField
	}
	Else if (times = "")
		continue := 1, times := 2
	Else if (times = StrLen(Pattern))
		continue = 1
	If !continue
		Return
	Loop, Parse, keystroke,""
		If (continue = A_Index)
			keystr := A_LoopField
	Loop, Parse, IsLabel,""
		If (continue = A_Index)
			IsLabel := A_LoopField
	hotkey := RegExReplace(A_ThisHotkey, "[\*\~\$\#\+\!\^]")
	IfInString, hotkey, %A_Space%
		StringTrimLeft, hotkey,hotkey,% InStr(hotkey,A_Space,1,0)
	backspace := "{BS " times "}"
	keywait = Ctrl|Alt|Shift|LWin|RWin
	Loop, Parse, keywait, |
		KeyWait, %A_LoopField%
	If ((!IsLabel or (IsLabel and IsLabel(keystr))) and InStr(A_ThisHotkey, "~") and !RegExMatch(A_ThisHotkey
	, "i)\^[^\!\d]|![^\d]|#|Control|Ctrl|LCtrl|RCtrl|Shift|RShift|LShift|RWin|LWin|Alt|LAlt|RAlt|Escape|BackSpace|F\d\d?|"
	. "Insert|Esc|Escape|BS|Delete|Home|End|PgDn|PgUp|Up|Down|Left|Right|ScrollLock|CapsLock|NumLock|AppsKey|"
	. "PrintScreen|CtrlDown|Pause|Break|Help|Sleep|Browser_Back|Browser_Forward|Browser_Refresh|Browser_Stop|"
	. "Browser_Search|Browser_Favorites|Browser_Home|Volume_Mute|Volume_Down|Volume_Up|MButton|RButton|LButton|"
	. "Media_Next|Media_Prev|Media_Stop|Media_Play_Pause|Launch_Mail|Launch_Media|Launch_App1|Launch_App2"))
		Send % backspace
	If (WinExist("AHK_class #32768") and hotkey = "RButton")
		WinClose, AHK_class #32768
	If !IsLabel
		Send % keystr
	else if IsLabel(keystr)
		Gosub, %keystr%
	Return
}	
Morse(timeout = 400) { ;by Laszo -> http://www.autohotkey.com/forum/viewtopic.php?t=16951 (Modified to return: KeyWait %key%, T%tout%)
   tout := timeout/1000
   key := RegExReplace(A_ThisHotKey,"[\*\~\$\#\+\!\^]")
   IfInString, key, %A_Space%
		StringTrimLeft, key, key,% InStr(key,A_Space,1,0)
	If Key in Shift,Win,Ctrl,Alt
		key1:="{L" key "}{R" key "}"
   Loop {
      t := A_TickCount
      KeyWait %key%, T%tout%
		Pattern .= A_TickCount-t > timeout
		If(ErrorLevel)
			Return Pattern
    If key in Capslock,LButton,RButton,MButton,ScrollLock,CapsLock,NumLock
      KeyWait,%key%,T%tout% D
    else if Asc(A_ThisHotkey)=36
		KeyWait,%key%,T%tout% D
    else
      Input,pressed,T%tout% L1 V,{%key%}%key1%
	If (ErrorLevel="Timeout" or ErrorLevel=1)
		Return Pattern
	else if (ErrorLevel="Max")
		Return
   }
}
;====================================================================================

