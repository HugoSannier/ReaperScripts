-- @description HugoSD_Replace_Item_By_Selection
-- @author Hugo SD
-- @version 0.1.1
-- @about
--   This script allows to instantly replace items by other ones, it also provides different remplacement methods.
-- @provides
--  [nomain] HugoSD_Replace_Item_By_Selection.lua

package.path = package.path..';'..debug.getinfo(1, "S").source:match [[^@?(.*[\/])[^\/]-$]] .. "?.lua;"
require('HugoSD_Replace_Item_By_Selection')

local proj = 0


local guiHeight = 395
local guiWidth = 260

local buttonH = 70
local buttonW = 303
local fontSizeButton = 20

local smallButtonH = 80
local smallButtonW = 80

local ctx = reaper.ImGui_CreateContext("Replace_Item_By_Selection")


Settings = {
    isRandomOrSequence = 0,   --float here because of radio button
    
    isStandardOrShuffle = 0,  --float here because of radio button    
    
    isRestartOrBackward = 0,  --float here because of radio button
    
    isErasedOrMuted = 0,      --float here because of radio button
    
    isRandomEnable = false,
    
    isSequenceEnable = true,
    
    isStandartDisable = true,

    isButton2Disable = true,

    isButtonReplaceDisable = true,
    
    avoidCounter = 0,


}


function HiddenTip(Tip)
reaper.ImGui_TextDisabled(ctx, "(?)")
 if reaper.ImGui_BeginItemTooltip(ctx) then
    reaper.ImGui_Text(ctx, Tip)
    reaper.ImGui_EndTooltip(ctx)
 end

end

function RGBRemap(value)

local newValue = value/255
    return newValue
end

function Remap(value, min, max, newMin, newMax)
local newValue = value/(max - min) * (newMax - newMin)
    return newValue

end



