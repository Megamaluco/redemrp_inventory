local ITEMS = {}


------------------------- EVENTS -------------------------





RegisterNetEvent("gui:ReloadMenu")
AddEventHandler("gui:ReloadMenu", function()
    loadPlayerInventory()
end)

RegisterNetEvent("gui:getItems")
AddEventHandler("gui:getItems", function(THEITEMS)
    ITEMS = THEITEMS
end)



--------------------DROP ITEM ------------------------------------------
function DrawText3D(x, y, z, text)
    local onScreen,_x,_y=GetScreenCoordFromWorldCoord(x, y, z)
    local px,py,pz=table.unpack(GetGameplayCamCoord())
    SetTextScale(0.35, 0.35)
    SetTextFontForCurrentCommand(1)
    SetTextColor(255, 255, 255, 215)
    local str = CreateVarString(10, "LITERAL_STRING", text, Citizen.ResultAsLong())
    SetTextCentre(1)
    DisplayText(str,_x,_y)
    local factor = (string.len(text)) / 150
    DrawSprite("generic_textures", "hud_menu_4a", _x, _y+0.0125,0.015+ factor, 0.03, 0.1, 100, 1, 1, 190, 0)
end



Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)

        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)

        -- if there's no nearby Pickups we can wait a bit to save performance
        if next(Pickups) == nil then
            Citizen.Wait(500)
        end

        for k,v in pairs(Pickups) do
            local distance = GetDistanceBetweenCoords(coords, v.coords.x, v.coords.y, v.coords.z, true)


            if distance <= 5.0 then
                DrawText3D(v.coords.x, v.coords.y, v.coords.z-0.5, v.name.." ".."["..v.amount.."]")

            end

            if distance <= 1.0 and not v.inRange and IsPedOnFoot(playerPed) then


                TriggerServerEvent("item:onpickup",v.obj)
                TriggerEvent("redemrp_notification:start", "COLLECTED: "..v.name.." ".."["..v.amount.."]", 3, "success")
                v.inRange = true
            end
        end
    end
end)
RegisterNetEvent('item:removePickup')
AddEventHandler('item:removePickup', function(obj)
    print(obj)
    SetEntityAsMissionEntity(obj, false, true)
    NetworkRequestControlOfEntity(obj)
    local timeout = 0
    while not NetworkHasControlOfEntity(obj) and timeout < 5000 do
        timeout = timeout+100
        if timeout == 5000 then
            print('Never got control of' .. obj)
        end
        Wait(100)
    end
    DeleteEntity(obj)
end)

RegisterNetEvent('item:pickup')
AddEventHandler('item:pickup', function(name, amount)
    local ped     = PlayerPedId()
    local coords  = GetEntityCoords(ped)
    local forward = GetEntityForwardVector(ped)
    local x, y, z = table.unpack(coords + forward * 1.6)
    print(x)
    print(y)
    if not HasModelLoaded("P_COTTONBOX01X") then
        RequestModel("P_COTTONBOX01X")
    end
    while not HasModelLoaded("P_COTTONBOX01X") do
        Wait(1)
    end
    local obj = CreateObject("P_COTTONBOX01X", x, y, z, true, true, true)
    PlaceObjectOnGroundProperly(obj)
    SetEntityAsMissionEntity(obj, true, false)
    TriggerServerEvent("item:SharePickupServer",name, obj , amount, x, y, z)
end)

RegisterNetEvent('item:Sharepickup')
AddEventHandler('item:Sharepickup', function(name, obj , amount, x, y, z , value)
if value == 1 then
    Pickups[obj] = {
        name = name,
        obj = obj,
        amount = amount,
        inRange = false,
        coords = {x = x, y = y, z = z}
    }
	else
	 Pickups[obj] = nil
	end
end)

RegisterCommand('getinv', function(source, args)
    TriggerServerEvent("player:getItems", source)
end)




------------------------- GENERAL METHODS -------------------------


