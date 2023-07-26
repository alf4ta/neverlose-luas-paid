_DEBUG = true
local widget = {
    icons = {
        icons = ui.get_icon("icons")

    }
}
 yapiyorum_bu_sporu = ui.sidebar("\aFFB3B3FFBetter OS [SRC]", "smile")
local betteros = ui.create("Better OS", widget.icons.icons .. " Better OS")
local enablebetteros = betteros:switch("Enable Better OS", false)
local find = ui.find("Aimbot", "Ragebot", "Main", "Hide Shots", "Options")

events.render:set(function()
    local lp = entity.get_local_player()
    if not lp then return end
    if not lp:is_alive() then return end
    if enablebetteros:get() and lp["m_fFlags"] == 256 then
        find:set("Break LC")
elseif enablebetteros:get() and lp["m_fFlags"] ~= 256 then
        find:set("Favor Fire Rate")
    end
end)