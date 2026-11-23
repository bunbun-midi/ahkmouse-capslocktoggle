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
        ; Read both movement groups.
        ijklX := GetKeyState("l", "P") - GetKeyState("j", "P")
        ijklY := GetKeyState("k", "P") - GetKeyState("i", "P")

        esdfX := GetKeyState("f", "P") - GetKeyState("s", "P")
        esdfY := GetKeyState("d", "P") - GetKeyState("e", "P")

        ; ESDF takes priority if both groups request movement.
        ; This prevents their movement speeds from adding together.
        usingESDF := (esdfX != 0 || esdfY != 0)

        if (usingESDF)
        {
            dx := esdfX
            dy := esdfY
        }
        else
        {
            dx := ijklX
            dy := ijklY
        }

        if (dx || dy)
        {
            altHeld := GetKeyState("Alt", "P")

            if (!alternateSpeedMode)
            {
                ; Original mode for both groups:
                ; normal = 12, Alt = 24 with default settings.
                speed := moveSpeed

                if (altHeld)
                    speed *= fastMultiplier
            }
            else if (usingESDF)
            {
                ; ESDF alternate:
                ; normal = 24, Alt = 12 with default settings.
                if (altHeld)
                    speed := moveSpeed * esdfAlternateAltMultiplier
                else
                    speed := moveSpeed * esdfAlternateNormalMultiplier
            }
            else
            {
                ; IJKL alternate:
                ; normal = 38.4, Alt = 16.8 with default settings.
                if (altHeld)
                {
                    speed := moveSpeed * fastMultiplier
                        * ijklAlternateAltMultiplier
                }
                else
                {
                    speed := moveSpeed * ijklAlternateNormalMultiplier
                }
            }

            ; Normalize diagonal movement speed.
            if (dx && dy)
                speed /= Sqrt(2)

            mx := Round(dx * speed)
            my := Round(dy * speed)
            MouseMove, %mx%, %my%, 0, R
        }
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
