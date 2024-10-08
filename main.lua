-- NoGeyserFallDamage v1.0.0
-- Onyx
log.info("Successfully loaded " .. _ENV["!guid"] .. ".")
mods.on_all_mods_loaded(function()
    for _, m in pairs(mods) do
        if type(m) == "table" and m.RoRR_Modding_Toolkit then
            for _, c in ipairs(m.Classes) do
                if m[c] then
                    _G[c] = m[c]
                end
            end
        end
    end
end)

player = nil
Airborne = false

gm.pre_script_hook(gm.constants.callback_execute, function(self, other, result, args)
    --remove airborne after landing
    if Airborne and player:is_grounded() then
        Airborne = false
    end
    -- set airborne after colliding with geyser
    if player ~= nil and player:is_colliding(Object.find("ror-geyser")) then
        Airborne = true
    end

    -- setup player
    if args[1].value == 25 then -- onPlayerInit
        player = Player.get_client()
    end
end)

-- set immune for 1 frame when landing
gm.pre_script_hook(gm.constants.damage_inflict, function(self, other, result, args)
    if Airborne then
        player:set_immune(1)
    end
end)