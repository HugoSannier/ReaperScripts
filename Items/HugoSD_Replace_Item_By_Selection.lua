--@noindex

local proj = 0

MediaPoolReplaced = {}
local mediaPoolReplacedPosition = {}

MediaPoolReplacer = {}

local function Literalize(str)
    -- kindda hard to get but the idea here is to replace all the magic character that we find (between '[]') by the them preceded by %
return string.gsub(
    str,
    "[%(%)%.%%%+%*%-%?%[%]%^%$]",
    function(character)
    return "%"..character
    end
)
end

function LogItemChunk(mediaTab)
    reaper.ClearConsole()
    for i = 1, #mediaTab, 1 do
        local _, chunk = reaper.GetItemStateChunk(mediaTab[i], "", false)
        local pattern = "\n".."GUID".."%s-{.-}\n"
        local guid = string.match(chunk, pattern, 1)
        reaper.ShowConsoleMsg("\nFor media item "..tostring(i).." the guid is : ".. tostring(guid))
    end

end

function HasValue(tab, val)
    local condition
    for i = 1, #tab, 1 do
        if val == tab[i] then
            condition = true
            break
        else
            condition = false
        end
    end
    return condition
end

local function ResetChunkValue(chunk, key, newValue)
    local pattern = "\n"..key.."%s-{.-}"
    for sub in chunk:gmatch(pattern) do
        local newValueLine = '\n'..key..(newValue or reaper.genGuid('')..'\n')
        local sub_pattern = Literalize(sub)
        chunk = string.gsub(chunk, sub_pattern, newValueLine, 1)
    end
    return chunk
end

local function DuplicateItem(item, position)
    local _, chunk = reaper.GetItemStateChunk(item, "", false)
    chunk = ResetChunkValue(chunk, "GUID", "")
    chunk = ResetChunkValue(chunk, "IGUID","")
    local track = reaper.GetMediaItemInfo_Value(item, "P_TRACK")
    local newItem = reaper.AddMediaItemToTrack(track)
    reaper.SetItemStateChunk(newItem, chunk, false)
    reaper.SetMediaItemInfo_Value(newItem, "D_POSITION", (position or 0))
    return newItem
end

local function GetMediaItemPosition(mediaTab)
    local positionTab = {}
    for i = 1, #mediaTab , 1 do
        local position = reaper.GetMediaItemInfo_Value(mediaTab[i], "D_POSITION")
        positionTab[i] = position
    end
    return positionTab
end
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
local function ReplaceItemPositionErase(replaced, replacer)
    local newPositions = GetMediaItemPosition(replaced)
    local replacedTrack = reaper.GetMediaItemInfo_Value(replaced[1], "P_TRACK")
    for k, v in pairs(replaced) do

        if Settings.isRandomOrSequence == 1 then --Sequence mode enabled
            reaper.SetMediaItemInfo_Value(replacer[k], "D_POSITION", newPositions[k])
            reaper.MoveMediaItemToTrack(replacer[k], replacedTrack)
        end

        if Settings.isRandomOrSequence == 0 then --Random mode
            reaper.SetMediaItemInfo_Value(replacer[k], "D_POSITION", newPositions[k])
            reaper.MoveMediaItemToTrack(replacer[k], replacedTrack)
        end

    end

    for k, v in pairs(replaced) do
        reaper.DeleteTrackMediaItem(replacedTrack, v)
    end
    for i = 1, #replaced, 1 do replaced[i] = nil end --clear the replaced table
    for i = 1, #replacer, 1 do replacer[i] = nil end --clear the replacer table
    reaper.UpdateArrange()    
end
local function ReplaceItemPositionMute(replaced, replacer)
    local newPositions = GetMediaItemPosition(replaced)
    local replacedTrack = reaper.GetMediaItemInfo_Value(replaced[1], "P_TRACK")
    local replacedTrackIdx = reaper.GetMediaTrackInfo_Value(replacedTrack, "IP_TRACKNUMBER")
    local _, replacedTrackName = reaper.GetSetMediaTrackInfo_String(replacedTrack, "P_NAME", "", false)

    reaper.InsertTrackAtIndex(replacedTrackIdx, false)
    local newTrack = reaper.GetTrack(proj, replacedTrackIdx)
    reaper.GetSetMediaTrackInfo_String(newTrack, "P_NAME", tostring(replacedTrackName) .." (New Assets)", true)

    for k, v in pairs(replacer) do
        reaper.SetMediaItemInfo_Value(v, "D_POSITION", newPositions[k])
        reaper.MoveMediaItemToTrack(v, newTrack)
    end
    reaper.SetMediaTrackInfo_Value(replacedTrack, "B_MUTE", 1)
    for i = 1, #replaced, 1 do replaced[i] = nil end --clear the replaced table
    for i = 1, #replacer, 1 do replacer[i] = nil end --clear the replacer table
    reaper.UpdateArrange()  
