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
local Airborne = {}
local JumpToGeyserMP = {}
Initialize(function()
    local packetConfig = Packet.new()
    local PlayerIndex = 1
    Callback.add("onPlayerInit", "No_Geyser_FallDamage-onPlayerInit", function(self)
        if not gm._mod_net_isOnline() then
            if (Player.get_client():same(self)) then
                player = {}
                PlayerIndex = 1
            end
            player[PlayerIndex] = Wrap.wrap(self)
            Airborne[PlayerIndex] = false
            JumpToGeyserMP[PlayerIndex] = params.JumpToGeyser
            PlayerIndex = PlayerIndex + 1
        end
    end)

    Callback.add("onGameStart", "NoGeyserFallDamage-onGameStart", function()
        local function myFunc()
            if gm._mod_net_isOnline() then
                if gm._mod_net_isClient() then
                    local msg = packetConfig:message_begin()
                    msg:write_instance(Player.get_client())
                    msg:write_byte(params.JumpToGeyser)
                    msg:send_to_host()
                end
                if gm._mod_net_isHost() then
                    local msg = packetConfig:message_begin()
                    msg:write_instance(Player.get_client())
                    msg:write_byte(params.JumpToGeyser)
                    msg:send_to_all()

                    player[1] = Player.get_client()
                    JumpToGeyserMP[1] = params.JumpToGeyser
                end
            end
        end

        Alarm.create(myFunc, 60)
        JumpToGeyserMP = {}
        player = {}
        Airborne = {}
    end)

    packetConfig:onReceived(function(msg)
        local msgplayer = msg:read_instance()
        player[msgplayer.m_id] = msgplayer
        JumpToGeyserMP[msgplayer.m_id] = msg:read_byte()
        Airborne[msgplayer.m_id] = false

        if gm._mod_net_isHost() then
            local msg = packetConfig:message_begin()
            msg:write_instance(msgplayer)
            msg:write_byte(JumpToGeyserMP[msgplayer.m_id])
            msg:send_to_all()
        end
    end)

    Callback.add("onPlayerStep", "No_Geyser_FallDamage-onPlayerStep", function(self)
        for i = 1, #player do
            if player[i] ~= nil then
                -- remove airborne after landing
                if Airborne[i] and player[i]:is_grounded() then
                    local function ResetAirborne()
                        Airborne[i] = false
                    end
                    Alarm.create(ResetAirborne, 5)
                end
                -- set airborne after colliding with geyser
                local colliding_geyser = false
                if Instance.find({gm.constants.oGeyser, gm.constants.oGeyserWeak}).object_index ~= nil and
                    player[i]:is_colliding(
                        Object.wrap(Instance.find({gm.constants.oGeyser, gm.constants.oGeyserWeak}).object_index)) then
                    Airborne[i] = true
                    colliding_geyser = true
                else
                    colliding_geyser = false
                end

                if JumpToGeyserMP[i] == true or JumpToGeyserMP[i] == 1 then
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
        end
    end)
end)

-- set immune for 1 frame when landing
gm.pre_script_hook(gm.constants.damage_inflict, function(self, other, result, args)
    for i = 1, #player do
        if Airborne[i] == 1 or Airborne[i] == true then
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
    if ImGui.Begin("No Geyser Falldamage") then
        params.JumpToGeyser = ImGui.Checkbox("Jump to use geyser", params.JumpToGeyser)
        Toml.save_cfg(_ENV["!guid"], params)
    end
    ImGui.End()
end)
