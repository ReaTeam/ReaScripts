-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of EmojImGui

local ImGui = require "emojimgui/ext/imgui"
local JSON  = require "emojimgui/ext/json"
local Asset = require "emojimgui/modules/assets"

local IconPicker = {}
IconPicker.__index = IconPicker

local SKIN_TONES = {
    {name = "All",          value = -1},
    {name = "Default",      value = 0},
    {name = "Light",        value = 1},
    {name = "Medium Light", value = 2},
    {name = "Medium",       value = 3},
    {name = "Medium Dark",  value = 4},
    {name = "Dark",         value = 5}
}

function IconPicker:new(options)
    local self              = setmetatable({}, IconPicker)

    options = options or {}

    -- Options with default values
    self.font_names         = options.fonts or {"OpenMoji", "TweMoji"}
    self.spacing            = options.spacing or 4
    self.icon_size          = options.icon_size or 25
    self.button_color       = options.button_color or 0xA3B8FFFF
    self.window_title       = options.window_title or "Emoji Picker"
    self.window_width       = options.window_width or 290
    self.window_height      = options.window_height or 600

    -- Use a random name for flagging the visibility of groups/subgroups
    -- Since the font structures are shared accross the lib, we want to avoid collisions between pickers
    self.vis_key            = "vis_" .. math.random()
    self.current_font_name  = self.font_names[1]
    self.current_skin_tone  = 0
    self.search_text        = ""
    self.open               = true
    self.recent_icons       = {}  -- By font name: {FontName = {icon_ids...}}

    self.with_color_picker  = false

    self:loadState()
    self:filter()

    return self
end

-- Load persistent state from Reaper ExtState
function IconPicker:loadState()
    -- Recent icons
    self.recent_icons = {}
    local saved_recents = reaper.GetExtState("EmojImGui", "recent_icons")
    if saved_recents ~= "" then
        local success, result = pcall(function()
            return JSON.decode(saved_recents)
        end)
        if success and result then
            self.recent_icons = result
        end
    end

    local saved_skin_tone = reaper.GetExtState("EmojImGui", "skin_tone")
    if saved_skin_tone ~= "" then
        self.current_skin_tone = tonumber(saved_skin_tone) or 0
    end

    local saved_font = reaper.GetExtState("EmojImGui", "selected_font")
    if saved_font ~= "" then
        for _, font_name in ipairs(self.font_names) do
            if font_name == saved_font then
                self.current_font_name = saved_font
                break
            end
        end
    end

    local saved_size = reaper.GetExtState("EmojImGui", "icon_size")
    if saved_size ~= "" then
        self.icon_size = tonumber(saved_size) or 20
    end

    local saved_color = reaper.GetExtState("EmojImGui", "button_color")
    if saved_color ~= "" then
        self.button_color = tonumber(saved_color) or 0xA3B8FFFF
    end
end

function IconPicker:saveState()
    reaper.SetExtState("EmojImGui", "recent_icons",     JSON.encode(self.recent_icons), true)
    reaper.SetExtState("EmojImGui", "skin_tone",        tostring(self.current_skin_tone), true)
    reaper.SetExtState("EmojImGui", "selected_font",    self.current_font_name, true)
    reaper.SetExtState("EmojImGui", "icon_size",        tostring(self.icon_size), true)
    reaper.SetExtState("EmojImGui", "button_color",     tostring(self.button_color), true)
end

function IconPicker:setIconSize(size)
    self.icon_size = size
    self:saveState()
end


function IconPicker:capitalize(str)
    local ret, _ = string.gsub(str, "^%l", string.upper)
    return ret
end

