-- See https://wiki.hypr.land/Configuring/Basics/Binds/

local programs = require("programs")

local mainMod = "SUPER" -- Sets "Windows" key as main modifier

-- Example binds, see https://wiki.hypr.land/Configuring/Basics/Binds/ for more
hl.bind(mainMod .. " + T",         hl.dsp.exec_cmd(programs.terminal))
hl.bind(mainMod .. " + return",    hl.dsp.exec_cmd(programs.terminal))
hl.bind(mainMod .. " + B",         hl.dsp.exec_cmd(programs.browser))
hl.bind(mainMod .. " + SHIFT + B", hl.dsp.exec_cmd(programs.p_browser))
hl.bind(mainMod .. " + E",         hl.dsp.exec_cmd(programs.fileManager))
hl.bind(mainMod .. " + space",     hl.dsp.exec_cmd(programs.menu))
hl.bind(mainMod .. " + R",         hl.dsp.exec_cmd(programs.menu))
hl.bind(mainMod .. " + C",         hl.dsp.window.close())
hl.bind(mainMod .. " + V",         hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + U",         hl.dsp.layout("togglesplit")) -- dwindle
hl.bind(mainMod .. " + P",         hl.dsp.exec_cmd("hyprshot -m window"))
hl.bind(mainMod .. " + SHIFT + P", hl.dsp.exec_cmd("hyprshot -m region"))
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd("killall waybar && waybar"))
hl.bind(mainMod .. " + M",         hl.dsp.exec_cmd("swaylock"))

-- Blank/unblank the internal laptop panel by hand (auto monitor switching removed).
-- Only the backlight is toggled -- the DRM output is left enabled. Powering the
-- output down (via `disabled` OR DPMS) makes Hyprland tear down and rebuild the
-- Intel GPU's renderer -- eDP-1 is its only output -- and the panel wakes to a
-- frozen frame that nothing in-session repaints (a known multi-GPU bug; neither
-- forcerendererreload nor a full reload recovers it). Dimming the backlight never
-- touches the output, so there is nothing to freeze.
--   https://github.com/hyprwm/Hyprland/issues/8357  (can't wake monitor after dpms off)
--   https://github.com/hyprwm/Hyprland/issues/4522  (dpms does not turn on again)
--   https://github.com/hyprwm/Hyprland/issues/8891  (screen freezes on multi-monitor nvidia)
--   https://github.com/hyprwm/Hyprland/discussions/13238  (disable/re-enable monitor misbehaves)
hl.bind(mainMod .. " + CTRL + Y", hl.dsp.exec_cmd("brightnessctl -d intel_backlight --save set 100%"))
hl.bind(mainMod .. " + CTRL + H", hl.dsp.exec_cmd("brightnessctl -d intel_backlight --save set 0"))
hl.bind(mainMod .. " + N",         hl.dsp.exec_cmd("hyprshutdown"))
hl.bind(mainMod .. " + SHIFT + N", hl.dsp.exec_cmd("hyprshutdown -t 'Shutting down...' --post-cmd 'shutdown -P 0'"))
hl.bind(mainMod .. " + CTRL + N", hl.dsp.exec_cmd("hyprshutdown -t 'Restarting...' --post-cmd 'reboot'"))

-- Move focus with mainMod + HJKL
hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "down" }))
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "right" }))

hl.bind(mainMod .. " + SHIFT + H", hl.dsp.window.swap({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + J", hl.dsp.window.swap({ direction = "down" }))
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.window.swap({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.window.swap({ direction = "right" }))

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key,             hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key,     hl.dsp.window.move({ workspace = i }))
end

-- Example special workspace (scratchpad)
hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll through existing workspaces with mainMod + scroll
-- hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
-- hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Laptop multimedia keys for volume and LCD brightness
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true })

-- Requires playerctl
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

-- Switch to a submap called `resize`.
hl.bind("ALT + R", hl.dsp.submap("resize"))

-- Start a submap called "resize".
hl.define_submap("resize", function()
    -- Set repeatable binds for resizing the active window.
    hl.bind("H", hl.dsp.window.resize({ x = -10, y = 0,   relative = true }), { repeating = true })
    hl.bind("J", hl.dsp.window.resize({ x = 0,   y = 10,  relative = true }), { repeating = true })
    hl.bind("K", hl.dsp.window.resize({ x = 0,   y = -10, relative = true }), { repeating = true })
    hl.bind("L", hl.dsp.window.resize({ x = 10,  y = 0,   relative = true }), { repeating = true })

    -- Use `reset` to go back to the global submap
    hl.bind("escape", hl.dsp.submap("reset"))
end)
