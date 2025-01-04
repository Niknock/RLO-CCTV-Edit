local Keys = {
    ["ESC"] = 322, ["F1"] = 288, ["F2"] = 289, ["F3"] = 170, ["F5"] = 166, ["F6"] = 167, ["F7"] = 168, ["F8"] = 169, ["F9"] = 56, ["F10"] = 57,
    ["~"] = 243, ["1"] = 157, ["2"] = 158, ["3"] = 160, ["4"] = 164, ["5"] = 165, ["6"] = 159, ["7"] = 161, ["8"] = 162, ["9"] = 163, ["-"] = 84, ["="] = 83, ["BACKSPACE"] = 177,
    ["TAB"] = 37, ["Q"] = 44, ["W"] = 32, ["E"] = 38, ["R"] = 45, ["T"] = 245, ["Y"] = 246, ["U"] = 303, ["P"] = 199, ["["] = 39, ["]"] = 40, ["ENTER"] = 18,
    ["CAPS"] = 137, ["A"] = 34, ["S"] = 8, ["D"] = 9, ["F"] = 23, ["G"] = 47, ["H"] = 74, ["K"] = 311, ["L"] = 182,
    ["LEFTSHIFT"] = 21, ["Z"] = 20, ["X"] = 73, ["C"] = 26, ["V"] = 0, ["B"] = 29, ["N"] = 249, ["M"] = 244, [","] = 82, ["."] = 81,
    ["LEFTCTRL"] = 36, ["LEFTALT"] = 19, ["SPACE"] = 22, ["RIGHTCTRL"] = 70,
    ["HOME"] = 213, ["PAGEUP"] = 10, ["PAGEDOWN"] = 11, ["DELETE"] = 178,
    ["LEFT"] = 174, ["RIGHT"] = 175, ["TOP"] = 27, ["DOWN"] = 173,
    ["NENTER"] = 201, ["N4"] = 108, ["N5"] = 60, ["N6"] = 107, ["N+"] = 96, ["N-"] = 97, ["N7"] = 117, ["N8"] = 61, ["N9"] = 118
}

local inCam = false
local cctvCam = 0
local cacheCameraData = nil

local selectedLocation = nil
local selectedCamera = nil
local isTabletVisible = false
local playanim = false

RegisterCommand("cctv", function()
    if not isTabletVisible then
        local xPlayer = ESX.GetPlayerData()
        local jobName = xPlayer.job.name
        local locations = {}

        for _, location in ipairs(Config.CCTVLocations) do
            if IsJobAllowed(jobName, location.jobs) then
                table.insert(locations, {
                    name = location.name,
                    cctv = location.cctv 
                })
            end
        end

        startAnim()

        SendNUIMessage({
            type = "updateLocations",
            locations = locations
        })

        SetNuiFocus(true, true)
        isTabletVisible = true
    end
end, false)

RegisterNUICallback("closeTablet", function(_, cb)
    SetNuiFocus(false, false)
    isTabletVisible = false
    stopAnim()
    cb("ok")
end)

RegisterNUICallback("selectLocation", function(data, cb)
    selectedLocation = Config.CCTVLocations[data.index + 1] 
    local locationData = selectedLocation

    local cameraElements = {}
    for j, camera in ipairs(locationData.cctv) do
        table.insert(cameraElements, {
            label = camera.info,
            value = j
        })
    end

    SendNUIMessage({
        type = "updateCameras",
        cameras = cameraElements
    })
    cb("ok")
end)

RegisterNUICallback("selectPosition", function(data, cb)

    local pos = data.pos
    local info = data.info

    if pos and info then
        TriggerEvent("cctv:startcamera", { pos = pos, info = info })
    end

    SetNuiFocus(false, false)
    isTabletVisible = false
    cb("ok")
end)

RegisterNetEvent("cctv:startcamera")
AddEventHandler("cctv:startcamera", function(cameraData)
    if not cameraData or not cameraData.pos then
        print("Error: Missing camera data!")
        return
    end

    local pos = cameraData.pos
    local x, y, z, h

    if type(pos) == "table" and pos.x and pos.y and pos.z and pos.w then
        x, y, z, h = pos.x, pos.y, pos.z, pos.w
    else
        return
    end

    if not x or not y or not z or not h then
        return
    end

    DisplayRadar(false)
    inCam = true

    SetTimecycleModifier("eyeINtheSKY")
    SetTimecycleModifierStrength(1.0)
    local scaleform = RequestScaleformMovie("SECURITY_CAMERA")
    while not HasScaleformMovieLoaded(scaleform) do
        Wait(0)
    end

    cctvCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(cctvCam, x, y, z + 1.2)
    SetCamRot(cctvCam, -15.0, 0.0, h)
    SetCamFov(cctvCam, 110.0)
    RenderScriptCams(true, false, 0, 1, 0)
    PushScaleformMovieFunction(scaleform, "PLAY_CAM_MOVIE")
    SetFocusArea(x, y, z, 0.0, 0.0, 0.0)
    PopScaleformMovieFunctionVoid()

    while inCam do
        DrawScaleformMovieFullscreen(scaleform, 255, 255, 255, 255)
        Wait(1)
    end

    ClearFocus()
    ClearTimecycleModifier()
    RenderScriptCams(false, false, 0, 1, 0)
    SetScaleformMovieAsNoLongerNeeded(scaleform)
    DestroyCam(cctvCam, false)
    DisplayRadar(true)
    inCam = false
end)

