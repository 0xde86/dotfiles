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

-- The internal panel always sits to the right of the external monitor(s):
-- `auto-left` pins externals to the leftmost slot, `auto-right` the internal to
-- the rightmost, so the ordering holds regardless of which is set up first.
local function position_for(output)
    return output == INTERNAL and "auto-right" or "auto-left"
end

local function configure(output, enabled)
    hl.monitor({
        output   = output,
        disabled = not enabled,
        mode     = "preferred",
        position = position_for(output),
        scale    = scale_for(output),
    })
end

-- Workspaces 1-9 live on the external monitor and 10 on the internal panel when
-- an external is connected; otherwise every workspace stays on the internal
-- panel. hl.workspace_rule is idempotent, so this is safe to re-run.
local function apply_workspaces()
    local external = power_profile.get_external_output()

    if external then
        for i = 1, 9 do
            hl.workspace_rule({ workspace = tostring(i), monitor = external })
        end
        hl.workspace_rule({ workspace = "10", monitor = INTERNAL, default = true, persistent = true })
    end
end

-- Anything unexpected (a projector, say) still gets a usable default.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

-- Every known output starts enabled: on startup everything is on. Monitors are
-- no longer switched automatically based on what is docked -- toggle the
-- internal panel by hand with SUPER+CTRL+Y (on) / SUPER+CTRL+H (off), bound in
-- keybinds.lua.
for _, output in ipairs(outputs) do
    configure(output, true)
end

apply_workspaces()

return {
    enable_internal = function()
        configure(INTERNAL, true)
        apply_workspaces()
    end,
    disable_internal = function()
        configure(INTERNAL, false)
        apply_workspaces()
    end,
}