GetClosestPlayer = function(coords)
    local players         = GetPlayers()
    local closestDistance = 5
    local closestPlayer   = {}
    local coords          = coords
    local usePlayerPed    = false
    local playerPed       = PlayerPedId()
    local playerId        = PlayerId()

    if coords == nil then
        usePlayerPed = true
        coords       = GetEntityCoords(playerPed)
    end

    for i=1, #players, 1 do
        local target = GetPlayerPed(players[i])

        if not usePlayerPed or (usePlayerPed and players[i] ~= playerId) then
            local targetCoords = GetEntityCoords(target)
            local distance     = GetDistanceBetweenCoords(targetCoords, coords.x, coords.y, coords.z, true)

            if closestDistance > distance then
                table.insert(closestPlayer, players[i])
                closestDistance = distance
            end
        end
    end

    return closestPlayer, closestDistance
end

function GetPlayers()
    local players = {}

    for i = 0, 31 do
        if NetworkIsPlayerActive(i) then
            print(i)
            table.insert(players, i)
        end
    end

    return players
end


--------------------------------------------------------------------------------
local isInInventory = false


Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if IsControlJustReleased(1, 0x4CC0E2FE) and IsInputDisabled(0) then
            openInventory()
        end
    end
end)

function openInventory()
    loadPlayerInventory()
    isInInventory = true
    SendNUIMessage({
        action = "display"
    })
    SetNuiFocus(true, true)
end
RegisterCommand('close', function(source, args)
    isInInventory = false
    SendNUIMessage({
        action = "hide"
    })
    SetNuiFocus(false, false)
end)
RegisterNUICallback('NUIFocusOff', function()
    isInInventory = false
    SendNUIMessage({
        action = "hide"
    })
    SetNuiFocus(false, false)
end)
RegisterCommand('test_pl', function(source, args)
   local players = {}
   players = GetClosestPlayer()
   
    for i=1, #players, 1 do
		print(players[i])
    end
   
end)

RegisterNUICallback('GetNearPlayers', function(data, cb)
    local playerPed = PlayerPedId()
    local players = {}
   players = GetClosestPlayer()

    local foundPlayers = false
    local elements     = {}

 for i=1, #players, 1 do
        foundPlayers = true
		print("znaleziono")
        table.insert(elements, {
            label = GetPlayerName(players[i]),
            player = GetPlayerServerId(players[i])
        })
   
end
    if not foundPlayers then
        print("nope")
    else
        SendNUIMessage({
            action = "nearPlayers",
            foundAny = foundPlayers,
            players = elements,
            item = data.item,
            count = data.count,
            type = data.type,
            what = data.what
        })
    end

  --  cb("ok")
end)

RegisterNUICallback('UseItem', function(data, cb)
    print(data.item)
    TriggerServerEvent("item:use" , data.item)
end)

RegisterNUICallback('DropItem', function(data, cb)
    print(data.item)
    print(data.number)
    TriggerServerEvent("item:drop", data.item, tonumber(data.number))
    --	cb("ok")
end)

RegisterNUICallback('GiveItem', function(data, cb)
    local playerPed = PlayerPedId()
    local players = GetClosestPlayer()
    
 for i=1, #players, 1 do
        if players[i] ~= PlayerId() then
            if GetPlayerServerId(players[i]) == data.player then
                local name = tostring(data.data.item)
                local amount = tonumber(data.data.count)
                local target = tonumber(data.player)
                TriggerServerEvent('test_lols', name, amount, target)

                break
            end
        end
   end
end)

function shouldSkipAccount (accountName)
    for index, value in ipairs(Config.ExcludeAccountsList) do
        if value == accountName then
            return true
        end
    end

    return false
end

function loadPlayerInventory()
    local test  = {}
    local value = 1

    for k, v in pairs(ITEMS) do
        local use = false
        if tonumber(v) > 0 then
            for _, u in pairs(Usable) do
                if k == u then
                    use = true
                   break
                end
            end
                table.insert(test, value,{
                    label     = k,
                    type      = 'item_standard',
                    count     = v,
                    name     = k,
                    usable    = use,
                    rare      = false,
                    limit      = 64,
                    canRemove = true
                })
                value = value + 1
            
        end
    end





    SendNUIMessage({
        action = "setItems",
        itemList = test
    })
end





