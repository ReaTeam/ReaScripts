-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of Reannotate

local S       = require "modules/settings"
local JSON    = require "ext/json"

local Defines = {}

Defines.TT_DEFAULT_W = 300
Defines.TT_DEFAULT_H = 100
Defines.MAX_SLOTS    = 8 -- Slot 0 is counted

local OS                            = reaper.GetOS()
local is_windows                    = OS:match('Win')
local is_macos                      = OS:match('OSX') or OS:match('macOS')
local is_linux                      = OS:match('Other')

Defines.OS              = OS
Defines.is_windows      = is_windows
Defines.is_macos        = is_macos
Defines.is_linux        = is_linux

Defines.POST_IT_COLORS = {
    0xFFFFFF, -- WHITE      Slot 0
    0x40acff, -- BLUE
    0x753ffc, -- VIOLET
    0xff40e5, -- PINK
    0xffe240, -- YELLOW
    0x3cf048, -- GREEN
    0xff9640, -- ORANGE
    0xff4040, -- RED        Slot 7
}

Defines.slot_labels = nil
Defines.slot_labels_dirty = nil

function Defines.deepCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[Defines.deepCopy(orig_key)] = Defines.deepCopy(orig_value)
        end
        setmetatable(copy, Defines.deepCopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function Defines.deepCompare(tbl1, tbl2)
	if tbl1 == tbl2 then
		return true
	elseif type(tbl1) == "table" and type(tbl2) == "table" then
		for key1, value1 in pairs(tbl1) do
			local value2 = tbl2[key1]

			if value2 == nil then
				-- avoid the type call for missing keys in tbl2 by directly comparing with nil
				return false
			elseif value1 ~= value2 then
				if type(value1) == "table" and type(value2) == "table" then
					if not Defines.deepCompare(value1, value2) then
						return false
					end
				else
					return false
				end
			end
		end

		-- check for missing keys in tbl1
		for key2, _ in pairs(tbl2) do
			if tbl1[key2] == nil then
				return false
			end
		end

		return true
	end

	return false
end

function Defines.ActiveProject()
    local p, _ = reaper.EnumProjects(-1)
    return p
end

function Defines.ActiveProjectMasterTrack()
    return reaper.GetMasterTrack(Defines.ActiveProject())
end

function Defines.defaultTooltipSize()
    return Defines.TT_DEFAULT_W, Defines.TT_DEFAULT_H
end

function Defines.SlotColor(slot)
    return Defines.POST_IT_COLORS[slot+1]
end

----- Project Labels

function Defines.RetrieveProjectSlotLabels()
    local _, str = reaper.GetSetMediaTrackInfo_String(Defines.ActiveProjectMasterTrack(), "P_EXT:Reannotate_ProjectSlotLabels", "", false)
    local slot_labels = {}
    if str == "" or str == nil then
    else
        slot_labels = JSON.decode(str)
    end

    -- Ensure labels have names by defaulting to global setting
    for i = 0, Defines.MAX_SLOTS -1 do
        slot_labels[i+1] = slot_labels[i+1] or S.getSetting("SlotLabel_" .. i)
    end

    Defines.slot_labels = slot_labels
end

function Defines.CommitProjectSlotLabels()
    if not Defines.slot_labels_dirty  then return end
    if not Defines.slot_labels        then Defines.RetrieveProjectSlotLabels() end

    local str = JSON.encode(Defines.slot_labels)
    reaper.GetSetMediaTrackInfo_String(Defines.ActiveProjectMasterTrack(), "P_EXT:Reannotate_ProjectSlotLabels", str, true)
    Defines.slot_labels_dirty = false
end

function Defines.SlotLabel(slot)
    if not Defines.slot_labels then Defines.RetrieveProjectSlotLabels() end
    return Defines.slot_labels[slot+1]
end

function Defines.SetSlotLabel(slot, label)
    if not Defines.slot_labels then Defines.RetrieveProjectSlotLabels() end
    Defines.slot_labels[slot+1] = label
    Defines.slot_labels_dirty = true
    Defines.CommitProjectSlotLabels()
end

------- Project Markdown

-- Not edited directly because we want preview / save features.
function Defines.RetrieveProjectMarkdownStyle()
    local _, str            = reaper.GetSetMediaTrackInfo_String(Defines.ActiveProjectMasterTrack(), "P_EXT:Reannotate_ProjectMarkdownStyle", "", false)

    local markdown_style = nil
    local fallback       = false

    if str == "" or str == nil then
        fallback = true
    else
        pcall(function()
            markdown_style = JSON.decode(str)
        end)

        if not markdown_style then
            fallback = true
        end
    end

    if fallback then
        -- Use new project markdown style
        markdown_style = Defines.deepCopy(S.getSetting("NewProjectMarkdown"))
        -- Commit it in project
        Defines.CommitProjectMarkdownStyle(markdown_style)
    end

    -- TODO : Normalize markdown_style after checkout for backward comp

    return markdown_style
end

function Defines.CommitProjectMarkdownStyle(markdown_style)
    -- TODO : Normalize markdown_style before commit for backward comp

    local str = JSON.encode(markdown_style)

    reaper.GetSetMediaTrackInfo_String(Defines.ActiveProjectMasterTrack(),"P_EXT:Reannotate_ProjectMarkdownStyle", str, true)
end

function Defines.RetrieveProjectStickerSize()
    local _, str =  reaper.GetSetMediaTrackInfo_String(Defines.ActiveProjectMasterTrack(), "P_EXT:Reannotate_ProjectStickerSize", "", false)
    local fallback = false
    local size = nil
    if str == "" or str == nil then
        fallback = true
    else
        size = tonumber(str)
    end

    if fallback then
        size = S.getSetting("NewProjectStickerSize")
        Defines.CommitProjectStickerSize(size)
    end

    return size
end

function Defines.CommitProjectStickerSize(size)
    reaper.GetSetMediaTrackInfo_String(Defines.ActiveProjectMasterTrack(),"P_EXT:Reannotate_ProjectStickerSize", "" .. size, true)
end

return Defines
