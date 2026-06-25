local floor = math.floor
local match = string.match
local tonumber = tonumber

local function Round(value)
    return floor(value + 0.5)
end

local function Lerp(startValue, endValue, amount)
    return startValue + (endValue - startValue) * amount
end

local function ClampedPercentageBetween(value, startValue, endValue)
    if startValue == endValue then
        return 0
    end

    local amount = (value - startValue) / (endValue - startValue)
    if amount < 0 then
        return 0
    elseif amount > 1 then
        return 1
    end

    return amount
end

local PixelUtil = {}
local cachedResolution
local cachedFactor

local function GetRegionScale(region)
    if region and region.GetEffectiveScale then
        return region:GetEffectiveScale()
    end

    if region and region.GetParent then
        local parent = region:GetParent()
        if parent and parent.GetEffectiveScale then
            return parent:GetEffectiveScale()
        end
    end

    if UIParent and UIParent.GetEffectiveScale then
        return UIParent:GetEffectiveScale()
    end

    return 1
end

function PixelUtil.GetPixelToUIUnitFactor()
    local resolution = ({ GetScreenResolutions() })[GetCurrentResolution()] or ""
    if resolution ~= cachedResolution then
        local _, physicalHeight = match(resolution, "(%d+).-(%d+)")
        physicalHeight = tonumber(physicalHeight) or 768
        cachedResolution = resolution
        cachedFactor = 768.0 / physicalHeight
    end

    return cachedFactor or 1
end

function PixelUtil.GetNearestPixelSize(uiUnitSize, layoutScale, minPixels)
    layoutScale = layoutScale or 1

    if uiUnitSize == 0 and (not minPixels or minPixels == 0) then
        return 0
    end

    local uiUnitFactor = PixelUtil.GetPixelToUIUnitFactor()
    local numPixels = Round((uiUnitSize * layoutScale) / uiUnitFactor)

    if minPixels then
        if uiUnitSize < 0 then
            if numPixels > -minPixels then
                numPixels = -minPixels
            end
        elseif numPixels < minPixels then
            numPixels = minPixels
        end
    end

    return numPixels * uiUnitFactor / layoutScale
end

function PixelUtil.SetWidth(region, width, minPixels)
    region:SetWidth(PixelUtil.GetNearestPixelSize(width, GetRegionScale(region), minPixels))
end

function PixelUtil.SetHeight(region, height, minPixels)
    region:SetHeight(PixelUtil.GetNearestPixelSize(height, GetRegionScale(region), minPixels))
end

function PixelUtil.SetSize(region, width, height, minWidthPixels, minHeightPixels)
    PixelUtil.SetWidth(region, width, minWidthPixels)
    PixelUtil.SetHeight(region, height, minHeightPixels)
end

function PixelUtil.SetPoint(region, point, relativeTo, relativePoint, offsetX, offsetY, minOffsetXPixels, minOffsetYPixels)
    local scale = GetRegionScale(region)
    region:SetPoint(
        point,
        relativeTo,
        relativePoint,
        PixelUtil.GetNearestPixelSize(offsetX or 0, scale, minOffsetXPixels),
        PixelUtil.GetNearestPixelSize(offsetY or 0, scale, minOffsetYPixels)
    )
end

function PixelUtil.SetStatusBarValue(statusBar, value)
    local width = statusBar:GetWidth()
    if width and width > 0 then
        local minValue, maxValue = statusBar:GetMinMaxValues()
        local percent = ClampedPercentageBetween(value, minValue, maxValue)
        if percent == 0 or percent == 1 then
            statusBar:SetValue(value)
        else
            local numPixels = PixelUtil.GetNearestPixelSize(width * percent, GetRegionScale(statusBar))
            statusBar:SetValue(Lerp(minValue, maxValue, numPixels / width))
        end
    else
        statusBar:SetValue(value)
    end
end

function GetPhysicalScreenSize()
    return GetScreenWidth(), GetScreenHeight()
end

_G.PixelUtil = PixelUtil
