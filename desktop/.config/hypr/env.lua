-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/

local power_profile = require("power_profile")

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("QT_STYLE_OVERRIDE", "Breeze")
hl.env("QT_QPA_PLATFORM", "wayland")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("EDITOR", "helix")
hl.env("GDK_BACKEND", "wayland")
hl.env("WEBKIT_DISABLE_DMABUF_RENDERER", "1")
hl.env("WEBKIT_DISABLE_COMPOSITING_MODE", "1")

-- Resolve card numbers from their PCI slots at startup because card numbers can
-- change between boots. NVIDIA is primary while docked; Intel is primary otherwise.
hl.env("AQ_DRM_DEVICES", power_profile.gpu_order)