function IconPicker:labelize(header)
    local subs = {}
    for tag in header:gmatch("[^- ]+") do
        subs[#subs+1] = self:capitalize(tag:lower())
    end
    return table.concat(subs, " / ")
end

function IconPicker:matchesSkinTone(icon)
    if self.current_skin_tone == -1 then    return true end

    -- No skin always match
    if not icon.k then return true end

    if type(icon.k) == "number" then
        return icon.k == self.current_skin_tone
    elseif type(icon.k) == "string" then
        -- Multi-tone icon like "3,5"
        for tone in icon.k:gmatch("%d+") do
            if tonumber(tone) == self.current_skin_tone then
                return true
            end
        end
    end

    return false
end

function IconPicker:addToRecent(icon)
    local recent = self.recent_icons[self.current_font_name] or {}

    -- Remove if already exists
    for i, icon_id in ipairs(recent) do
        if icon.x == icon_id then
            table.remove(recent, i)
            break
        end
    end

    -- Add to front
    table.insert(recent, 1, icon.x)

    -- Keep only most recent
    while #recent > 32 do
        table.remove(recent)
    end

    self:saveState()
end

function IconPicker:filterIcon(icon, group, subgroup)
    -- If the skin does not match the settings, filter out
    if not self:matchesSkinTone(icon) then
        return true
    end

    -- No search terms, we're ok
    if self.search_text == ''                               then return false end
    if group.n:lower():find(self.search_text, 1, true)      then return false end
    if subgroup.n:lower():find(self.search_text, 1, true)   then return false end
    if icon.l:lower():find(self.search_text, 1, true)       then return false end

    -- Search in tags
    for _, t in ipairs(icon.t) do
        if t:find(self.search_text, 1, true) then return false end
    end

    return true
end

-- Apply filtering
function IconPicker:filter()
    local font_spec     = Asset.FontSpec(self.current_font_name)
    local groups        = font_spec.groups

    self.filtered_icons = {}
    for _, group in ipairs(groups) do
        local group_one_showed = false
        for _, subgroup in ipairs(group.s or {}) do
            local sub_one_showed = false
            for _, icon in ipairs(subgroup.c or {}) do
                if self:filterIcon(icon, group, subgroup) then
                    self.filtered_icons[icon.x] = true
                else
                    sub_one_showed = true
                    group_one_showed = true
                end

                if icon.v then
                    for _, variant in ipairs(icon.v) do
                        if self:filterIcon(variant, group, subgroup) then
                            self.filtered_icons[variant.x] = true
                        else
                            sub_one_showed = true
                            group_one_showed = true
                        end
                    end
                end
            end
            -- Mark subgroup as visible/invisible
            subgroup[self.vis_key] = sub_one_showed
        end
        -- Mark group as visible/invisible
        group[self.vis_key] = group_one_showed
    end
end

-- Draw a single icon button
function IconPicker:drawIcon(ctx, icon, prefix, avail_w)
    local btn_id = "##" .. prefix .. "_" .. icon.x
    local clicked = false

    -- Style and color must be pushed every time because of the tooltip
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding, 0, 0)
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_FrameRounding, 2)
    ImGui.PushFont(ctx, Asset.Font(ctx, self.current_font_name), self.icon_size)
    if ImGui.Button(ctx, icon.utf8 .. btn_id) then
        clicked = true
    end
    ImGui.PopFont(ctx)
    ImGui.PopStyleVar(ctx, 2)

    if ImGui.IsItemHovered(ctx) then
        ImGui.SetTooltip(ctx, self:capitalize(icon.l))
    end

    ImGui.SameLine(ctx, 0, 0)

    local cursor_x = ImGui.GetCursorPosX(ctx)
    local button_width, _ = ImGui.GetItemRectSize(ctx)

    -- Enough room to continue with next button
    if cursor_x + self.spacing + button_width <= avail_w then
        ImGui.SameLine(ctx, 0, self.spacing)
    else
        ImGui.NewLine(ctx)
    end

    return clicked
end


