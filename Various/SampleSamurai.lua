-- @description SampleSamurai
-- @author Eric Czichy
-- @version 1.0.1
-- @changelog The help window now contains some further links
-- @about
--   # SampleSamurai 
--
--   SampleSamurai aspires to be a simple, easy to use solution for tedious sampling tasks in the Reaper environment.

print = reaper.ShowConsoleMsg

package.path = reaper.GetResourcePath() .. '/Scripts/rtk/1/?.lua'
local rtk
local rf = function () require('rtk') end
if pcall(rf) then
  rtk = require('rtk')
  -- Debuging:
  --rtk.log.level = rtk.log.DEBUG
  
else
  print("Reapertoolkit (RTK) is not installed or found. Please make sure you have installed rtk correctly.\nReapPack repository: https://reapertoolkit.dev/index.xml")
  return
end

-- sample globals--
local autoClear = false
local includeMidiNote = true
local trackID = -1
local track = -1
local mediaItems = 1
local mediaLength = 1
local startOctave = 1
local endNote = 0
local startNote = 0
local endOctave = 1
local noteVolume = 127
local maxVolume = -60
local pauseTime = 1
local midiChannel = 1
local NOTE_ON_MSG = 0x90 | (midiChannel - 1)
local NOTE_OFF_MSG = 0x80 | (midiChannel - 1)
local reps = 0
local note = 0
local lastNote = 0
local stopNext = 0
local interval = 1
local isRunning = false
local midiDevice = 0
local estimatedTime = '0'
local midiStartDelay = 0.2
AMP_DB = 8.6562
----------------------------Defer Function--------------------------------------

function defer(func, s)
  local curtime = reaper.time_precise()
  deferHelper(func, curtime + s)
end

function deferHelper(func, timeToStart)
  if(timeToStart <= reaper.time_precise()) then func() return end
  local f = function () deferHelper(func, timeToStart) end
  reaper.defer(f)
end

----------------------------Helper Functions--------------------------------------

function clearTrack()
  -- check for valid track
  if trackID < 0 or reaper.GetTrack(0, trackID) == nil then
    displayText("No valid track!")
    return
  end
  if(track == -1)then track = reaper.GetTrack(0, trackID) end
  local trackItemCount = reaper.CountTrackMediaItems(track)
  local i = -20
  while trackItemCount > 0 and i < 1000 do
    local item = reaper.GetTrackMediaItem(track, 0)
    if(item ~= nil) then
      if reaper.DeleteTrackMediaItem(track, item) then 
        trackItemCount = trackItemCount - 1 
      end
    end
    i = i + 1
  end
  reaper.UpdateTimeline()
end

-- get MIDI devices  with 16 = 0
function getMidiDevices()
  local deviceNames = {}
  local deviceID = {}
  local count = 0
  local maxDeviceCount = reaper.GetNumMIDIOutputs() 
  -- iterate over possible devices
  for i = 0, maxDeviceCount, 1 do
    local b, tmp = reaper.GetMIDIOutputName(i, "")
    if(b) then
      deviceNames[count] = tmp
      deviceID[count] = i + 16
      count = count + 1
    end
  end
  return deviceID, deviceNames, count
end

----------------------------GUI--------------------------------------

-- color constants
local backgroundColor = '#8e0c27'
local sliderColor = '#0c3402'
local borderColor = '#020024'
local buttoncolor = '#515151'
local generalPadding = 15
-- Button constants
local noteSelectionButtonWidth = 80
local noteSelectionButtonHeight = 35

-- print in app
function displayText(txt)
  local popup = rtk.Popup{
    child = rtk.Text{txt, wrap = rtk.Text.WRAP_BREAK_WORD, spacing = 1},
  }
  popup:open()
end

-- Main Window
local mainWindow = rtk.Window{minw = 650, minh= 580, h= 580, bg = backgroundColor, docked = false, title = 'SampleSamurai', borderless = true, border = {borderColor, 3}}
-- resize minimation
mainWindow.onresize = function (lastw, lasth)
  if(mainWindow.minw > mainWindow.w) then
    
    mainWindow:resize(mainWindow.minw, mainWindow.h)
  end
  if(mainWindow.minh > mainWindow.h) then
    mainWindow:resize(mainWindow.w, mainWindow.minh)
  end
