--[[
  Description: Smart fill gaps by stretching item tails
  Version: 1.3.2
  Author: Lokasenna
  Donation: https://paypal.me/Lokasenna
  Changelog:
    Fix: Expand error message when the library is missing
  Links:
    Forum Thread https://forum.cockos.com/showthread.php?p=2046085
    Lokasenna's Website http://forum.cockos.com/member.php?u=10417
  About:
    Intelligently fills gaps between items, using a combination of RMS level
    detection and max/min lengths to identify the "tail" of a signal and leave
    the transient alone.

  Donation: https://www.paypal.me/Lokasenna
]]--


local settings = {}
local default_settings = {

    thresh_db = -24,
    rms_window = 0.01,          -- Seconds. Set to 0 for instantaneous.
    protect_left = 0.2,         -- Seconds.
    min_rate = 0.2,             -- Min. rate that the split item can end up at
                                -- (Higher values will result in more skips)

    add_split_markers = true,
    add_skip_markers = true,

    crossfade_left = 0.001,   -- seconds. Set to 0 to skip.
    crossfade_right = 0.001,
    crossfade_shape = 1,        -- Shape = 1 is "equal power", probably the least audible.

    trim_items = true,
    step_markers = true,

    next_item_distance = 0.3

}

local script_title = "Smart fill gaps by stretching item tails"

local added_markers = {}


------------------------------------
-------- Debugging stuff -----------
------------------------------------

-- Press Ctrl+Shift+Alt+Z to enable GUI.dev_mode

-- True:    Debug messages are printed instantly, which can make Reaper lag/freeze for a bit.
-- False:   Debug messages are saved until the script is finished and then printed all at once.
dm_realtime = true

