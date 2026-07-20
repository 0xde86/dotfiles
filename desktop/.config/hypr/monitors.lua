-- See https://wiki.hypr.land/Configuring/Basics/Monitors/

local power_profile = require("power_profile")

hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

local function apply_power_profile()
    local external_output = power_profile.get_external_output()

    if external_output then
        hl.monitor({ output = external_output, mode = "preferred", position = "0x0", scale = 1.67 })
        hl.monitor({ output = "eDP-1", disabled = true })
        return
    end

    hl.monitor({ output = "eDP-1", mode = "preferred", position = "0x0", scale = 2.40 })

    for _, output in ipairs(power_profile.external_outputs) do
        hl.monitor({ output = output, disabled = true })
    end
end

apply_power_profile()

-- Keep a usable display enabled when the external monitor is hot-plugged or
-- unplugged. GPU renderer priority still changes only at the next login.
hl.on("monitor.added", apply_power_profile)
hl.on("monitor.removed", apply_power_profile)
