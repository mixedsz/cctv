CCTVCam = nil
PlayerDataShown = false
CamID = 1
ScannedPlayers = {}
PlayerJob = nil
PlayerJobLabel = nil
PlayerGrade = nil
Hacking = false
BombPlaced = false
HackStarted = false
OldCoords = nil
PlayerName = nil
UILoaded = false

local sensitivity = 1.5 -- Fare hassasiyeti
local pitch = 0.0
local yaw = 0.0
local roll = 0.0

CreateThread(function()
	while true do
		if Config.Framework == "esx" then
			PlayerData = Framework.GetPlayerData()
		else
			PlayerData = Framework.Functions.GetPlayerData()
		end

		if table_size(PlayerData) > 5 and UILoaded then
            PlayerJob = PlayerData.job.name

            if Config.Framework == "esx" then
                PlayerGrade = PlayerData.job.grade_label
                PlayerJobLabel = PlayerData.job.label
                PlayerName = PlayerData.firstName .. " " .. PlayerData.lastName
            else
                PlayerGrade = PlayerData.job.grade.name
                PlayerJobLabel = PlayerData.job.label
                PlayerName = PlayerData.charinfo.firstname .. " " .. PlayerData.charinfo.lastname
            end

            SendNUIMessage({
                action = "loggedIn",
                name = PlayerName,
                job = PlayerJobLabel,
                grade = PlayerGrade,
            })
            
            break
		end

		Wait(5000)
	end
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded')
AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    PlayerJob = Framework.Functions.GetPlayerData().job.name
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate')
AddEventHandler('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerJob = JobInfo.name
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(playerData)
    PlayerJob = playerData.job.name
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
    PlayerJob = job.name
end)

function openCameras()
    if not isPlayerJobWhitelisted(PlayerJob) then return end

    triggerServerCallback("0r_cctv:server:isCamerasActive", function(cb)
        if cb then
            local selectedCamera = Cameras[CamID]
            local ped = PlayerPedId()
            local pedCoords = GetEntityCoords(ped)
            local pedHeading = GetEntityHeading(ped)
            local camRotX = selectedCamera.rotX
            local camRotZ = selectedCamera.rotZ
            local camFov = selectedCamera.fov

            OldCoords = pedCoords

            SetEntityVisible(ped, false)
            FreezeEntityPosition(ped, true)
            SetEntityInvincible(ped, true)
            SetEntityCoords(ped, selectedCamera.x, selectedCamera.y, selectedCamera.z - 1)

            CCTVCam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", selectedCamera.x, selectedCamera.y, selectedCamera.z, camRotX, selectedCamera.rotY, camRotZ, selectedCamera.fov, true, 0)
            RenderScriptCams(true, false, 0, true, true)   

            local street = GetStreetNameAtCoord(selectedCamera.x, selectedCamera.y, selectedCamera.z)
            local streetName = GetStreetNameFromHashKey(street)
            local zone = GetNameOfZone(selectedCamera.x, selectedCamera.y, selectedCamera.z)
            local zoneName = GetLabelText(zone)

            SendNUIMessage({
                action = "toggleUi",
                status = true,
                camData = selectedCamera,
                street = streetName,
                zone = zoneName,
            })

            local lastCheck = GetGameTimer()

            CreateThread(function()
                while CCTVCam ~= nil do
                    local pedHeading = GetEntityHeading(ped)

                    if lastCheck + 1000 < GetGameTimer() then
                        lastCheck = GetGameTimer()

                        SendNUIMessage({
                            action = "updateCompassData",
                            heading = pedHeading,
                        })
                    end

                    local camRot = GetCamRot(CCTVCam, 2)
                    local slowed = IsControlPressed(0, 36) or IsDisabledControlPressed(0, 36)

                    local forwardVector = GetEntityForwardVector(ped) 
                    local distance = 300.0 

                    local shape = StartExpensiveSynchronousShapeTestLosProbe(selectedCamera.x, selectedCamera.y, selectedCamera.z, 
                        selectedCamera.x + forwardVector.x * distance, 
                        selectedCamera.y + forwardVector.y * distance, 
                        selectedCamera.z + forwardVector.z * distance, 
                        10, ped, 0)

                    local shapeTestHandle, hit, endCoords, surfaceNormal, entityHit = GetShapeTestResult(shape)

                    DisableAllControlActions(0)

                    if hit ~= 0 and entityHit ~= 0 then
                        if not doesPlayerExist(entityHit) then
                            if IsEntityAPed(entityHit) then
                                local result = exports["loaf_headshot_base64"]:getBase64(PlayerPedId())
                                local mug = nil

                                if result.success then
                                    mug = result.base64
                                end

                                if IsPedAPlayer(entityHit) then
                                    triggerServerCallback("0r_cctv:server:scanPlayer", function(cb)
                                        ScannedPlayers[entityHit] = {
                                            ped = entityHit,
                                            type = "player",
                                            name = cb?.name or "Unknown",
                                            image = mug or "assets/default.png",
                                            birthDate = cb?.birthDate or "Unknown",
                                        }
                                    end, NetworkGetNetworkIdFromEntity(entityHit))
                                else
                                    ScannedPlayers[entityHit] = {
                                        ped = entityHit,
                                        type = "ped",
                                        name = "Citizen",
                                        image = mug or "assets/default.png",
                                        birthDate = "Unknown",
                                    }
                                end
                            elseif IsEntityAVehicle(entityHit) then
                                ScannedPlayers[entityHit] = {
                                    ped = entityHit,
                                    type = "vehicle",
                                    name = GetDisplayNameFromVehicleModel(GetEntityModel(entityHit)),
                                    birthDate = GetVehicleNumberPlateText(entityHit),
                                }
                            end
                        else
                            if not PlayerDataShown then
                                PlayerDataShown = true
                                SendNUIMessage({
                                    action = "showPlayerData",
                                    playerData = ScannedPlayers[entityHit],
                                })
                            end
                        end
                    else
                        if PlayerDataShown then
                            PlayerDataShown = false
                            SendNUIMessage({
                                action = "hidePlayerData",
                            })
                        end
                    end

                    if IsDisabledControlJustPressed(0, 202) then
                        leaveCam()
                    end
                    
                    if IsDisabledControlJustPressed(0, 14) then
                        camFov = camFov + 2.0
                    elseif IsDisabledControlJustPressed(0, 15) then
                        camFov = camFov - 2.0
                    end
                    
                    if IsDisabledControlJustPressed(0, 36) then
                        SetNuiFocus(true, true)
                    end

                    local mouseX, mouseY = GetDisabledControlNormal(0, 1), GetDisabledControlNormal(0, 2)

                    pitch = (pitch - (mouseY * sensitivity))
                    yaw = yaw + (mouseX * sensitivity)

                    camRotX = pitch

                    if pitch > 85.0 then
                        pitch = 85.0
                    elseif pitch < -85.0 then
                        pitch = -85.0
                    end

                    if yaw > 80 then
                        yaw = 80
                    elseif yaw < -80 then
                        yaw = -80
                    end

                    if IsDisabledControlJustPressed(0, 175) then
                        CamID = CamID + 1

                        if CamID > #Cameras then
                            CamID = 1
                        end

                        yaw = 0.0
                        pitch = 0.0

                        local selectedCamera = Cameras[CamID]
                        SetEntityCoords(ped, selectedCamera.x, selectedCamera.y, selectedCamera.z - 1)
                        SetCamParams(CCTVCam, selectedCamera.x, selectedCamera.y, selectedCamera.z, selectedCamera.rotX, selectedCamera.rotY, selectedCamera.rotZ, selectedCamera.fov, true, 0, 2)

                        camRotZ = selectedCamera.rotZ
                        camRotX = selectedCamera.rotX
                        camFov = selectedCamera.fov
                        
                        local street = GetStreetNameAtCoord(selectedCamera.x, selectedCamera.y, selectedCamera.z)
                        local streetName = GetStreetNameFromHashKey(street)
                        local zone = GetNameOfZone(selectedCamera.x, selectedCamera.y, selectedCamera.z)
                        local zoneName = GetLabelText(zone)

                        SendNUIMessage({
                            action = "toggleUi",
                            status = true,
                            camData = selectedCamera,
                            street = streetName,
                            zone = zoneName,
                        })
                    elseif IsDisabledControlJustPressed(0, 174) then
                        CamID = CamID - 1
                        if CamID < 1 then
                            CamID = #Cameras
                        end

                        local selectedCamera = Cameras[CamID]
                        SetEntityCoords(ped, selectedCamera.x, selectedCamera.y, selectedCamera.z - 1)
                        SetCamParams(CCTVCam, selectedCamera.x, selectedCamera.y, selectedCamera.z, selectedCamera.rotX, selectedCamera.rotY, selectedCamera.rotZ, selectedCamera.fov, true, 0, 2)
                        
                        camRotZ = selectedCamera.rotZ
                        camRotX = selectedCamera.rotX
                        camFov = selectedCamera.fov

                        local street = GetStreetNameAtCoord(selectedCamera.x, selectedCamera.y, selectedCamera.z)
                        local streetName = GetStreetNameFromHashKey(street)
                        local zone = GetNameOfZone(selectedCamera.x, selectedCamera.y, selectedCamera.z)
                        local zoneName = GetLabelText(zone)

                        SendNUIMessage({
                            action = "toggleUi",
                            status = true,
                            camData = selectedCamera,
                            street = streetName,
                            zone = zoneName,
                        })
                    end

                    if camRotX < -85 then 
                        camRotX = -85.0
                    elseif camRotX > 60 then
                        camRotX = 60.0
                    end

                    if camFov > 70 then
                        camFov = 70.0
                    elseif camFov < 10.0 then
                        camFov = 10.0
                    end

                    SetCamRot(CCTVCam, camRotX, camRot.y, camRotZ - yaw, 2)
                    SetCamFov(CCTVCam, camFov)

                    SetEntityRotation(ped, camRotX, 0.0, camRotZ - yaw, 2, true)
                    Wait(0)
                end
            end)
        else
            Config.Notify("The CCTV system is not active.", "error", 5000)
        end
    end)
end

function leaveCam()
    if CCTVCam ~= nil then
        SendNUIMessage({
            action = "toggleUi",
            status = false,
        })

        DoScreenFadeOut(500)
        Wait(500)

        EnableAllControlActions(0)
        SetSeethrough(false)
        SetNightvision(false)

        local ped = PlayerPedId()

        SetEntityCoords(ped, OldCoords.x, OldCoords.y, OldCoords.z - 1.0)
        SetEntityHeading(ped, pedHeading)

        RenderScriptCams(false, false, 0, true, true)
        DestroyCam(CCTVCam, true)

        DoScreenFadeIn(500)

        FreezeEntityPosition(ped, false)
        SetEntityInvincible(ped, false)
        SetEntityVisible(ped, true)

        CCTVCam = nil
        ScannedPlayers = {}
    end
end

function changeCamEffect(effect)
    if effect == 1 then
        SetSeethrough(false)
        SetNightvision(false)
    elseif effect == 2 then
        SetSeethrough(false)
        SetNightvision(true)
    elseif effect == 3 then
        SetSeethrough(true)
        SetNightvision(false)
        SeethroughSetHeatscale(2, 0.3)
        SeethroughSetNoiseAmountMin(0.0)
        SeethroughSetNoiseAmountMax(0.0)
        SeethroughSetFadeStartDistance(100.0)
        SeethroughSetFadeEndDistance(300.0)
        SeethroughSetHiLightIntensity(1.0)
        SeethroughSetColorNear(105.0, 105.0, 105.0)
    end
end

RegisterNuiCallback("changeType", function(data)
    changeCamEffect(data.type)
end)

RegisterNuiCallback("nuiFocus", function()
    SetNuiFocus(false, false)
end)

RegisterNuiCallback("loaded", function()
    UILoaded = true
end)

function doesPlayerExist(ped)
    for _, player in pairs(ScannedPlayers) do
        if player.ped == ped then
            return true
        end
    end

    return false
end

CreateThread(function()
    local sleep = 1000

    if Config.Target == "qb-target" then
        for k, coord in pairs(Config.Menus) do
            exports["qb-target"]:AddCircleZone("openCamera"..k, vec3(coord.x, coord.y, coord.z), 1.5, 
            {
                name = "openCamera"..k,
                debugPoly = false,
            },
            {
                options = {
                    {
                        action = openCameras,
                        icon = "fas fa-video",
                        label = "Open CCTV",
                    },
                },
                distance = 1.5
            })
        end

        exports["qb-target"]:AddCircleZone("hackCameras", vec3(Config.HackingMenu.x, Config.HackingMenu.y, Config.HackingMenu.z), 1.5, 
        {
            name = "hackCameras",
            debugPoly = false,
        },
        {
            options = {
                {
                    action = startHacking,
                    icon = "fas fa-video",
                    label = "Hack CCTV System",
                },
            },
            distance = 1.5
        })

        exports["qb-target"]:AddCircleZone("placeBomb", vec3(Config.BombPlaceCoords.x, Config.BombPlaceCoords.y, Config.BombPlaceCoords.z), 1.5, 
            {
                name = "placeBomb",
                debugPoly = false,
            },
            {
                options = {
                    {
                        action = Plant,
                        icon = "fas fa-video",
                        label = "Place Bomb",
                    },
                },
                distance = 1.5
            })
    elseif Config.Target == "ox-target" then
        for _, coord in pairs(Config.Menus) do
            exports["ox_target"]:addSphereZone({
                coords = vector3(coord.x, coord.y, coord.z),
                radius = 1.5,
                options = {
                    {
                        onSelect = openCameras,
                        icon = "fas fa-video",
                        label = "Open CCTV",
                    },
                },
            })
        end

        exports["ox_target"]:addSphereZone({
            coords = vector3(Config.HackingMenu.x, Config.HackingMenu.y, Config.HackingMenu.z),
            radius = 1.5,
            options = {
                {
                    onSelect = startHacking,
                    icon = "fas fa-video",
                    label = "Hack CCTV System",
                },
            },
        })

        -- exports["ox_target"]:addSphereZone({
        --     coords = vector3(Config.BombPlaceCoords.x, Config.BombPlaceCoords.y, Config.BombPlaceCoords.z),
        --     radius = 1.5,
        --     options = {
        --         {
        --             onSelect = Plant,
        --             icon = "fas fa-video",
        --             label = "Place Bomb",
        --         },
        --     },
        -- })
    end

    while true do
        Wait(sleep)

        if CCTVCam == nil and isPlayerJobWhitelisted(PlayerJob) and CanDoAction() then
            local ped = PlayerPedId()
            local pedCoords = GetEntityCoords(ped)
            local menu, distance = getClosestMenu()

            if distance < 1.5 then
                sleep = 0
                DrawText3D(menu.x, menu.y, menu.z, "[E] Open CCTV")

                if IsControlJustPressed(0, 38) then
                    openCameras()
                end
            else
                sleep = 1000
            end
        end
    end
end)

CreateThread(function()
    local sleep = 1000

    while true do
        Wait(sleep)

        local ped = PlayerPedId()
        local pedCoords = GetEntityCoords(ped)
        local distance = #(pedCoords - vector3(Config.HackingMenu.x, Config.HackingMenu.y, Config.HackingMenu.z))

        if distance < 1.5 and CanDoAction() then
            sleep = 0
            DrawText3D(pedCoords.x, pedCoords.y, pedCoords.z, "[E] Hack CCTV")

            if IsControlJustPressed(0, 38) then
                triggerServerCallback("0r_cctv:server:checkItem", function(hasItem)
                    if hasItem then
                        startHacking()
                    else
                        Config.Notify("You don't have a hacking device.", "error", 5000)
                    end
                end, Config.HackItem)
            end
        else
            sleep = 1000
        end 
    end
end)

-- CreateThread(function()
--     local sleep = 1000

--     while true do
--         Wait(sleep)

--         local ped = PlayerPedId()
--         local pedCoords = GetEntityCoords(ped)
--         local distance = #(pedCoords - vector3(Config.BombPlaceCoords.x, Config.BombPlaceCoords.y, Config.BombPlaceCoords.z))

--         if distance < 1.0 and CanDoAction() then
--             sleep = 0
--             DrawText3D(pedCoords.x, pedCoords.y, pedCoords.z, "[E] Place Bomb")

--             if IsControlJustPressed(0, 38) then
--                 triggerServerCallback("0r_cctv:server:checkItem", function(hasItem)
--                     if hasItem then
--                         Plant()
--                     else
--                         Config.Notify("You don't have a bomb.", "error", 5000)
--                     end
--                 end, Config.BombItem)
--             end
--         else
--             sleep = 1000
--         end 
--     end
-- end)

function CanDoAction()
    return not Hacking and not hackfinish and not BombPlaced and not HackStarted and Config.Target == "DrawText"
end

function table_size(table)
    local count = 0

    for _ in pairs(table) do
        count = count + 1
    end

    return count
end