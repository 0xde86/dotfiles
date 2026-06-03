-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("QT_STYLE_OVERRIDE", "Breeze")
hl.env("QT_QPA_PLATFORM", "wayland")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("EDITOR", "helix")
hl.env("GDK_BACKEND", "wayland")
hl.env("WEBKIT_DISABLE_DMABUF_RENDERER", "1")
hl.env("WEBKIT_DISABLE_COMPOSITING_MODE", "1")

-- ❯ lspci -d ::03xx
-- 00:02.0 VGA compatible controller: Intel Corporation CometLake-H GT2 [UHD Graphics] (rev 05)
-- 01:00.0 VGA compatible controller: NVIDIA Corporation GA104M [GeForce RTX 3070 Mobile / Max-Q] (rev a1)
-- ~
-- ❯ ls -l /dev/dri/by-path
-- lrwxrwxrwx - root 18 Apr 16:59 pci-0000:00:02.0-card -> ../card2
-- lrwxrwxrwx - root 18 Apr 16:59 pci-0000:00:02.0-render -> ../renderD129
-- lrwxrwxrwx - root 18 Apr 16:59 pci-0000:01:00.0-card -> ../card1
-- lrwxrwxrwx - root 18 Apr 16:59 pci-0000:01:00.0-render -> ../renderD128
hl.env("AQ_DRM_DEVICES", "/dev/dri/card2:/dev/dri/card1")
