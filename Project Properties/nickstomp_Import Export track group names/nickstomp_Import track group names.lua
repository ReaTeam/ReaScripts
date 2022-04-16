-- @noindex

GROUPS_MAX = 64

function GetOpenCSVFile()
    if not reaper.JS_Dialog_BrowseForOpenFiles then
        Msg("Please install JS_ReaScript REAPER extension, available in Reapack extension, under ReaTeam Extensions repository.")
    else
        retval, file = reaper.JS_Dialog_BrowseForOpenFiles(
            "Open txt track group names file", '', 'track_groups.txt','txt files (.txt)\0*.txt\0All Files (*.*)\0*.*\0', false)

        if retval and file ~= '' then
            if not file:find('.txt') then
                file = file .. ".txt"
            end
            return file
        end
    end
end

function ReadGroupNamesFromFile(filename)
    local group_names = {}
    for line in io.lines(filename) do
        table.insert(group_names, line);
    end
    return group_names
end

function GetGroupNameString(idx)
    return string.format('TRACK_GROUP_NAME:%d', idx)
end

function SetGroupName(idx, name)
    assert(reaper.GetSetProjectInfo_String(0, GetGroupNameString(idx), name, true))
end

function SetGroupNames(group_names_tbl)
    for i = 1, GROUPS_MAX do
        SetGroupName(i, group_names_tbl[i])
    end
end

function Main()
    local my_file = GetOpenCSVFile()
    local group_names = ReadGroupNamesFromFile(my_file)
    SetGroupNames(group_names)
end

reaper.Undo_BeginBlock()
Main()
reaper.Undo_EndBlock("Import track group names", -1)
