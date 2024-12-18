log.info("Successfully loaded " .. _ENV["!guid"] .. ".")
params = {}
mods["RoRRModdingToolkit-RoRR_Modding_Toolkit"].auto(true)
mods.on_all_mods_loaded(function()
    for k, v in pairs(mods) do
        if type(v) == "table" and v.tomlfuncs then
            Toml = v
        end
    end
    params = {
        JumpToGeyser = true
    }
    params = Toml.config_update(_ENV["!guid"], params) -- Load Save
end)

local player = nil
local Airborne = false
local Geyser = nil
Initialize(function()
    Callback.add("onPlayerInit", "No_Geyser_FallDamage-onPlayerInit", function()
        player = Player.get_client()
    end)

    Callback.add("onPlayerStep", "No_Geyser_FallDamage-onPlayerStep", function()
        -- remove airborne after landing
        if Airborne and player:is_grounded() then
            Airborne = false
        end
        -- set airborne after colliding with geyser
        local colliding_geyser = false
        if player ~= nil and player:is_colliding(Object.find("ror-geyser")) then
            Airborne = true
            colliding_geyser = true
        else
            colliding_geyser = false
        end

        if params.JumpToGeyser then
            --Get colldiding Geyser
            if colliding_geyser then
                Geyser = player:get_collisions(Object.find("ror-geyser"))[1].value
            else
                --Reset Geyser after player exits it
                if Geyser ~= nil then
                    if Geyser.jump_force_default ~= nil then
                        Geyser.jump_force = Geyser.jump_force_default
                    end
                    Geyser.sound_cd_frame = 0
                    Geyser = nil
                end
            end

            if Geyser ~= nil then
                --Disable Geyser
                if player.moveUpHold == 0.0 then
                    if Geyser.disabled == nil or Geyser.disabled == 0 then
                        Geyser.jump_force_default = Geyser.jump_force
                    end
                    if player.pVspeed == 0 then
                        Geyser.jump_force = -15
                    else
                        Geyser.jump_force = -player.pVspeed
                    end
                    Geyser.sound_cd_frame = 1000000 + Geyser.sound_cd_frame
                    Geyser.disabled = 1
                else
                    --Enable Geyser
                    if Geyser.disabled ~= nil and Geyser.disabled == 1 then
                        Geyser.sound_cd_frame = 0
                        Geyser.jump_force = Geyser.jump_force_default
                        Geyser.disabled = 0
                    end
                end
            end
        end
    end)
end)

-- set immune for 1 frame when landing
gm.pre_script_hook(gm.constants.damage_inflict, function(self, other, result, args)
    if Airborne then
        player:set_immune(1)
    end
end)

gui.add_to_menu_bar(function()
        params.JumpToGeyser = ImGui.Checkbox("Jump to use geyser", params.JumpToGeyser)
        Toml.save_cfg(_ENV["!guid"], params)
end)
