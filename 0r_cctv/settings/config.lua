Config = {
    Framework = "esx", -- "qb" or "esx"
    HackingMenu = vector4(460.59, -989.04, 25.14, 272.0),
    -- BombPlaceCoords = vector4(451.33, -977.84, 30.69, 180.4),
    CameraTimeout = 1, -- minutes
    Target = "ox-target", -- "DrawText" or "qb-target" or "ox-target"

    HackItem = "laptop_h", -- Item to hack the bank
    BombItem = "bomb", -- Item to place the bomb

    Menus = {
        vector4(447.97, -973.44, 30.69, 177.8),
    },

    WhitelistedJobs = {
        "police",
        "ambulance",
    },

    RouletteWords = {
        "0RESMON0",
        "ATYSCRIP",
        "0RESATY0",
    },

    CoreExport = function()
        if Config.Framework == "qb" then
            return exports["qb-core"]:GetCoreObject()
        elseif Config.Framework == "esx" then
            return exports["es_extended"]:getSharedObject()
        end
    end,

    Notify = function(message, type, length)
        if Config.Framework == "qb" then
            TriggerEvent('QBCore:Notify', message, type, length or 5000)
        else
            Framework.ShowNotification(message)
        end
    end,
}