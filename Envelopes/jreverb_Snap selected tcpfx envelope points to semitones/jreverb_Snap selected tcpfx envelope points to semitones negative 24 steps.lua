-- @noindex

tbl = {0.04166666666, 
0.08333333333, 
0.125, 
0.16666666666, 
0.20833333333, 
0.25,
0.29166666666,
0.33333333333,
0.375,
0.41666666666,
0.45833333333,
0.5,
0.54166666666,
0.58333333333,
0.625,
0.66666666666,
0.70833333333,
0.75,
0.79166666666,
0.83333333333,
0.875,
0.91666666666,
0.95833333333,
1 }

function snap_pitchbend_envelope_points_to_semitones_negative24_explicit()
  track = reaper.GetSelectedTrack(0,0)
  env = reaper.GetSelectedTrackEnvelope(0)
  if not env then return end
  
  for i = 1, 1 do
    local points = reaper.CountEnvelopePoints(env)
    for ptidx = 0, points  do    
      local retval, time, value, shape, tension, selected = reaper.GetEnvelopePoint(env, ptidx)
      if selected then
        reaper.Undo_BeginBlock()
      if value <= tbl[24] then 
         pointval = tbl[23] end
      if value <= tbl[23] then 
         pointval = tbl[22] end
      if value <= tbl[22] then 
         pointval = tbl[21] end
      if value <= tbl[21] then 
         pointval = tbl[20] end         
      if value <= tbl[20] then 
         pointval = tbl[19] end
      if value <= tbl[19] then 
         pointval = tbl[18] end 
      if value <= tbl[18] then 
         pointval = tbl[17] end
      if value <= tbl[17] then 
         pointval = tbl[16] end          
      if value <= tbl[16] then 
         pointval = tbl[15] end          
      if value <= tbl[15] then 
         pointval = tbl[14] end          
      if value <= tbl[14] then 
         pointval = tbl[13] end          
      if value <= tbl[13] then 
         pointval = tbl[12] end           
      if value <= tbl[12] then 
         pointval = tbl[11] end           
      if value <= tbl[11] then 
         pointval = tbl[10] end  
      if value <= tbl[10] then 
         pointval = tbl[9] end           
      if value <= tbl[9] then 
         pointval = tbl[8] end           
      if value <= tbl[8] then 
         pointval = tbl[7] end           
      if value <= tbl[7] then 
         pointval = tbl[6] end 
      if value <= tbl[6] then 
         pointval = tbl[5] end          
      if value <= tbl[5] then 
         pointval = tbl[4] end          
      if value <= tbl[4] then 
         pointval = tbl[3] end          
      if value <= tbl[3] then 
         pointval = tbl[2] end          
      if value <= tbl[2] then 
         pointval = tbl[1] end           
      if value <= tbl[1] then 
         pointval = 0 end             
      if value <= 0 then 
         pointval = tbl[24] end
           reaper.SetEnvelopePoint(env, ptidx,_,pointval, _, _, 1, true)
            reaper.Envelope_SortPoints( env )
               end
              end
             end
             end
            reaper.UpdateArrange()
            snap_pitchbend_envelope_points_to_semitones_negative24_explicit()