end

---- APP
local app =  mainWindow:add(rtk.Application())
app.statusbar:hide()

-- GLOBAL TOOLBAR
-- helpButton
local helpButton = rtk.Button{label = '?', bpadding = 2, lpadding = 9, font = 'arial', fontsize = 25, w = 30, h = 30, halign = 'left', valign = 'bottom'}
helpButton.onclick = function()
  local text = [[1. Disable metronome precount
  2. Choose track to record to in SampleSamurai window
  3. In the Reaper track control panel, set track input to the channels your device is connected to or choose "record output" for virtual instruments
  4. In SampleSamurai, set correct midi device, choose external soundcard for hardware devices and virtual keyboard for virtual instruments
  5. Select the same midi channel your device is set to
  6. Select desired start and end note to define your range and the desired velocity and interval
  7. Set minimum length, shorter for percussive sounds and longer for sustained notes
  8. Set volume threshold so the release part of the note is not cut off early
  9. Hit "start" button
  10. Wait until SampleSamurai has recorded all of the notes
  11. Individual items will be named with midi note values and note names
  12. If you need multiple velocity layers, just transfer the items into a new track and repeat the process with different velocity values
]]

  local helpWrapper = rtk.VBox()
  helpWrapper:add(rtk.Text{text, wrap = rtk.Text.WRAP_BREAK_WORD, spacing = 1})
  local helpWrapperButtons = helpWrapper:add(rtk.HBox())
  helpWrapperButtons:add(rtk.Button{
    label = 'Video', 
    onclick = function ()
      rtk.open_url("https://www.youtube.com/watch?v=2-a7UDW9ZHQ")
    end
  })
  helpWrapperButtons:add(rtk.Button{
    label = 'Feedback', 
    onclick = function ()
      rtk.open_url("https://forum.cockos.com/showthread.php?t=287934&referrerid=200450")
    end
  })
  helpWrapperButtons:add(rtk.Button{
    label = '<3', 
    onclick = function ()
      rtk.open_url("https://www.paypal.com/paypalme/eczi?country.x=DE&locale.x=de_DE")
    end
  })
  local popup = rtk.Popup{
    child = helpWrapper,
  }
  popup:open()
 end

-- exit Button
local exitButton = rtk.Button{label = 'X', bpadding = 2, lpadding = 8, font = 'arial', fontsize = 25, w = 30, h = 30, halign = 'left', valign = 'bottom'}
  exitButton.onclick = function()
  isRunning = false
  mainWindow:close()
end 
app.toolbar:attr('bg', backgroundColor)
app.toolbar:attr('padding', generalPadding)
app.toolbar:attr('bpadding', 0)
app.toolbar:attr('valign', 'center')
app.toolbar:add(helpButton)
app.toolbar:add(rtk.Spacer{minh = 20, w = 10})
app.toolbar:add(exitButton)

