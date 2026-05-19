local CamerasActive = true

RegisterServerCallback("0r_cctv:server:isCamerasActive", function(source, cb)
    cb(CamerasActive)
end)

RegisterServerCallback("0r_cctv:server:scanPlayer", function(source, cb, netId)
    local entity = NetworkGetEntityFromNetworkId(netId)
    local targetSrc = nil

    for _, playerId in ipairs(GetPlayers()) do
        if GetPlayerPed(tonumber(playerId)) == entity then
            targetSrc = tonumber(playerId)
            break
        end
    end

    if not targetSrc then
        cb(nil)
        return
    end

    if Config.Framework == "qb" then
        local Player = Framework.Functions.GetPlayer(targetSrc)
        cb(Player and {
            name = Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname,
            birthDate = Player.PlayerData.charinfo.birthdate,
        } or nil)
    else
        local xPlayer = Framework.GetPlayerFromId(targetSrc)
        cb(xPlayer and {
            name = xPlayer.getName(),
            birthDate = xPlayer.get('dateofbirth'),
        } or nil)
    end
end)

RegisterServerCallback("0r_cctv:server:checkItem", function(source, cb, item)
    if Config.Framework == "qb" then
        local Player = Framework.Functions.GetPlayer(source)
        cb(Player ~= nil and Player.Functions.GetItemByName(item) ~= nil)
    else
        local xPlayer = Framework.GetPlayerFromId(source)
        if not xPlayer then cb(false) return end
        local inventoryItem = xPlayer.getInventoryItem(item)
        cb(inventoryItem ~= nil and inventoryItem.count > 0)
    end
end)

RegisterNetEvent("0r_cctv:server:disableCameras")
AddEventHandler("0r_cctv:server:disableCameras", function()
    local src = source
    if not src or src == 0 then return end

    CamerasActive = false

    SetTimeout(Config.CameraTimeout * 60 * 1000, function()
        CamerasActive = true
    end)
end)
