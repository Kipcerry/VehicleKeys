ESX = exports["es_extended"]:getSharedObject()
local ExtraVehicleKeys = {}
local CanToggleVehicleLock = true
local Lightbars = {
	'fbiold',
	'lightbarTwoSticks',
	'longLightbar'
}

function IsLightbar(vehicle)
	local IsLightbar = false
	for k, v in pairs(Lightbars) do
		if GetHashKey(v) == GetEntityModel(vehicle) then 
			IsLightbar = true
		end
	end
	return IsLightbar
end


RegisterKeyMapping(Config.VehicleLockCommand, Config.VehicleLockText, 'keyboard', 'u')
RegisterCommand(Config.VehicleLockCommand, function()
	ToggleVehicleLock()
end, false)

function GetClosestVehicleNotLightbar()
	local Vehicle = ESX.Game.GetClosestVehicle(GetEntityCoords(PlayerPedId()))
	local Distance = #(GetEntityCoords(Vehicle) - GetEntityCoords(PlayerPedId()))
	if Distance <= Config.ToggleLockRange then
		if IsLightbar(Vehicle) then
			local Vehicles = ESX.Game.GetVehiclesInArea(GetEntityCoords(Vehicle), 1.0)
			for k, v in pairs(Vehicles) do
				if not IsLightbar(v) then
					return v
				end
			end
		else
			return Vehicle
		end
	else
		return nil
	end
end

function ToggleVehicleLock()
	if not CanToggleVehicleLock then
		return
	end
	CanToggleVehicleLock = false
	local Vehicle = nil
	local Player = PlayerPedId()
	if IsPedInAnyVehicle(Player) then
		Vehicle = GetVehiclePedIsIn(Player, false)
	else
		Vehicle = GetClosestVehicleNotLightbar()
	end
	if DoesEntityExist(Vehicle) then
		local HasVehicleKeys = false
		for k, v in pairs(ExtraVehicleKeys) do
			if v == ESX.Math.Trim(GetVehicleNumberPlateText(Vehicle)) then
				HasVehicleKeys = true
			end
		end
		local Plate = tostring(GetVehicleNumberPlateText(Vehicle))
		ESX.TriggerServerCallback('VehicleKeys:HasVehicleKeys', function(Owner)
			if Owner or HasVehicleKeys then
				UpdateVehicleLocked(Vehicle)
			end
		end, Plate)
	else
		ESX.ShowNotification(Config.NoVehicleInArea)
	end
	Wait(1000)
	CanToggleVehicleLock = true
end


function UpdateVehicleLocked(Vehicle)
	local VehicleLockStatus = GetVehicleDoorLockStatus(Vehicle)
	local Player = PlayerPedId()
	local PlayerCoords = GetEntityCoords(Player)
	local Prop = GetHashKey('p_car_keys_01')
	LoadModel(Prop)
	LoadAnim('anim@mp_player_intmenu@key_fob@')
	SetCurrentPedWeapon(Player, GetHashKey("WEAPON_UNARMED")) 
	local KeyFob = CreateObject(Prop, PlayerCoords.x, PlayerCoords.y, PlayerCoords.z, true, true, false)
	local Pos, Rot = vector3(0.09,0.04,0.0), vector3(0.09,0.04,0.0)
	AttachEntityToEntity(KeyFob, Player, GetPedBoneIndex(Player, 57005), Pos.x, Pos.y, Pos.z, Rot.x, Rot.y, Rot.z, true, true, false, true, 1, true)
	TaskPlayAnim(PlayerPedId(), 'anim@mp_player_intmenu@key_fob@', "fob_click", 8.0, 8.0, -1, 48, 1, false, false, false)
	TriggerServerEvent('VehicleKeys:Server:PlaySoundAtCoords', GetEntityCoords(Vehicle))
	SetVehicleLights(Vehicle, 2)
	Citizen.Wait(200)
	SetVehicleLights(Vehicle, 1)
	Citizen.Wait(200)
	SetVehicleLights(Vehicle, 2)
	Citizen.Wait(200)
	GetControlOfEntity(Vehicle)
	if not DecorExistOn(Vehicle, lock_decor) then
		SetVehicleDoorsLocked(Vehicle, GetVehicleDoorLockStatus(Vehicle))
	end
	if VehicleLockStatus == 1 then
		SetVehicleDoorsLocked(Vehicle, 2)
		ESX.ShowNotification(Config.LockVehicle)
	elseif VehicleLockStatus == 2 then
		SetVehicleDoorsLocked(Vehicle, 1)
		ESX.ShowNotification(Config.UnlockVehicle)
	end
	TriggerServerEvent('VehicleKeys:Server:PlaySoundAtCoords', GetEntityCoords(Vehicle))
	Citizen.Wait(200)
	SetVehicleLights(Vehicle, 1)
	SetVehicleLights(Vehicle, 0)
	Citizen.Wait(200)
	DeleteEntity(KeyFob) 
