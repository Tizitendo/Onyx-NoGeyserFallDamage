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

local player = {}
local Geyser = {}
Initialize(function()
    local PlayerIndex = 1
    Callback.add("onPlayerInit", "No_Geyser_FallDamage-onPlayerInit", function(self, other, result, args)
        if (Player.get_client():same(self)) then
            player = {}
            PlayerIndex = 1
        end
        player[PlayerIndex] = Wrap.wrap(self)
        player[PlayerIndex].Airborne = false
        PlayerIndex = PlayerIndex + 1
    end)

    Callback.add("onPlayerStep", "No_Geyser_FallDamage-onPlayerStep", function()
        for i = 1, #player do
            -- remove airborne after landing
            if player[i].Airborne and player[i]:is_grounded() then
                player[i].Airborne = false
            end
            -- set airborne after colliding with geyser
            local colliding_geyser = false
            if player[i] ~= nil and Instance.find({gm.constants.oGeyser, gm.constants.oGeyserWeak}).object_index ~= nil and
                player[i]:is_colliding(
                    Object.wrap(Instance.find({gm.constants.oGeyser, gm.constants.oGeyserWeak}).object_index)) then
                player[i].Airborne = true
                colliding_geyser = true
            else
                colliding_geyser = false
            end

            if params.JumpToGeyser then
                -- Get colldiding Geyser
                if colliding_geyser then
                    Geyser[i] = player[i]:get_collisions(Object.wrap(
                        Instance.find({gm.constants.oGeyser, gm.constants.oGeyserWeak}).object_index))[1].value
                else
                    -- Reset Geyser after player exits it
                    if Geyser[i] ~= nil then
                        if Geyser[i].jump_force_default ~= nil then
                            Geyser[i].jump_force = Geyser[i].jump_force_default
                        end
                        Geyser[i].sound_cd_frame = 0
                        Geyser[i] = nil
                    end
                end

                if Geyser[i] ~= nil then
                    -- Disable Geyser
                    -- you have to check for 0 and false because they are apparently different and on the client moveuphold is 0 and on host it's false for some reason
                    if player[i].moveUpHold == 0 or player[i].moveUpHold == false then
                        if Geyser[i].disabled == nil or Geyser[i].disabled == 0 then
                            Geyser[i].jump_force_default = Geyser[i].jump_force
                        end
                        if player[i].pVspeed == 0 then
                            Geyser[i].jump_force = -15
                        else
                            Geyser[i].jump_force = -player[i].pVspeed
                        end
                        Geyser[i].sound_cd_frame = 1000000 + Geyser[i].sound_cd_frame
                        Geyser[i].disabled = 1
                    else
                        -- Enable Geyser
                        if Geyser[i].disabled ~= nil and Geyser[i].disabled == 1 then
                            Geyser[i].sound_cd_frame = 0
                            Geyser[i].jump_force = Geyser[i].jump_force_default
                            Geyser[i].disabled = 0
                        end
                    end
                end
            end
        end
    end)
end)

-- set immune for 1 frame when landing
gm.pre_script_hook(gm.constants.damage_inflict, function(self, other, result, args)
    for i = 1, #player do
        if player[i].Airborne == 1 then
            player[i]:set_immune(1)
        end
    end
end)

-- Gui
gui.add_to_menu_bar(function()
    params.JumpToGeyser = ImGui.Checkbox("Jump to use geyser", params.JumpToGeyser)
    Toml.save_cfg(_ENV["!guid"], params)
end)
gui.add_imgui(function()
    if ImGui.Begin("ArtificerPlus") then
        params.JumpToGeyser = ImGui.Checkbox("Jump to use geyser", params.JumpToGeyser)
        Toml.save_cfg(_ENV["!guid"], params)
    end
    ImGui.End()
end)
