local _, ns = ...

ns.wotlk = ns.wotlk or {}

local WotLK = ns.wotlk

function WotLK.RequireAwesomeWotlk()
    local hasUnitLookup = C_NamePlate and C_NamePlate.GetNamePlateForUnit
    local hasPlateEnumeration = C_NamePlate and C_NamePlate.GetNamePlates

    return hasUnitLookup and hasPlateEnumeration
end

function WotLK.GetNamePlates()
    if C_NamePlate and C_NamePlate.GetNamePlates then
        return C_NamePlate.GetNamePlates() or {}
    end

    return {}
end

function WotLK.EnumerateNamePlates()
    local plates = WotLK.GetNamePlates()
    local index = 0

    return function()
        index = index + 1
        return plates[index]
    end
end

function WotLK.GetNamePlateForUnit(unit)
    if C_NamePlate and C_NamePlate.GetNamePlateForUnit then
        return C_NamePlate.GetNamePlateForUnit(unit)
    end

    if GetNamePlateForUnit then
        return GetNamePlateForUnit(unit)
    end
end

function WotLK.GetNamePlateSize()
    local cvarWidth = WotLK.GetAwesomeCVarNumber("nameplateWidth", nil)
    local cvarHeight = WotLK.GetAwesomeCVarNumber("nameplateHeight", nil)
    if cvarWidth and cvarHeight then
        return cvarWidth, cvarHeight
    end

    return ns.clickableWidth or ns.c_width or 110, ns.clickableHeight or 30
end

local NAMEPLATE_PROJECTION_DEFAULTS = {
    nameplateVerticalOffset = { value = 0.66, min = -0.25, max = 1.25 },
    nameplateAngle = { value = 0, min = 0, max = 3.1415 },
}

function WotLK.NormalizeNamePlateProjectionCVars()
    local changed = false

    for cvar, data in pairs(NAMEPLATE_PROJECTION_DEFAULTS) do
        local value = WotLK.GetAwesomeCVarNumber(cvar, nil)
        if value == nil or value < data.min or value > data.max then
            WotLK.SetAwesomeCVar(cvar, tostring(data.value))
            changed = true
        end
    end

    return changed
end

function WotLK.GetAwesomeCVarBool(name, default)
    if C_CVar and C_CVar.GetBool then
        local ok, value = pcall(C_CVar.GetBool, name)
        if ok and value ~= nil then
            return value
        end
    end

    return WotLK.GetCVarBool(name, default)
end

function WotLK.GetAwesomeCVarNumber(name, default)
    if C_CVar and C_CVar.GetNumber then
        local ok, value = pcall(C_CVar.GetNumber, name)
        if ok and value ~= nil then
            return value
        end
    end

    return WotLK.GetCVarNumber(name, default)
end

function WotLK.SetAwesomeCVar(name, value)
    if C_CVar and C_CVar.Set then
        local ok, result = pcall(C_CVar.Set, name, value)
        if ok then
            return result
        end
    end

    return WotLK.SetCVar(name, value)
end

function WotLK.SetNamePlateStackingEnabled(nameplate, enabled)
    if nameplate and nameplate.SetStackingEnabled then
        local ok = pcall(nameplate.SetStackingEnabled, nameplate, enabled and true or false)
        return ok
    end

    return false
end

function WotLK.RefreshNativeNameplateMotion()
end

function WotLK.After(delay, callback)
    return C_Timer.After(delay, callback)
end

function WotLK.NewTimer(delay, callback)
    return C_Timer.NewTimer(delay, callback)
end

function WotLK.NextFrame(callback)
    return C_Timer.After(0, callback)
end

function WotLK.GetCVarBool(name, default)
    if C_CVar and C_CVar.GetBool then
        local ok, value = pcall(C_CVar.GetBool, name)
        if ok and value ~= nil then
            return value
        end
    end

    if GetCVarBool then
        local ok, value = pcall(GetCVarBool, name)
        if ok and value ~= nil then
            return value
        end
    end

    local value = WotLK.GetCVarString(name, nil)
    if value ~= nil then
        return value == "1" or value == 1 or value == true or value == "true"
    end

    return default
end

function WotLK.GetCVarString(name, default)
    if GetCVar then
        local ok, value = pcall(GetCVar, name)
        if ok and value ~= nil then
            return value
        end
    end

    return default
end

function WotLK.GetCVarNumber(name, default)
    if C_CVar and C_CVar.GetNumber then
        local ok, value = pcall(C_CVar.GetNumber, name)
        if ok and value ~= nil then
            return value
        end
    end

    local value = tonumber(WotLK.GetCVarString(name, nil))
    if value ~= nil then
        return value
    end

    return default
