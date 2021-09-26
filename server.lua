RegisterNetEvent("limePrimePressedSprayServer")
RegisterNetEvent("limePrimePressedSmokeServer")

-- Probably want to do some distance checks instead of sync to all
AddEventHandler("limePrimePressedSprayServer", function(vehicle, isActive)
    local temp = source    
    for _, playerId in ipairs(GetPlayers()) do
        -- Could technically sync with user of vehicle as well and remove client side particle activation
        if (tonumber(temp) ~= tonumber(playerId)) then
            TriggerClientEvent("limePrimePressedSprayClient", playerId,vehicle, isActive)
        end
        
    end  
end)
-- Probably want to do some distance checks instead of sync to all
AddEventHandler("limePrimePressedSmokeServer", function(vehicle, isActive)
    local temp = source    
    for _, playerId in ipairs(GetPlayers()) do
        -- Could technically sync with user of vehicle as well and remove client side particle activation
        if (tonumber(temp) ~= tonumber(playerId)) then
            TriggerClientEvent("limePrimePressedSmokeClient", playerId,vehicle, isActive)
        end
        
    end  
end)
