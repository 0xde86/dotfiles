local M = {}

M.terminal    = "kitty"
M.fileManager = "kitty --override confirm_os_window_close=0 -e yazi"
M.menu        = "hyprlauncher"
M.browser     = "brave --password-store=gnome"
M.p_browser   = "flatpak run net.mullvad.MullvadBrowser"

return M
