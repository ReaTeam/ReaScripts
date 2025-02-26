-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of MaCCLane

local function ext(filename)
    local index = string.find(filename, "%.[^.]*$")
    if not index then
        return ''
    end
    return filename:sub(index+1, -1)
end

local function baseName(filename)
    local index = string.find(filename, "%.[^.]*$")
    if not index then
        return ''
    end
    return filename:sub(1, index-1)
end

local function crawlForFiles(folder, ze_ext)
    local sdir  = ''
    local file  = ''
    local p     = 0
    local ret   = {
        name    = "___root",
        subs    = {},
        files   = {},
        fweight = 0
    }

    reaper.EnumerateSubdirectories(folder, -1)
    while sdir do
        sdir = reaper.EnumerateSubdirectories(folder, p)
        if not sdir then
            break
        end
        local sret = crawlForFiles(folder .. "/" .. sdir, ze_ext)
        sret.name  = sdir
        ret.subs[#ret.subs+1] = sret
        ret.fweight = ret.fweight + sret.fweight
        p = p + 1
    end

    p = 0
    reaper.EnumerateFiles(folder, -1)
    while file do
        file = reaper.EnumerateFiles(folder, p)
        if not file then
            break
        end
        local ext = ext(file)
        if ext == ze_ext then
            ret.files[#ret.files+1] = {
                folder=folder,
                name=baseName(file),
                full_path=folder.."/"..file
            }
            ret.fweight = ret.fweight + 1
        end
        p = p + 1
    end
    table.sort(ret.subs,  function(a,b) return a.name < b.name end)
    table.sort(ret.files, function(a,b) return a.name < b.name end)
    return ret
end

return {
   -- buildRecursiveMenuFromFolder    = buildRecursiveMenuFromFolder,
    crawlForFiles                   = crawlForFiles,
    baseName                        = baseName,
    ext                             = ext
}