local dMsgs = {}
local function dMsg(str)
    if GUI.dev_mode then
      dMsgs[#dMsgs+1] = tostring(str)
    end
end

local function print_dMsgs()
    if #dMsgs > 0 then
        local str = string.sub( table.concat(dMsgs, "\n"), -15000 )
        reaper.ShowConsoleMsg( str:match("\n.+") .. "\n" )
        dMsgs = {}
    end
end

local iterated_items = 0

------------------------------------
-------- GUI Library ---------------
------------------------------------


local lib_path = reaper.GetExtState("Lokasenna_GUI", "lib_path_v2")
if not lib_path or lib_path == "" then
    reaper.MB("Couldn't load the Lokasenna_GUI library. Please install 'Lokasenna's GUI library v2 for Lua', available on ReaPack, then run the 'Set Lokasenna_GUI v2 library path.lua' script in your Action List.", "Whoops!", 0)
    return
end
loadfile(lib_path .. "Core.lua")()


GUI.req("Classes/Class - Label.lua")()
GUI.req("Classes/Class - Options.lua")()
GUI.req("Classes/Class - Textbox.lua")()
GUI.req("Classes/Class - Menubox.lua")()
GUI.req("Classes/Class - Slider.lua")()
GUI.req("Classes/Class - Button.lua")()
GUI.req("Classes/Class - Window.lua")()
-- If any of the requested libraries weren't found, abort the script.
if missing_lib then return 0 end





------------------------------------
-------- Error Messages ------------
------------------------------------


local errors = {}
errors.noNextItem = "Next item not found within specified range"
errors.splitPastEnd = "Calculated split point is past the end of the item"
errors.noSplitPoint = "No point that satisfies the current parameters"
errors.splitFailed = "Error splitting item. Probably an invalid split position"


------------------------------------
-------- Audio Processing ----------
------------------------------------


local audio = {}
function audio.dBFromVal(val) return 20*math.log(val, 10) end
function audio.ValFromdB(dB_val) return 10^(dB_val/20) end


--[[    Loop through the samples of the active take in a given MediaItem

    item    MediaItem

    func    Function to run for each sample. Will be passed three arguments:

            spl     Sample level (-1 to +1)
            pos     Time position in the item (seconds)
            chan    Audio channel

            If the function returns anything other than false/nil, the loop
            will terminate and iterateSamples will pass that as a return value.

            Note: This process is read-only. The function can't do anything to
            the samples.

    start_pos
            Starting time to loop from

    window  Maximum length of time in the item to examine

    reverse Boolean. If true, starts from the end and works backwards. The
            time passed to 'func' will still be measured from the beginning
            of the item for consistency.


    Note: I can't take sole credit for this. It was adapted from eugen2777's
    "Create stretch markers at transients" EEL script and then tidied/expanded.

]]--
function audio.iterateSamples(item, func, start, window, reverse)

    if not (item and func) then return end

    local val_out
    local iterated_samples = 0


    local take = reaper.GetActiveTake(item)
    local PCM_source = reaper.GetMediaItemTake_Source(take)
    local samplerate = reaper.GetMediaSourceSampleRate(PCM_source)

    dMsg("\t\tsamplerate: " .. samplerate)

    if not samplerate then
        reaper.MB("Couldn't access the item. Maybe it's not audio?", "Oops", 0)
        return nil
    end

    local item_len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")

    -- Math is much easier if we convert to playrate == 1
    -- Don't worry, we'll put everything back afterward
    local playrate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
    -- local new_len = item_len * playrate

    if playrate ~= 1 then
        reaper.SetMediaItemTakeInfo_Value(take, "D_PLAYRATE", 1)
        reaper.SetMediaItemInfo_Value(item, "D_LENGTH", item_len * playrate)
    end

    local new_len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")

    -- Define the time range w.r.t the original playrate

    local range_len = window and math.min(window, new_len) or new_len
    local range_start = reverse
      and (start and (start - range_len) or 0)
      or  (start and start or 0)

    if range_start < 0 then range_start = 0 end

    --dMsg("\tchecking window: " .. range_start .. " to " .. range_start + range_len)

    local range_end = range_start + range_len
    local range_len_spls = math.floor(range_len * samplerate)

    dMsg("\t\trange_spls = " .. range_len_spls)

    -- Break the range into blocks
    local block_size = 65536
    local n_blocks = math.floor(range_len_spls / block_size)
    local extra_spls = range_len_spls - block_size * n_blocks

    -- Allow for multichannel audio
    local n_channels = reaper.GetMediaSourceNumChannels(PCM_source)

    dMsg("\t\titem has " .. n_channels .. " channels")

    -- It's significantly faster to use locals for CPU-intensive tasks
    local GetSamples = reaper.GetAudioAccessorSamples

    -- 'samplebuffer' will hold all of the audio data for each block
    local samplebuffer = reaper.new_array(block_size * n_channels)
    local audio = reaper.CreateTakeAudioAccessor(take)

    dMsg("\t\trange_len: " .. range_len)
    dMsg("\t\trange_start: " .. range_start)
    dMsg("\t\trange_end: " .. range_end)
    dMsg("\t\tn_blocks: " .. n_blocks)
    dMsg("\t\textra_spls: " .. extra_spls)

    -- Loop through the audio, one block at a time
    local time_start =
        --reverse   and (range_end - ((extra_spls * n_channels) / samplerate))
        -- reverse   and (range_end - extra_spls / samplerate)
        reverse    and range_end
                   or  0

    dMsg("\t\ttime_start: " .. time_start)

    local time_offset = ((block_size * n_channels) / samplerate) * (reverse and -1 or 1)

    for cur_block = 0, n_blocks do

        -- The last iteration will almost never be a full block
        --if cur_block == n_blocks then block_size = extra_spls end
        local block_size = (cur_block == n_blocks) and extra_spls or block_size

        samplebuffer.clear()

        -- Loads 'samplebuffer' with the next block
        GetSamples(audio, samplerate, n_channels, (reverse and (time_start - (block_size / samplerate)) or time_start), block_size, samplebuffer)

        dMsg("getting block: " .. block_size .. " samples")
        dMsg("starting @: " .. time_start)
        --[[

        -- Loop through each channel separately
        local chan_start, chan_end, spl_start, spl_end, step
        if reverse then
            chan_start, chan_end = n_channels, 1
            spl_start, spl_end = block_size, 1
            step = -1
        else
            chan_start, chan_end = 1, n_channels
            spl_start, spl_end = 1, block_size
            step = 1
        end


        for chan_cur = chan_start, chan_end, step do

            for spl_cur = spl_start, spl_end, step do

                iterated_samples = iterated_samples + 1

                -- Sample position in the block
                local pos = (spl_cur - 1) * n_channels + chan_cur
                local val = samplebuffer[pos]

                --val_out = func(spl, time_start + ((pos * n_channels) / samplerate))
                val_out = func(val, time_start + (spl_cur / samplerate))
                if val_out then
                  dMsg("\t\tgot val_out: " .. tostring(val_out))
                  goto finished
                end

            end

        end

        ]]--

        local spl_start, spl_end, step
        if reverse then
          spl_start, spl_end = block_size * n_channels, 1
          step = -1
        else
          spl_start, spl_end = 1, block_size * n_channels
          step = 1
        end

        dMsg("\t\t\tspl_start: " .. spl_start)
        dMsg("\t\t\tspl_end: " .. spl_end)

        for i = spl_start, spl_end, step do

          iterated_samples = iterated_samples + 1

          local val = samplebuffer[i]
          local chan = (i - 1) % n_channels + 1
          local pos = math.modf((i - 1) / n_channels) / samplerate + range_start

          val_out = func(val, pos, chan)
          if val_out then
            dMsg("\t\tgot val_out: " .. tostring(val_out))
            goto finished

          end

        end

        time_start = time_start + time_offset

    end

    ::finished::

    if GUI.dev_mode then
      iterated_items = iterated_items + 1
      dMsg("\t\titerate samples looked through " .. iterated_samples .. " samples")
    end

    -- Tell Reaper we're done working with this item, so the memory can be freed
    reaper.DestroyAudioAccessor(audio)

    -- Put it back the way we found it
    reaper.SetMediaItemTakeInfo_Value(take, "D_PLAYRATE", playrate)
    reaper.SetMediaItemInfo_Value(item, "D_LENGTH", item_len)
    return val_out

end




------------------------------------
-------- Item Class ----------------
------------------------------------


local Item = {}
Item.__index = Item
function Item.new(item)
    local i = {item = item}
    setmetatable(i, Item)
    i:initValues()
    return i
end


function Item:doWorkflow()

    local ret, err

    ret, err = self:isGap()
    --if err then goto skip end

    if ret then
        ret, err = self:doSplit()
        --if err then goto skip end

        if ret then
            self:fillGap()
            self:addSplitMarker()
            self:crossfadeLeft()
            self:crossfadeRight()
        end

    elseif not err and settings.trim_items then

        self:trimExcess()
        self:crossfadeRight()
    end

    if err then
        self:addSkipMarker(err)
    end

end


-- Called in the New method
function Item:initValues()

    self.track = reaper.GetMediaItemTrack(self.item)
    self.take = reaper.GetActiveTake(self.item)

    self.pos = reaper.GetMediaItemInfo_Value(self.item, "D_POSITION")
    self.len = reaper.GetMediaItemInfo_Value(self.item, "D_LENGTH")
    self.idx = reaper.GetMediaItemInfo_Value(self.item, "IP_ITEMNUMBER")

    self.next = self:getNextItem()

end


function Item:isGap()

    if not self.next then
        return nil, errors.noNextItem
    end

    return self.next.pos > self:getEnd()

end


function Item:doSplit()

    local split, err
    dMsg(self.splitpos)
    if self.splitpos then
        split = self.splitpos
    else
        split, err = self:getSplitPos()
    end
    --self.splitpos = self.splitpos or self:getSplitPos()
    if not split then return nil, err end

    self.splitpos = split
    if self.splitpos >= self:getEnd() then
        return nil, errors.splitPastEnd
    end

    self.item = reaper.SplitMediaItem( self.item, self.splitpos )
    if not self.item then
      return nil, errors.splitFailed
     end
    self:initValues()
    return true

end


function Item:fillGap()

    local new_len = self.next.pos - self.pos
    reaper.SetMediaItemInfo_Value(self.item, "D_LENGTH", new_len)
    local rate = reaper.GetMediaItemTakeInfo_Value(self.take, "D_PLAYRATE")
    reaper.SetMediaItemTakeInfo_Value(self.take, "D_PLAYRATE", rate / (new_len / self.len))

    self.len = new_len
end


function Item:trimExcess()

    if not self.next or (self.pos + self.len <= self.next.pos) then return end
    reaper.SetMediaItemInfo_Value(self.item, "D_LENGTH", self.next.pos - self.pos)

end


function Item:addSplitMarker()

    if not settings.add_split_markers then return end

    local color = reaper.ColorToNative(0, 255, 0)|0x1000000

    added_markers[#added_markers+1] = reaper.AddProjectMarker2(
        0, false, self.pos, 0, "SPLIT", -1, color )

end


function Item:addSkipMarker(err)

    if not settings.add_skip_markers then return end

    local color = reaper.ColorToNative(255, 0, 0)|0x1000000
    added_markers[#added_markers+1] = reaper.AddProjectMarker2(
        0,
        false,
        self:getEnd(),
        0,
        "SKIPPED" .. (err and (": " .. err) or ""),
        -1,
        color )


end




------------------------------------
-------- Item Helpers --------------
------------------------------------


function Item:getNextItem()

    local next = {}
    next.item = reaper.GetTrackMediaItem(self.track, self.idx + 1)
    if not next.item then return end

    next.pos = reaper.GetMediaItemInfo_Value(next.item, "D_POSITION")

    if (next.pos - self:getEnd()) > tonumber(settings.next_item_distance) then return end

    next.len = reaper.GetMediaItemInfo_Value(next.item, "D_LENGTH")

    return next

end


function Item:getEnd()
    return self.pos + self.len
end


function Item:getSplitPos()

    --local pos_stretch = self:posAtStretchLimit()
    local pos_left = self:posProtectLeft() or 0
    local pos_stretch = self:posAtStretchLimit()

    local start = pos_stretch - self.pos
    local window = pos_stretch - pos_left - settings.crossfade_left

    dMsg("pos_left: " .. pos_left ..
      " | pos_stretch: " .. pos_stretch ..
      " | self.pos: " .. self.pos ..
      " | end: " .. self:getEnd() ..
      " | crossfade_left: " .. settings.crossfade_left ..
      " | window is from: " .. (pos_left) .. " to " .. (pos_left + window) .. " (" .. window .. ")"
    )

    local pos_thresh =
      (window > 0 and start >= 0) and self:lastPosAboveThreshold(window, pos_stretch - self.pos)

    if pos_thresh then
        return pos_thresh
    else
        return nil, errors.noSplitPoint
    end
    --return math.max(pos_left, pos_thresh)
end


function Item:posProtectLeft()
    if not settings.protect_left then return nil end

    local pos = self.pos + settings.protect_left
    dMsg("posProtectLeft returning: " .. pos)
    return pos
end


function Item:posAtStretchLimit()
    if not settings.min_rate then return nil end

    local rate = settings.min_rate
    local gap = self.next.pos - self:getEnd()
    local pos = self:getEnd() - (rate * gap)/(1 - rate)

    --local pos = self.next.pos - (self.next.pos - self:getEnd()) / settings.min_rate
    dMsg("posAtStretchLimit returning: " .. pos)
    return pos
end


-- Returned value is adjusted to the next zero crossing
-- window = Length to check (from end)
-- start_pos = Don't return a zero until we're <= this
function Item:lastPosAboveThreshold(window, start_pos)

    dMsg("lastPosAboveThreshold")
    dMsg("\tsearch window: " .. tostring(window) .. "\n\tstart pos: " .. tostring(start_pos))
    local thresh = audio.ValFromdB(settings.thresh_db)

    local last_zero_pos
    local last_spl = 0

    local rms_window = math.max( self:splsFromTime( settings.rms_window ), 1 )
    dMsg("\trms window = " .. rms_window .. " samples (" .. settings.rms_window .. " seconds)")

    local PCM_source = reaper.GetMediaItemTake_Source(self.take)
    local n_channels = reaper.GetMediaSourceNumChannels(PCM_source)

    local rms_tracking = {}
    for i = 1, n_channels do
      rms_tracking[i] = {square_sum = 0}
    end

    -- Yay efficiency
    local sqrt = math.sqrt

    local positions = {}
    local passed_start = false
    -- Will be passed to iterateSamples
    local function check_sample(spl, pos, chan)

      local rms
      if rms_window > 1 then

          rms_tracking[chan][#rms_tracking[chan] + 1] = spl^2

          -- dMsg(spl .. ", " .. pos .. ", " .. chan)

          rms_tracking[chan].square_sum =
            rms_tracking[chan].square_sum + rms_tracking[chan][#rms_tracking[chan]]

          if #rms_tracking[chan] > rms_window then

            rms_tracking[chan].square_sum =
              rms_tracking[chan].square_sum - rms_tracking[chan][#rms_tracking[chan] - rms_window]
              rms = sqrt(rms_tracking[chan].square_sum / rms_window)

          end

      else
          rms = math.abs(spl)
      end

      if not passed_start then
        dMsg("passed start at " .. pos .. " (" .. (self.pos + pos) .. ")")
        passed_start = true
      end

      if rms and rms >= thresh and rms_tracking[chan].last_zero_pos then
          dMsg("\t\treturning rms over threshold at " .. pos .. " (" .. (self.pos + pos) .. ")")
          return rms_tracking[chan].last_zero_pos

      elseif (pos <= start_pos) then
        passed_start = true

        if spl == 0 then
          rms_tracking[chan].last_zero_pos = pos
          -- dMsg("\t\tzero crossing at " .. pos .. " (" .. (self.pos + pos) .. "), rms is " .. tostring(rms))
        elseif rms_tracking[chan].last_spl and (rms_tracking[chan].last_spl * spl < 0) then

          -- pos was occasionally negative... not sure why
          --last_zero_pos = math.abs((pos + last_pos) / 2)
          rms_tracking[chan].last_zero_pos = (pos + rms_tracking[chan].last_pos) / 2
        end

      end


      rms_tracking[chan].last_pos = pos
      rms_tracking[chan].last_spl = spl

    end




    dMsg("\titerateSamples...")

    local splitpos = audio.iterateSamples(self.item, check_sample, start_pos, window, true)
    dMsg("\titerateSamples returned a zero-crossing at: " .. tostring(splitpos))
    splitpos = splitpos or last_zero_pos
    dMsg("\tusing a zero-crossing of: " .. tostring(splitpos))
    dMsg("\tlastposAboveThreshold returning: " .. (splitpos and (self.pos + splitpos) or "No split, no zero-crossing"))

    dMsg("------\npositions:\n" .. table.concat(positions, "\n") .. "\n-------")
    return splitpos and (self.pos + splitpos)

end


-- Convert from time (seconds) to samples at the item's sample rate
function Item:splsFromTime(time)

    local PCM_source = reaper.GetMediaItemTake_Source(self.take)
    local sample_rate = reaper.GetMediaSourceSampleRate(PCM_source)
    return math.floor( sample_rate * time )

end


function Item:crossfadeLeft()

    --reaper.MB("No crossfade logic yet.", "Whoops!", 0)

    -- pos = pos - fade
    -- length = length + fade
    -- source pos = source pos - fade

    local fade = settings.crossfade_left
    if not fade or fade == 0 then return end

    dMsg("\tcrossfading left")

    local track, item, take = self.track, self.item, self.take

    local half = fade / 2

    -- Adjust positioning
    reaper.SetMediaItemInfo_Value(item, "D_POSITION", self.pos - half)
    reaper.SetMediaItemInfo_Value(item, "D_LENGTH", self.len + half, false)
    reaper.SetMediaItemTakeInfo_Value(
        take, "D_STARTOFFS", reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS") - half)

    reaper.SetMediaItemInfo_Value(item, "D_FADEINLEN", fade)

    local prev = reaper.GetTrackMediaItem(
        track, reaper.GetMediaItemInfo_Value(item, "IP_ITEMNUMBER") - 1)

    reaper.SetMediaItemInfo_Value(
        prev, "D_LENGTH", reaper.GetMediaItemInfo_Value(prev, "D_LENGTH") + half, false)

    reaper.SetMediaItemInfo_Value(prev, "D_FADEOUTLEN", fade)

    if settings.crossfade_shape < 8 then
        reaper.SetMediaItemInfo_Value(item, "C_FADEINSHAPE", settings.crossfade_shape)
        reaper.SetMediaItemInfo_Value(prev, "C_FADEOUTSHAPE", settings.crossfade_shape)
    end

end


function Item:crossfadeRight()

    dMsg("\tcrossfading right")

    -- Get next (should be under self.next)
    local fade = settings.crossfade_right
    if not fade or fade == 0 or not self.next then return end

    local next, take = self.next.item, reaper.GetActiveTake(self.next.item)

    reaper.SetMediaItemInfo_Value(next, "D_POSITION", self.next.pos - fade)
    reaper.SetMediaItemInfo_Value(next, "D_LENGTH", self.next.len + fade)
    reaper.SetMediaItemTakeInfo_Value(
        take, "D_STARTOFFS", reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS") - fade)

    reaper.SetMediaItemInfo_Value(next, "D_FADEINLEN", fade)

    reaper.SetMediaItemInfo_Value(self.item, "D_FADEOUTLEN", fade)

    if settings.crossfade_shape < 8 then
        reaper.SetMediaItemInfo_Value(next, "C_FADEINSHAPE", settings.crossfade_shape)
        reaper.SetMediaItemInfo_Value(self.item, "C_FADEOUTSHAPE", settings.crossfade_shape)
    end

end



------------------------------------
-------- Step functions ------------
------------------------------------


local Step = {curidx = 0}

function Step.init()

    Step.curidx = added_markers[1]

end

function Step.gotoMarker()
    if #added_markers == 0 then return end
    reaper.GoToMarker(0, added_markers[Step.curidx], false)
end

function Step.nextMarker()
    Step.curidx = math.min(Step.curidx+1, #added_markers)
    Step.gotoMarker()
end

function Step.prevMarker()
    Step.curidx = math.max(Step.curidx-1, 1)
    Step.gotoMarker()
end

function Step.deleteMarker()
    reaper.DeleteProjectMarker(0, added_markers[Step.curidx], false)
    table.remove(added_markers, Step.curidx)

    if #added_markers == 0 then
        GUI.elms.step_window:close()
    else
        Step.curidx = GUI.clamp(1, Step.curidx, #added_markers)
        Step.gotoMarker()
    end

end





------------------------------------
-------- Script Logic --------------
------------------------------------


local function selectedMediaItemsByPosition()

    local items = {}

    for i = 0, reaper.CountSelectedMediaItems(0)-1 do

        local item = reaper.GetSelectedMediaItem(0, i)
        if not item then return end

        local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")

        if not items[pos] then items[pos] = {} end
        items[pos][#items[pos]+1] = item

    end

    return items

end


local function processItems(items_by_pos)

    if not items_by_pos then return end

    -- Find a split point for the first item in each position, and then copy that for
    -- the remaining items rather than scanning them too.
    for pos, items in GUI.kpairs(items_by_pos) do

        dMsg("\nPosition " .. pos .. " has " .. #items .. " items\n")

        dMsg("Item 1")
        local first = Item.new(items[1])
        first:doWorkflow()

        local cur
        for i = 2, #items do
            dMsg("\nItem " .. i)
            cur = Item.new(items[i])

            if settings.use_first then
              if not first.splitpos then break end
              cur.splitpos = first.splitpos
            end

            cur:doWorkflow()
        end

    end

end


local function Main()

    reaper.Undo_BeginBlock()
    reaper.PreventUIRefresh(1)

    local num_items = reaper.CountSelectedMediaItems(0)

    iterated_items = 0
    dMsg("Processing " .. num_items .. " items")
    local start_time = reaper.time_precise()


    processItems( selectedMediaItemsByPosition() )


    local elapsed = reaper.time_precise() - start_time

    dMsg("\niterateSamples looked at " .. iterated_items .. " items")
    dMsg("\nAll done!\nTotal time: " .. elapsed .. " seconds\n" ..
        "Average: " .. elapsed / iterated_items .. " seconds per item")

    reaper.PreventUIRefresh(-1)
    reaper.UpdateTimeline()
    reaper.Undo_EndBlock(script_title, -1)

    if settings.step_markers and #added_markers >0 then GUI.elms.step_window:open() end

end




------------------------------------
-------- GUI Logic -----------------
------------------------------------


local function saveWindowState()

  GUI.save_window_state("Lokasenna", script_title .. ".window")

end

local function loadWindowState()

  GUI.load_window_state("Lokasenna", script_title .. ".window")

end



local function getUnitMultiplier(unit)

    unit = GUI.elms.S_unit.optarray[unit]
    if unit == "frames" then
        dMsg("frame rate: " .. reaper.TimeMap_curFrameRate(0) .. ", duration = " .. 1/reaper.TimeMap_curFrameRate(0))
        return 1 / reaper.TimeMap_curFrameRate(0)
    elseif unit == "samples" then
        local take = reaper.GetActiveTake( reaper.GetSelectedMediaItem(0, 0) )
        local PCM_source = reaper.GetMediaItemTake_Source(take)
        local samplerate = reaper.GetMediaSourceSampleRate(PCM_source)
        dMsg("sample rate: " .. samplerate .. ", duration = " .. 1/samplerate)
        return 1 / samplerate
    else
        return 0.001
    end

end


local function settingsFromGUI()

    local settings = {}

    for name, elm in pairs(GUI.elms) do

        if not name:match("^S_") then goto skip end

        if name == "S_markers" then
            settings.add_split_markers,
            settings.add_skip_markers = table.unpack(elm:val())

        elseif name == "S_opts" then
            settings.trim_items,
            settings.step_markers,
            settings.use_first = table.unpack(elm:val())
        else
            settings[name:match("S_(.+)")] = elm:val()
        end

        ::skip::

    end

    return settings

end


local function convertSettings(settings)

    local mult = getUnitMultiplier(settings.unit)

    settings.rms_window = settings.rms_window * mult
    settings.protect_left = settings.protect_left * mult
    settings.crossfade_left = settings.crossfade_left * mult
    settings.crossfade_right = settings.crossfade_right * mult

    settings.crossfade_shape = settings.crossfade_shape - 1

    return settings

end


local function settingsToString()

    local settings = settingsFromGUI()

    local sorted = {}
    for k in pairs(settings) do
        sorted[#sorted+1] = k
    end
    table.sort(sorted)

    local strs = {}
    for _, k in pairs(sorted) do
        strs[#strs+1] = k .. "=" .. tostring(settings[k])
    end

    return table.concat(strs, "|")

end

local function saveSettings()

    reaper.SetExtState("Lokasenna", script_title, settingsToString(), true)

end


local function loadSettings()

    local str = reaper.GetExtState("Lokasenna", script_title)
    if not str or str == "" then return default_settings end

    local settings = {}
    for param in str:gmatch("[^|]+") do

        local k, v = param:match("([^=]+)=([^=]+)")
        if not tonumber(v) then
            v = (v == "true")
        end
        settings[k] = v

    end

    return settings

end


local function settingsToGUI()

    local settings = loadSettings()

    GUI.Val("S_markers", {settings.add_split_markers, settings.add_skip_markers})
    settings.add_split_markers, settings.add_skip_markers = nil, nil,

    GUI.Val("S_opts", {settings.trim_items, settings.step_markers, settings.use_first})
    settings.trim_items, settings.step_markers, settings.use_first = nil, nil, nil

    GUI.Val("S_thresh_db", settings.thresh_db + 60)
    settings.thresh_db = nil

    for name, val in pairs(settings) do
        GUI.Val("S_"..name, val)
    end
--[[
    local default_settings = {

    thresh_db = -24,
    rms_window = 0.01,          -- Seconds. Set to 0 for instantaneous.
    protect_left = 0.2,         -- Seconds.
    min_rate = 0.2,             -- Min. rate that the split item can end up at
                                -- (Higher values will result in more skips)

    add_split_markers = true,
    add_skip_markers = true,

    crossfade_left = 0.001,   -- seconds. Set to 0 to skip.
    crossfade_right = 0.001,
    crossfade_shape = 1,        -- Shape = 1 is "equal power", probably the least audible.

    trim_items = true,
    step_markers = true,

}]]--
end


local function btn_go()

    settings = convertSettings( settingsFromGUI() )
    saveSettings()
    Main()

end




------------------------------------
-------- GUI Stuff -----------------
------------------------------------


GUI.name = "Split and stretch item tails"
GUI.x, GUI.y, GUI.w, GUI.h = 0, 0, 336, 600
GUI.anchor, GUI.corner = "screen", "C"



GUI.New("S_thresh_db", "Slider", {
    z = 11,
    x = 64,
    y = 40.0,
    w = 208,
    caption = "RMS threshold:",
    min = -60,
    max = 0,
    defaults = {36},
    inc = 1,
    dir = "h",
    font_a = 3,
    font_b = 4,
    col_txt = "txt",
    col_fill = "elm_fill",
    bg = "wnd_bg",
    show_handles = true,
    show_values = true,
    cap_x = 0,
    cap_y = 0,
    tooltip = "RMS value to split tails at"
})

GUI.New("S_rms_window", "Textbox", {
    z = 11,
    x = 136.0,
    y = 80.0,
    w = 80,
    h = 20,
    caption = "RMS window:",
    cap_pos = "left",
    font_a = 3,
    font_b = "monospace",
    color = "txt",
    bg = "wnd_bg",
    shadow = true,
    pad = 4,
    undo_limit = 20,
    retval = 10,
    tooltip = "RMS window length\n\nSet to 0db for simple peak detection"
})



GUI.New("S_protect_left", "Textbox", {
    z = 11,
    x = 136.0,
    y = 104.0,
    w = 80,
    h = 20,
    caption = "Protect left:",
    cap_pos = "left",
    font_a = 3,
    font_b = "monospace",
    color = "txt",
    bg = "wnd_bg",
    shadow = true,
    pad = 4,
    undo_limit = 20,
    retval = 200,
    tooltip = "Minimum distance from the left edge to split and crossfade"
})

GUI.New("S_min_rate", "Textbox", {
    z = 11,
    x = 136.0,
    y = 128.0,
    w = 80,
    h = 20,
    caption = "Min. stretch rate:",
    cap_pos = "left",
    font_a = 3,
    font_b = "monospace",
    color = "txt",
    bg = "wnd_bg",
    shadow = true,
    pad = 4,
    undo_limit = 20,
    retval = 0.5,
    tooltip = "Minimum stretch rate to allow when finding a split point"
})



GUI.New("S_crossfade_left", "Textbox", {
    z = 11,
    x = 136.0,
    y = 168.0,
    w = 80,
    h = 20,
    caption = "Crossfade @ split:",
    cap_pos = "left",
    font_a = 3,
    font_b = "monospace",
    color = "txt",
    bg = "wnd_bg",
    shadow = true,
    pad = 4,
    undo_limit = 20,
    retval = 1,
    tooltip = "Crossfade the original and split items across the split point\n\nSet to 0 to disable"
})

GUI.New("S_crossfade_right", "Textbox", {
    z = 11,
    x = 136.0,
    y = 192.0,
    w = 80,
    h = 20,
    caption = "Crossfade @ stretch:",
    cap_pos = "left",
    font_a = 3,
    font_b = "monospace",
    color = "txt",
    bg = "wnd_bg",
    shadow = true,
    pad = 4,
    undo_limit = 20,
    retval = 1,
    tooltip = "Pull the next item's start to the left, to crossfade with the stretched end\n\nSet to 0 to disable"
})

GUI.New("S_crossfade_shape", "Menubox", {
    z = 11,
    x = 136.0,
    y = 216.0,
    w = 80,
    h = 20,
    caption = "Crossfade shape:",
    optarray = {"1", "2", "3", "4", "5", "6", "7", "Default"},
    retval = 8,
    font_a = 3,
    font_b = 4,
    col_txt = "txt",
    col_cap = "txt",
    bg = "wnd_bg",
    pad = 4,
    noarrow = false,
    align = 0,
})


GUI.New("S_next_item_distance", "Textbox", {
  z = 11,
  x = 136.0,
  y = 256.0,
  w = 80,
  h = 20,
  caption = "Max. gap to process:",
  cap_pos = "left",
  font_a = 3,
  font_b = "monospace",
  color = "txt",
  bg = "wnd_bg",
  shadow = true,
  pad = 4,
  undo_limit = 20,
  retval = 0.3,
  tooltip = "Maximum length of gap between items that should be processed"
})


GUI.New("S_markers", "Checklist", {
    z = 11,
    x = 48.0,
    y = 308.0,
    w = 240,
    h = 72,
    caption = "Place markers:",
    optarray = {"At split points","When no split point is found"},
    dir = "v",
    pad = 4,
    font_a = 2,
    font_b = 3,
    col_txt = "txt",
    col_fill = "elm_fill",
    bg = "wnd_bg",
    frame = true,
    shadow = true,
    swap = nil,
    opt_size = 20
})

GUI.New("S_opts", "Checklist", {
    z = 11,
    x = 48,
    y = 392,
    w = 208,
    h = 84,
    caption = "",
    optarray = {"Trim ends of overlapping items","Step through markers afterward","Match the first item at each position"},
    frame = false
})




GUI.New("S_unit", "Menubox", {
    z = 11,
    x = 218,
    y = 80,
    w = 80,
    h = 20,
    caption = "",
    optarray = {"ms","samples","frames"},
    retval = 1,
})

GUI.New("lbl_unit1", "Label", {
    z = 11,
    x = 222,
    y = 110,
    caption = "ms",
    font = 4,
    color = "txt",
    bg = "wnd_bg",
    shadow = true
})

GUI.New("lbl_unit2", "Label", {
    z = 11,
    x = 222,
    y = 174,
    caption = "ms",
    font = 4,
    color = "txt",
    bg = "wnd_bg",
    shadow = true
})

GUI.New("lbl_unit3", "Label", {
    z = 11,
    x = 222,
    y = 198,
    caption = "ms",
    font = 4,
    color = "txt",
    bg = "wnd_bg",
    shadow = true
})

GUI.New("lbl_unit4", "Label", {
  z = 11,
  x = 222,
  y = 262,
  caption = "s",
  font = 4,
  color = "txt",
  bg = "wnd_bg",
  shadow = true
})



GUI.New("btn_go", "Button", {
    z = 11,
    x = 144,
    y = 480,
    w = 48,
    h = 24,
    caption = "Go!",
    font = 3,
    col_txt = "txt",
    col_fill = "elm_frame",
    func = btn_go
})



------------------------------------
-------- Step-Through window -------
------------------------------------


GUI.elms_hide[12] = true
GUI.elms_hide[13] = true

GUI.New("step_window", "Window", {
    z = 13,
    x = 0,
    y = 0,
    w = 256,
    h = 116,
    caption = "Step through markers...",
    z_set = {12, 13},
    center = true
})

GUI.New("step_prev", "Button", {
    z = 12,
    x = 24,
    y = 16,
    w = 64,
    h = 20,
    caption = "Previous",
    func = Step.prevMarker
})

GUI.New("step_delete", "Button", {
    z = 12,
    x = 96,
    y = 16,
    w = 64,
    h = 20,
    caption = "Delete",
    func = Step.deleteMarker
})

GUI.New("step_next", "Button", {
    z = 12,
    x = 168,
    y = 16,
    w = 64,
    h = 20,
    caption = "Next",
    func = Step.nextMarker
})

GUI.New("step_done", "Button", {
    z = 12,
    x = 96,
    y = 56,
    w = 64,
    h = 20,
    caption = "Done",
})


function GUI.elms.step_window:onopen()

    self:adjustchildelms()
    Step.init()

end

function GUI.elms.step_done.func()

    GUI.elms.step_window:close()

end


------------------------------------
-------- Method overrides ----------
------------------------------------


function GUI.Textbox:validate()

    if tonumber(self.retval) then
        self.lastval = self.retval
    else
        self.retval = self.lastval
    end

end


local old_lostfocus = GUI.Textbox.lostfocus
function GUI.Textbox:lostfocus()

    old_lostfocus(self)
    self:validate()

end

local old_init = GUI.Textbox.init
function GUI.Textbox:init()

    old_init(self)
    self.lastval = self.retval

end



local function updateUnitLabels()

    local _, val = GUI.Val("S_unit")
    GUI.Val("lbl_unit1", val)
    GUI.Val("lbl_unit2", val)
    GUI.Val("lbl_unit3", val)

end

function GUI.elms.S_unit:onmouseup()

    GUI.Menubox.onmouseup(self)
    updateUnitLabels()

end

function GUI.elms.S_unit:onwheel(inc)

    GUI.Menubox.onwheel(self, inc)
    updateUnitLabels()

end


settingsToGUI()
local ret = {GUI.load_window_state("Lokasenna", script_title .. ".window")}

GUI.exit = saveWindowState

GUI.func = print_dMsgs
GUI.freq = 1

GUI.Init()
GUI.Main()
