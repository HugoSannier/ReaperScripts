-- @description Shuffle_Selected_Media_Items
-- @author Hugo SD
-- @version 0.1
-- @about
--   This script allows to instantly inverse selected items positions.

local proj = 0

local mediaItemsPosition = {}
local lootedRandomNumbers = {}

local function GetSelectedMediaItem()
    local mediasInProjectCount = reaper.CountMediaItems(proj)
    local selectedMediaItems = {}
    for i = 0, mediasInProjectCount - 1, 1
    do
        local currentMediaItems = reaper.GetMediaItem(proj, i)
        if reaper.IsMediaItemSelected(currentMediaItems) then
            table.insert(selectedMediaItems, currentMediaItems)
        end
    end
    return selectedMediaItems
end
local function HasValue(val,tab)
    local condition
    for i = 0, #tab, 1 do
        if val == tab[i] then
            condition = true
            break
        else
            condition = false
        end
    end
    return condition
end
local function StockMediaItemPosition(mediaTab,positionTab)
    for i = 1, #mediaTab , 1 do
        local position = reaper.GetMediaItemInfo_Value(mediaTab[i], "D_POSITION")
        positionTab[i] = position
    end
end
local function GenerateRandomNumbers(amount)
    if amount > 0 and amount ~= nil then
        while #lootedRandomNumbers ~= amount  do
            local randomNumber = math.random(1, amount)
            if HasValue(randomNumber, lootedRandomNumbers) then
            else
                table.insert(lootedRandomNumbers, 1, randomNumber)
            end
        end
    end
    
end

reaper.Undo_BeginBlock()
local selectedMediaItems = GetSelectedMediaItem()
if #selectedMediaItems > 1 then

    GenerateRandomNumbers(#selectedMediaItems)
    StockMediaItemPosition(selectedMediaItems, mediaItemsPosition)
    for i = 1, #selectedMediaItems, 1 do
        local newPosition = mediaItemsPosition[lootedRandomNumbers[i]]
        reaper.SetMediaItemInfo_Value(selectedMediaItems[i], "D_POSITION", newPosition)
    end
    reaper.UpdateArrange()    
else
    reaper.ShowMessageBox("Select at least two items", "Missing items", 0)
end
reaper.Undo_EndBlock("shuffle item", 0)


