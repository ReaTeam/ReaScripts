-- @description unsolo track with its number
-- @author mena Awad
-- @version 1.0


 num_of_tracks = reaper.CountTracks(0)
    if num_of_tracks  == 0 then  return end;

 sel_tr = reaper.GetSelectedTrack(0, 0)
if  sel_tr ~= nil then
 sel_tr_num = reaper.GetMediaTrackInfo_Value(sel_tr, "IP_TRACKNUMBER")
retval, preset = reaper.GetUserInputs("EnterTrackNumberToUnsolo", 1, "", sel_tr_num)
else
retval, preset = reaper.GetUserInputs("EnterTrackNumberToUnsolo", 1, "", "0")
end

if (preset == "0" or preset == "") then return end
if (tonumber(preset)  >= 0 and tonumber(preset) <= num_of_tracks) then
t = preset -1
elseif (tonumber(preset) >= num_of_tracks) then
t = tonumber(num_of_tracks-1)
end
    tr = reaper.GetTrack(0, t)
reaper.SetMediaTrackInfo_Value(tr, 'I_SOLO', 0)
	local timer2 =  reaper.NamedCommandLookup("_OSARA_REPORTSEL")
		reaper.Main_OnCommand(timer2, 0)

