-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/ for more
-- See https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/ for workspace rules

hl.workspace_rule({ workspace = "1",  monitor = "DP-3" })
hl.workspace_rule({ workspace = "2",  monitor = "DP-3" })
hl.workspace_rule({ workspace = "3",  monitor = "DP-3" })
hl.workspace_rule({ workspace = "4",  monitor = "DP-3" })
hl.workspace_rule({ workspace = "5",  monitor = "DP-3" })
hl.workspace_rule({ workspace = "6",  monitor = "DP-3" })
hl.workspace_rule({ workspace = "7",  monitor = "DP-3" })
hl.workspace_rule({ workspace = "8",  monitor = "DP-3" })
hl.workspace_rule({ workspace = "9",  monitor = "DP-3" })
hl.workspace_rule({ workspace = "10", monitor = "eDP-1" })

hl.window_rule({
    -- Ignore maximize requests from all apps. You'll probably like this.
    name  = "suppress-maximize-events",
    match = { class = ".*" },

    suppress_event = "maximize",
})

hl.window_rule({
    -- Fix some dragging issues with XWayland
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },

    no_focus = true,
})

-- Hyprland-run windowrule
hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },

    move  = "20 monitor_h-120",
    float = true,
})
