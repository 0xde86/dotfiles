-- See https://wiki.hypr.land/Configuring/Basics/Autostart/

local programs = require("programs")

hl.on("hyprland.start", function()
    hl.exec_cmd("waybar & hyprpaper & hypridle") -- & swaync
    hl.exec_cmd("systemctl --user start hyprpolkitagent")

    hl.exec_cmd(programs.terminal, { workspace = "1 silent" })
    hl.exec_cmd(programs.browser,  { workspace = "2 silent" })
    -- hl.exec_cmd("nm-applet")
end)

-- hl.exec_cmd("gsettings set org.gnome.desktop.interface gtk-theme \"YOUR_THEME_NAME\"") -- For GTK3 apps
-- hl.exec_cmd("gsettings set org.gnome.desktop.interface color-scheme \"prefer-dark\"")  -- For GTK4 apps
