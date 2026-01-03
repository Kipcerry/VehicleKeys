
ESX = exports["es_extended"]:getSharedObject()

ESX.RegisterServerCallback('VehicleKeys:HasVehicleKeys', function(source, cb, plate)
    local xPlayer = ESX.GetPlayerFromId(source)
	MySQL.Async.fetchAll('SELECT owner FROM owned_vehicles WHERE owner = @owner AND plate = @plate', {
		['@owner'] = xPlayer.identifier,
		['@plate'] = plate
	}, function(result)
		if result[1] then
			cb(result[1].owner == xPlayer.identifier)
		else
			cb(false)
		end
	end)
end)

RegisterServerEvent('VehicleKeys:EditKeys')
AddEventHandler('VehicleKeys:EditKeys', function(PlayerId, Plate, Recieve, NoAlert)
	if not PlayerId then
		PlayerId = source
	end
    TriggerClientEvent('VehicleKeys:EditKeys', PlayerId, Plate, Recieve, NoAlert)
end)

RegisterServerEvent('VehicleKeys:Server:PlaySoundAtCoords')
AddEventHandler('VehicleKeys:Server:PlaySoundAtCoords', function(Coords)
    TriggerClientEvent('VehicleKeys:Client:PlaySoundAtCoords', -1, Coords)
end)