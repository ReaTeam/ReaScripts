-- @noindex

GROUPS_MAX = 64

function Msg(val)
    reaper.ShowConsoleMsg(tostring(val) .. "\n")
end

function GetSaveCSVFile()
    if not reaper.JS_Dialog_BrowseForSaveFile then
        Msg("Please install JS_ReaScript REAPER extension, available in Reapack extension, under ReaTeam Extensions repository.")
    else
        retval, file = reaper.JS_Dialog_BrowseForSaveFile(
            "Export track groups to file", '', 'track_groups.txt', 'txt files (.txt)\0*.txt\0All Files (*.*)\0*.*\0')

        if retval and file ~= '' then
            if not file:find('.txt') then
                file = file .. ".txt"
            end
            return file
        end
    end
end

function GetGroupNameString(idx)
    return string.format('TRACK_GROUP_NAME:%d', idx)
end

function GetGroupName(idx)
    local retval, group_name_str = reaper.GetSetProjectInfo_String(0, GetGroupNameString(idx), '', false);
    assert(retval)
    return group_name_str
end

function GetGroupNames(table)
    local group_names = {}
    for i = 1, GROUPS_MAX do
        group_names[i] = GetGroupName(i)
    end
    return group_names
end

function file_write_line(f, line)
    f:write(tostring(line) .. "\n")
end

function WriteGroupNamesToFile(my_file, group_names_lst)
    local f = io.open(my_file, "w")
    for i = 1, GROUPS_MAX do
        file_write_line(f, group_names_lst[i])
    end
    f:close() -- never forget to close the file
end

function Main()
    local my_file = GetSaveCSVFile()
    local group_names_lst = GetGroupNames()
    WriteGroupNamesToFile(my_file, group_names_lst)
end

Main()