end

function WotLK.SetCVar(name, value)
    if C_CVar and C_CVar.Set then
        local ok, result = pcall(C_CVar.Set, name, value)
        if ok then
            return result
        end
    end

    if SetCVar then
        local ok, result = pcall(SetCVar, name, value)
        if ok then
            return result
        end
    end
end

function WotLK.SafeRegisterEvent(frame, event)
    local ok = pcall(frame.RegisterEvent, frame, event)
    return ok
end

function WotLK.SafeUnregisterEvent(frame, event)
    local ok = pcall(frame.UnregisterEvent, frame, event)
    return ok
end

function WotLK.IsInRaid()
    return GetNumRaidMembers and GetNumRaidMembers() > 0
end

function WotLK.IsInGroup()
    return WotLK.IsInRaid() or (GetNumPartyMembers and GetNumPartyMembers() > 0)
end

function WotLK.GetNumGroupMembers()
    if WotLK.IsInRaid() then
        return GetNumRaidMembers()
    end

    local party = GetNumPartyMembers and GetNumPartyMembers() or 0
    return party > 0 and party + 1 or 0
end

function WotLK.GetGroupRole(unit)
    if UnitGroupRolesAssigned then
        local tank, healer, damager = UnitGroupRolesAssigned(unit)
        if tank == "TANK" or tank == "HEALER" or tank == "DAMAGER" or tank == "NONE" then
            return tank
        end
        if tank then return "TANK" end
        if healer then return "HEALER" end
        if damager then return "DAMAGER" end
    end

    return "NONE"
end

function WotLK.UnitIsPet(unit)
    if _G.UnitIsPet then
        return _G.UnitIsPet(unit)
    end

    if not unit or (UnitExists and not UnitExists(unit)) then
        return false
    end

    if UnitIsPlayer and UnitIsPlayer(unit) then
        return false
    end

    if UnitCreatureType and UnitCreatureType(unit) == "Totem" then
        return false
    end

    if UnitPlayerControlled and UnitPlayerControlled(unit) then
        return true
    end

    local guid = UnitGUID and UnitGUID(unit)
    if type(guid) == "string" and string.sub(guid, 1, 5) == "0xF14" then
        return true
    end

    return false
end

function WotLK.GetCombatLogCurrentEventInfo(...)
    if CombatLogGetCurrentEventInfo then
        return CombatLogGetCurrentEventInfo(...)
    end

    local timestamp, subevent, sourceGUID, sourceName, sourceFlags,
          destGUID, destName, destFlags = ...

    return timestamp, subevent, false,
           sourceGUID, sourceName, sourceFlags, nil,
           destGUID, destName, destFlags, nil,
           select(9, ...)
end

function WotLK.ForEachAura(unit, filter, maxCount, callback)
    maxCount = maxCount or 40

    for index = 1, maxCount do
        local name, rank, icon, count, debuffType, duration, expirationTime,
              unitCaster, canStealOrPurge, shouldConsolidate, spellID =
            UnitAura(unit, index, filter)

        if not name then
            break
        end

        local stop = callback(
            name,
            rank,
            icon,
            count,
            debuffType,
            duration,
            expirationTime,
            unitCaster,
            canStealOrPurge,
            shouldConsolidate,
            spellID,
            index
        )

        if stop then
            break
        end
    end
end

function WotLK.RegisterBucket(frame, event, interval, callback)
    local pending = {}
    local scheduled = false

    local function Flush()
        scheduled = false
        local batch = pending
        pending = {}
        callback(batch)
    end

    frame:RegisterEvent(event)
    frame:HookScript("OnEvent", function(_, firedEvent, ...)
        if firedEvent ~= event then
            return
        end

        pending[#pending + 1] = ...

        if not scheduled then
            scheduled = true
            WotLK.After(interval, Flush)
        end
    end)
end

function WotLK.RegisterUnitBucket(frame, event, interval, callback)
    local pendingUnits = {}
    local scheduled = false

    local function Flush()
        scheduled = false
        callback(pendingUnits)
        wipe(pendingUnits)
    end

    frame:RegisterEvent(event)
    frame:HookScript("OnEvent", function(_, firedEvent, unit)
        if firedEvent ~= event then
            return
        end

        if unit then
            pendingUnits[unit] = true
        end

        if not scheduled then
            scheduled = true
            WotLK.After(interval, Flush)
        end
    end)
end
