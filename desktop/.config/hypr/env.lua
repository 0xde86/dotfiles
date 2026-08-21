-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/

local power_profile = require("power_profile")

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("QT_QPA_PLATFORM", "wayland")

-- Qt apps (hyprpolkitagent's auth dialog, ...) build their whole look out of the
-- Qt palette. gtk3 derives that palette from the Catppuccin Frappe GTK theme, so
-- they match the rest of the system; xdgdesktopportal only supplied a dark hint,
-- leaving Qt on its stock grey palette. Hyprland re-exports this var into the
-- systemd user session, so the hyprpolkitagent unit picks it up too.
hl.env("QT_QPA_PLATFORMTHEME", "gtk3")
hl.env("GTK_USE_PORTAL", "1")
hl.env("GDK_BACKEND", "wayland")
hl.env("WEBKIT_DISABLE_DMABUF_RENDERER", "1")
hl.env("WEBKIT_DISABLE_COMPOSITING_MODE", "1")

-- Resolve card numbers from their PCI slots at startup because card numbers can
-- change between boots. NVIDIA is primary while docked; Intel is primary otherwise.
hl.env("AQ_DRM_DEVICES", power_profile.gpu_order)
