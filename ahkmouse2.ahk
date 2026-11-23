#NoEnv
#SingleInstance Force
#InstallKeybdHook
SendMode Input
SetBatchLines, -1
SetMouseDelay, -1

; ---------- Settings ----------
moveSpeed := 12
fastMultiplier := 2

; Alternate mode, relative to the original speeds:
alternateNormalMultiplier := 3.2
alternateAltMultiplier := 0.7

scrollInterval := 80
scrollAmount := 1

notificationDuration := 3000
notificationX := 16
notificationY := 16

notificationBrightColor := "35D9C5"
notificationBrightText := "102724"
notificationDarkColor := "202020"
notificationDarkText := "F0F0F0"
; ------------------------------

; Start in the original speed mode.
alternateSpeedMode := false

lastScroll := 0
lastCapsState := GetKeyState("CapsLock", "T")

; Create a borderless, click-through notification.
; It will not take focus from the active application.
Gui, CapsOSD:New, +AlwaysOnTop -Caption +ToolWindow +E0x08000020
Gui, CapsOSD:Color, %notificationDarkColor%
Gui, CapsOSD:Margin, 16, 12
Gui, CapsOSD:Font, s11 cF0F0F0, Segoe UI
Gui, CapsOSD:Add, Text, vCapsStatus w430 h24 +0x200, Mouse controls

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
*i::
*j::
*k::
*l::
*7::
*8::
*9::
return

; Toggle speed mode with the equals key.
; KeyWait prevents repeated toggles when the key is held.
*=::
    alternateSpeedMode := !alternateSpeedMode
    Gosub, ShowSpeedNotification
    KeyWait, =
return

; Navigation key remaps.
y::PgDn
6::PgUp
5::Home
t::End

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
            altHeld := GetKeyState("Alt", "P")

            if (alternateSpeedMode)
            {
                if (altHeld)
                {
                    ; 0.7x the ORIGINAL Alt-held speed.
                    speed := moveSpeed * fastMultiplier
                        * alternateAltMultiplier
                }
                else
                {
                    ; 3.2x the ORIGINAL normal speed.
                    speed := moveSpeed * alternateNormalMultiplier
                }
            }
            else
            {
                ; Original mode: normal speed, Alt for 2x speed.
                speed := moveSpeed

                if (altHeld)
                    speed *= fastMultiplier
            }

            ; Normalize diagonal movement speed.
            if (dx && dy)
                speed /= Sqrt(2)

            mx := Round(dx * speed)
            my := Round(dy * speed)
            MouseMove, %mx%, %my%, 0, R
        }
    }

    ; Hold 7 or 9 to scroll up; hold 8 to scroll down.
    scrollDown := GetKeyState("8", "P")
    scrollUp := GetKeyState("7", "P") || GetKeyState("9", "P")

    ; Opposing scroll directions cancel.
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
    if (lastCapsState)
    {
        modeName := alternateSpeedMode ? "Alternate" : "Original"
        notificationText := "Caps Lock: ON - Speed mode: " . modeName
        notificationBright := true
    }
    else
    {
        notificationText := "Caps Lock: OFF - Mouse mode OFF"
        notificationBright := false
    }

    Gosub, DisplayNotification
return


ShowSpeedNotification:
    if (alternateSpeedMode)
    {
        notificationText := "Alternate speed: fast default / Alt slows down"
        notificationBright := true
    }
    else
    {
        notificationText := "Original speed: normal default / Alt speeds up"
        notificationBright := false
    }

    Gosub, DisplayNotification
return


DisplayNotification:
    ; Restart the timer so every notification lasts three seconds.
    SetTimer, HideCapsNotification, Off

    if (notificationBright)
    {
        backgroundColor := notificationBrightColor
        textColor := notificationBrightText
    }
    else
    {
        backgroundColor := notificationDarkColor
        textColor := notificationDarkText
    }

    Gui, CapsOSD:Color, %backgroundColor%
    Gui, CapsOSD:Font, % "s11 c" . textColor, Segoe UI
    GuiControl, CapsOSD:Font, CapsStatus
    GuiControl, CapsOSD:, CapsStatus, %notificationText%

    Gui, CapsOSD:Show, % "NoActivate AutoSize x"
        . notificationX . " y" . notificationY

    SetTimer, HideCapsNotification, % -notificationDuration
return


HideCapsNotification:
    Gui, CapsOSD:Hide
return