Citizen.CreateThread(function ()
    while true do
        Wait(0)
        if inCam then
			DisableAllControlActions(0)
			EnableControlAction(1, Keys['T'])
			EnableControlAction(1, 191)
			EnableControlAction(1, Keys['TOP'])
			EnableControlAction(1, Keys['DOWN'])
	
            local rota = GetCamRot(cctvCam, 2)
            if IsDisabledControlPressed(1, Keys['A']) then
                SetCamRot(cctvCam, rota.x, 0.0, rota.z + 0.7, 2)
            end

            if IsDisabledControlPressed(1, Keys['D']) then
                SetCamRot(cctvCam, rota.x, 0.0, rota.z - 0.7, 2)
            end

            if IsDisabledControlPressed(1, Keys['W']) then
                SetCamRot(cctvCam, rota.x + 0.7, 0.0, rota.z, 2)
            end

            if IsDisabledControlPressed(1, Keys['S']) then
                SetCamRot(cctvCam, rota.x - 0.7, 0.0, rota.z, 2)
            end

            if IsDisabledControlPressed(1, Keys['N+']) then
                local currentFOV = GetCamFov(cctvCam)
                if currentFOV > FOV_MIN then
                    SetCamFov(cctvCam, currentFOV - FOV_STEP)
                end
            end

            if IsDisabledControlPressed(1, Keys['N-']) then
                local currentFOV = GetCamFov(cctvCam)
                if currentFOV < FOV_MAX then
                    SetCamFov(cctvCam, currentFOV + FOV_STEP)
                end
            end
			
            if IsDisabledControlPressed(1, Keys['BACKSPACE']) then
				StoppAll()
            end
			
			local ped = PlayerPedId()
			if IsEntityDead(ped) then
				StoppAll()
			end
        end
    end
end)

function StoppAll()
	inCam = false
	DisplayRadar(true)
	cacheCameraData = nil

	local xPlayer = ESX.GetPlayerData()
	local jobName = xPlayer.job.name
	local locations = {}

	for _, location in ipairs(Config.CCTVLocations) do
		if IsJobAllowed(jobName, location.jobs) then
			table.insert(locations, {
				name = location.name,
				cctv = location.cctv 
			})
		end
	end

	SendNUIMessage({
		type = "updateLocations",
		locations = locations
	})

	SetNuiFocus(true, true)
	isTabletVisible = true
end

function IsJobAllowed(playerJob, allowedJobs)
    for _, allowedJob in ipairs(allowedJobs) do
        if playerJob == allowedJob then
            return true
        end
    end
    return false
end

function startAnim()
    if not playanim then
        playanim = true
        Citizen.CreateThread(function()
            RequestAnimDict("amb@world_human_seat_wall_tablet@female@base")

            while not HasAnimDictLoaded("amb@world_human_seat_wall_tablet@female@base") do
                Wait(0)
            end

            attachObject()
            local ped = PlayerPedId()
            TaskPlayAnim(ped, "amb@world_human_seat_wall_tablet@female@base", "base", 8.0, -8.0, -1, 50, 0, false, false, false)
        end)
    end
end

function attachObject()
    local ped = PlayerPedId()
    tab = CreateObject(GetHashKey("prop_cs_tablet"), 0, 0, 0, true, true, true)
    SetEntityCollision(tab, ped, false)
    AttachEntityToEntity(tab, ped, GetPedBoneIndex(ped, 57005), 0.17, 0.10, -0.13, 20.0, 180.0, 180.0, true, true, false, true, 1, true)
end

function stopAnim()
    local ped = PlayerPedId()
    StopAnimTask(ped, "amb@world_human_seat_wall_tablet@female@base", "base", 8.0, -8.0, -1, 50, 0, false, false, false)
    if tab then
        DeleteEntity(tab)
        tab = nil
    end
    playanim = false
end
