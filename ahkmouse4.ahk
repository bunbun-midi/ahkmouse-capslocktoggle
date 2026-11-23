#NoEnv
#SingleInstance Force
#InstallKeybdHook
SendMode Input
SetBatchLines, -1
SetMouseDelay, -1

; ---------- Settings ----------
moveSpeed := 12
fastMultiplier := 2

; IJKL alternate speeds, relative to the original speeds.
ijklAlternateNormalMultiplier := 3.2
ijklAlternateAltMultiplier := 0.7

; ESDF alternate speeds, relative to the base moveSpeed.
esdfAlternateNormalMultiplier := 2
esdfAlternateAltMultiplier := 1

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

; Borderless, non-activating, click-through notification.
Gui, CapsOSD:New, +AlwaysOnTop -Caption +ToolWindow +E0x08000020
Gui, CapsOSD:Color, %notificationDarkColor%
Gui, CapsOSD:Margin, 16, 12
Gui, CapsOSD:Font, s11 cF0F0F0, Segoe UI
Gui, CapsOSD:Add, Text, vCapsStatus w460 h24 +0x200, Mouse controls

SetTimer, MouseControl, 10
return


; Only activate these controls while Caps Lock is ON.
#If GetKeyState("CapsLock", "T")

; Shift + either movement group sends ordinary arrow keys.
; Shift takes priority over Alt.
*+i::SendInput, {Up}
*+j::SendInput, {Left}
*+k::SendInput, {Down}
*+l::SendInput, {Right}

*+e::SendInput, {Up}
*+s::SendInput, {Left}
*+d::SendInput, {Down}
*+f::SendInput, {Right}

; Movement and scrolling are handled by the timer.
*i::
*j::
*k::
*l::
*e::
*s::
*d::
*f::
*7::
*8::
*9::
*c::
*v::
return

; Toggle speed mode with the equals key.
; KeyWait prevents repeated toggles while held.
*=::
    alternateSpeedMode := !alternateSpeedMode
    Gosub, ShowSpeedNotification
    KeyWait, =
return

; Navigation key remaps.
y::PgDn
x::PgDn

6::PgUp
z::PgUp

5::Home
b::Home

t::End
n::End

; Left mouse button: press, hold, and release.
h::LButton
SC027::LButton    ; Semicolon key on a US keyboard
Space::LButton
a::LButton
g::LButton

; Right mouse button: press, hold, and release.
u::RButton
o::RButton
w::RButton
r::RButton

; Middle mouse button: press, hold, and release.
F7::MButton
3::MButton

#If


MouseControl:
    capsState := GetKeyState("CapsLock", "T")

    ; Notify whenever Caps Lock changes state.
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

    ; Shift turns both movement groups into arrow keys.
    if !GetKeyState("Shift", "P")
    {
        altHeld := GetKeyState("Alt", "P")

        ; Determine each group's movement amount independently.
        if (!alternateSpeedMode)
        {
            ; Original mode:
            ; both groups use 12 normally, or 24 with Alt.
            ijklSpeed := moveSpeed

            if (altHeld)
                ijklSpeed *= fastMultiplier

            esdfSpeed := ijklSpeed
        }
        else
        {
            ; Alternate mode uses different speeds for each group.
            if (altHeld)
            {
                ; Default settings:
                ; IJKL = 16.8, ESDF = 12.
                ijklSpeed := moveSpeed * fastMultiplier
                    * ijklAlternateAltMultiplier

                esdfSpeed := moveSpeed * esdfAlternateAltMultiplier
            }
            else
            {
                ; Default settings:
                ; IJKL = 38.4, ESDF = 24.
                ijklSpeed := moveSpeed * ijklAlternateNormalMultiplier
                esdfSpeed := moveSpeed * esdfAlternateNormalMultiplier
            }
        }

        ; Every held key contributes its full signed amount.
        ; Add contributions from both groups together.
        mx := (GetKeyState("l", "P") - GetKeyState("j", "P"))
            * ijklSpeed
            + (GetKeyState("f", "P") - GetKeyState("s", "P"))
            * esdfSpeed

        my := (GetKeyState("k", "P") - GetKeyState("i", "P"))
            * ijklSpeed
            + (GetKeyState("d", "P") - GetKeyState("e", "P"))
            * esdfSpeed

        ; No diagonal normalization or group priority.
        ; Round only after adding all contributions.
        mx := Round(mx)
        my := Round(my)

        if (mx || my)
            MouseMove, %mx%, %my%, 0, R
    }

    ; Scroll down: 8 or V.
    scrollDown := GetKeyState("8", "P")
        || GetKeyState("v", "P")

    ; Scroll up: 7, 9, or C.
    scrollUp := GetKeyState("7", "P")
        || GetKeyState("9", "P")
        || GetKeyState("c", "P")

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
    ; Give each notification a fresh display period.
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