-- MAIN WINDOW 
app:add_screen{
name = 'main',
  init = function(app, screen)
    
  -- Toolbar 
  screen.toolbar = rtk.HBox{w = 1, bg = backgroundColor, lpadding = 10}
  local toolBar =  screen.toolbar
  local heading = toolBar:add(rtk.Heading{text = 'SampleSamurai', fontsize = 40, bpadding = 0})

  -- main wrapper    
  screen.widget = rtk.VBox{}
  local mainWrapper = screen.widget:add( rtk.VBox{spacing= 10, bg = backgroundColor, padding = generalPadding})
  -- top Wrapper
  local topWrapper = mainWrapper:add(rtk.HBox{h = 0.3, w = 1.0, minh = 200, minw = 300 })
  -- Midi wrapper for Track and devices 
  local midiWrapper = topWrapper:add(rtk.VBox{h = 1, w = 1/3, border = {borderColor, 2}, rmargin = 10})
    local trackWrapper = midiWrapper:add(rtk.VBox{h = 0.4, w = 1, padding = 10})
    local deviceWrapper = midiWrapper:add(rtk.VBox{h = 0.5 , w = 1, padding = 10})
    local midiChannelWrapper = midiWrapper:add(rtk.HBox{h = 1, w = 1,padding = 10, halign='right'})
  -- note and velovity/interval wrappers
  local topRightWrapper = topWrapper:add(rtk.VBox{h = 1, w = 1.0, halign = 'center', border = {borderColor, 2}})
    local noteWrapper = topRightWrapper:add(rtk.HBox{w=1, minw = noteSelectionButtonWidth * 0.5, h=0.5, halign = 'center'})
    local velocityIntervalWrapper = topRightWrapper:add(rtk.HBox{w = 0.5})
  -- Wrapper for both start/end selections
  local noteStartWrapper = noteWrapper:add(rtk.HBox{ minw = noteSelectionButtonWidth * 2.5, halign = 'center'})
  noteWrapper:add(rtk.Box.FLEXSPACE)  -- spacer between start/end wrapper
  local noteEndWrapper = noteWrapper:add(rtk.HBox{minw = noteSelectionButtonWidth * 2.5 , halign = 'right'})
  -- velocity and interval selection wrapper
  local velocityWrapper = velocityIntervalWrapper:add(rtk.HBox{h=1})
  velocityIntervalWrapper:add(rtk.Box.FLEXSPACE)  -- spacer between velocity and interval selection
  local intervalWrapper = velocityIntervalWrapper:add(rtk.HBox{h=1})
  -- slider Wrapper
  local sliderWrapper = mainWrapper:add(rtk.VBox{ border = {borderColor, 2}, padding = 10})
  -- nameModificationWrapper
  local nameModificationWrapper = mainWrapper:add(rtk.VBox{ padding = 10, w = 1})

    -- channel/track selection
  trackWrapper:add(rtk.Heading{'Track'}, { valign='top'})
  local trackSelect = nil
  function displayTrackDropdown()
    local trackCount = 1
    local tracks = {}
    local i = 0
    local maxTracks = reaper.CountTracks(0)
    local firstTrackFound = nil

    if maxTracks <= 0 then
      tracks [1] = {"No tracks found!", id = -2}
    else
      -- search for used tracks
      while trackCount <= maxTracks or i > 100 do
        local mediaTrack = reaper.GetTrack(0, i)
        if(mediaTrack ~= nil) then
          if firstTrackFound == nil then
            firstTrackFound = i
          end
          local hasName , trackName = reaper.GetTrackName(mediaTrack)
          if(not hasName) then
            trackName = "Track " .. i
          end
          tracks[trackCount] = {trackName, id = i}
          trackCount = trackCount + 1
          
        end
        i =  i + 1
      end
    end
    table.insert(tracks, {'Scan Tracks', id = -1})
    --delete old
    if trackSelect ~= nil then
      trackWrapper:remove(trackSelect)
    end
    trackSelect = trackWrapper:add(rtk.OptionMenu{ 
      w = 1, 
      tracks,
      },
      {valign='bottom'}
    )
    trackSelect.onchange = function(self, item)
      if item.id == -1 then
        displayTrackDropdown()
      else
        trackID = item.id
        track = reaper.GetTrack(0, trackID)
      end
    end
    
    if firstTrackFound ~= nil then
      trackSelect:select(firstTrackFound)
      trackID = firstTrackFound
      track = reaper.GetTrack(0, trackID)
    else
      trackSelect:select(-2)
    end
  end
  displayTrackDropdown()


  -- midi device selection 
  deviceWrapper:add(rtk.Heading{'MIDI Device'}, { valign='top'})
  local deviceSelect = nil

  -- display MIDI devices to GUI
  function displayMidiDevicesDropdown()
    local deviceID, deviceNames, count = getMidiDevices()
    local dropDown= {}
    dropDown[1] = {'Virtual Keyboard', id =0}
    if count > 0 then
      for i = 0, count-1, 1 do
        dropDown[i+2] = {deviceNames[i], id = deviceID[i]}
      end
    end
    table.insert(dropDown, {'Scan devices', id = -1})

    -- delete old dropDown
    if deviceSelect ~= nil then  
      deviceWrapper:remove(deviceSelect)
    end
    -- generate dropdown
    deviceSelect = deviceWrapper:add(rtk.OptionMenu{ w = 1,
    menu = dropDown,
    },
    {valign='bottom'}
    )
    -- set on click
    deviceSelect.onchange = function(self, item)
      if(item.id == -1) then
        displayMidiDevicesDropdown()
        displayText("Scanning for devices!")
      end
      midiDevice = item.id
    end

    deviceSelect:select(0)
  end
  displayMidiDevicesDropdown()

  -- midi channel selection
  midiChannelWrapper:add(rtk.Heading{'Channel'}, { halign='left'})
  local midiChannelDropdown = {}
  for i = 1, 16, 1 do
    midiChannelDropdown[i] = {tostring(i), id = i}
  end
  midiChannelWrapper:add(rtk.Box.FLEXSPACE)
  local midiChannelSelection = midiChannelWrapper:add(rtk.OptionMenu{ halign='right', 
    menu = midiChannelDropdown,
    },
    {align='right', expand = true}
  )
  midiChannelSelection.onchange = function(self, item)
      midiChannel = item.id
  end
  midiChannelSelection:select(1)

  -- start note selectionstartOctave
  local startNoteBox = noteStartWrapper:add(rtk.VBox{ margin=10, spacing=5, halign  = 'center'})
  startNoteBox:add(rtk.Heading{'Start'}, { valign='top', halign = 'center'})
  local startNoteSelect = startNoteBox:add(rtk.OptionMenu{
    w = noteSelectionButtonWidth, h = noteSelectionButtonHeight,
    menu={
        {'C', id =0},
        {'C#', id =1},
        {'D', id =2},
        {'D#', id =3},
        {'E', id =4},
        {'F', id =5},
        {'F#', id =6},
        {'G', id =7},
        {'G#', id =8},
        {'A', id =9},
        {'A#', id =10},
        {'B', id =11}
      },
    },
    {valign='bottom'}
  )
  startNoteSelect.onchange = function(self, item)
    startNote = item.id
  end
  startNoteSelect:select(0)

  -- start note octave selection
  local startOctaveBox = noteStartWrapper:add(rtk.VBox{margin=10, spacing=5, halign  = 'center'})
  startOctaveBox:add(rtk.Heading{'Octave'}, { valign='top', halign = 'center'})
  local startOctaveSelect = startOctaveBox:add(rtk.OptionMenu{
    w = noteSelectionButtonWidth, h =noteSelectionButtonHeight,
    menu={
      {'-1', id =0},
      {'0', id =1},
      {'1', id =2},
      {'2', id =3},
      {'3', id =4},
      {'4', id =5},
      {'5', id =6},
      {'6', id =7},
      {'7', id =8},
      {'8', id =9},
      {'9', id =10},
      },
    },
    {valign='bottom'}
  )
  startOctaveSelect.onchange = function(self, item)
    startOctave = item.id

  end
  startOctaveSelect:select(1)

  -- end note selection
  local endNoteNox = noteEndWrapper:add(rtk.VBox{ margin=10, spacing=5, halign  = 'center'})
  endNoteNox:add(rtk.Heading{'Last'}, { valign='top', halign = 'center'})
  local endNoteSelect = endNoteNox:add(rtk.OptionMenu{
    w = noteSelectionButtonWidth, h = noteSelectionButtonHeight,
    menu={
        {'C', id =0},
        {'C#', id =1},
        {'D', id =2},
        {'D#', id =3},
        {'E', id =4},
        {'F', id =5},
        {'F#', id =6},
        {'G', id =7},
        {'G#', id =8},
        {'A', id =9},
        {'A#', id =10},
        {'B', id =11}
      },
    },
    {valign='bottom'}
  )
  endNoteSelect.onchange = function(self, item)
    endNote = item.id
  end
  endNoteSelect:select(0)

  -- end octave selection
  local endOctaveBox = noteEndWrapper:add(rtk.VBox{ margin=10, spacing=5, halign  = 'center'})
  endOctaveBox:add(rtk.Heading{'Octave'}, { valign='top', halign = 'center'})
  local endOtaveSelect = endOctaveBox:add(rtk.OptionMenu{
    w = noteSelectionButtonWidth, h = noteSelectionButtonHeight,
    menu={
        {'-1', id =0},
        {'0', id =1},
        {'1', id =2},
        {'2', id =3},
        {'3', id =4},
        {'4', id =5},
        {'5', id =6},
        {'6', id =7},
        {'7', id =8},
        {'8', id =9},
        {'9', id =10},
      },
    },
    {valign='bottom'}
  )
  endOtaveSelect.onchange = function(self, item)
    endOctave = item.id

  end
  endOtaveSelect:select(1)

  -- interval selection
  local stepBox = intervalWrapper:add(rtk.VBox{ margin=10, spacing=5,  halign = 'center'})
  stepBox:add(rtk.Heading{'Interval  '}, { valign='top', halign = 'center'})
  local stepSelect = stepBox:add(rtk.OptionMenu{
    w = noteSelectionButtonWidth, h = noteSelectionButtonHeight,
    menu={
        {'1', id =1},
        {'2', id =2},
        {'3', id =3},
        {'4', id =4},
        {'5', id =5},
        {'6', id =6},
        {'7', id =7},
        {'8', id =8},
        {'9', id =9},
        {'10', id =10},
        {'11', id =11},
        {'12', id =12},
      },
    },
    {valign='bottom'}
  )
  stepSelect.onchange = function(self, item)
    interval = item.id
  end
  stepSelect:select(1)


  -- velocity selection
  local velocityBox = velocityWrapper:add(rtk.VBox{ margin=10, spacing=5,  halign = 'center'})
  velocityBox:add(rtk.Heading{'Velocity  '}, { valign='top', halign = 'center'})
  local stepSelect = velocityBox:add(rtk.OptionMenu{
    w = noteSelectionButtonWidth, h = noteSelectionButtonHeight,
    menu={
        {'10%', id =1},
        {'20%', id =2},
        {'30%', id =3},
        {'40%', id =4},
        {'50%', id =5},
        {'60%', id =6},
        {'70%', id =7},
        {'80%', id =8},
        {'90%', id =9},
        {'100%', id =10},
      },
    },
    {valign='bottom'}
  )
  stepSelect.onchange = function(self, item)
    noteVolume = math.floor(127 * (item.id / 10))
  end
  stepSelect:select(10)

  -- mediaLength slider
  sliderWrapper:add(rtk.Heading{'Minimum length'})
  local mediaLengthNoteWrapper = sliderWrapper:add(rtk.HBox())
  mediaLengthNoteWrapper:add(rtk.Text{'0.4', w=25})
  local mediaLengthSlider = mediaLengthNoteWrapper:add(rtk.Slider{ min=-9, max=40, spacing=0.5,padding = 4, fontsize = 0.5, color = sliderColor, value = 1})
  local mediaLengthSliderCurrentSelectionDisplay = mediaLengthNoteWrapper:add(rtk.Text{'1 s', w=50})
  mediaLengthSlider.onchange = function (self)
    mediaLength = 2.7  ^ (self.value/10)
    if(mediaLength > 1) then
      mediaLength = math.floor(mediaLength)
    else
      mediaLength =  math.floor(mediaLength*100)/100
    end
    mediaLengthSliderCurrentSelectionDisplay:attr('text', mediaLength .. ' s')
  end

  -- pause Slider slider
  sliderWrapper:add(rtk.Heading{'Time between'})
  local pauseWrapper = sliderWrapper:add(rtk.HBox())
  pauseWrapper:add(rtk.Text{'0.5', w=25})
  local pauseSlider = pauseWrapper:add(rtk.Slider{ min=5, max=50, spacing=0.5, padding = 4, fontsize = 0.5, color = sliderColor, step = 5, ticks = true, value = 10})
  local pauseSliderCurrentSelectionDisplay = pauseWrapper:add(rtk.Text{'1 s', w=50})
  pauseSlider.onchange = function (self)
    pauseTime = self.value/10
    pauseSliderCurrentSelectionDisplay:attr('text', pauseTime .. ' s')
  end

  -- max volume slider 
  sliderWrapper:add(rtk.Heading{'Volume threshold'})
  local maxVolumeNoteWrapper = sliderWrapper:add(rtk.HBox())
  maxVolumeNoteWrapper:add(rtk.Text{'-129', w=25})
  local maxVolumeSlider  = maxVolumeNoteWrapper:add(rtk.Slider{step=1, min= -49, max=0,  ticks=false, spacing=0.5,padding = 4, fontsize = 0.5, color = sliderColor, value = 0})
  local maxVolumeSliderCurrentSelectionDisplay = maxVolumeNoteWrapper:add(rtk.Text{'0 dB', w=50})
  maxVolume = 0
  maxVolumeSlider.onchange = function (self)
    if(self.value == 0) then maxVolume = 0
    else 
      maxVolume = -math.floor( 2.7 ^ (self.value/-10))
    end
    maxVolumeSliderCurrentSelectionDisplay:attr('text', maxVolume .. '  dB')
  end


  -- name modifications
  local midiNameModification = nameModificationWrapper:add(rtk.CheckBox{label = 'Include MIDI note', halign = 'right', tagged = 'left', value = rtk.CheckBox.CHECKED})
  midiNameModification.onchange = function (self)
    includeMidiNote = self.value
  end
  
  -- BOTTOM BAR
  screen.widget:add(rtk.Box.FLEXSPACE)
  local bottomWrapper = screen.widget:add(rtk.HBox{padding = 20})
  -- clear button
  local clearButton = rtk.Button{label='Clear Track', color = buttoncolor}
  clearButton.onclick = clearTrack

  -- Autoclear checkBox
  local bottomRightWrapper = rtk.HBox{valign = 'center', spacing = 4}
  local autoClearCheckBox = rtk.CheckBox{label = 'Auto clear', halign = 'right', tagged = 'left', value = rtk.CheckBox.UNCHECKED, iconpos = 'right'}
  autoClearCheckBox.onchange = function (self)
    autoClear = self.value
  end
  -- Start button
  local startButton = rtk.Button{label='Start'}
  startButton:attr('color', buttoncolor) 
  startButton.onclick = function()
    if(isRunning == false) then 
      if autoClear then
        clearTrack()
      end
      initStart()
    else
      isRunning = false
    end
  end
  bottomRightWrapper:add(autoClearCheckBox)
  bottomRightWrapper:add(startButton)
  bottomWrapper:add(clearButton)
  bottomWrapper:add(rtk.Box.FLEXSPACE)
  bottomWrapper:add(bottomRightWrapper)
end
}
-- Recording Screen
local timerTime = nil
app:add_screen{
  name = 'recordingScreen',
  init = function (app, screen)
    screen.widget = rtk.VBox{halign = 'center', h = 1, w = 1}
    local mainWrapper =  screen.widget:add(rtk.VBox{halign = 'center', valign = 'center'})
    mainWrapper:add(rtk.Spacer{h=60})
    local recordingText = mainWrapper:add(rtk.Heading{'RECORDING',textalign='center',fontsize=150})
    mainWrapper:add(rtk.Spacer{h = 70})
    timerTime = mainWrapper:add(rtk.Text{estimatedTime, fontsize = 28})
    screen.widget:add(rtk.Box.FLEXSPACE)
    local bottomWrapper = screen.widget:add(rtk.HBox{halign = 'right', w = 1, padding = 20})
    bottomWrapper:add(rtk.Box.FLEXSPACE)
    local stopButton = bottomWrapper:add(rtk.Button{label = 'Stop', color = 'red'})
    stopButton.onclick = function ()
      isRunning = false
    end
  end,  
  update = function (app, screen)
    timerTime:attr('text', estimatedTime)
  end
}

