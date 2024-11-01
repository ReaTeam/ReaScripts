-- @description Split items at timeline grid (with extra options)
-- @author amagalma
-- @version 1.00
-- @donation https://www.paypal.me/amagalma
-- @about
--   Splits selected items at timeline grid. Choice of the exact placement of the split (or of the cross-fade, if any) is offered.
--
--   - Requires ReaImgui and SWS Extensions


package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua'
local ImGui = require 'imgui' '0.9.3.2'

local ctx = ImGui.CreateContext('amagalma_Split item at specified note durations')
local window_flags = ImGui.WindowFlags_NoCollapse | ImGui.WindowFlags_AlwaysAutoResize

local ext = "amagalma_SplitAtGrid"
local rv, splitautoxfade, restore_autoxfade
local crossfade = reaper.HasExtState( ext, "place" ) and tonumber(reaper.GetExtState( ext, "place" )) or 0
local finetune = reaper.HasExtState( ext, "fine" ) and tonumber(reaper.GetExtState( ext, "fine" )) or 0


local function loop()
  local visible, open = ImGui.Begin(ctx, 'Split items at timeline grid', true, window_flags)
  if visible then

    ImGui.Text(ctx, "Crossfade placement:")
    rv,crossfade = ImGui.RadioButtonEx(ctx, 'left', crossfade, 0); ImGui.SameLine(ctx)
    rv,crossfade = ImGui.RadioButtonEx(ctx, 'center', crossfade, 1); ImGui.SameLine(ctx)
    rv,crossfade = ImGui.RadioButtonEx(ctx, 'right', crossfade, 2); ImGui.SameLine(ctx)
    rv,crossfade = ImGui.RadioButtonEx(ctx, 'none', crossfade, 3);

    ImGui.Spacing(ctx) ; ImGui.Spacing(ctx) ; ImGui.Separator(ctx) ; ImGui.Spacing(ctx)

    ImGui.Text(ctx, "Split placement fine tuning:") ; ImGui.Spacing(ctx)
    rv, finetune = ImGui.DragInt(ctx, ' ms', finetune, 0.25)
    ImGui.Spacing(ctx) ; ImGui.Spacing(ctx) ; ImGui.Separator(ctx) ; ImGui.Spacing(ctx)

    if ImGui.Button(ctx, " Change grid ",0, 0) then
      reaper.Main_OnCommand(reaper.NamedCommandLookup('_RS968436cb97d25a22a749f6291f35d4638fe6f0c6'), 0) -- amagalma_Set project grid (via dropdown menu).lua
    end

    ImGui.SameLine(ctx)

    if ImGui.Button(ctx, " Split items ",0, 0) and reaper.CountSelectedMediaItems(0) > 0 then
      reaper.PreventUIRefresh(1)
      if finetune ~=0 then
        reaper.ApplyNudge( 0, 0, 0, 0, finetune, true, 0 )
      end
      --set crossfade
      if crossfade == 3 then
        if reaper.GetToggleCommandState( 40912 ) == 1 then
          reaper.Main_OnCommand(40928, 0) -- Disable crossfade on split (disregard toolbar auto-crossfade button)
          restore_autoxfade = true
        end
      else
        splitautoxfade = tonumber(({reaper.get_config_var_string( "splitautoxfade" )})[2])
        local xf_left = splitautoxfade & 131072 ~= 0
        local xf_center = splitautoxfade & 262144 ~= 0
        local current_crossfade = xf_left and 0 or xf_center and 1 or 2
        if crossfade ~= current_crossfade then -- set wanted placement
          local set, clear
          if crossfade == 0 then
            set, clear = 131072, 262144
          elseif crossfade == 1 then
            set, clear = 262144, 131072
          else
            clear = 131072 | 262144
          end
          local splitautoxfade_new = splitautoxfade & ~clear
          reaper.SNM_SetIntConfigVar( "splitautoxfade", (set and (splitautoxfade_new | set) or splitautoxfade_new) )
        end
      end
      reaper.Main_OnCommand(40932, 0) -- Split items at timeline grid
      -- Recover
      if finetune ~=0 then -- bring it back
        reaper.ApplyNudge( 0, 0, 0, 0, -finetune, true, 0 )
      end
      if crossfade ~= current_crossfade then -- set it back
        if crossfade ~= 3 then
          reaper.SNM_SetIntConfigVar( "splitautoxfade", splitautoxfade )
        else
          if restore_autoxfade then
            reaper.Main_OnCommand(40927, 0) -- Enable crossfade on split (disregard toolbar auto-crossfade button)
          end
        end
      end
      reaper.PreventUIRefresh(-1)
      reaper.UpdateArrange()
      reaper.Undo_OnStateChange("Split items at grid")
    end

    ImGui.Spacing(ctx) ;
    ImGui.End(ctx)
  end
  if open then
    reaper.defer(loop)
  end
end

reaper.atexit(function()
  reaper.SetExtState( ext, "place", tostring(crossfade), true )
  reaper.SetExtState( ext, "fine", tostring(finetune), true )
end)

reaper.defer(loop)
