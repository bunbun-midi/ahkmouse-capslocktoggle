l#NoEnv
#SingleInstance Force
#InstallKeybdHook
SendMode Input
SetBatchLines, -1
SetMouseDelay, -1

; ---------- Settings ----------
moveSpeed := 12         ; Pixels per movement tick
fastMultiplier := 2     ; Speed multiplier while Alt is held

scrollInterval := 80    ; Milliseconds between scroll steps
scrollAmount := 1       ; Wheel notches per scroll step

notificationDuration := 3000
notificationX := 16
notificationY := 16
; ------------------------------

lastScroll := 0
lastCapsState := GetKeyState("CapsLock", "T")

; Create a dark, borderless notification.
; Extended styles make it non-activating and click-through.
Gui, CapsOSD:New, +AlwaysOnTop -Caption +ToolWindow +E0x08000020
Gui, CapsOSD:Color, 202020
Gui, CapsOSD:Margin, 16, 12
Gui, CapsOSD:Font, s11 cF0F0F0, Segoe UI
Gui, CapsOSD:Add, Text, vCapsStatus w290 h24 +0x200, Caps Lock: OFF - Mouse mode OFF

SetTimer, MouseControl, 10
return


; Only activate these controls while Caps Lock is ON.
#If GetKeyState("CapsLock", "T")

; Shift + I/J/K/L sends ordinary arrow keys.
; Shift takes priority over Alt.
*+i::SendInput, {Up}
*+j::SendInput, {Left}
*+k::SendInput, {Down}
*+l::SendInput, {Right}

; Movement and scrolling are handled by the timer.
; Wildcards also capture these keys while modifiers are held.
*i::
*j::
*k::
*l::
*8::
*9::
return

; Mouse-button remaps: press, hold, and release.
h::LButton
SC027::LButton    ; Semicolon key on a US keyboard
Space::LButton

u::RButton
o::RButton

F7::MButton

#If


MouseControl:
    capsState := GetKeyState("CapsLock", "T")

    ; Show the notification whenever Caps Lock changes state.
    if (capsState != lastCapsState)
    {
        lastCapsState := capsState
        Gosub, ShowCapsNotification
    }

    if (!capsState)
    {
        lastScroll := 0
        return
    }

    ; Shift uses I/J/K/L as arrows, so suspend mouse movement.
    if !GetKeyState("Shift", "P")
    {
        ; Opposite directions cancel.
        ; Adjacent directions allow diagonal movement.
        dx := GetKeyState("l", "P") - GetKeyState("j", "P")
        dy := GetKeyState("k", "P") - GetKeyState("i", "P")

        if (dx || dy)
        {
            speed := moveSpeed

            ; Alt doubles mouse movement speed.
            if GetKeyState("Alt", "P")
                speed *= fastMultiplier

            ; Normalize diagonal movement speed.
            if (dx && dy)
                speed /= Sqrt(2)

            mx := Round(dx * speed)
            my := Round(dy * speed)
            MouseMove, %mx%, %my%, 0, R
        }
    }

    ; Hold 8 or 9 to scroll repeatedly.
    scrollDown := GetKeyState("8", "P")
    scrollUp := GetKeyState("9", "P")

    if (scrollDown != scrollUp)
    {
        if (!lastScroll || A_TickCount - lastScroll >= scrollInterval)
        {
            if (scrollDown)
                Click, WheelDown, %scrollAmount%
            else
                Click, WheelUp, %scrollAmount%

            lastScroll := A_TickCount
        }
    }
    else
    {
        lastScroll := 0
    }
return


ShowCapsNotification:
    ; Cancel any previous hide timer so each change gets
    ; a fresh three-second display period.
    SetTimer, HideCapsNotification, Off

    if (lastCapsState)
        notificationText := "Caps Lock: ON - Mouse mode ON"
    else
        notificationText := "Caps Lock: OFF - Mouse mode OFF"

    GuiControl, CapsOSD:, CapsStatus, %notificationText%

    Gui, CapsOSD:Show, % "NoActivate AutoSize x"
        . notificationX . " y" . notificationY

    SetTimer, HideCapsNotification, % -notificationDuration
return


HideCapsNotification:
    Gui, CapsOSD:Hide
return