function setTimer()
  estimatedTime = 'Estimated time: ' .. (mediaItems - reps) * mediaLength + (mediaItems - reps -1) * pauseTime .. 's'
  reps = reps +1
  app.screens.recordingScreen:update()
end


------------------------sampling--------------------------------------

-- stop recording
function stopRecord()
  reaper.Main_OnCommand(1013, 1)
  reaper.OnStopButton()
  isRunning = false
  if app:current_screen() ~= 'main' then
    app:pop_screen()
  end
  renameItems()
end

-- peak test
function waitForPeak()
  reaper.ClearConsole()
  reaper.ClearPeakCache() 
  local peak = (reaper.Track_GetPeakInfo(track, 1))
  
  local peakInDb = AMP_DB*math.log(peak)
  
  -- wait for peak
  if(peakInDb > maxVolume and isRunning == true) then
    defer(waitForPeak, 0.01)

  -- loop until max media items reached
  else
    reaper.SetMediaTrackInfo_Value( track, "I_RECARM",0)

    if stopNext == 0 then
      -- check for overstepping last note end set stop for next
      note = note + interval
      if note >= lastNote then
        note = lastNote
        stopNext = 1
      end
      defer(conversion, pauseTime)
    else
      -- turn off recording
      stopRecord()
    end
  end