-- Draw the component
function IconPicker:draw(ctx)
    if not self.open then return nil end

    local selected_icon = nil
    local font_spec     = Asset.FontSpec(self.current_font_name)

    ImGui.SetNextWindowSize(ctx, self.window_width, self.window_height, ImGui.Cond_FirstUseEver)

    local visible, open = ImGui.Begin(ctx, self.window_title, true, ImGui.WindowFlags_None | ImGui.WindowFlags_NoDocking | ImGui.WindowFlags_TopMost)
    self.open = open

    if visible then

        ImGui.AlignTextToFramePadding(ctx)

        local smart_offset = ImGui.CalcTextSize(ctx, "Font") + 15

        -- Font selector (if multiple fonts)
        if #self.font_names > 1 then
            ImGui.Text(ctx, "Font")
            ImGui.SameLine(ctx)
            ImGui.SetCursorPosX(ctx, smart_offset)
            ImGui.PushItemWidth(ctx, 100)
            if ImGui.BeginCombo(ctx, "##font", self.current_font_name) then
                for _, font_name in ipairs(self.font_names) do
                    local is_selected = (self.current_font_name == font_name)
                    if ImGui.Selectable(ctx, font_name, is_selected) then
                        self.current_font_name = font_name
                        self:saveState()
                        self:filter()
                    end
                    if is_selected then
                        ImGui.SetItemDefaultFocus(ctx)
                    end
                end
                ImGui.EndCombo(ctx)
            end
            ImGui.PopItemWidth(ctx)
            ImGui.SameLine(ctx)
        end

        -- Search field
        local search_width, _ = ImGui.GetContentRegionAvail(ctx)
        ImGui.SetNextItemWidth(ctx, search_width)
        local changed, new_text = ImGui.InputTextWithHint(ctx, "##search", "Search...", self.search_text)

        if changed then
            self.search_text = new_text
            self:filter()
        end

        -- Skin tone selector
        ImGui.AlignTextToFramePadding(ctx)
        ImGui.Text(ctx, "Skin")
        ImGui.SameLine(ctx)
        ImGui.SetCursorPosX(ctx, smart_offset)
        ImGui.PushItemWidth(ctx, 100)
        local current_tone_name = "Default"
        for _, tone in ipairs(SKIN_TONES) do
            if tone.value == self.current_skin_tone then
                current_tone_name = tone.name
                break
            end
        end
        if ImGui.BeginCombo(ctx, "##skintone", current_tone_name) then
            for _, tone in ipairs(SKIN_TONES) do
                local is_selected = (self.current_skin_tone == tone.value)
                if ImGui.Selectable(ctx, tone.name, is_selected) then
                    self.current_skin_tone = tone.value
                    self:saveState()
                    self:filter()
                end
                if is_selected then
                    ImGui.SetItemDefaultFocus(ctx)
                end
            end
            ImGui.EndCombo(ctx)
        end
        ImGui.PopItemWidth(ctx)


        -- PREVIEW
        ImGui.SameLine(ctx)
        ImGui.Text(ctx, "Preview")
        ImGui.SameLine(ctx)
        local psw, _ = ImGui.GetContentRegionAvail(ctx)
        ImGui.SetNextItemWidth(ctx, psw - (self.with_color_picker and 27 or 0))
        local size_changed, new_size = ImGui.SliderInt(ctx, "##size", self.icon_size, 12, 64)

        if size_changed then
            self:setIconSize(new_size)
        end

        if self.with_color_picker then
            ImGui.SameLine(ctx)
            local color_changed, new_color = ImGui.ColorEdit4(ctx, "##btncolor", self.button_color, ImGui.ColorEditFlags_NoInputs)
            if color_changed then
                self.button_color = new_color
                self:saveState()
            end
        else
            self.button_color = font_spec.advised_background_color
        end

        ImGui.Separator(ctx)

        local avail_w, avail_h = ImGui.GetContentRegionAvail(ctx)
        avail_w = avail_w - 16 -- Remove scrollbar

        -- Scrollable area
        if ImGui.BeginChild(ctx, "##content", 0, -25) then

            -- Recent icons section
            local recent = self.recent_icons[self.current_font_name] or {}
            if #recent > 0 and self.search_text == "" then
                ImGui.PushStyleColor(ctx, ImGui.Col_Text, 0x00AAFFFF)
                ImGui.Text(ctx, "MOST RECENT")
                ImGui.PopStyleColor(ctx)

                ImGui.PushStyleColor(ctx, ImGui.Col_Button, self.button_color)
                for _, icon_id in ipairs(recent) do
                    local icon = font_spec.icon_dict[icon_id]
                    if icon then
                        if self:drawIcon(ctx, icon, "recent", avail_w) then
                            selected_icon = icon
                        end
                    end
                end
                ImGui.PopStyleColor(ctx)

                ImGui.Dummy(ctx,1,10)
                ImGui.Separator(ctx)
            end

            self.icon_count = 0
            -- Display groups
            for _, group in ipairs(font_spec.groups) do
                -- Group header
                if group[self.vis_key] then
                    ImGui.PushStyleColor(ctx, ImGui.Col_Text, 0x00AAFFFF)
                    ImGui.Text(ctx, " " .. group.n:upper():gsub("-"," / "))
                    ImGui.PopStyleColor(ctx)
                    ImGui.Separator(ctx)
                end

                ImGui.PushStyleColor(ctx, ImGui.Col_Button, self.button_color)
                -- Subgroups
                for _, subgroup in ipairs(group.s or {}) do
                    if subgroup[self.vis_key] then
                        -- Subgroup header
                        ImGui.Text(ctx, self:labelize(subgroup.n))

                        ImGui.PushStyleColor(ctx, ImGui.Col_Button, self.button_color)
                        for _, icon in ipairs(subgroup.c or {}) do
                            if not self.filtered_icons[icon.x] then
                                if self:drawIcon(ctx, icon, "icon", avail_w) then
                                    selected_icon = icon
                                end
                                self.icon_count = self.icon_count + 1
                            end

                            for _, variant in ipairs(icon.v or {}) do
                                if not self.filtered_icons[variant.x] then
                                    if self:drawIcon(ctx, variant, "icon", avail_w) then
                                        selected_icon = variant
                                    end
                                    self.icon_count = self.icon_count + 1
                                end
                            end
                        end
                        ImGui.PopStyleColor(ctx)

                        ImGui.Spacing(ctx)
                    end
                end
                ImGui.PopStyleColor(ctx)

                if group[self.vis_key] then
                    ImGui.Spacing(ctx)
                end
            end

            ImGui.EndChild(ctx)
        end

        -- Icon count footer
        ImGui.Separator(ctx)
        ImGui.PushStyleColor(ctx, ImGui.Col_Text, 0x888888FF)
        ImGui.Text(ctx, string.format("%d icons", self.icon_count or 0))
        ImGui.PopStyleColor(ctx)

        ImGui.End(ctx)
    end

    -- Add selected icon to recent list
    if selected_icon then
        self:addToRecent(selected_icon)
    end

    if selected_icon then
        return {
            id          = selected_icon.x,
            label       = selected_icon.l,
            codepoint   = selected_icon.p,
            utf8        = selected_icon.utf8,
            font_name   = self.current_font_name
        }
    else
        return nil
    end
end

return IconPicker
