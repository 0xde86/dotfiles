-- See https://wiki.hypr.land/Configuring/Basics/Monitors/

local power_profile = require("power_profile")

local INTERNAL = "eDP-1"

local outputs = { INTERNAL }

for _, output in ipairs(power_profile.external_outputs) do
    outputs[#outputs + 1] = output
end

local function scale_for(output)
    return output == INTERNAL and 2.40 or 1.67
end

-- hl.monitor() merges into the rule already stored for that output, so
-- `disabled` has to be passed on every call. Leaving it out keeps an earlier
-- `disabled = true` in place and the output never lights up again.
local function configure(output, disabled)
    hl.monitor({
        output   = output,
        disabled = disabled,
        mode     = "preferred",
        position = "0x0",
        scale    = scale_for(output),
    })
end

-- Anything unexpected (a projector, say) still gets a usable default.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

-- Every known output starts enabled so Hyprland modesets each connected one at
-- least once. An output disabled before it is ever modeset keeps whatever the
-- kernel console left on it, which is why the laptop panel used to sit there
-- showing the boot log. Switching it off below is a real modeset and blanks it.
for _, output in ipairs(outputs) do
    hl.monitor({
        output   = output,
        disabled = false,
        mode     = "preferred",
        position = "auto",
        scale    = scale_for(output),
    })
end

local function apply_power_profile()
    local primary = power_profile.get_external_output() or INTERNAL

    -- Enable the wanted output first: Hyprland refuses to disable the last
    -- enabled one, so switching off before switching on would be a no-op.
    configure(primary, false)

    for _, output in ipairs(outputs) do
        if output ~= primary then
            -- Only switch off outputs that are actually plugged in. A leftover
            -- `disabled = true` on an unplugged one would bring it back dark,
            -- and Hyprland reports no monitor.added for an output it never
            -- enabled, so nothing would switch it on again.
            configure(output, power_profile.is_connected(output))
        end
    end
end

-- Keep a usable display enabled when the external monitor is hot-plugged or
-- unplugged. GPU renderer priority still changes only at the next login.
--
-- Re-apply from a one-shot timer rather than straight from the event: on
-- hotplug neither /sys nor the monitor list has settled yet when the event
-- fires. Re-applying is idempotent, so overlapping timers are harmless.
local function schedule_apply()
    hl.timer(apply_power_profile, { timeout = 500, type = "oneshot" })
end

hl.on("hyprland.start", schedule_apply)
hl.on("config.reloaded", schedule_apply)
hl.on("monitor.added", schedule_apply)
hl.on("monitor.removed", schedule_apply)