end

function sendMidiStop()
  -- send midi off 
  reaper.StuffMIDIMessage(midiDevice, NOTE_OFF_MSG, note, 0)
  waitForPeak()
end

function sendMidiStart()
  -- We have to select the right extern device -> midiDevice>=16 only for plugins set to 0
  reaper.StuffMIDIMessage(midiDevice, NOTE_ON_MSG, note, noteVolume)
  defer(sendMidiStop, mediaLength)
end

-- Start recording
function conversion()
  if(isRunning == false)then
    stopRecord()
    return
  end
  
  setTimer()
  reaper.SetMediaTrackInfo_Value(track, "I_RECARM",1)
  -- wait between arm record and send midi
  defer(sendMidiStart, midiStartDelay)
  return
end

-- init before recording
function initStart()
  reps = 0
  if trackID < 0 or reaper.GetTrack(0, trackID) == nil then
    displayText("No valid track!")
    return
  end
  -- generate midi message with selected midi channel
  NOTE_ON_MSG = 0x90 | (midiChannel - 1)
  NOTE_OFF_MSG = 0x80 | (midiChannel - 1)
  note = startNote + startOctave * 12
  lastNote = endNote + endOctave * 12
  if lastNote == note or (lastNote < note and interval == 1)then
    mediaItems = 1
    stopNext = 1
  elseif note > lastNote then
    displayText("Start note higher than end note!")
    return
  else
    mediaItems = math.floor((lastNote - note) / interval)
    mediaItems = mediaItems +1 
    if (lastNote - note) % interval ~= 0 then
      mediaItems = mediaItems +1     
    end
    stopNext = 0
  end
  if(track == -1 or reaper.GetTrack(0, trackID) ~= track) then track = reaper.GetTrack(0, trackID) end -- Also check if the track was deleted, but new created
  isRunning = true
  reaper.Main_OnCommand(1013, 0) -- Transport: Record
  app:push_screen('recordingScreen')
  conversion()
