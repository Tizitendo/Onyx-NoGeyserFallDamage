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

Initialize(function()
    local packetConfig = Packet.new()

    Callback.add(Callback.TYPE.onGameStart, "NoGeyserFallDamage-onGameStart", function()
        local function GameStart()
            local playerdata = Player.get_client():get_data()
            playerdata.Airborne = false
            playerdata.JumpToGeyser = params.JumpToGeyser

            if gm._mod_net_isOnline() and gm._mod_net_isClient() then
                local msg = packetConfig:message_begin()
                msg:write_instance(Player.get_client())
                msg:write_byte(playerdata.JumpToGeyser)
                msg:send_to_host()
            end
        end
        Alarm.create(GameStart, 1)
    end)

    packetConfig:onReceived(function(msg)
        local msgplayer = msg:read_instance()
        msgplayer:get_data().JumpToGeyser = msg:read_byte()
    end)

    gm.pre_code_execute("gml_Object_pGeyser_Collision_pActor", function(self, other)
        local geyser = Instance.wrap(self)
        local playerdata = Instance.wrap(other):get_data()
        if gm.actor_is_player(other) then
            playerdata.Airborne = true
            if not gm.bool(other.moveUpHold) and playerdata.JumpToGeyser then
                return false
            end
        else
            local collision = geyser:get_collisions(gm.constants.oP)
            for i = 1, #collision do
                if not gm.bool(collision[i].moveUpHold) and Instance.wrap(collision[i]):get_data().JumpToGeyser then
                    return false
                end
            end
        end
    end)

    local guarded = false
    gm.pre_script_hook(gm.constants.actor_phy_on_landed, function(self, other, result, args)
        if not gm.bool(self.invincible) and Instance.wrap(self):get_data().Airborne then
            self.invincible = 1
            guarded = true
        end
    end)
    gm.post_script_hook(gm.constants.actor_phy_on_landed, function(self, other, result, args)
        local playerdata = Instance.wrap(self):get_data()
        if playerdata.Airborne and guarded then
            self.invincible = 0
            guarded = false
        end
        playerdata.Airborne = false
    end)
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