end


RegisterNetEvent('VehicleKeys:Client:PlaySoundAtCoords', function(Coords)
	PlaySoundFromCoord(-1, "Remote_Control_Close", Coords.x, Coords.y, Coords.z, "PI_Menu_Sounds", 1, 0)
end)


function GetControlOfEntity(entity)
	local netTime = 15
	NetworkRequestControlOfEntity(entity)
	while not NetworkHasControlOfEntity(entity) and netTime > 0 do 
		NetworkRequestControlOfEntity(entity)
		Citizen.Wait(1)
		netTime = netTime -1
	end
end

-- Check if has owned vehicle key:

function LoadAnim(animDict)
	RequestAnimDict(animDict); while not HasAnimDictLoaded(animDict) do Citizen.Wait(1) end
end

-- Load Model
function LoadModel(model)
	RequestModel(model); while not HasModelLoaded(model) do Citizen.Wait(1) end
end

if Config.SharedKeys then
	RegisterCommand(Config.ShareKeyCommand, function(source, args, rawCommand)
		local PlayerId = tonumber(args[1])
		ShareVehicleKey(PlayerId)
	end, false)

	function ShareVehicleKey(PlayerId)
		local Vehicle = nil
		local Player = PlayerPedId()
		if IsPedInAnyVehicle(Player) then
			Vehicle = GetVehiclePedIsIn(Player, false)
			if not PlayerId then
				if GetPedInVehicleSeat(Vehicle, 0) ~= 0 then
					PlayerPedId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(GetPedInVehicleSeat(Vehicle, 0)))
				end
			end
		else
			Vehicle = GetClosestVehicleNotLightbar()
		end
		if DoesEntityExist(Vehicle) then
			local HasVehicleKeys = false
			for k, v in pairs(ExtraVehicleKeys) do
				if v == ESX.Math.Trim(GetVehicleNumberPlateText(Vehicle)) then
					HasVehicleKeys = true
				end
			end
			local Plate = tostring(GetVehicleNumberPlateText(Vehicle))
			ESX.TriggerServerCallback('VehicleKeys:HasVehicleKeys', function(Owner)
				if PlayerId then
    				local OwnPlayerId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(PlayerPedId()))
					if PlayerId == OwnPlayerId then
						ESX.ShowNotification(Config.CantGiveToSelf)
					else
						local RecievingPlayer = GetPlayerPed(GetPlayerFromServerId(PlayerId))
						local RecievingPlayerCoords = GetEntityCoords(RecievingPlayer)
						local Distance = #(RecievingPlayerCoords - GetEntityCoords(Player))
						if Distance <= Config.ShareRange then
							if Owner then
								TriggerServerEvent('VehicleKeys:EditKeys', PlayerId, Plate, true, false)
							elseif HasVehicleKeys then
								TriggerServerEvent('VehicleKeys:EditKeys', PlayerId, Plate, true, false)
								TriggerServerEvent('VehicleKeys:EditKeys', false, Plate, true, false)
							end
						else
							ESX.ShowNotification(Config.NoPlayerInArea)
						end
					end
				else
					ESX.ShowNotification(Config.NoPlayerInArea)
				end
			end, Plate)
		else
			ESX.ShowNotification(Config.NoVehicleInArea)
		end
	end

	RegisterNetEvent('VehicleKeys:EditKeys')
	AddEventHandler('VehicleKeys:EditKeys', function(Plate, Recieve, NoAlert)
		if Recieve then
			table.insert(ExtraVehicleKeys, ESX.Math.Trim(Plate))
			if not NoAlert then
				ESX.ShowNotification(Config.RecievedKeys..Plate)
			end
		else
			for i = 1, #ExtraVehicleKeys do
				if ExtraVehicleKeys[i] == ESX.Math.Trim(Plate) then
					if not NoAlert then
				ESX.ShowNotification(Config.RemovedKeys..Plate)
					end
					table.remove(ExtraVehicleKeys, i)
				end
			end
		end
	end)
end