end
  
------------------------rename items--------------------------------------
  
function renameItems()
  local trackItemCount = reaper.CountTrackMediaItems(track)
  if(trackItemCount ~= mediaItems) then
    displayText("Something went wrong while renaming.\nNames may be wrong! Try to clear the Track.\n")
      return
  end
  
  for i=0, trackItemCount-1, 1 do
    local note = startNote + startOctave * 12 + interval * i
    if note > lastNote and i > 0 then
      note = lastNote
    end
    local item = reaper.GetTrackMediaItem(track, i)
    local take = reaper.GetMediaItemTake(item, 0)
    if(take ~= nil) then
      reaper.GetSetMediaItemTakeInfo_String(take, 'P_NAME', numberToNote(note), true)
    else
      displayText("Something went wrong while getting media item infos. Try to clear the track.")
    end
  end
end

function numberToNote(n)
  local midiNote = n
  local octave = math.floor(n / 12 )
  local note
  if not(octave==0) then
    note = n % (octave *12)
  else
    note = n
  end
  
  if note == 0 then note = 'C'
  elseif note == 1 then   note = 'C#'
  elseif note == 2 then   note = 'D'
  elseif note == 3 then   note = 'D#'
  elseif note == 4 then   note = 'E'
  elseif note == 5 then   note = 'F'
  elseif note == 6 then   note = 'F#'
  elseif note == 7 then   note = 'G'
  elseif note == 8 then   note = 'G#'
  elseif note == 9 then   note = 'A'
  elseif note == 10 then   note = 'A#'
  elseif note == 11 then   note = 'B'
  else note = 'Something went wrong with your note!'
  end
  local itemName = tostring(note) .. tostring(octave - 1) 
  if includeMidiNote then itemName =  itemName .. ' ' .. tostring(midiNote) end
  return  itemName
end

mainWindow:open()