end
local function UnSelectedMediaItem(mediaTab)
    for i = 1, #mediaTab, 1 do
        reaper.SetMediaItemSelected(mediaTab[i], false)
    end
    
end

local function RepopulatePool(mediaTab, target)
    local itemNeeded = target - #mediaTab

    if Settings.isRandomOrSequence == 1 and Settings.isRestartOrBackward == 0 then -- Sequence mode, restart
        local idx = 1
        for i = 1, itemNeeded, 1 do
            local newItem = DuplicateItem(mediaTab[idx])
            table.insert(mediaTab, newItem)
            idx = idx +1
            if idx > #mediaTab then
                idx = 1
            end
        end
    end

    if Settings.isRandomOrSequence == 1 and Settings.isRestartOrBackward == 1 then -- Sequence mode, backward
        local isGoingForward = false
        local idx = #mediaTab - 1

        for i = 1, itemNeeded, 1 do
            local newItem = DuplicateItem(mediaTab[idx],0)
            table.insert(mediaTab, newItem)
            if isGoingForward == true then idx = idx + 1 end
            if isGoingForward == false then idx = idx - 1 end

            if isGoingForward == true and idx > #mediaTab then 
                idx = #mediaTab - 1
                isGoingForward = false
            end

            if isGoingForward == false and idx < 1 then 
                idx = 1 + 1
                isGoingForward = true
            end
        end
        
    end

    if Settings.isRandomOrSequence == 0 and Settings.isStandardOrShuffle == 0 then -- Random mode, standart
        local newItemPool = {}
        local randomNumberPool = {}
        while #newItemPool ~= target do
            local randomNumber = math.random(1, #mediaTab)
            if not HasValue(randomNumberPool, randomNumber) then
                table.insert(randomNumberPool, randomNumber)
                local newItem = DuplicateItem(mediaTab[randomNumber], 0)
                table.insert(newItemPool, newItem)
                if #randomNumberPool > Settings.avoidCounter then
                    table.remove(randomNumberPool, 1)
                end
            end 
        end
        for i = 1, #mediaTab, 1 do mediaTab[i] = nil end --clear the mediaTab table
        for i = 1, #newItemPool, 1 do rawset(mediaTab, i, newItemPool[i]) end-- move all the newItemPool content to mediaTab
    end

    if Settings.isRandomOrSequence == 0 and Settings.isStandardOrShuffle == 1 then -- Random mode, shuffle
        local newItemPool = {}
        local randomNumberPool = {}
        while #newItemPool < target do
            local randomNumber = math.random(1, #mediaTab)
            if not HasValue(randomNumberPool, randomNumber) and #randomNumberPool ~= #mediaTab then
                table.insert(randomNumberPool, randomNumber)
                local newItem = DuplicateItem(mediaTab[randomNumber])
                table.insert(newItemPool, newItem)
            elseif #randomNumberPool == #mediaTab then
                for i = 1, #randomNumberPool, 1 do randomNumberPool[i] = nil end --clear the table
            end
        end
        for i = 1, #mediaTab, 1 do mediaTab[i] = nil end --clear the mediaTab table
        for i = 1, #newItemPool, 1 do rawset(mediaTab, i, newItemPool[i]) end-- move all the newItemPool content to mediaTab
    end
end

function GetMediaPoolReplaced() -- Button 1
    MediaPoolReplaced = GetSelectedMediaItem()
    mediaPoolReplacedPosition = GetMediaItemPosition(MediaPoolReplaced)
    UnSelectedMediaItem(MediaPoolReplaced)
    reaper.UpdateArrange()
end

function GetMediaPoolReplacer() -- Button 2
    MediaPoolReplacer = GetSelectedMediaItem()
    UnSelectedMediaItem(MediaPoolReplacer)
    reaper.UpdateArrange()
end

function Replace()
    reaper.Undo_BeginBlock2(proj)
    if Settings.isErasedOrMuted == 0 then --Erased
        RepopulatePool(MediaPoolReplacer, #MediaPoolReplaced)
        ReplaceItemPositionErase(MediaPoolReplaced, MediaPoolReplacer)
    elseif Settings.isErasedOrMuted == 1 then --Muted 
        RepopulatePool(MediaPoolReplacer, #MediaPoolReplaced)
        ReplaceItemPositionMute(MediaPoolReplaced, MediaPoolReplacer)
    end
    reaper.Undo_EndBlock2(proj, "Replace_Item_By_Selection", -1)
end


