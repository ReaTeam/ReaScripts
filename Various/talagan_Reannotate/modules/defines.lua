-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of Reannotate

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

Defines.POSTER_TYPES = {
    PROJECT_DEFAULT                     = 0,
    NO_POSTER                           = 1,
    CUSTOM_PLAIN_POSTER                 = 2,
    CUSTOM_MARKDOWN_POSTER              = 3,
    NOTE_RENDERERED_AS_PLAIN_POSTER     = 4,
    NOTE_RENDERERED_AS_MARKDOWN_POSTER  = 5,

    POSTER_TYPE_COUNT                   = 6
}

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

function Defines.PosterTypeToName(type, default_type)
    if type == Defines.POSTER_TYPES.PROJECT_DEFAULT then
        local defname = ''
        if default_type then
            if default_type == Defines.POSTER_TYPES_PROECT_DEFAULT then
                error("Developer error : circular poster type for project pointing to itself")
            end
            defname = " (" .. Defines.PosterTypeToName(default_type, default_type) .. ")"
        end

        return "Project Default" .. defname
    end
    if type == Defines.POSTER_TYPES.NO_POSTER                           then return "None" end
    if type == Defines.POSTER_TYPES.CUSTOM_PLAIN_POSTER                 then return "Custom plain" end
    if type == Defines.POSTER_TYPES.CUSTOM_MARKDOWN_POSTER              then return "Custom markdown" end
    if type == Defines.POSTER_TYPES.NOTE_RENDERERED_AS_PLAIN_POSTER     then return "Note as plain" end
    if type == Defines.POSTER_TYPES.NOTE_RENDERERED_AS_MARKDOWN_POSTER  then return "Note as markdown" end

    error("DEVELOPER ERROR : Unknown post type" .. type)
end

function Defines.PosterTypeComboInfo(default_type)
    local start = 0
    if default_type == nil then start = 1 end
    local ret = { list = {} , reverse_lookup = {} }
    for i=start, Defines.POSTER_TYPES.POSTER_TYPE_COUNT-1 do
        local s = Defines.PosterTypeToName(i, default_type)
        ret.list[#ret.list+1] = s
        ret.reverse_lookup[s] = i
    end
    return ret
end


return Defines
