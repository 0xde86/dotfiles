hl.config({
    cursor = {
        min_refresh_rate = 60,
        no_warps         = true,
    },

    -- https://wiki.hypr.land/Configuring/Basics/Variables/#input
    input = {
        -- "us" stays first: binds are resolved against the first layout, so
        -- SUPER + H/J/K/L keep working while typing in Russian.
        kb_layout  = "us,ru",
        kb_variant = ",",
        kb_model   = "",
        -- Toggle layouts with ALT + SHIFT. Other common choices:
        --   grp:caps_toggle       -- Caps Lock
        --   grp:ctrl_shift_toggle -- CTRL + SHIFT
        --   grp:toggle            -- right ALT
        -- (SUPER + space is taken by the launcher, so grp:win_space_toggle is out.)
        kb_options = "grp:alt_shift_toggle",
        kb_rules   = "",

        follow_mouse = 1,

        sensitivity = 0, -- -1.0 - 1.0, 0 means no modification.

        touchpad = {
            natural_scroll = true,
        },
    },
})

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Gestures/
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

-- Example per-device config
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Devices/ for more
hl.device({
    name        = "epic-mouse-v1",
    sensitivity = -0.5,
})
