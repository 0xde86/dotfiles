-- Select a power-conscious GPU/display profile from the connected outputs.

local function is_connected(output)
    for card = 0, 15 do
        local path = "/sys/class/drm/card" .. card .. "-" .. output .. "/status"
        local file = io.open(path, "r")

        if file then
            local status = file:read("*l")
            file:close()

            if status == "connected" then
                return true
            end
        end
    end

    return false
end

local external_outputs = { "DP-3", "DP-2", "DP-1", "HDMI-A-1" }

local function get_external_output()
    for _, output in ipairs(external_outputs) do
        if is_connected(output) then
            return output
        end
    end

    return nil
end

local function get_drm_card(pci_slot)
    local expected_slot = "PCI_SLOT_NAME=" .. pci_slot

    for card = 0, 15 do
        local path = "/sys/class/drm/card" .. card .. "/device/uevent"
        local file = io.open(path, "r")

        if file then
            for line in file:lines() do
                if line == expected_slot then
                    file:close()
                    return "/dev/dri/card" .. card
                end
            end

            file:close()
        end
    end

    error("no DRM card found for PCI device " .. pci_slot)
end

local intel_gpu = get_drm_card("0000:00:02.0")
local nvidia_gpu = get_drm_card("0000:01:00.0")
local external_output = get_external_output()
local docked = external_output ~= nil

return {
    docked = docked,
    external_output = external_output,
    external_outputs = external_outputs,
    get_external_output = get_external_output,
    primary_output = external_output or "eDP-1",
    power_mode = docked and "balanced" or "power-saver",
    gpu_order = docked
        and nvidia_gpu .. ":" .. intel_gpu
        or intel_gpu .. ":" .. nvidia_gpu,
}