function Loop()
    local visible, p_open = reaper.ImGui_Begin( ctx, "Replace_Item_By_Selection", true, reaper.ImGui_WindowFlags_NoDocking() | reaper.ImGui_WindowFlags_NoResize())
    if visible then
        reaper.ImGui_SetNextWindowSize(ctx, guiWidth, guiHeight, reaper.ImGui_Cond_Once())
        reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_WindowRounding(), 5)

        if reaper.ImGui_BeginTable(ctx, "Button Table", 1)then

            
            reaper.ImGui_TableNextColumn(ctx)
            reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ItemSpacing(), 0, 10)
            reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FrameRounding(), 10)
            
            reaper.ImGui_BeginGroup(ctx)
            
            -- Button 1--
            reaper.ImGui_PushFont(ctx, nil, fontSizeButton)
            reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), reaper.ImGui_ColorConvertDouble4ToU32(Remap(58, 0, 255, 0, 1), Remap(168, 0, 255, 0, 1), Remap(255, 0, 255, 0, 1), 1))
            if reaper.ImGui_Button(ctx, "1", smallButtonH, smallButtonW) then 
                GetMediaPoolReplaced()
            end
            reaper.ImGui_PopFont(ctx)
            if reaper.ImGui_BeginItemTooltip(ctx) then
                reaper.ImGui_Text(ctx, "Select items and click this button\nto add them to the replaced pool")
                reaper.ImGui_EndTooltip(ctx)
            end
            reaper.ImGui_PopStyleColor(ctx)

            -- Button 2--
            reaper.ImGui_PushFont(ctx, nil, fontSizeButton)
            if #MediaPoolReplaced <= 0 then
                Settings.isButton2Disable = true
            elseif #MediaPoolReplaced > 0 then
                Settings.isButton2Disable = false
            end
            reaper.ImGui_BeginDisabled(ctx, Settings.isButton2Disable)
            reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), reaper.ImGui_ColorConvertDouble4ToU32(Remap(58, 0, 255, 0, 1), Remap(168, 0, 255, 0, 1), Remap(255, 0, 255, 0, 1), 1))
            if reaper.ImGui_Button(ctx, "2", smallButtonH, smallButtonW) then 
                GetMediaPoolReplacer()
            end
            reaper.ImGui_PopFont(ctx)
            if reaper.ImGui_BeginItemTooltip(ctx) then
                reaper.ImGui_Text(ctx, "Select items and click this button\nto add them to the replacer pool \n\n /!\\ You need to select item to\nreplaced first.")
                reaper.ImGui_EndTooltip(ctx)
            end
            reaper.ImGui_PopStyleColor(ctx)
            reaper.ImGui_EndGroup(ctx)
            reaper.ImGui_SameLine(ctx, 0, 10)
            reaper.ImGui_EndDisabled(ctx)

            -- Replace Button --
            reaper.ImGui_PushFont(ctx, nil, fontSizeButton)
            if #MediaPoolReplaced <= 0 and #MediaPoolReplacer <= 0  then
                Settings.isButtonReplaceDisable = true
            elseif #MediaPoolReplaced > 0 and #MediaPoolReplacer > 0 then
                Settings.isButtonReplaceDisable = false
            end
            reaper.ImGui_BeginDisabled(ctx, Settings.isButtonReplaceDisable)
            reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), reaper.ImGui_ColorConvertDouble4ToU32(Remap(147, 0, 255, 0, 1), Remap(45, 0, 255, 0, 1), Remap(45, 0, 255, 0, 1), 1))
            reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), reaper.ImGui_ColorConvertDouble4ToU32(Remap(177, 0, 255, 0, 1), Remap(77, 0, 255, 0, 1), Remap(77, 0, 255, 0, 1), 1))
            if reaper.ImGui_Button(ctx, "REPLACE", 150, 170) then 
                Replace()
            end
            reaper.ImGui_PopStyleColor(ctx); reaper.ImGui_PopStyleColor(ctx)
            reaper.ImGui_EndDisabled(ctx)

            reaper.ImGui_PopStyleVar(ctx) --Spacing
            reaper.ImGui_PopStyleVar(ctx) --Rounding
            reaper.ImGui_PopFont(ctx)
            if reaper.ImGui_BeginItemTooltip(ctx) then
                reaper.ImGui_Text(ctx, "Replaced items in the replaced pool\n by items in the replaced pool.\n\n /!\\ You need to select items to\nreplaced and replacer items first.")
                reaper.ImGui_EndTooltip(ctx)
            end
        reaper.ImGui_EndTable(ctx)
        end

        reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FrameRounding(), 5)
        -- reaper.ImGui_NewLine(ctx);
        -- _, Settings.isErasedOrMuted = reaper.ImGui_Checkbox(ctx, "Erase or mute", Settings.isErasedOrMuted) 
        _, Settings.isErasedOrMuted = reaper.ImGui_RadioButtonEx(ctx, "Erased", Settings.isErasedOrMuted, 0)
        reaper.ImGui_SameLine(ctx, 0, 5); HiddenTip("Erased : replacing items will erase old ones.")
        reaper.ImGui_SameLine(ctx, 0, 30) ;_, Settings.isErasedOrMuted = reaper.ImGui_RadioButtonEx(ctx, "Muted", Settings.isErasedOrMuted, 1)
        reaper.ImGui_SameLine(ctx, 0, 5); HiddenTip( "Muted : replacing items will be place on a\nnew track and old item's track will be muted")
        reaper.ImGui_PopStyleVar(ctx) --Rounding

        -- Options ----
        reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_SeparatorTextAlign(), 0.5, 0.5)
        reaper.ImGui_PushFont(ctx, nil, 16)
        reaper.ImGui_SeparatorText(ctx, "Options")
        reaper.ImGui_PopStyleVar(ctx)
        reaper.ImGui_PopFont(ctx)

        if  reaper.ImGui_BeginTable(ctx, "", 2, reaper.ImGui_TableFlags_BordersInnerV()) then

            reaper.ImGui_TableNextColumn(ctx); _, Settings.isRandomOrSequence = reaper.ImGui_RadioButtonEx(ctx, "Random", Settings.isRandomOrSequence, 0)
            reaper.ImGui_TableNextColumn(ctx); _, Settings.isRandomOrSequence = reaper.ImGui_RadioButtonEx(ctx, "Sequence",  Settings.isRandomOrSequence, 1)


            ------ Random Block ------
            reaper.ImGui_BeginDisabled(ctx, Settings.isRandomEnable)
            reaper.ImGui_TableNextColumn(ctx)
            _, Settings.isStandardOrShuffle = reaper.ImGui_RadioButtonEx(ctx, "Standard",  Settings.isStandardOrShuffle, 0)
            reaper.ImGui_BeginDisabled(ctx, Settings.isStandartDisable)
            reaper.ImGui_Text(ctx, "Avoid last : ")
            if reaper.ImGui_ArrowButton(ctx, "Left_Arrow", reaper.ImGui_Dir_Left()) then
                Settings.avoidCounter = Settings.avoidCounter - 1
                if Settings.avoidCounter <= 0 then
                    Settings.avoidCounter = 0
                end
            end
            reaper.ImGui_SameLine(ctx, 0, 2);
            if reaper.ImGui_ArrowButton(ctx, "Right_Arrow", reaper.ImGui_Dir_Right()) then
                if  #MediaPoolReplacer > 0 then
                    Settings.avoidCounter = Settings.avoidCounter + 1
                    if Settings.avoidCounter >= #MediaPoolReplacer then
                        Settings.avoidCounter = #MediaPoolReplacer - 1
                    end          
                end
            end
            reaper.ImGui_SameLine(ctx, 0, 10); reaper.ImGui_Text(ctx, tostring(Settings.avoidCounter))
            reaper.ImGui_SameLine(ctx, 0, 10); HiddenTip("Avoid counter cant be higher than the number of replacer assets ")

            reaper.ImGui_EndDisabled(ctx)
            _, Settings.isStandardOrShuffle = reaper.ImGui_RadioButtonEx(ctx, "Shuffle",  Settings.isStandardOrShuffle, 1)
            reaper.ImGui_SameLine(ctx, 0, 5); HiddenTip("In shuffle mode the script will place all\nthe assets once  before placing them again")
            reaper.ImGui_EndDisabled(ctx)

            ------ Sequence Block -------
            reaper.ImGui_TableNextColumn(ctx)
            reaper.ImGui_BeginDisabled(ctx, Settings.isSequenceEnable)
            
            reaper.ImGui_Text(ctx, "End of the sequence : ")
            _, Settings.isRestartOrBackward = reaper.ImGui_RadioButtonEx(ctx, "Restart", Settings.isRestartOrBackward, 0) 
            reaper.ImGui_SameLine(ctx, 0, 5); HiddenTip("A to Z then A to Z")
            
            _, Settings.isRestartOrBackward = reaper.ImGui_RadioButtonEx(ctx, "Backward", Settings.isRestartOrBackward, 1) 
            reaper.ImGui_SameLine(ctx, 0, 5); HiddenTip("A to Z then Z to A")
            reaper.ImGui_EndDisabled(ctx)
            reaper.ImGui_EndTable(ctx)


            ---- Disable Logic ----
            if Settings.isStandardOrShuffle == 0 and Settings.isStandartDisable == true then
                Settings.isStandartDisable = false
            end
            if Settings.isStandardOrShuffle == 1 and Settings.isStandartDisable == false then
                Settings.isStandartDisable = true
            end

            if Settings.isRandomOrSequence == 0 and Settings.isRandomEnable == true then
                Settings.isRandomEnable = false
                Settings.isSequenceEnable = true
            end

            if Settings.isRandomOrSequence == 1 and Settings.isRandomEnable == false then
                Settings.isRandomEnable = true
                Settings.isSequenceEnable = false
            end        
        end
        reaper.ImGui_PopStyleVar(ctx) --window Rounding

    
        reaper.ImGui_End(ctx)
    end

    if p_open then
        reaper.defer(Loop)
    end
end


reaper.defer(Loop)

