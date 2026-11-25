-- @description Dubbing Prompter: subtitles, roles and takes for dubbing
-- @author zaraki999kenpachi
-- @version 8.0.2
-- @changelog First release

-- 1.12.0: «Суфлёр на телефон / планшет» (страница в reaper_www_root, позиция через веб-интерфейс REAPER, кнопки Назад/Следующая).
-- Dubbing Prompter 1.6.0 — original REAPER ReaScript (sound director's workstation for dubbing)
-- Requires only REAPER native Lua/gfx API (SWS optional for paste).
-- 0.7.0: auto-recorded marks from dub track, take loudness check (peak/clipping/quiet), HTML script per role, timecode in frames.
-- 0.6.0: best take (M), QC report, script per role, dub shift in frames, F1 help, overlay restore.
-- 0.5.0: "recorded" marks + progress per role, takes count and overrun check against the dub track,
--        chars-per-second meter, notes, bookmarks, original-text compare, play line with pre-roll / loop,
--        per-role and per-track ducking depth, ducking from real dub items, fit timing to takes,
--        time shift, global replace, role rename, SRT per role, project export/import, auto versions.
local SEC="DubbingSystem"
local K={subs="subtitle_data_v1",orig="original_track_guid",dub="dubbing_track_guid",duck="duck_db",pre="pre_roll_ms",post="post_roll_ms",fi="fade_in_ms",fo="fade_out_ms",source="subtitle_source"}

-- Цепочка эффектов дорожки дубляжа. fx — часть имени плагина, как в списке FX REAPER.
-- preset — имя пресета, который вы сохранили в самом плагине (Save preset). Если пресета нет,
-- плагин стоит с настройками по умолчанию.
DUB_CHAIN={
 {fx="VST3: RX 9 Voice De-noise",preset="Dubbing"},   -- 1. очистка голоса от шума (как у звука режиссёра дубляжа)
 {fx="VST3: RX 9 De-reverb",preset="Dubbing"},        -- 2. убрать комнатную реверберацию из голоса
 {fx="VST3: SPL De-Esser",preset="Dubbing"},          -- 3. шипящие (S-REDUCTION 3–7, AUTO THRESHOLD вкл.)
 {fx="VST3: FabFilter Pro-Q 3",preset="Dubbing"},     -- 4. эквалайзер: срез ниже ~90 Гц, муть 200–400 Гц, разборчивость 2–4 кГц
 {fx="VST3: FabFilter Pro-C 2",preset="Dubbing"},     -- 5. компрессор: ровная громкость, как в закадровом переводе
 {fx="VST3: SPL Vitalizer MK2-T",preset="Dubbing"},   -- 6. яркость и присутствие речи (по слуху)
 {fx="VST3: FabFilter Pro-L 2",preset="Dubbing"},     -- 7. лимитер в конце, потолок громкости
}
dub_rec_off=false   -- true, пока эффекты дорожки дубляжа выключены на время записи
local W,H=1080,740
local rows, selected, scroll, status = {},1,0,"Пробел — play/stop · P — реплика · L — цикл · D — записано · B — закладка · N — след. закладка"
local duck,pre,post,fi,fo=25,100,150,120,220
local only_dub,follow,win_from_dub=false,true,false
local preroll=3
local lastcap=0 -- must be declared BEFORE button()/draw(), otherwise buttons never fire
local show_help=false
local PREF={keys={play_line=112,loop=108,done=100,mark=98,next_mark=110,best=109,actor=114},
 cols={takes=true,cps=true,dur=true,over=true,note=true,verdict=true}}
local qc_cps,qc_gap,qc_short=20,0.08,1.0   -- QC thresholds: chars/sec, min pause (s), short line (s)
local ov_restore_at=nil -- time when a restored overlay should be started (after the old one has exited)
local ui_locked=false
local search,search_focus,role_filter="",false,""
local status_filter=""   -- "", "redo", "check", "ok", "none" (not recorded)
local VERDICTS={ok="ок",redo="переписать",check="спорно",lip="губы не совпадают"}
local edit_mode,edit_buf,edit_target=false,"","text"
local undo_stack={}
local vis,roles,role_idx={}, {}, {}
local role_duck={}
local wins_cache,wins_time,wins_dirty={},0,true
local dub_cache,dub_time={}, -10
local last_cur=0
local loop_active=false
local last_ver_time,last_ver_str=os.time(),""

local function extget(k,def) local _,v=reaper.GetProjExtState(0,SEC,k); if v=="" then return def end; return v end
local function trim(s) return ((s or ""):gsub("^%s+",""):gsub("%s+$","")) end
local function fmt(t) local h=math.floor(t/3600); local m=math.floor(t/60)%60; local s=t%60; return string.format("%02d:%02d:%06.3f",h,m,s) end
local function fps_now() local ok,f=pcall(reaper.TimeMap_curFrameRate,0); if ok and f and f>0 then return f end; return 25 end
local function tcf(t) local f=fps_now(); local n=math.floor(f+0.5); local total=math.floor(t*f+0.5)
 return string.format("%02d:%02d:%02d:%02d",total//(n*3600),(total//(n*60))%60,(total//n)%60,total%n) end
local frames_mode=false
local function ftime(t) if frames_mode then return tcf(t) end; return fmt(t) end
local function clean_name(s) return trim((tostring(s or ""):gsub("[,\t\r\n]"," "))) end

local function tc(s)
 s=s or ""
 local h,m,ss,ms=s:match("^(%d+):(%d%d):(%d%d)[,.](%d+)$")
 if h then return tonumber(h)*3600+tonumber(m)*60+tonumber(ss)+tonumber(ms)/(10^#ms) end
end

-- lower-case that also understands Cyrillic (Lua's string.lower does not)
local function ulower(s)
 local ok,res=pcall(function()
  local t={}
  for _,c in utf8.codes(s) do
   if c>=0x41 and c<=0x5A then c=c+32
   elseif c>=0x410 and c<=0x42F then c=c+32
   elseif c==0x401 then c=0x451
   elseif c>=0x400 and c<=0x40F then c=c+80
   elseif c==0x490 then c=0x491 end
   t[#t+1]=utf8.char(c)
  end
  return table.concat(t)
 end)
 if ok then return res end
 return s:lower()
end

local function utf8_pop(s) if s=="" then return s end; local o=utf8.offset(s,-1); if o then return s:sub(1,o-1) end; return "" end
local function tail(s,n) local len=utf8.len(s); if len and len>n then return "…"..s:sub(utf8.offset(s,len-n+1)) end; return s end
local function short(t,n)
 t=(t or ""):gsub("\n"," / ")
 local len=utf8.len(t)
 if len and len>n then t=t:sub(1,utf8.offset(t,n-2)-1).."..." end
 return t
end
local function ulen(s) local n=utf8.len(s); return n or #s end

-- ---------- parsing ----------
local function finish_rows(list)
 for _,r in ipairs(list) do r.done=false; r.note=""; r.mark=false; r.orig="" end
 table.sort(list,function(a,b) return a.start<b.start end)
 return list
end

-- SRT timecode: hh:mm:ss,ms (also h:mm:ss, mm:ss and "." instead of ",")
local function srt_tc(x)
 x=(x or ""):gsub(",", ".")
 local h,m,sec=x:match("^(%d+):(%d+):(%d+%.?%d*)$")
 if h then return tonumber(h)*3600+tonumber(m)*60+tonumber(sec) end
 local m2,sec2=x:match("^(%d+):(%d+%.?%d*)$")
 if m2 then return tonumber(m2)*60+tonumber(sec2) end
end

local function parse_srt(s)
 local out={}; s=s:gsub("\r\n","\n"):gsub("\r","\n")
 for block in (s.."\n\n"):gmatch("(.-)\n%s*\n") do
  local a,b,body=block:match("([%d:]+[,.]%d+)%s*%-%->%s*([%d:]+[,.]%d+)[^\n]*\n(.*)")
  if a and b then local st,en=srt_tc(a),srt_tc(b); if st and en and en>st then
   body=body:gsub("<[^>]->",""):gsub("{[^}]*}",""):gsub("\\N","\n")
   body=trim(body)
   if body~="" then out[#out+1]={start=st,finish=en,text=body,role=""} end
  end end
 end; return out
end

local function parse_ass(s)
 local out,in_events={},false; s=s:gsub("\r\n","\n"):gsub("\r","\n")
 for line in (s.."\n"):gmatch("(.-)\n") do
  if line:match("^%[Events%]") then in_events=true elseif line:match("^%[") then in_events=false
  elseif in_events and line:match("^Dialogue:") then
   local p=line:gsub("^Dialogue:%s*",""); local f,pos={},1
   for i=1,9 do local c=p:find(",",pos,true); if not c then break end; f[i]=p:sub(pos,c-1); pos=c+1 end
   if f[2] and f[3] and pos<=#p then
    local st,en=tc(f[2]),tc(f[3])
    local txt=p:sub(pos):gsub("{[^}]*}",""):gsub("\\N","\n"):gsub("\\n","\n")
    -- role = Name field, otherwise Style (ignoring "Default")
    local role=trim(f[5] or "")
    if role=="" then role=trim(f[4] or "") end
    if role:lower()=="default" or role=="*Default" then role="" end
    role=clean_name(role)
    if st and en and en>st and trim(txt)~="" then out[#out+1]={start=st,finish=en,text=trim(txt),role=role} end
   end
  end
 end; return out
end

-- times: hh:mm:ss.ms, mm:ss.ms or plain seconds
local function tc_loose(x)
 x=trim(x or ""):gsub(",", ".")
 local h,m,sec=x:match("^(%d+):(%d+):([%d%.]+)$")
 if h then return tonumber(h)*3600+tonumber(m)*60+tonumber(sec) end
 local m2,sec2=x:match("^(%d+):([%d%.]+)$")
 if m2 then return tonumber(m2)*60+tonumber(sec2) end
 return tonumber(x)
end

local function parse_vtt(s)
 local out={}; s=s:gsub("\r\n","\n"):gsub("\r","\n")
 for block in (s.."\n\n"):gmatch("(.-)\n%s*\n") do
  local a,b,rest=block:match("([%d:%.]+)%s*%-%->%s*([%d:%.]+)[^\n]*\n?(.*)")
  if a and b then
   local st,en=tc_loose(a),tc_loose(b)
   local role=rest:match("<v%s+([^>]+)>") or ""
   local text=rest:gsub("<v[^>]*>",""):gsub("</?[^>]+>",""):gsub("\n%s*"," \n"):gsub("^%s+",""):gsub("%s+$","")
   if st and en and en>st and text~="" then out[#out+1]={start=st,finish=en,text=text,role=trim(role)} end
  end
 end
 return out
end

-- CSV / TSV / semicolon files: start;end;text;role (first line may be a header)
local function parse_csv(s)
 local out={}
 for line in (s.."\n"):gmatch("(.-)\n") do
  line=trim((line:gsub("\r","")))
  if line~="" then
   local sep=line:find(";",1,true) and ";" or (line:find("\t",1,true) and "\t" or ",")
   local f={}
   for part in (line..sep):gmatch("(.-)"..(sep=="\t" and "\t" or sep)) do f[#f+1]=trim(part) end
   local st,en=tc_loose(f[1]),tc_loose(f[2])
   if st and en and en>st and (f[3] or "")~="" then out[#out+1]={start=st,finish=en,text=f[3],role=f[4] or ""} end
  end
 end
 return out
end

-- UTF-7 (some web subtitle exports: "--+AD4-" is "-->", "+BCEE..-" is base64 Cyrillic)
local function utf7_decode(s)
 local B64="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
 local val={}; for k=1,#B64 do val[B64:sub(k,k)]=k-1 end
 local out={}; local i,n=1,#s
 while i<=n do
  local c=s:sub(i,i)
  if c~="+" then out[#out+1]=c; i=i+1
  elseif s:sub(i+1,i+1)=="-" then out[#out+1]="+"; i=i+2
  else
   local j=i+1
   while j<=n and val[s:sub(j,j)] do j=j+1 end
   local acc,nb,hi=0,0,nil
   for k=i+1,j-1 do
    acc=((acc<<6)|val[s:sub(k,k)])&0xFFFFFF; nb=nb+6
    if nb>=16 then
     nb=nb-16; local u=(acc>>nb)&0xFFFF
     if u>=0xD800 and u<=0xDBFF then hi=u
     else
      local cp=u
      if u>=0xDC00 and u<=0xDFFF and hi then cp=0x10000+((hi-0xD800)<<10)+(u-0xDC00) end
      hi=nil
      if cp>0 then out[#out+1]=utf8.char(cp) end
     end
    end
   end
   if s:sub(j,j)=="-" then j=j+1 end
   i=j
  end
 end
 return table.concat(out)
end

local function read_subs_file(path)
 local f=io.open(path,"rb"); if not f then return nil end
 local data=f:read("*a"); f:close()
 if data:find("+AD4-",1,true) then data=utf7_decode(data) end   -- UTF-7 export (see utf7_decode)
 -- diagnostics for the import message: how many timecode lines and what the first one looks like
 local tcl=0; local first=""
 for ln in (data.."\n"):gmatch("([^\n]*)\n") do
  if ln:find("-->",1,true) then tcl=tcl+1; if first=="" then first=ln:sub(1,60) end end
 end
 last_sub_hint=string.format("bytes %d, строк со временем: %d",#data,tcl)..(first~="" and (", первая: "..first) or "")
 -- UTF-16 (Windows Notepad "Unicode"): convert to UTF-8 so the parsers can read it
 local b1,b2=data:byte(1,2)
 if (b1==0xFF and b2==0xFE) or (b1==0xFE and b2==0xFF) or data:find("\0",1,true) then
  local le=(b1==0xFF and b2==0xFE) or (b1~=0xFE and data:byte(2)==0)
  local start=((b1==0xFF and b2==0xFE) or (b1==0xFE and b2==0xFF)) and 3 or 1
  local out={}
  for i=start,#data-1,2 do
   local lo,hi=data:byte(i,i+1)
   local cp=le and (lo+hi*256) or (hi+lo*256)
   if cp>=0xD800 and cp<=0xDBFF then cp=0xFFFD end -- surrogates are not needed for subtitles
   if cp~=0 then out[#out+1]=utf8.char(cp) end
  end
  data=table.concat(out)
 end
 data=data:gsub("^\239\187\191","")
 local ext=path:lower():match("%.([%w]+)$") or ""
 local list
 if ext=="srt" then list=parse_srt(data) elseif ext=="ass" or ext=="ssa" then list=parse_ass(data)
 elseif ext=="vtt" then list=parse_vtt(data)
 elseif ext=="csv" or ext=="tsv" then list=parse_csv(data) else
  list={}; local t=0; data=data:gsub("\r\n","\n"):gsub("\r","\n")
  for line in (data.."\n"):gmatch("(.-)\n") do
   line=trim(line)
   if line~="" then
    local a,b,body=line:match("^(%d%d:%d%d:%d%d[,.]%d+)%s*%-%->%s*(%d%d:%d%d:%d%d[,.]%d+)%s*|%s*(.*)$")
    if a and b then local st,en=tc(a),tc(b); if st and en and en>st then list[#list+1]={start=st,finish=en,text=body,role=""} end
    else list[#list+1]={start=t,finish=t+3,text=line,role=""}; t=t+3.25 end
   end
  end
 end
 return finish_rows(list)
end

-- ---------- derived data ----------
local PAL={0xFFD64F,0x4FC2F7,0x82C785,0xF06192,0xBA68C8,0xFF8A66,0x4DB5AB,0xA18880,0x8FA3AD,0xDCE875}

local function role_rgb(role)
 local i=role_idx[role or ""]
 if not i then return nil end
 local h=PAL[((i-1)%#PAL)+1]
 return {((h>>16)&255)/255,((h>>8)&255)/255,(h&255)/255}
end

local function rebuild_roles()
 roles,role_idx={}, {}
 for _,s in ipairs(rows) do
  local r=s.role or ""
  if r~="" and not role_idx[r] then roles[#roles+1]=r; role_idx[r]=#roles end
 end
 if role_filter~="" and not role_idx[role_filter] then role_filter="" end
end

local function rebuild_vis()
 vis={}
 local q=nil
 if search~="" then q=ulower(search) end
 for i,s in ipairs(rows) do
  local ok=(role_filter=="" or (s.role or "")==role_filter)
  if ok and q then ok=(ulower(s.text):find(q,1,true)~=nil) end
  if ok and status_filter~="" then
   if status_filter=="none" then ok=not s.done
   else ok=(s.verdict==status_filter) end
  end
  if ok then vis[#vis+1]=i end
 end
end

local function mark_dirty() rebuild_roles(); rebuild_vis(); wins_dirty=true end

-- ---------- storage ----------
local function esc(s) local t=(s or ""):gsub("\n","\\n"); t=t:gsub("[\t\r]"," "); return t end
local function unesc(s) return ((s or ""):gsub("\\n","\n")) end

local function serialize_rows()
 local t={}
 for _,s in ipairs(rows) do
  t[#t+1]=string.format("%.6f\t%.6f\t%s\t%s\t%d\t%d\t%s\t%s\t%s\t%s",s.start,s.finish,esc(s.text),esc(s.role),s.done and 1 or 0,s.mark and 1 or 0,esc(s.note),esc(s.orig),s.take and string.format("%.6f",s.take) or "",s.verdict or "")
 end
 return table.concat(t,"\n")
end

local function parse_saved(raw)
 local out={}
 for line in ((raw or "").."\n"):gmatch("(.-)\n") do
  local f={}
  for part in (line.."\t"):gmatch("(.-)\t") do f[#f+1]=part end
  local st,en=tonumber(f[1]),tonumber(f[2])
  if st and en and f[3] then
   out[#out+1]={start=st,finish=en,text=unesc(f[3]),role=f[4] or "",done=(f[5]=="1"),mark=(f[6]=="1"),note=unesc(f[7]),orig=unesc(f[8]),take=tonumber(f[9] or ""),verdict=((f[10] or "")~="" and f[10]) or nil}
  end
 end
 return out
end

local function save_role_duck()
 local t={}
 for r,db in pairs(role_duck) do t[#t+1]=r.."\t"..tostring(db) end
 reaper.SetProjExtState(0,SEC,"role_duck",table.concat(t,"\n"))
end

local function load_role_duck()
 role_duck={}
 local raw=extget("role_duck","")
 for line in (raw.."\n"):gmatch("(.-)\n") do
  local r,db=line:match("^(.-)\t(.+)$")
  if r and tonumber(db) then role_duck[r]=tonumber(db) end
 end
end

local function save()
 reaper.SetProjExtState(0,SEC,K.subs,serialize_rows())
 reaper.SetProjExtState(0,SEC,"subtitle_count",tostring(#rows))
 for key,val in pairs({duck=duck,pre=pre,post=post,fi=fi,fo=fo}) do reaper.SetProjExtState(0,SEC,K[key],tostring(val)) end
 reaper.SetProjExtState(0,SEC,"only_dub",only_dub and "1" or "0")
 reaper.SetProjExtState(0,SEC,"follow_play",follow and "1" or "0")
 reaper.SetProjExtState(0,SEC,"win_from_dub",win_from_dub and "1" or "0")
 reaper.SetProjExtState(0,SEC,"preroll",tostring(preroll))
 reaper.SetProjExtState(0,SEC,"tc_frames",frames_mode and "1" or "0")
 reaper.SetProjExtState(0,SEC,"qc_cps",tostring(qc_cps)); reaper.SetProjExtState(0,SEC,"qc_gap",tostring(qc_gap)); reaper.SetProjExtState(0,SEC,"qc_short",tostring(qc_short))
 save_role_duck()
 wins_dirty=true
end

local function load_saved()
 local _,raw=reaper.GetProjExtState(0,SEC,K.subs)
 rows=parse_saved(raw)
 duck=tonumber(extget(K.duck,"25")) or 25; pre=tonumber(extget(K.pre,"100")) or 100; post=tonumber(extget(K.post,"150")) or 150
 fi=tonumber(extget(K.fi,"120")) or 120; fo=tonumber(extget(K.fo,"220")) or 220
 only_dub=(extget("only_dub","0")=="1"); follow=(extget("follow_play","1")=="1")
 win_from_dub=(extget("win_from_dub","0")=="1"); preroll=tonumber(extget("preroll","3")) or 3
 frames_mode=(extget("tc_frames","0")=="1")
 qc_cps=tonumber(extget("qc_cps","20")) or 20; qc_gap=tonumber(extget("qc_gap","0.08")) or 0.08; qc_short=tonumber(extget("qc_short","1.0")) or 1.0
 load_role_duck()
end

-- ---------- undo ----------
local function push_undo()
 local c={}
 for i,s in ipairs(rows) do c[i]={start=s.start,finish=s.finish,text=s.text,role=s.role,done=s.done,note=s.note,mark=s.mark,orig=s.orig,take=s.take,verdict=s.verdict} end
 undo_stack[#undo_stack+1]={rows=c,selected=selected}
 if #undo_stack>30 then table.remove(undo_stack,1) end
end

local function undo()
 local u=table.remove(undo_stack)
 if not u then status="Нечего отменять"; return end
 rows=u.rows; selected=math.max(1,math.min(u.selected,#rows))
 save(); mark_dirty(); status="Отменено"
end

-- ---------- import ----------
-- loads a subtitle file as the translation (used by the file dialog and by "Из видео")
local function load_subs_path(path,from_note)
 local list=read_subs_file(path)
 if not list then status="Не удалось открыть файл"; return end
 push_undo()
 rows=list; selected=1; scroll=0
 search=""; role_filter=""; search_focus=false
 reaper.SetProjExtState(0,SEC,K.source,path); save(); mark_dirty()
 if #rows==0 then status="Субтитры не найдены ("..(last_sub_hint or "")..")"
 else status=(from_note or "Импортировано реплик")..": "..#rows..(#roles>0 and (", ролей: "..#roles) or "") end
end

local function import_orig()
 if #rows==0 then status="Сначала импортируй субтитры (перевод)"; return end
 local ok,path=reaper.GetUserFileNameForRead("","Оригинальные субтитры (SRT / ASS / SSA / TXT)","")
 if not ok then return end
 local list=read_subs_file(path)
 if not list or #list==0 then status="Оригинал не прочитан"; return end
 push_undo()
 local n=0
 for _,s in ipairs(rows) do
  local best,bo
  for _,o in ipairs(list) do
   local ov=math.min(o.finish,s.finish)-math.max(o.start,s.start)
   if ov>0 and (not bo or ov>bo) then best,bo=o,ov end
   if o.start>s.finish then break end
  end
  if best then s.orig=(best.text:gsub("\n"," ")); n=n+1 end
 end
 save(); mark_dirty(); status="Оригинал привязан к "..n.." репликам"
end

-- ---------- tracks / dub items ----------
local function track_guid(tr) if not tr then return "" end; local _,g=reaper.GetSetMediaTrackInfo_String(tr,"GUID","",false); return g end
local function find_track(g) if g=="" then return nil end; for i=0,reaper.CountTracks(0)-1 do local t=reaper.GetTrack(0,i); if track_guid(t)==g then return t end end end
local function track_name(tr) local _,n=reaper.GetSetMediaTrackInfo_String(tr,"P_NAME","",false); if n=="" then n="Track" end; return n end

local function orig_tracks()
 local out={}
 for g in extget(K.orig,""):gmatch("[^,]+") do
  local t=find_track(g)
  if t then out[#out+1]={tr=t,guid=g} end
 end
 return out
end

local function set_track(which)
 local n=reaper.CountSelectedTracks(0)
 if n==0 then status="Сначала выдели аудиодорожку"; return end
 if which=="orig" then
  local g={}
  for i=0,n-1 do g[#g+1]=track_guid(reaper.GetSelectedTrack(0,i)) end
  reaper.SetProjExtState(0,SEC,K.orig,table.concat(g,","))
  status="Оригинал: дорожек "..n
 else
  local tr=reaper.GetSelectedTrack(0,0)
  reaper.SetProjExtState(0,SEC,K.dub,track_guid(tr))
  status="Дубляж: "..track_name(tr)
 end
 wins_dirty=true; dub_time=-10
end

-- sorted list of {start,end} for the items of the dub track
local function load_dub_items()
 local tr=find_track(extget(K.dub,""))
 local iv={}
 if not tr then return iv end
 for i=0,reaper.CountTrackMediaItems(tr)-1 do
  local it=reaper.GetTrackMediaItem(tr,i)
  local p=reaper.GetMediaItemInfo_Value(it,"D_POSITION")
  iv[#iv+1]={p,p+reaper.GetMediaItemInfo_Value(it,"D_LENGTH")}
 end
 table.sort(iv,function(a,b) return a[1]<b[1] end)
 return iv
end

local function dub_items_cached()
 local now=reaper.time_precise()
 if now-dub_time>2 then dub_cache=load_dub_items(); dub_time=now end
 return dub_cache
end

-- takes count + overrun (seconds the recording runs past the end of the line)
local function row_takes(s,items)
 local n,maxend=0,nil
 for _,it in ipairs(items) do
  if it[1]>=s.finish then break end
  if it[2]>s.start then n=n+1; if not maxend or it[2]>maxend then maxend=it[2] end end
 end
 local over=0
 if maxend then over=maxend-s.finish end
 return n,over
end

-- ---------- ducking ----------
local function row_db(s) return role_duck[s.role or ""] or duck end

-- build duck windows, merging ones whose ramps would overlap; each window keeps the deepest dB of its lines
local function compute_wins()
 local intervals={}
 if win_from_dub then
  for _,it in ipairs(load_dub_items()) do intervals[#intervals+1]={start=it[1],finish=it[2],db=duck} end
 else
  local items=only_dub and load_dub_items() or nil
  if items and #items==0 then items=nil end
  for _,s in ipairs(rows) do
   if (not items) or row_takes(s,items)>0 then intervals[#intervals+1]={start=s.start,finish=s.finish,db=row_db(s)} end
  end
 end
 local wins={}
 for _,s in ipairs(intervals) do
  local ds=math.max(0,s.start-pre/1000)
  local hold_end=s.finish+post/1000
  local w=wins[#wins]
  if w and ds<=w.hold_end+fo/1000 then
   if hold_end>w.hold_end then w.hold_end=hold_end end
   if s.db>w.db then w.db=s.db end
  else wins[#wins+1]={ds=ds,hold_end=hold_end,db=s.db} end
 end
 return wins
end

local function get_wins()
 local now=reaper.time_precise()
 if wins_dirty or now-wins_time>2 then wins_cache=compute_wins(); wins_time=now; wins_dirty=false end
 return wins_cache
end

local function generate_duck()
 if #rows==0 and not win_from_dub then status="Сначала импортируй субтитры"; return end
 local ot=orig_tracks()
 if #ot==0 then
  local n=reaper.CountSelectedTracks(0)
  if n==0 then status="Выдели оригинальные дорожки и нажми «Назначить оригинал»"; return end
  local g={}
  for i=0,n-1 do g[#g+1]=track_guid(reaper.GetSelectedTrack(0,i)) end
  reaper.SetProjExtState(0,SEC,K.orig,table.concat(g,","))
  ot=orig_tracks()
 end
 local wins=compute_wins()
 if #wins==0 then status="Нет окон приглушения: на дорожке дубляжа нет звука под репликами"; return end
 local yes=reaper.ShowMessageBox("Создать огибающую приглушения на дорожках: "..#ot..", окон: "..#wins.."?\n\nВНИМАНИЕ: текущие точки Volume будут заменены.","Dubbing Prompter",1)
 if yes~=1 then return end
 reaper.Undo_BeginBlock()
 local done=0
 for _,o in ipairs(ot) do
  local env=reaper.GetTrackEnvelopeByName(o.tr,"Volume")
  if not env then
   reaper.SetOnlyTrackSelected(o.tr); reaper.Main_OnCommand(40406,0); env=reaper.GetTrackEnvelopeByName(o.tr,"Volume")
  end
  if env then
   -- Volume envelope may use fader scaling: convert linear gain to the envelope's own value range
   local mode=reaper.GetEnvelopeScalingMode(env)
   local top=reaper.ScaleToEnvelopeMode(mode,1)
   local override=tonumber(extget("odb_"..o.guid,""))
   reaper.DeleteEnvelopePointRange(env,-1e9,1e9)
   if wins[1].ds>0 then reaper.InsertEnvelopePoint(env,0,top,0,0,false,true) end
   for _,w in ipairs(wins) do
    local floorv=reaper.ScaleToEnvelopeMode(mode,10^(-(override or w.db)/20))
    local down_end=math.min(w.ds+fi/1000,w.hold_end)
    reaper.InsertEnvelopePoint(env,w.ds,top,0,0,false,true)
    reaper.InsertEnvelopePoint(env,down_end,floorv,0,0,false,true)
    reaper.InsertEnvelopePoint(env,w.hold_end,floorv,0,0,false,true)
    reaper.InsertEnvelopePoint(env,w.hold_end+fo/1000,top,0,0,false,true)
   end
   reaper.Envelope_SortPoints(env); done=done+1
  end
 end
 reaper.UpdateArrange(); reaper.Undo_EndBlock("Dubbing System: generate ducking automation",-1)
 status="Автоматизация создана: дорожек "..done..", окон "..#wins
end

local function edit_settings()
 local def=string.format("%s,%s,%s,%s,%s",duck,pre,post,fi,fo)
 local ok,res=reaper.GetUserInputs("Настройки ducking",5,"Приглушение (дБ),Перед репликой (мс),После реплики (мс),Плавное снижение (мс),Возврат громкости (мс)",def)
 if not ok then return end
 local v={}; for n in res:gmatch("[^,]+") do v[#v+1]=tonumber((n:gsub(",","."))) end
 if #v==5 and v[1] and v[2] and v[3] and v[4] and v[5] then
  duck=math.max(0,v[1]); pre=math.max(0,v[2]); post=math.max(0,v[3]); fi=math.max(0,v[4]); fo=math.max(0,v[5])
  save(); status="Настройки сохранены"
 else status="Неверные значения настроек" end
end

local function split_csv(s)
 local f={}
 for part in ((s or "")..","):gmatch("(.-),") do f[#f+1]=trim(part) end
 return f
end

local function edit_role_duck()
 if #roles==0 then status="В субтитрах нет ролей"; return end
 local n=math.min(#roles,16)
 local caps,defs={}, {}
 for i=1,n do caps[i]=roles[i]; defs[i]=role_duck[roles[i]] and tostring(role_duck[roles[i]]) or "" end
 local ok,res=reaper.GetUserInputs("Приглушение по ролям, дБ (пусто = общее "..duck..")",n,table.concat(caps,","),table.concat(defs,","))
 if not ok then return end
 local f=split_csv(res)
 for i=1,n do
  local v=tonumber(((f[i] or ""):gsub(",",".")))
  role_duck[roles[i]]=(v and v>=0) and v or nil
 end
 save(); status="Глубина по ролям сохранена"
end

local function edit_track_duck()
 local ot=orig_tracks()
 if #ot==0 then status="Сначала назначь оригинальные дорожки"; return end
 local n=math.min(#ot,16)
 local caps,defs={}, {}
 for i=1,n do caps[i]=clean_name(track_name(ot[i].tr)); defs[i]=extget("odb_"..ot[i].guid,"") end
 local ok,res=reaper.GetUserInputs("Приглушение по дорожкам, дБ (пусто = по окну)",n,table.concat(caps,","),table.concat(defs,","))
 if not ok then return end
 local f=split_csv(res)
 for i=1,n do
  local v=tonumber(((f[i] or ""):gsub(",",".")))
  reaper.SetProjExtState(0,SEC,"odb_"..ot[i].guid,v and tostring(v) or "")
 end
 status="Глубина по дорожкам сохранена"
end

-- ---------- overlay ----------
local function launch_overlay()
 local dirs={reaper.GetResourcePath().."/Scripts/DubbingSystem/"}
 local sp=({reaper.get_action_context()})[2]
 if sp then local d=sp:match("^(.*[/\\])"); if d then table.insert(dirs,1,d) end end
 for _,d in ipairs(dirs) do
  local path=d.."Dubbing_SubOverlay.lua"
  local f=io.open(path,"r")
  if f then
   f:close(); save()
   -- run the overlay as its own action so it keeps working after Prompter is closed
   local cmd=reaper.AddRemoveReaScript(true,0,path,true)
   if cmd and cmd>0 then
    reaper.Main_OnCommand(cmd,0)
    status="Оверлей: запуск / выключение (если REAPER спросит — выбери Terminate)"
   else status="Не удалось зарегистрировать оверлей как действие" end
   return
  end
 end
 status="Помести Dubbing_SubOverlay.lua рядом с Prompter или в Scripts/DubbingSystem"
end

-- restore: close any running overlay, reset its saved settings to defaults and start it again
local OV_CFG="DubbingSubOverlayV2"
local OV_KEYS={"attach","mode","offset","h","size","bold","bg","title","font","color","role_color","show_role",
 "show_next","progress","countdown","autofit","role_filter","karaoke","outline","multi"}
local function restore_overlay()
 for _,k in ipairs(OV_KEYS) do reaper.DeleteExtState(OV_CFG,k,false) end
 local running=false
 local hb=tonumber(reaper.GetExtState(OV_CFG,"hb") or "")
 if hb and reaper.time_precise()-hb<1.0 then running=true; reaper.SetExtState(OV_CFG,"quit","1",false) end
 if running then
  -- wait for the old instance to notice the quit flag and exit, then launch a fresh one
  ov_restore_at=reaper.time_precise()+1.5
  status="Оверлей перезапускается с настройками по умолчанию…"
 else
  reaper.DeleteExtState(OV_CFG,"quit",false)
  launch_overlay()
  status="Оверлей восстановлен с настройками по умолчанию"
 end
end

-- ---------- selection / navigation ----------
local ROWH,VISIBLE=48,6

local function goto_row(i)
 if rows[i] then selected=i; reaper.SetEditCurPos(rows[i].start,true,true) end
end

local function vpos_of(idx) for i,v in ipairs(vis) do if v==idx then return i end end; return 0 end

local function show_row(idx)
 local vp=vpos_of(idx)
 if vp==0 then return end
 if vp-1<scroll then scroll=vp-1 elseif vp>scroll+VISIBLE then scroll=vp-VISIBLE end
end

local function move_sel(d)
 if #vis==0 then return end
 local vp=vpos_of(selected)
 local nv
 if vp==0 then nv=(d>0) and 1 or #vis else nv=math.max(1,math.min(#vis,vp+d)) end
 goto_row(vis[nv]); show_row(vis[nv])
end

local function row_at(pos)
 local lo,hi,idx=1,#rows,0
 while lo<=hi do
  local mid=(lo+hi)//2
  if rows[mid].start<=pos then idx=mid; lo=mid+1 else hi=mid-1 end
 end
 for i=idx,math.max(1,idx-8),-1 do
  local s=rows[i]
  if s and pos<s.finish then return i end
 end
 return 0
end

-- ---------- editing ----------
local function commit_sorted(s)
 table.sort(rows,function(a,b) return a.start<b.start end)
 for i,r in ipairs(rows) do if r==s then selected=i; break end end
 save(); mark_dirty()
end

local function edit_time()
 local s=rows[selected]; if not s then status="Выбери реплику"; return end
 local role=clean_name(s.role)
 local ok,res=reaper.GetUserInputs("Время и роль",3,"Начало (ЧЧ:ММ:СС.ммм),Конец (ЧЧ:ММ:СС.ммм),Роль",ftime(s.start)..","..ftime(s.finish)..","..role)
 if not ok then return end
 local a,b,r=res:match("^([^,]*),([^,]*),?(.*)$")
 if not a then status="Неверный формат"; return end
 local function pt(x)
  x=trim(x)
  local a,b,c,d=x:match("^(%d+):(%d%d):(%d%d):(%d%d)$")
  if a then return (tonumber(a)*3600+tonumber(b)*60+tonumber(c))+tonumber(d)/fps_now() end
  return tc(x) or tonumber(x)
 end
 local st,en=pt(a),pt(b)
 if not st or not en or en<=st then status="Неверное время (конец должен быть позже начала)"; return end
 push_undo(); s.start,s.finish,s.role=st,en,clean_name(r)
 commit_sorted(s); status="Время и роль изменены"
end

local function begin_edit(target)
 local s=rows[selected]; if not s then status="Выбери реплику"; return end
 edit_target=target or "text"
 edit_mode=true; edit_buf=(edit_target=="note") and (s.note or "") or s.text; search_focus=false
end

local function end_edit(do_save)
 if do_save then
  local s=rows[selected]; local t=trim(edit_buf)
  if s and edit_target=="note" then push_undo(); s.note=t; save(); mark_dirty(); status=(t=="") and "Заметка удалена" or "Заметка сохранена"
  elseif s and t~="" then push_undo(); s.text=t; save(); mark_dirty(); status="Текст изменён"
  else status="Пустой текст не сохранён" end
 else status="Правка отменена" end
 edit_mode=false
end

local function split_row()
 local s=rows[selected]; if not s then status="Выбери реплику"; return end
 local text=(s.text:gsub("\n"," "))
 local mid=#text/2
 local best,bd
 for p in text:gmatch("()%s") do local d=math.abs(p-mid); if not bd or d<bd then best,bd=p,d end end
 if not best then status="В реплике нет пробелов — разбивать нечего"; return end
 local a,b=trim(text:sub(1,best-1)),trim(text:sub(best+1))
 if a=="" or b=="" then status="Не получилось разбить реплику"; return end
 push_undo()
 local t=s.start+(s.finish-s.start)*(#a/(#a+#b))
 local new={start=t,finish=s.finish,text=b,role=s.role,done=false,note="",mark=false,orig=""}
 s.text=a; s.finish=t
 table.insert(rows,selected+1,new)
 save(); mark_dirty(); status="Реплика разбита"
end

local function merge_row()
 local s,n=rows[selected],rows[selected+1]
 if not s or not n then status="Нет следующей реплики"; return end
 push_undo()
 s.text=s.text.." "..n.text; s.finish=math.max(s.finish,n.finish)
 if n.note~="" then s.note=(s.note~="" and (s.note.." / ") or "")..n.note end
 s.done=s.done and n.done
 table.remove(rows,selected+1)
 save(); mark_dirty(); status="Реплики склеены"
end

local function delete_row()
 if not rows[selected] then return end
 push_undo(); table.remove(rows,selected)
 selected=math.max(1,math.min(selected,#rows))
 save(); mark_dirty(); status="Реплика удалена (Ctrl+Z — вернуть)"
end

-- session journal: plain text file next to REAPER resources, one line per action
local function log_event(msg)
 local f=io.open(reaper.GetResourcePath().."/DubbingSystem_log.txt","a")
 if f then f:write(os.date("%Y-%m-%d %H:%M:%S").."  "..msg.."\n"); f:close() end
end

local function toggle_done(i)
 local idx=i or selected
 local s=rows[idx]; if not s then return end
 s.done=not s.done; save()
 log_event("№"..idx.." "..(s.role~="" and s.role or "-").." "..(s.done and "записано" or "отметка снята"))
 status=s.done and "Записано" or "Отметка снята"
end

local function toggle_mark()
 local s=rows[selected]; if not s then return end
 s.mark=not s.mark; save(); status=s.mark and "Закладка поставлена" or "Закладка снята"
end

local function next_mark()
 if #rows==0 then return end
 for k=1,#rows do
  local i=((selected-1+k)%#rows)+1
  if rows[i].mark then goto_row(i); show_row(i); status="Закладка: реплика №"..i; return end
 end
 status="Закладок нет"
end

-- play the selected line with a pre-roll; loop = repeat [line-preroll .. line+post]
local function play_line(do_loop)
 local s=rows[selected]; if not s then status="Выбери реплику"; return end
 local start=math.max(0,s.start-preroll)
 if do_loop then
  if loop_active then
   loop_active=false
   if reaper.GetToggleCommandState(1068)==1 then reaper.Main_OnCommand(1068,0) end
   status="Цикл реплики выключен"; return
  end
  reaper.GetSet_LoopTimeRange(true,true,start,s.finish+post/1000,false)
  if reaper.GetToggleCommandState(1068)~=1 then reaper.Main_OnCommand(1068,0) end
  loop_active=true
  status="Цикл реплики включён (L — выключить)"
 else
  status="Воспроизведение реплики с пре-роллом "..preroll.." с"
 end
 reaper.SetEditCurPos(start,true,true)
 if (reaper.GetPlayState()&1)~=1 then reaper.OnPlayButton() end
end

local function fit_to_takes(all)
 local items=load_dub_items()
 if #items==0 then status="На дорожке дубляжа нет итемов (назначь дубляж)"; return end
 -- every take is claimed by the ONE line it overlaps most; a line then uses its longest claimed take
 local claimed={}
 for _,it in ipairs(items) do
  local brow,bo
  for _,s in ipairs(rows) do
   if s.start>=it[2] then break end
   local ov=math.min(it[2],s.finish)-math.max(it[1],s.start)
   if ov>0 and (not bo or ov>bo) then brow,bo=s,ov end
  end
  if brow then
   local cur=claimed[brow]
   if not cur or (it[2]-it[1])>(cur[2]-cur[1]) then claimed[brow]=it end
  end
 end
 local function best(s) return claimed[s] end
 local targets={}
 if all then
  if reaper.ShowMessageBox("Подогнать тайминг ВСЕХ реплик под записи на дорожке дубляжа?\n(по итему с наибольшим пересечением; Ctrl+Z вернёт)","Dubbing Prompter",1)~=1 then return end
  for _,s in ipairs(rows) do targets[#targets+1]=s end
 else
  local s=rows[selected]; if not s then status="Выбери реплику"; return end
  targets[1]=s
 end
 push_undo()
 local n=0
 for _,s in ipairs(targets) do
  local it=best(s)
  if it and it[2]>it[1] then s.start,s.finish=it[1],it[2]; n=n+1 end
 end
 if n==0 then table.remove(undo_stack); status="Записей под репликами не найдено"; return end
 local keep=rows[selected]
 commit_sorted(keep); status="Подогнано реплик: "..n
end

-- ---------- menus / dialogs ----------
local function popup(items)
 gfx.x,gfx.y=gfx.mouse_x,gfx.mouse_y
 return gfx.showmenu(table.concat(items,"|"))
end

local function shift_time()
 if #rows==0 then return end
 local scope=popup({"Все реплики","Только роль выбранной реплики","Выбранная и все после неё"})
 if scope==0 then return end
 local ok,res=reaper.GetUserInputs("Сдвиг времени",1,"Секунд (например 0.5 или -1)","0")
 if not ok then return end
 local d=tonumber((res:gsub(",",".")))
 if not d or d==0 then status="Неверное значение сдвига"; return end
 local role=rows[selected] and rows[selected].role or ""
 push_undo()
 local n=0
 for i,s in ipairs(rows) do
  local hit=(scope==1) or (scope==2 and (s.role or "")==role) or (scope==3 and i>=selected)
  if hit then s.start=math.max(0,s.start+d); s.finish=math.max(s.start+0.05,s.finish+d); n=n+1 end
 end
 commit_sorted(rows[selected]); status="Сдвинуто реплик: "..n.." на "..d.." с"
end

local function plain_gsub(s,find,rep)
 local fe=find:gsub("%p","%%%0")
 local re=rep:gsub("%%","%%%%")
 return s:gsub(fe,re)
end

local function replace_text()
 if #rows==0 then return end
 local ok,find=reaper.GetUserInputs("Глобальная замена",1,"Найти (с учётом регистра)","")
 if not ok or find=="" then return end
 local ok2,rep=reaper.GetUserInputs("Глобальная замена",1,"Заменить на ("..short(find,20)..")","")
 if not ok2 then return end
 push_undo()
 local n=0
 for _,s in ipairs(rows) do
  local new,c=plain_gsub(s.text,find,rep)
  if c>0 then s.text=new; n=n+c end
 end
 if n==0 then table.remove(undo_stack); status="Не найдено: "..find; return end
 save(); mark_dirty(); status="Замен: "..n
end

local function rename_role()
 if #roles==0 then status="В субтитрах нет ролей"; return end
 local items={}
 for i,r in ipairs(roles) do items[i]=r end
 local idx=popup(items)
 if idx==0 or not roles[idx] then return end
 local old=roles[idx]
 local ok,new=reaper.GetUserInputs("Переименовать роль",1,"Новое имя для «"..old.."»",old)
 new=clean_name(new)
 if not ok or new=="" or new==old then return end
 push_undo()
 for _,s in ipairs(rows) do if s.role==old then s.role=new end end
 if role_duck[old] then role_duck[new]=role_duck[old]; role_duck[old]=nil end
 if role_filter==old then role_filter=new end
 save(); mark_dirty(); status="Роль переименована: "..old.." → "..new
end

local function reset_done()
 if reaper.ShowMessageBox("Снять отметки «записано» со всех реплик?","Dubbing Prompter",1)~=1 then return end
 push_undo()
 for _,s in ipairs(rows) do s.done=false end
 save(); status="Отметки сняты"
end

local function set_preroll()
 local ok,res=reaper.GetUserInputs("Пре-ролл",1,"Секунд до реплики",tostring(preroll))
 if not ok then return end
 local v=tonumber((res:gsub(",",".")))
 if not v or v<0 or v>60 then status="Неверное значение пре-ролла"; return end
 preroll=v; save(); status="Пре-ролл: "..v.." с"
end

-- ---------- export / conversion ----------
local function srt_time(t)
 local ms=math.floor(t*1000+0.5)
 local h=ms//3600000; ms=ms%3600000
 local m=ms//60000; ms=ms%60000
 local s=ms//1000; ms=ms%1000
 return string.format("%02d:%02d:%02d,%03d",h,m,s,ms)
end

local function out_dir_base()
 local src=extget(K.source,"")
 local dir,base=src:match("^(.*[/\\])([^/\\]+)%.[^%.]+$")
 if not dir then
  local ok,pp=pcall(reaper.GetProjectPath,"")
  dir=((ok and pp) or "").."/"; base="Dubbing"
 end
 return dir,base
end

local function write_srt(path,list)
 local f=io.open(path,"wb"); if not f then return false end
 local out={}
 for i,s in ipairs(list) do out[#out+1]=i.."\n"..srt_time(s.start).." --> "..srt_time(s.finish).."\n"..s.text.."\n" end
 f:write(table.concat(out,"\n")); f:close()
 return true
end

local function export_srt()
 if #rows==0 then status="Нечего экспортировать"; return end
 local dir,base=out_dir_base()
 local path=dir..base.."_edited.srt"
 if write_srt(path,rows) then status="SRT сохранён: "..path else status="Не удалось записать: "..path end
end

local function export_srt_roles()
 if #roles==0 then status="В субтитрах нет ролей"; return end
 local dir,base=out_dir_base()
 local n=0
 for _,r in ipairs(roles) do
  local list={}
  for _,s in ipairs(rows) do if s.role==r then list[#list+1]=s end end
  local fname=(r:gsub("[/\\:*?\"<>|]","_"))
  if write_srt(dir..base.."_"..fname..".srt",list) then n=n+1 end
 end
 status="SRT по ролям: файлов "..n.." (в папке "..dir..")"
end

-- ---------- takes: best take, QC report, script per role, dub shift ----------
-- dub items overlapping a line, sorted by start (with item handles)
local function dub_takes_of_row(s)
 local out={}
 local tr=find_track(extget(K.dub,""))
 if not tr or not s then return out end
 for i=0,reaper.CountTrackMediaItems(tr)-1 do
  local it=reaper.GetTrackMediaItem(tr,i)
  local p=reaper.GetMediaItemInfo_Value(it,"D_POSITION")
  local e=p+reaper.GetMediaItemInfo_Value(it,"D_LENGTH")
  if p<s.finish and e>s.start then out[#out+1]={item=it,pos=p} end
 end
 table.sort(out,function(a,b) return a.pos<b.pos end)
 return out
end

-- cycle: no best take -> take 1 -> take 2 ... -> no best take.
-- the chosen take stays audible, the others of this line are muted (cycling back to "none" unmutes all)
local function cycle_best_take()
 local s=rows[selected]; if not s then status="Выбери реплику"; return end
 local tk=dub_takes_of_row(s)
 if #tk==0 then status="У реплики нет дублей на дорожке дубляжа"; return end
 local cur=0
 if s.take then for i,t in ipairs(tk) do if math.abs(t.pos-s.take)<0.0005 then cur=i end end end
 local nxt=cur+1
 if nxt>#tk then nxt=0 end
 for i,t in ipairs(tk) do
  reaper.SetMediaItemInfo_Value(t.item,"B_MUTE",(i==nxt) and 0 or ((nxt==0) and 0 or 1))
 end
 reaper.UpdateArrange()
 if nxt==0 then s.take=nil; status="Лучший дубль не выбран (все дубли звучат)"
 else s.take=tk[nxt].pos; status="Лучший дубль: "..nxt.." из "..#tk.." (остальные заглушены)" end
 save(); wins_dirty=true; dub_time=-10
 log_event("№"..selected.." лучший дубль: "..(nxt==0 and "нет" or (nxt.." из "..#tk)))
end

-- QC report: speed, pauses, missing takes, overrun, per-role progress -> text file + summary box
local function qc_report()
 if #rows==0 then status="Нечего проверять"; return end
 local items=load_dub_items()
 local L={}
 local nfast,nshort,ngap,nover,nno=0,0,0,0,0
 for i,s in ipairs(rows) do
  local dur=s.finish-s.start
  local n=ulen((s.text:gsub("\n","")))
  local cps=n/math.max(dur,0.05)
  if cps>=qc_cps then nfast=nfast+1; L[#L+1]=string.format("№%03d  скорость %.0f зн/с  %s",i,cps,short(s.text,50)) end
  if dur<qc_short then nshort=nshort+1; L[#L+1]=string.format("№%03d  короткая реплика %.2f с",i,dur) end
  local nx=rows[i+1]
  if nx then
   local gap=nx.start-s.finish
   if gap<qc_gap then ngap=ngap+1; L[#L+1]=string.format("№%03d-%03d  пауза %.2f с%s",i,i+1,gap,gap<0 and " (перекрытие)" or "") end
  end
  local tk,over=row_takes(s,items)
  if tk==0 and not s.done then nno=nno+1 end
  if tk>0 and over>0.25 then nover=nover+1; L[#L+1]=string.format("№%03d  дубль длиннее реплики на %.1f с",i,over) end
 end
 local head={"ПРОВЕРКА (QC) — "..os.date("%Y-%m-%d %H:%M"),
  "Реплик: "..#rows.."  скорость ≥"..qc_cps.." зн/с: "..nfast.."  короткие: "..nshort.."  пауза <"..qc_gap.." с: "..ngap..
  "  дубль длиннее: "..nover.."  без дубля (не записано): "..nno,""}
 for _,r in ipairs(roles) do
  local d,t=0,0
  for _,s in ipairs(rows) do if s.role==r then t=t+1; if s.done then d=d+1 end end end
  head[#head+1]="Роль "..r..": записано "..d.." из "..t
 end
 head[#head+1]=""
 local text=table.concat(head,"\n").."\n"..table.concat(L,"\n").."\n"
 local dir,base=out_dir_base()
 local path=dir..base.."_QC.txt"
 local f=io.open(path,"wb")
 if f then f:write(text); f:close() end
 local shown={}
 for i=1,math.min(#head,8) do shown[#shown+1]=head[i] end
 reaper.ShowMessageBox(table.concat(shown,"\n").."\n\nПолный отчёт: "..path,"Dubbing Prompter — QC",0)
 log_event("QC: скорость "..nfast..", пауза "..ngap..", без дубля "..nno)
 status="Отчёт QC сохранён: "..path
end

-- one text script per role: number, timing, text, note
local function export_role_scripts()
 if #roles==0 then status="В субтитрах нет ролей"; return end
 local dir,base=out_dir_base()
 local n=0
 for _,r in ipairs(roles) do
  local out={"СЦЕНАРИЙ — "..r.."  ("..base..")",""}
  for i,s in ipairs(rows) do
   if s.role==r then
    out[#out+1]=string.format("№%03d  %s – %s  (%.1f с)%s",i,fmt(s.start),fmt(s.finish),s.finish-s.start,s.done and "  [записано]" or "")
    out[#out+1]=s.text
    if (s.orig or "")~="" then out[#out+1]="  оригинал: "..(s.orig:gsub("\n"," ")) end
    if (s.note or "")~="" then out[#out+1]="  заметка: "..(s.note:gsub("\n"," ")) end
    out[#out+1]=""
   end
  end
  local fname=(r:gsub("[/\\:*?\"<>|]","_"))
  local f=io.open(dir..base.."_"..fname.."_сценарий.txt","wb")
  if f then f:write(table.concat(out,"\n")); f:close(); n=n+1 end
 end
 log_event("Сценарии по ролям: "..n)
 status="Сценарии по ролям: файлов "..n.." (в папке "..dir..")"
end

-- move the dub takes of the selected line by N frames (project frame rate)
local function shift_dub_takes()
 local s=rows[selected]; if not s then status="Выбери реплику"; return end
 local tk=dub_takes_of_row(s)
 if #tk==0 then status="У реплики нет дублей на дорожке дубляжа"; return end
 local ok,res=reaper.GetUserInputs("Сдвиг дублей",1,"Кадров (например 2 или -3)","0")
 if not ok then return end
 local frames=tonumber((res:gsub(",",".")))
 if not frames or frames==0 then status="Неверное число кадров"; return end
 local okf,fps=pcall(function() return (reaper.TimeMap_curFrameRate(0)) end)
 if not okf or not fps or fps<=0 then fps=25 end
 local d=frames/fps
 for _,t in ipairs(tk) do reaper.SetMediaItemInfo_Value(t.item,"D_POSITION",math.max(0,t.pos+d)) end
 if s.take then s.take=s.take+d end
 reaper.UpdateArrange(); save(); wins_dirty=true; dub_time=-10
 log_event("№"..selected.." дубли сдвинуты на "..frames.." кадр.")
 status="Дубли сдвинуты на "..frames.." кадр. ("..string.format("%.3f",d).." с)"
end

-- mark lines as recorded when a take exists on the dub track (only sets, never clears)
local function mark_recorded_from_dub()
 if #rows==0 then status="Нет реплик"; return end
 local items=load_dub_items()
 push_undo()
 local n=0
 for _,s in ipairs(rows) do
  if not s.done then
   local c=row_takes(s,items)
   if c>0 then s.done=true; n=n+1 end
  end
 end
 if n==0 then table.remove(undo_stack); status="Новых записей на дорожке дубляжа не найдено"; return end
 save(); mark_dirty(); log_event("Авто-отметка записанных по дорожке дубляжа: "..n)
 status="Отмечено как записанные: "..n.." (Ctrl+Z отменит)"
end

-- peak and RMS of one take via an audio accessor (16 kHz mono)
local function take_levels(item)
 local take=reaper.GetActiveTake(item)
 if not take then return nil end
 local acc=reaper.CreateTakeAudioAccessor(take)
 if not acc then return nil end
 local SR,BLK=16000,4096
 local peak,sumsq,cnt=0,0,0
 local st,en=reaper.GetAudioAccessorStartTime(acc),reaper.GetAudioAccessorEndTime(acc)
 local buf=reaper.new_array(BLK)
 local t=st
 while t<en do
  buf.clear()
  reaper.GetAudioAccessorSamples(acc,SR,1,t,BLK,buf)
  local arr=buf.table(1,BLK)
  for i=1,BLK do
   local v=arr[i] or 0
   local a=v<0 and -v or v
   if a>peak then peak=a end
   sumsq=sumsq+v*v
  end
  cnt=cnt+BLK
  t=t+BLK/SR
 end
 reaper.DestroyAudioAccessor(acc)
 return peak, (cnt>0 and math.sqrt(sumsq/cnt) or 0)
end

-- RMS in dB of a take between two take-relative times (room tone check)
local function take_rms_db(item, from, to)
 local take=reaper.GetActiveTake(item)
 if not take then return nil end
 local acc=reaper.CreateTakeAudioAccessor(take)
 if not acc then return nil end
 local SR,BLK=16000,1024
 local st,en=reaper.GetAudioAccessorStartTime(acc),reaper.GetAudioAccessorEndTime(acc)
 local t0,t1=math.max(st,from),math.min(en,to)
 local sumsq,cnt=0,0
 local buf=reaper.new_array(BLK)
 local t=t0
 while t<t1 do
  buf.clear()
  reaper.GetAudioAccessorSamples(acc,SR,1,t,BLK,buf)
  local arr=buf.table(1,BLK)
  for i=1,BLK do local v=arr[i] or 0; sumsq=sumsq+v*v end
  cnt=cnt+BLK; t=t+BLK/SR
 end
 reaper.DestroyAudioAccessor(acc)
 if cnt==0 then return nil end
 local rms=math.sqrt(sumsq/cnt)
 return rms>0 and 20*math.log(rms,10) or -150
end

-- check every take on the dub track: clipping, too quiet; report with the line number
local function check_take_levels()
 if not reaper.new_array or not reaper.CreateTakeAudioAccessor then
  status="Проверка громкости нужна REAPER 6.x или новее"; return
 end
 local tr=find_track(extget(K.dub,""))
 if not tr then status="Назначь дорожку дубляжа"; return end
 local L,nclip,nquiet,nok,nnoise={},0,0,0,0
 local cnt=reaper.CountTrackMediaItems(tr)
 for i=0,cnt-1 do
  local it=reaper.GetTrackMediaItem(tr,i)
  local p=reaper.GetMediaItemInfo_Value(it,"D_POSITION")
  local len=reaper.GetMediaItemInfo_Value(it,"D_LENGTH")
  local peak,rms=take_levels(it)
  if peak then
   local pdb=peak>0 and 20*math.log(peak,10) or -150
   local rdb=rms>0 and 20*math.log(rms,10) or -150
   local ndb=take_rms_db(it,0,0.3) or -150
   if ndb>-50 then nnoise=nnoise+1 end
   -- line this take belongs to (by its middle)
   local mid=p+len/2
   local no="—"
   for j,s in ipairs(rows) do if mid>=s.start and mid<s.finish then no=string.format("№%03d",j); break end end
   local flag=""
   if peak>=0.99 then nclip=nclip+1; flag="  КЛИППИНГ"
   elseif pdb<-30 then nquiet=nquiet+1; flag="  очень тихо" else nok=nok+1 end
   if ndb>-50 then flag=flag.."  ШУМ В ПАУЗЕ" end
   L[#L+1]=string.format("%s  %s  пик %.1f dBFS  RMS %.1f dBFS  шум %.1f dBFS  %.1f с%s",no,fmt(p),pdb,rdb,ndb,len,flag)
  end
 end
 local head={"ПРОВЕРКА ГРОМКОСТИ ДУБЛЕЙ — "..os.date("%Y-%m-%d %H:%M"),
  "Дублей: "..(nclip+nquiet+nok).."  клиппинг: "..nclip.."  очень тихо (<-30 dBFS): "..nquiet.."  шум в паузе (>-50 dBFS): "..nnoise,""}
 local text=table.concat(head,"\n").."\n"..table.concat(L,"\n").."\n"
 local dir,base=out_dir_base()
 local path=dir..base.."_Levels.txt"
 local f=io.open(path,"wb"); if f then f:write(text); f:close() end
 log_event("Громкость: дублей "..(nclip+nquiet+nok)..", клиппинг "..nclip..", тихо "..nquiet)
 reaper.ShowMessageBox(table.concat(head,"\n").."\n\nПолный отчёт: "..path,"Dubbing Prompter — громкость",0)
 status="Громкость проверена: клиппинг "..nclip..", тихо "..nquiet
end

-- level all dub takes to the median RMS (clamped to +-6 dB), via take volume
local function level_takes()
 if not reaper.new_array or not reaper.CreateTakeAudioAccessor then status="Выравнивание нужна REAPER 6.x или новее"; return end
 local tr=find_track(extget(K.dub,""))
 if not tr then status="Назначь дорожку дубляжа"; return end
 if reaper.ShowMessageBox("Выровнять громкость всех дублей под медиану (±6 дБ)?\nCtrl+Z в REAPER вернёт.","Dubbing Prompter",1)~=1 then return end
 local list={}
 for i=0,reaper.CountTrackMediaItems(tr)-1 do
  local it=reaper.GetTrackMediaItem(tr,i)
  local _,rms=take_levels(it)
  if rms and rms>0 then list[#list+1]={it=it,rms=rms} end
 end
 if #list<2 then status="Для выравнивания нужно хотя бы два дубля"; return end
 local sorted={}
 for _,e in ipairs(list) do sorted[#sorted+1]=e.rms end
 table.sort(sorted)
 local med=sorted[math.ceil(#sorted/2)]
 local lo,hi=10^(-6/20),10^(6/20)
 local changed=0
 for _,e in ipairs(list) do
  local g=med/e.rms
  if g<lo then g=lo elseif g>hi then g=hi end
  local cur=reaper.GetMediaItemInfo_Value(e.it,"D_VOL")
  if cur<=0 then cur=1 end
  reaper.SetMediaItemInfo_Value(e.it,"D_VOL",cur*g)
  changed=changed+1
 end
 reaper.UpdateArrange(); wins_dirty=true
 log_event("Выравнивание громкости дублей: "..changed)
 status="Громкость выровнена у дублей: "..changed.." (±6 дБ, Ctrl+Z в REAPER вернёт)"
end

-- per-role script as an HTML page: open it in a browser and print to PDF
local function hesc(x)
 x=tostring(x or "")
 x=(x:gsub("&","&amp;")); x=(x:gsub("<","&lt;")); x=(x:gsub(">","&gt;"))
 return x
end
local function export_role_html()
 if #roles==0 then status="В субтитрах нет ролей"; return end
 local dir,base=out_dir_base()
 local n=0
 for _,r in ipairs(roles) do
  local h={"<!doctype html><html lang='ru'><head><meta charset='utf-8'><title>"..hesc(r).."</title><style>",
   "body{font-family:Arial,sans-serif;margin:24px;color:#111}h1{font-size:20px}",
   "table{border-collapse:collapse;width:100%}td,th{border:1px solid #bbb;padding:6px;vertical-align:top;font-size:14px}",
   "th{background:#eee;text-align:left}.t{white-space:nowrap;font-family:monospace}.n{color:#666;font-size:12px}",
   "@media print{body{margin:10mm}}</style></head><body>",
   "<h1>Сценарий: "..hesc(r).."</h1><p class='n'>"..hesc(base).." · "..os.date("%Y-%m-%d").."</p>",
   "<table><tr><th>№</th><th>Тайминг</th><th>Текст</th><th>Записано</th></tr>"}
  for i,s in ipairs(rows) do
   if s.role==r then
    local note=((s.note or "")~="") and ("<div class='n'>✎ "..hesc(s.note).."</div>") or ""
    local orig=((s.orig or "")~="") and ("<div class='n'>оригинал: "..hesc(s.orig).."</div>") or ""
    h[#h+1]="<tr><td>"..string.format("%03d",i).."</td><td class='t'>"..ftime(s.start).."<br>"..ftime(s.finish).."</td><td>"..
     hesc(s.text):gsub("\n","<br>")..orig..note.."</td><td>"..(s.done and "✓" or "").."</td></tr>"
   end
  end
  h[#h+1]="</table></body></html>"
  local fname=(r:gsub("[/\\:*?\"<>|]","_"))
  local f=io.open(dir..base.."_"..fname.."_сценарий.html","wb")
  if f then f:write(table.concat(h,"\n")); f:close(); n=n+1 end
 end
 log_event("HTML-сценарии по ролям: "..n)
 status="HTML-сценарии: файлов "..n.." (открой в браузере и «Печать → Сохранить в PDF»)"
end

-- Excel-friendly CSV (UTF-8 with BOM, ';' separator, decimal comma): session sheet for the studio
local function export_session_csv()
 if #rows==0 then status="Нечего экспортировать"; return end
 local items=load_dub_items()
 local function num(x) return (string.format("%.2f",x):gsub("%.",",")) end
 local out={"\239\187\191№;Роль;Начало;Конец;Длительность, с;Зн/с;Текст;Записано;Дублей;Превышение, с;Заметка"}
 for i,s in ipairs(rows) do
  local dur=s.finish-s.start
  local cps=ulen((s.text:gsub("\n","")))/math.max(dur,0.05)
  local n,over=row_takes(s,items)
  local q=function(v) v=tostring(v or ""):gsub("[;\r\n]"," "); return v end
  out[#out+1]=table.concat({i,q(s.role),fmt(s.start),fmt(s.finish),num(dur),string.format("%.0f",cps),q(s.text),
    s.done and "да" or "нет",n,num(math.max(0,over)),q(s.note)},";")
 end
 local dir,base=out_dir_base()
 local path=dir..base.."_лист_сессии.csv"
 local f=io.open(path,"wb")
 if not f then status="Не удалось записать: "..path; return end
 f:write(table.concat(out,"\n").."\n"); f:close()
 log_event("Лист сессии (CSV): реплик "..#rows)
 status="Лист сессии сохранён: "..path
end

-- WebVTT export (opens in most editors and NLEs)
local function export_vtt()
 if #rows==0 then status="Нечего экспортировать"; return end
 local out={"WEBVTT",""}
 for i,s in ipairs(rows) do
  local r=(s.role or "")~="" and ("<v "..s.role..">") or ""
  local a=(srt_time(s.start):gsub(",","."))
  local b=(srt_time(s.finish):gsub(",","."))
  out[#out+1]=a.." --> "..b
  out[#out+1]=r..s.text
  out[#out+1]=""
 end
 local dir,base=out_dir_base()
 local path=dir..base..".vtt"
 local f=io.open(path,"wb")
 if not f then status="Не удалось записать: "..path; return end
 f:write(table.concat(out,"\n")); f:close()
 status="VTT сохранён: "..path
end

-- session summary: today's journal lines + current verdicts of the project
local function session_summary()
 local today=os.date("%Y-%m-%d")
 local rec,redo,verd=0,0,0
 local f=io.open(reaper.GetResourcePath().."/DubbingSystem_log.txt","r")
 if f then
  for line in f:lines() do
   if line:sub(1,10)==today then
    if line:find("записано",1,true) and not line:find("снята",1,true) then rec=rec+1 end
    if line:find("вызывной",1,true) or line:find("Вызывной",1,true) then verd=verd+1 end
   end
  end
  f:close()
 end
 local ok,nr,nc,nk,nd=0,0,0,0,0
 for _,s in ipairs(rows) do
  if s.verdict=="ok" then ok=ok+1 elseif s.verdict=="redo" then nr=nr+1 elseif s.verdict=="check" then nc=nc+1 end
  if s.done then nd=nd+1 end
 end
 local L={
  "СВОДКА ЗА "..today,"",
  "Сегодня отмечено записанным: "..rec,
  "Вызывных листов сделано сегодня: "..verd,"",
  "Всего реплик: "..#rows.."  записано: "..nd,
  "Оценки: ок "..ok.."  переписать "..nr.."  спорно "..nc,
 }
 reaper.ShowMessageBox(table.concat(L,"\n"),"Dubbing Prompter — сводка за день",0)
 status="Сводка за день показана"
end

-- actor summary: lines, recorded, remaining, duration and takes per role
local function actor_summary()
 if #roles==0 then status="В субтитрах нет ролей"; return end
 local items=load_dub_items()
 local L={}
 for _,r in ipairs(roles) do
  local lines,done,dur,takes=0,0,0,0
  for _,s in ipairs(rows) do
   if s.role==r then
    lines=lines+1; if s.done then done=done+1 end
    dur=dur+(s.finish-s.start)
    local n=row_takes(s,items); takes=takes+n
   end
  end
  L[#L+1]=string.format("%s: записано %d из %d, осталось %d · реплик %.0f с · дублей %d",r,done,lines,lines-done,dur,takes)
 end
 reaper.ShowMessageBox(table.concat(L,"\n"),"Dubbing Prompter — сводка по актёрам",0)
 status="Сводка по актёрам показана"
end

-- thresholds for QC and warnings (chars/sec, min pause, short line)
local function edit_qc_thresholds()
 local def=string.format("%s,%s,%s",qc_cps,qc_gap,qc_short)
 local ok,res=reaper.GetUserInputs("Пороги проверки",3,"Скорость, зн/с,Минимальная пауза, с,Короткая реплика, с",def)
 if not ok then return end
 local v={}; for n in res:gmatch("[^,]+") do v[#v+1]=tonumber((n:gsub(",","."))) end
 if #v==3 and v[1] and v[2] and v[3] then
  qc_cps,qc_gap,qc_short=math.max(1,v[1]),math.max(0,v[2]),math.max(0,v[3])
  save(); status="Пороги сохранены: "..qc_cps.." зн/с, пауза "..qc_gap.." с, короткая <"..qc_short.." с"
 else status="Неверные значения порогов" end
end

-- take verdict: ok / redo (переписать) / check (спорно); same key again clears it
local function set_verdict(v)
 local s=rows[selected]; if not s then status="Выбери реплику"; return end
 push_undo()
 if s.verdict==v then s.verdict=nil else s.verdict=v end
 save(); mark_dirty()
 status=s.verdict and ("Оценка: "..VERDICTS[s.verdict]) or "Оценка снята"
 log_event("№"..selected.." оценка: "..(s.verdict and VERDICTS[s.verdict] or "снята"))
end

local STATUS_CYCLE={"","redo","check","lip","ok","none"}
local STATUS_NAME={[""]="все",redo="переписать",check="спорно",lip="губы",ok="ок",none="не записано"}
local function cycle_status_filter()
 local idx=1
 for i,v in ipairs(STATUS_CYCLE) do if v==status_filter then idx=i end end
 status_filter=STATUS_CYCLE[(idx % #STATUS_CYCLE)+1]
 rebuild_vis(); scroll=0
 status="Фильтр: "..STATUS_NAME[status_filter]
end

-- call sheet: lines of one role that are not recorded yet, as HTML (print to PDF) for the next session
local function export_call_sheet()
 if #roles==0 then status="В субтитрах нет ролей"; return end
 local idx=popup(roles)
 local r=roles[idx]
 if not r then return end
 local dir,base=out_dir_base()
 local h={"<!doctype html><html lang='ru'><head><meta charset='utf-8'><title>Вызывной лист</title><style>",
  "body{font-family:Arial,sans-serif;margin:24px;color:#111}table{border-collapse:collapse;width:100%}",
  "td,th{border:1px solid #bbb;padding:6px;font-size:14px;vertical-align:top}th{background:#eee;text-align:left}",
  ".t{font-family:monospace;white-space:nowrap}@media print{body{margin:10mm}}</style></head><body>",
  "<h1>Вызывной лист: "..hesc(r).."</h1><p>"..hesc(base).." · дата: "..os.date("%Y-%m-%d").."</p>",
  "<table><tr><th>№</th><th>Тайминг</th><th>Текст</th><th>Заметка</th></tr>"}
 local n=0
 for i,s in ipairs(rows) do
  if s.role==r and not s.done then
   n=n+1
   h[#h+1]="<tr><td>"..string.format("%03d",i).."</td><td class='t'>"..ftime(s.start).."<br>"..ftime(s.finish).."</td><td>"..
    hesc(s.text):gsub("\n","<br>").."</td><td>"..hesc(s.note or "").."</td></tr>"
  end
 end
 h[#h+1]="</table><p>Реплик к записи: "..n.."</p></body></html>"
 local fname=(r:gsub("[/\\:*?\"<>|]","_"))
 local f=io.open(dir..base.."_вызывной_"..fname..".html","wb")
 if not f then status="Не удалось записать файл"; return end
 f:write(table.concat(h,"\n")); f:close()
 log_event("Вызывной лист "..r..": "..n)
 status="Вызывной лист: "..n.." реплик (HTML в папке "..dir..")"
end

-- ---------- multi-selection (Ctrl+click) and batch actions ----------
function toggle_pick(i)
 local s=rows[i]; if not s then return end
 s.pick=not s.pick
 status=s.pick and ("Выбрано реплик: "..count_picks()) or ("Выбор снят, выбрано: "..count_picks())
end

function count_picks()
 local n=0
 for _,s in ipairs(rows) do if s.pick then n=n+1 end end
 return n
end

-- targets of a batch action: all picked lines, or the selected one if nothing is picked
function batch_targets()
 local t={}
 for _,s in ipairs(rows) do if s.pick then t[#t+1]=s end end
 if #t==0 and rows[selected] then t[1]=rows[selected] end
 return t
end

function batch_shift()
 local t=batch_targets()
 if #t==0 then status="Нет реплик"; return end
 local ok,res=reaper.GetUserInputs("Пакетный сдвиг",1,"Секунд для "..#t.." реплик (например 0.5 или -1)","0")
 if not ok then return end
 local d=tonumber((res:gsub(",",".")))
 if not d or d==0 then status="Неверное значение сдвига"; return end
 push_undo()
 for _,s in ipairs(t) do
  s.start=math.max(0,s.start+d); s.finish=math.max(s.start+0.05,s.finish+d)
 end
 commit_sorted(rows[selected] or t[1]); log_event("Пакетный сдвиг "..#t.." реплик на "..d.." с")
 status="Сдвинуто реплик: "..#t.." на "..d.." с (Ctrl+Z отменит)"
end

function batch_role()
 local t=batch_targets()
 if #t==0 then status="Нет реплик"; return end
 local ok,res=reaper.GetUserInputs("Пакетная роль",1,"Роль для "..#t.." реплик (пусто = без роли)","")
 if not ok then return end
 push_undo()
 local r=clean_name(res)
 for _,s in ipairs(t) do s.role=r end
 save(); mark_dirty(); log_event("Пакетная роль «"..r.."» для "..#t.." реплик")
 status="Роль назначена: "..#t.." реплик (Ctrl+Z отменит)"
end

function batch_done(v)
 local t=batch_targets()
 if #t==0 then status="Нет реплик"; return end
 push_undo()
 for _,s in ipairs(t) do s.done=v end
 save(); mark_dirty(); log_event((v and "Пакетно записано: " or "Пакетно снято: ")..#t)
 status=(v and "Отмечено записанными: " or "Снята отметка у: ")..#t.." (Ctrl+Z отменит)"
end

function clear_picks()
 for _,s in ipairs(rows) do s.pick=nil end
 status="Выбор реплик снят"
end

-- next actor: cycles the role filter (same order as the role button)
function cycle_role_filter()
 if #roles==0 then status="В субтитрах нет ролей"; return end
 if role_filter=="" then role_filter=roles[1]
 else
  local i=role_idx[role_filter] or 0
  role_filter=roles[i+1] or ""
 end
 rebuild_vis(); scroll=0
 status="Актёр: "..(role_filter=="" and "все" or role_filter)
end

-- environment check: what the script needs and what is missing
function check_env()
 local function has(name) return reaper[name]~=nil end
 local L={
  "ОКРУЖЕНИЕ DUBBING",
  "REAPER: "..(reaper.GetAppVersion and reaper.GetAppVersion() or "?"),
  "ReaImGui (оверлей): "..(has("ImGui_CreateContext") and "есть" or "НЕТ — установи через ReaPack"),
  "js_ReaScriptAPI (привязка оверлея к видео): "..(has("JS_Window_Find") and "есть" or "нет (оверлей будет без привязки)"),
  "Аудио-доступ (громкость, шум): "..((has("CreateTakeAudioAccessor") and has("new_array")) and "есть" or "НЕТ — нужен REAPER 6.x+"),
  "Частота кадров проекта: "..(has("TimeMap_curFrameRate") and tostring(fps_now()).." fps" or "нет функции"),
  "Дорожка дубляжа: "..(extget(K.dub,"")~="" and "назначена" or "НЕ назначена"),
 }
 local found=false
 local dd={reaper.GetResourcePath().."/Scripts/DubbingSystem/"}
 local sp=({reaper.get_action_context()})[2]
 if sp then local d0=sp:match("^(.*[/\\])"); if d0 then table.insert(dd,1,d0) end end
 for _,d in ipairs(dd) do
  local f=io.open(d.."Dubbing_SubOverlay.lua","r")
  if f then f:close(); found=true end
 end
 L[#L+1]="Файл оверлея рядом с Prompter: "..(found and "найден" or "не найден (положи рядом с Prompter)")
 reaper.ShowMessageBox(table.concat(L,"\n"),"Dubbing — проверка окружения",0)
 status="Проверка окружения показана"
end

local -- ---------- LUFS (ITU-R BS.1770 K-weighting, gated; 48 kHz) ----------
function kw_coeffs(fs)
 local f0,G,Q=1681.974450955533,3.999843853973347,0.7071752369554196
 local K=math.tan(math.pi*f0/fs); local Vh=10^(G/20); local Vb=Vh^0.4996667741545416
 local a0=1+K/Q+K*K
 local c1={b0=(Vh+Vb*K/Q+K*K)/a0,b1=2*(K*K-Vh)/a0,b2=(Vh-Vb*K/Q+K*K)/a0,a1=2*(K*K-1)/a0,a2=(1-K/Q+K*K)/a0}
 f0,Q=38.13547087602444,0.5003270373238773
 K=math.tan(math.pi*f0/fs); a0=1+K/Q+K*K
 local c2={b0=1/a0,b1=-2/a0,b2=1/a0,a1=2*(K*K-1)/a0,a2=(1-K/Q+K*K)/a0}
 return c1,c2
end

-- integrated / max momentary / max short-term loudness of one take (LUFS); nil if too short or silent
function take_loudness(take)
 if not take or not reaper.CreateTakeAudioAccessor then return nil end
 local acc=reaper.CreateTakeAudioAccessor(take); if not acc then return nil end
 local SR,CH=48000,4800                       -- 100 ms hops
 local c1,c2=kw_coeffs(SR)
 local st,en=reaper.GetAudioAccessorStartTime(acc),reaper.GetAudioAccessorEndTime(acc)
 local buf=reaper.new_array(CH)
 local x1,x2,y1,y2=0,0,0,0                    -- stage 1 state
 local u1,u2,v1,v2=0,0,0,0                    -- stage 2 state
 local hops={}
 local t=st
 while t<en-1e-9 do
  buf.clear(); reaper.GetAudioAccessorSamples(acc,SR,1,t,CH,buf)
  local arr=buf.table(1,CH)
  local ssq=0
  for i=1,CH do
   local x=arr[i] or 0
   local y=c1.b0*x+c1.b1*x1+c1.b2*x2-c1.a1*y1-c1.a2*y2
   x2=x1; x1=x; y2=y1; y1=y
   local z=c2.b0*y+c2.b1*u1+c2.b2*u2-c2.a1*v1-c2.a2*v2
   u2=u1; u1=y; v2=v1; v1=z
   ssq=ssq+z*z
  end
  hops[#hops+1]=ssq/CH
  t=t+CH/SR
 end
 reaper.DestroyAudioAccessor(acc)
 if #hops<4 then return nil end
 local function lk(ms) return -0.691+10*math.log(ms,10) end
 local blocks={}
 for k=4,#hops do local m=0; for j=k-3,k do m=m+hops[j] end; blocks[#blocks+1]=m/4 end
 local sum,n=0,0
 for _,m in ipairs(blocks) do if m>0 and lk(m)>-70 then sum=sum+m; n=n+1 end end
 if n==0 then return nil end
 local rel=lk(sum/n)-10
 local s2,n2=0,0
 for _,m in ipairs(blocks) do if m>0 and lk(m)>-70 and lk(m)>rel then s2=s2+m; n2=n2+1 end end
 local integrated=(n2>0) and lk(s2/n2) or nil
 local mmax,smax=nil,nil
 for _,m in ipairs(blocks) do local l=m>0 and lk(m) or nil; if l and (not mmax or l>mmax) then mmax=l end end
 for k=30,#hops do local m=0; for j=k-29,k do m=m+hops[j] end; local l=m>0 and lk(m/30) or nil; if l and (not smax or l>smax) then smax=l end end
 return integrated,mmax,smax
end

-- LUFS of every dub item (active take), with the line it belongs to
function lufs_track()
 local tr=find_track(extget(K.dub,""))
 if not tr then status="Назначь дорожку дубляжа"; return end
 if not reaper.CreateTakeAudioAccessor then status="Нужен REAPER 6.x+"; return end
 local L,sum,n={},0,0
 for i=0,reaper.CountTrackMediaItems(tr)-1 do
  local it=reaper.GetTrackMediaItem(tr,i)
  local p=reaper.GetMediaItemInfo_Value(it,"D_POSITION")
  local len=reaper.GetMediaItemInfo_Value(it,"D_LENGTH")
  local mid=p+len/2
  local no="—"
  for j,r in ipairs(rows) do if mid>=r.start and mid<r.finish then no=string.format("№%03d",j); break end end
  local ig,mm,sh=take_loudness(reaper.GetActiveTake(it))
  if ig then sum=sum+ig; n=n+1 end
  L[#L+1]=string.format("%s  %s  интегральная %s LUFS  макс. момент. %s  макс. кратк. %s",no,fmt(p),
    ig and string.format("%.1f",ig) or "—", mm and string.format("%.1f",mm) or "—", sh and string.format("%.1f",sh) or "—")
 end
 local head={"ГРОМКОСТЬ LUFS — "..os.date("%Y-%m-%d %H:%M"),"Дублей измерено: "..n..(n>0 and ("  средняя интегральная: "..string.format("%.1f",sum/n).." LUFS") or ""),""}
 local dir,base=out_dir_base()
 local path=dir..base.."_LUFS.txt"
 local f=io.open(path,"wb"); if f then f:write(table.concat(head,"\n").."\n"..table.concat(L,"\n").."\n"); f:close() end
 reaper.ShowMessageBox(table.concat(head,"\n"),"Dubbing Prompter — LUFS",0)
 status="LUFS измерены: "..n.." дублей (файл "..path..")"
end

-- takes inside one item: each take's loudness against the median of the item
function take_compare()
 local tr=find_track(extget(K.dub,""))
 if not tr then status="Назначь дорожку дубляжа"; return end
 local L,multi,bad={},0,0
 for i=0,reaper.CountTrackMediaItems(tr)-1 do
  local it=reaper.GetTrackMediaItem(tr,i)
  local nt=reaper.CountTakes(it)
  if nt>1 then
   multi=multi+1
   local vals,arr={},{}
   for j=0,nt-1 do
    local ig=take_loudness(reaper.GetTake(it,j))
    vals[#vals+1]={j+1,ig}
    if ig then arr[#arr+1]=ig end
   end
   table.sort(arr)
   local med=arr[math.ceil(#arr/2)] or 0
   for _,v in ipairs(vals) do
    local d=v[2] and (v[2]-med) or 0
    local flag=""
    if math.abs(d)>3 then bad=bad+1; flag="  ⚠ отличается больше 3 дБ" end
    L[#L+1]=string.format("элемент %d (%s), дубль %d: %s LUFS, %+.1f дБ к медиане%s",i+1,
      fmt(reaper.GetMediaItemInfo_Value(it,"D_POSITION")),v[1],v[2] and string.format("%.1f",v[2]) or "—",d,flag)
   end
  end
 end
 local head={"ТАКИ ВНУТРИ ЭЛЕМЕНТОВ — "..os.date("%Y-%m-%d %H:%M"),"Элементов с несколькими takes: "..multi.."  отличаются больше 3 дБ: "..bad,""}
 local dir,base=out_dir_base()
 local path=dir..base.."_Takes.txt"
 local f=io.open(path,"wb"); if f then f:write(table.concat(head,"\n").."\n"..table.concat(L,"\n").."\n"); f:close() end
 reaper.ShowMessageBox(table.concat(head,"\n"),"Dubbing Prompter — takes",0)
 status="Takes сравнены: элементов "..multi.."; отличаются: "..bad
end

-- problems with the reason, and jump to a chosen line (cursor + scroll)
function problem_items()
 local items,idxs={},{}
 local dub=load_dub_items()
 for i,s in ipairs(rows) do
  local reasons={}
  local dur=s.finish-s.start
  local cps=ulen((s.text:gsub("\n","")))/math.max(dur,0.05)
  if cps>=qc_cps then reasons[#reasons+1]=string.format("скорость %.0f зн/с",cps) end
  if dur<qc_short then reasons[#reasons+1]="короткая" end
  local nx=rows[i+1]
  if nx and nx.start-s.finish<qc_gap then reasons[#reasons+1]="пауза / перекрытие" end
  local n,over=row_takes(s,dub)
  if n==0 and not s.done then reasons[#reasons+1]="нет дубля" end
  if n>0 and over>0.25 then reasons[#reasons+1]=string.format("дубль длиннее на %.1f с",over) end
  if s.verdict=="redo" then reasons[#reasons+1]="переписать"
  elseif s.verdict=="check" then reasons[#reasons+1]="спорно"
  elseif s.verdict=="lip" then reasons[#reasons+1]="губы не совпадают" end
  if #reasons>0 then items[#items+1]=string.format("№%03d  %s  %s",i,fmt(s.start),table.concat(reasons,", ")); idxs[#idxs+1]=i end
 end
 return items,idxs
end

function problem_jump()
 local items,idxs=problem_items()
 if #items==0 then status="Проблемных реплик нет"; return end
 local show={}
 for i=1,math.min(#items,60) do show[i]=items[i] end
 local pick=popup(show)
 local idx=idxs[pick]
 if not idx then return end
 goto_row(idx); show_row(idx)
 status="Перешли к реплике №"..idx
end

-- user preferences (key letters and list columns) are kept per user, not per project
function save_prefs()
 local ks={}
 for name,code in pairs(PREF.keys) do ks[#ks+1]=name.."="..code end
 local cs={}
 for name,on in pairs(PREF.cols) do cs[#cs+1]=name.."="..(on and "1" or "0") end
 reaper.SetExtState("DubbingPrompter","keys",table.concat(ks,","),true)
 reaper.SetExtState("DubbingPrompter","cols",table.concat(cs,","),true)
end

function load_prefs()
 local ks=tostring(reaper.GetExtState("DubbingPrompter","keys") or "")
 for name,code in ks:gmatch("(%w+)=(%d+)") do if PREF.keys[name]~=nil then PREF.keys[name]=tonumber(code) end end
 local cs=tostring(reaper.GetExtState("DubbingPrompter","cols") or "")
 for name,v in cs:gmatch("(%w+)=([01])") do if PREF.cols[name]~=nil then PREF.cols[name]=(v=="1") end end
end

function hotkeys_menu()
 local order={"play_line","loop","done","mark","next_mark","best","actor"}
 local labels="Воспроизвести реплику,Цикл реплики,Записано,Закладка,След. закладка,Лучший дубль,Следующий актёр"
 local defs={}
 for _,name in ipairs(order) do defs[#defs+1]=string.char(PREF.keys[name]) end
 local ok,res=reaper.GetUserInputs("Горячие клавиши (одна латинская буква)",7,labels,table.concat(defs,","))
 if not ok then return end
 local vals={}
 for part in (res..","):gmatch("(.-),") do vals[#vals+1]=trim(part):lower() end
 local seen={}
 for i,name in ipairs(order) do
  local v=vals[i] or ""
  if not v:match("^%a$") or seen[v] then status="Клавиши не сохранены: нужны разные латинские буквы"; return end
  seen[v]=true
 end
 for i,name in ipairs(order) do PREF.keys[name]=string.byte(vals[i]) end
 save_prefs()
 status="Горячие клавиши сохранены (1–4 для оценок не меняются)"
end

function cols_menu()
 local order={"takes","cps","dur","over","note","verdict"}
 local names={takes="дубли (×N)",cps="зн/с",dur="длительность",over="превышение",note="заметка",verdict="оценка"}
 local items={}
 for i,k in ipairs(order) do items[i]=(PREF.cols[k] and "✓ " or "    ")..names[k] end
 local pick=popup(items)
 local k=order[pick]
 if not k then return end
 PREF.cols[k]=not PREF.cols[k]; save_prefs()
 status="Колонка «"..names[k].."»: "..(PREF.cols[k] and "показана" or "скрыта")
end

local function profiles_dir() return reaper.GetResourcePath().."/DubbingSystem_profiles/" end

function profile_save()
 local ok,name=reaper.GetUserInputs("Профиль настроек",1,"Имя профиля","Профиль 1")
 if not ok then return end
 name=trim(name):gsub("[/\\:*?\"<>|]","_")
 if name=="" then status="Пустое имя профиля"; return end
 reaper.RecursiveCreateDirectory(profiles_dir(),0)
 local L={"duck="..duck,"pre="..pre,"post="..post,"fi="..fi,"fo="..fo,"preroll="..preroll,
  "only_dub="..(only_dub and 1 or 0),"win_from_dub="..(win_from_dub and 1 or 0),
  "qc_cps="..qc_cps,"qc_gap="..qc_gap,"qc_short="..qc_short,"frames="..(frames_mode and 1 or 0)}
 for r,db in pairs(role_duck) do L[#L+1]="role:"..r.."="..db end
 local f=io.open(profiles_dir()..name..".dubprof","wb")
 if not f then status="Не удалось записать профиль"; return end
 f:write(table.concat(L,"\n").."\n"); f:close()
 status="Профиль сохранён: "..name
end

function profile_load()
 local files={}
 local i=0
 while true do
  local f=reaper.EnumerateFiles(profiles_dir(),i)
  if not f then break end
  if f:match("%.dubprof$") then files[#files+1]=f end
  i=i+1
 end
 if #files==0 then status="Сохранённых профилей нет"; return end
 local pick=popup(files)
 local fname=files[pick]
 if not fname then return end
 local f=io.open(profiles_dir()..fname,"rb")
 if not f then status="Профиль не открылся"; return end
 local data=f:read("*a"); f:close()
 push_undo()
 role_duck={}
 for line in (data.."\n"):gmatch("(.-)\n") do
  local role,db=line:match("^role:(.-)=(.+)$")
  if role then role_duck[role]=tonumber(db) or duck
  else
   local k,v=line:match("^(%w+)=(.+)$")
   v=tonumber(v)
   if k=="duck" and v then duck=v elseif k=="pre" and v then pre=v elseif k=="post" and v then post=v
   elseif k=="fi" and v then fi=v elseif k=="fo" and v then fo=v elseif k=="preroll" and v then preroll=v
   elseif k=="only_dub" then only_dub=(v==1) elseif k=="win_from_dub" then win_from_dub=(v==1)
   elseif k=="qc_cps" and v then qc_cps=v elseif k=="qc_gap" and v then qc_gap=v elseif k=="qc_short" and v then qc_short=v
   elseif k=="frames" then frames_mode=(v==1) end
  end
 end
 save(); mark_dirty()
 status="Профиль загружен: "..fname
end

function toggle_frames()
 frames_mode=not frames_mode; save()
 status=frames_mode and "Таймкод в кадрах ("..fps_now().." fps)" or "Таймкод в секундах"
end

local function export_project()
 if #rows==0 then status="Нечего экспортировать"; return end
 local dir,base=out_dir_base()
 local path=dir..base..".dubproj"
 local f=io.open(path,"wb"); if not f then status="Не удалось записать: "..path; return end
 local t={"DUBPROJ1",
  "duck="..duck,"pre="..pre,"post="..post,"fi="..fi,"fo="..fo,"preroll="..preroll,
  "only_dub="..(only_dub and 1 or 0),"win_from_dub="..(win_from_dub and 1 or 0)}
 t[#t+1]="@@ROLEDUCK"
 for r,db in pairs(role_duck) do t[#t+1]=r.."\t"..db end
 t[#t+1]="@@SUBS"
 t[#t+1]=serialize_rows()
 f:write(table.concat(t,"\n")); f:close()
 status="Проект сохранён: "..path
end

local function import_project()
 local ok,path=reaper.GetUserFileNameForRead("","Проект Dubbing (.dubproj)","")
 if not ok then return end
 local f=io.open(path,"rb"); if not f then status="Не удалось открыть файл"; return end
 local data=f:read("*a"); f:close()
 if not data:match("^DUBPROJ1") then status="Это не файл проекта Dubbing"; return end
 local head,rd,subs=data:match("^(.-)@@ROLEDUCK\n(.-)@@SUBS\n(.*)$")
 if not head then status="Файл проекта повреждён"; return end
 push_undo()
 local kv={}
 for k,v in head:gmatch("([%w_]+)=([^\n]*)") do kv[k]=tonumber(v) end
 duck=kv.duck or duck; pre=kv.pre or pre; post=kv.post or post; fi=kv.fi or fi; fo=kv.fo or fo
 preroll=kv.preroll or preroll
 only_dub=(kv.only_dub==1); win_from_dub=(kv.win_from_dub==1)
 role_duck={}
 for line in (rd.."\n"):gmatch("(.-)\n") do
  local r,db=line:match("^(.-)\t(.+)$")
  if r and tonumber(db) then role_duck[r]=tonumber(db) end
 end
 rows=parse_saved(subs); selected=1; scroll=0
 save(); mark_dirty(); status="Проект загружен: реплик "..#rows
end

local function native_col(role)
 local c=role_rgb(role)
 if not c then return 0 end
 return reaper.ColorToNative(math.floor(c[1]*255),math.floor(c[2]*255),math.floor(c[3]*255))|0x1000000
end

local function to_regions(silent)
 if #rows==0 then status="Нет субтитров"; return end
 if not silent and reaper.ShowMessageBox("Создать "..#rows.." регионов из субтитров?\n(существующие регионы не удаляются)","Dubbing Prompter",1)~=1 then return end
 reaper.Undo_BeginBlock(); reaper.PreventUIRefresh(1)
 for _,s in ipairs(rows) do reaper.AddProjectMarker2(0,true,s.start,s.finish,s.text,-1,native_col(s.role)) end
 reaper.PreventUIRefresh(-1); reaper.UpdateTimeline(); reaper.Undo_EndBlock("Dubbing System: subtitles to regions",-1)
 status="Создано регионов: "..#rows
end

local function to_items(silent)
 if #rows==0 then status="Нет субтитров"; return end
 if not silent and reaper.ShowMessageBox("Создать новую дорожку с "..#rows.." текстовыми итемами?","Dubbing Prompter",1)~=1 then return end
 reaper.Undo_BeginBlock(); reaper.PreventUIRefresh(1)
 local idx=reaper.CountTracks(0)
 reaper.InsertTrackAtIndex(idx,true)
 local tr=reaper.GetTrack(0,idx)
 reaper.GetSetMediaTrackInfo_String(tr,"P_NAME","Dubbing Subtitles (text items)",true)
 for _,s in ipairs(rows) do
  local it=reaper.AddMediaItemToTrack(tr)
  reaper.SetMediaItemInfo_Value(it,"D_POSITION",s.start)
  reaper.SetMediaItemInfo_Value(it,"D_LENGTH",s.finish-s.start)
  reaper.GetSetMediaItemInfo_String(it,"P_NOTES",s.text,true)
  local c=native_col(s.role); if c~=0 then reaper.SetMediaItemInfo_Value(it,"I_CUSTOMCOLOR",c) end
 end
 reaper.PreventUIRefresh(-1); reaper.UpdateArrange(); reaper.Undo_EndBlock("Dubbing System: subtitles to text items",-1)
 status="Создана дорожка с итемами: "..#rows
end

-- ---------- дорожка дубляжа с цепочкой эффектов ----------
-- Шаблон цепочки дубляжа (сохранён из REAPER: RX 9 Voice De-noise → RX 9 De-reverb → SPL De-Esser → Pro-Q 3 → Pro-C 2 → SPL Vitalizer MK2-T → Pro-L 2).
-- Вставляется на новую дорожку целиком, со всеми настройками. FXID убраны, REAPER назначит новые.
DUB_CHAIN_RFX=[==[
BYPASS 0 0
<VST "VST3: RX 9 Voice De-noise (iZotope)" "RX 9 Voice De-noise.vst3" 0 "" 1361098585{565354723944305258203920566F6963} ""
  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
  AAAAAAAA
>
WAK 0 0
BYPASS 0 0
<VST "VST3: RX 9 De-reverb (iZotope)" "RX 9 De-reverb.vst3" 0 "" 1631956404{56535472395630525820392044652D72} ""
  tK1FYe5e7f4CAAAAAQAAAAAAAAACAAAAAAAAAAIAAAABAAAAAAAAAAIAAAAAAAAAegMAAAEAAAD//wAA
  tQEAAAEAAABpqTYAAwAAAKkBAADZDgAAeJzNl11PwjAUhu/3K5pdGwMS/LoTQWKihDjE6zOorKZrSdsZCdl/l00IDjrotrJw1e2055ynX+/Olg5CyH3kTOEfhTwFCrvo
  Hi0Tc9IzWsxTg9slE0U4A7FwLzadY6BRZnhiHIKAUO5Yj4XaCxhvOzaPaRunHm7XG1qBTeL0KA4xU5WRM/Y0OBb4Gwtf22sW/miSnVToIeQRU6gDbIoaBzwy6Z8oB6XN
  vJv/Tj8mzvHVczXtc7Uv2zbIruyTXdsha9knuy3L1WPg00PHMQPU4Zwa8SgR4WpIqyYANkmv81nhvWAQjLCZdahPoLI01RuWZBoBPS8qj1NeUL/qBjMWsLrBjPWrbjBj
  +aoHbASEri4lm6nAvq42yiv+KBBYBpxO0YATaSyxBb5GZck+fNQHVUDCzJluCjKt6zU0gNB4hTwlEnYTnG3ZVpArLXzRGAu5KuVMwd6fmdkqtXJoNOY92z6y26fcz1d+
  i5XpqXdrPZGCe/XnhTqLOUhN4a/HOqk2nfb0NKqcHifnTfdj9gpfXOimkQO9RWz+j0JYpShO7PwCkvvkzLUBAAAAAAAAaak2AAMAAACpAQAA2Q4AAHiczZddT8IwFIbv
  9yuaXRsDEvy6E0FiooQ4xOszqKyma0nbGQnZf5dNCA466LaycNXttOecp1/vzpYOQsh95EzhH4U8BQq76B4tE3PSM1rMU4PbJRNFOAOxcC82nWOgUWZ4YhyCgFDuWI+F
  2gsYbzs2j2kbpx5u1xtagU3i9CgOMVOVkTP2NDgW+BsLX9trFv5okp1U6CHkEVOoA2yKGgc8MumfKAelzbyb/04/Js7x1XM17XO1L9s2yK7sk13bIWvZJ7sty9Vj4NND
  xzED1OGcGvEoEeFqSKsmADZJr/NZ4b1gEIywmXWoT6CyNNUblmQaAT0vKo9TXlC/6gYzFrC6wYz1q24wY/mqB2wEhK4uJZupwL6uNsor/igQWAacTtGAE2kssQW+RmXJ
  PnzUB1VAwsyZbgoyres1NIDQeIU8JRJ2E5xt2VaQKy180RgLuSrlTMHen5nZKrVyaDTmPds+stun3M9XfouV6al3az2Rgnv154U6izlITeGvxzqpNp329DSqnB4n5033
  Y/YKX1zoppEDvUVs/o9CWKUoTuz8ApL75Mw=
  AAAAAAAA
>
WAK 0 0
BYPASS 0 0
<VST "VST3: SPL De-Esser (Plugin Alliance)" "SPL De-Esser.vst3" 0 "" 753351401{5653545350443173706C2064652D6573} ""
  6TrnLO5e7f4CAAAAAQAAAAAAAAACAAAAAAAAAAIAAAABAAAAAAAAAAIAAAAAAAAACAEAAAEAAAD//wAA
  fAAAAAEAAABCWENrAAAAdEVmY3QAAABgUG10cgAAAFgAAABgAAAABgAAAAIAAAAAUHJlcwAAAAAAAAAATWlTaQAAAAAAAAAAQWN0MT+AAAA/gAAAUmVkMT6MzOQAAAAA
  QXV0MT+AAAA/gAAARmx0cgAAAAAAAAAAQnlwYQAAAAQAAAAAfAAAAAAAAABCWENrAAAAdEVmY3QAAABgUG10cgAAAFgAAABgAAAABgAAAAIAAAAAUHJlcwAAAAAAAAAA
  TWlTaQAAAAAAAAAAQWN0MT+AAAA/gAAAUmVkMT6MzOQAAAAAQXV0MT+AAAA/gAAARmx0cgAAAAAAAAAAQnlwYQAAAAQAAAAA
  AAAAAAAA
>
WAK 0 0
BYPASS 0 0
<VST "VST3: Pro-Q 3 (FabFilter)" "FabFilter Pro-Q 3.vst3" 0 "" 756089518{72C4DB717A4D459AB97E51745D84B39D} ""
  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
  ZWQAAAAAAACAPw==
  AAAAAAAA
>
WAK 0 0
BYPASS 0 0
<VST "VST3: Pro-C 2 (FabFilter)" "FabFilter Pro-C 2.vst3" 0 "" 1000537396{79F415E3C8E74807AD5DA3CF7024F618} ""
  NP2iO+5e7f4EAAAAAQAAAAAAAAACAAAAAAAAAAQAAAAAAAAACAAAAAAAAAACAAAAAQAAAAAAAAACAAAAAAAAAP8AAAABAAAAAAAAAA==
  4wAAAAEAAABGYWJGAgAAAA8AAABEZWZhdWx0IFNldHRpbmcAAAAALgAAAAAAAAAAALDB8O7uPgAAoEEAAHBCmGvIPraN0j4AAIA/AAAAAAAAAAAAAAAAAAAAAAAAgL8A
  AAAAAACAPwAAAAAAAAAAAAAAAAAAAD8AAAAAAAAAAHia1EAAAEBAAACAPwAAgD/acx9BAAAAAAAAAD8AAAAAAAAAAHiaREEAAEBAAAAAAAAAAAAAAIA/AAAAAAAAAAAA
  AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEBAAACAPwAAAAABAAAAAQAAAAwAAAAAAAAARkZlZAAAAAAAAIA/
  AAAAAAAA
>
WAK 0 0
BYPASS 0 0
<VST "VST3: SPL Vitalizer MK2-T (Plugin Alliance)" "SPL Vitalizer MK2-T.vst3" 0 "" 1568678752{5653545350565473706C20766974616C} ""
  YCOAXe5e7f4CAAAAAQAAAAAAAAACAAAAAAAAAAIAAAABAAAAAAAAAAIAAAAAAAAAMAIAAAEAAAD//wAA
  EAEAAAEAAABCWENrAAABCEVmY3QAAAD0UG10cgAAAOwAAAD0AAAACwAAAAQAAAAAUHJlcwAAAAAAAAAAAAAAAAAAAABBY3R2P4AAAD+AAAA/gAAAP4AAAERyaXY/AAAA
  PwAAAD8AAAA/AAAAQlNuZD8AAAA/AAAAPwAAAD8AAABCQ21wAAAAAAAAAAAAAAAAAAAAAE1pSGk/M6WyPwAAAD8AAAA/AAAAUHJvYz2AAwQAAAAAAAAAAAAAAABMQ0Zy
  PyZmZz8AAAA/AAAAPwAAAExDSXQ/JJ92AAAAAAAAAAAAAAAARXhwYQAAAAAAAAAAAAAAAAAAAABPdXRwPwAAAD8AAAA/AAAAPwAAAEJ5cGEAAAAEAAAAABABAAAAAAAA
  QlhDawAAAQhFZmN0AAAA9FBtdHIAAADsAAAA9AAAAAsAAAAEAAAAAFByZXMAAAAAAAAAAAAAAAAAAAAAQWN0dj+AAAA/gAAAP4AAAD+AAABEcml2PwAAAD8AAAA/AAAA
  PwAAAEJTbmQ/AAAAPwAAAD8AAAA/AAAAQkNtcAAAAAAAAAAAAAAAAAAAAABNaUhpPzOlsj8AAAA/AAAAPwAAAFByb2M9gAMEAAAAAAAAAAAAAAAATENGcj8mZmc/AAAA
  PwAAAD8AAABMQ0l0PySfdgAAAAAAAAAAAAAAAEV4cGEAAAAAAAAAAAAAAAAAAAAAT3V0cD8AAAA/AAAAPwAAAD8AAABCeXBhAAAABAAAAAA=
  AAAAAAAA
>
WAK 0 0
BYPASS 0 0
<VST "VST3: Pro-L 2 (FabFilter)" "FabFilter Pro-L 2.vst3" 0 "" 1938458649{AFD92F729A0447B7B5E8D1D568DEA985} ""
  GYiKc+5e7f4EAAAAAQAAAAAAAAACAAAAAAAAAAQAAAAAAAAACAAAAAAAAAACAAAAAQAAAAAAAAACAAAAAAAAAMcAAAABAAAAEQAAAA==
  qwAAAAEAAABGYWJGAgAAAA8AAABEZWZhdWx0IFNldHRpbmcAAAAAIAAAAAc6v0AAAKBA7FE4PqR/0D5+jcY+AADAPgAAAD8AAAAAAAAAAAAAAAAAAIA/AAAAAAAAAEAA
  AAAAAAAAAAAAAAAAAAAAAAAAAAAAgL8AAIA/AAAAAAAAAAAAAIA/AAAAAAAAwEAAAIA/AAAAAAAAAAAAAIC/AAAAAAAAgD8AAAAAAQAAAAEAAAAMAAAAAAAAAEZGZWQA
  AAAAAACAPw==
  AAAAAAAA
>
WAK 0 0
]==]

-- вставляет шаблон цепочки в трек целиком (FXCHAIN в трек-чанк); false, если не получилось
function set_chain_from_rfx(tr)
 local ok,chunk=reaper.GetTrackStateChunk(tr,"",false)
 if not ok or not chunk or chunk=="" or chunk:find("<FXCHAIN") then return false end
 local new,n=chunk:gsub(">%s*$",function() return "<FXCHAIN\n"..DUB_CHAIN_RFX.."\n>\n>\n" end)
 if n~=1 then return false end
 return reaper.SetTrackStateChunk(tr,new,false)
end
-- ===== Сведение аниме: структура и цепочки из проекта anime_mix (FXID убраны, REAPER создаст свои) =====
ANIME_CH={}
ANIME_CH["master"]=[==[
      WNDRECT 643 168 1127 653
      SHOW 0
      LASTSEL 0
      DOCKED 0
      BYPASS 0 0 0
      <VST "VST: ReaLimit (Cockos)" realimit.dll 0 "" 1919708532<565354726C6D747265616C696D697400> ""
        dG1scu5e7f4CAAAAAQAAAAAAAAACAAAAAAAAAAIAAAABAAAAAAAAAAIAAAAAAAAAMAAAAAEAAAAAABAA
        AwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAAAAAD+fduMQw8Y/
        AAAQAAAA
      >
      MULTIFXLINK 0
      FLOATPOS 0 0 0 0
      WAK 0 0
]==]
ANIME_CH["raw"]=[==[
      WNDRECT 643 168 1127 653
      SHOW 0
      LASTSEL 0
      DOCKED 0
      BYPASS 0 0 0
      <VST "VST: ReaComp (Cockos)" reacomp.dll 0 "" 1919247213<5653547265636D726561636F6D700000> ""
        bWNlcu9e7f4EAAAAAQAAAAAAAAACAAAAAAAAAAQAAAAAAAAACAAAAAAAAAACAAAAAQAAAAAAAAACAAAAAAAAAFwAAAAAAAAAAAAQAA==
        776t3g3wrd6jXLQ83no8PixwEzk2c5g8AAAAAAAAAAAAAIA/dyBgPIzU8ToAAAAAnNEHMwAAgD8AAAAAAAAAAAAAgD8AAAAAAAAAAAAAgD4AAAAAAAAAAAAAAAA=
        AAAQAAAA
      >
      MULTIFXLINK 0
      FLOATPOS 0 0 0 0
      WAK 0 0
]==]
ANIME_CH["voiceall"]=[==[
      WNDRECT 643 168 1127 653
      SHOW 0
      LASTSEL 0
      DOCKED 0
      BYPASS 0 0 0
      <VST "VST3: SPL IRON (Plugin Alliance)" "SPL IRON.vst3" 0 "" 1375722613{5653545350495273706C2069726F6E00} ""
        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
        AAAQAAAA
      >
      MULTIFXLINK 0
      FLOATPOS 0 0 0 0
      WAK 0 0
      <COMMENT
        0J7QsdGJ0LjQuSDQutC+0LzQv9GA0LXRgdGB0L7RgCAo0L3QsNGA0YPQu9C10L0p
      >
]==]
ANIME_CH["effall"]=[==[
      WNDRECT 643 168 1127 653
      SHOW 0
      LASTSEL 1
      DOCKED 0
      BYPASS 1 0 0
      <VST "VST3: Pro-Q 3 (FabFilter)" "FabFilter Pro-Q 3.vst3" 0 "" 756089518{72C4DB717A4D459AB97E51745D84B39D} ""
        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
        AAAAAEZGZWQAAAAAAACAPw==
        AAAQAAAA
      >
      MULTIFXLINK 0
      FLOATPOS 0 0 0 0
      WAK 0 0
      <COMMENT
        0YLQtdC70LXRhNC+0L0v0YLQtdC70LXQstC40LfQvtGAL9GA0LDRhtC40Y8=
      >
      BYPASS 1 0 0
      <VST "VST3: Pro-Q 3 (FabFilter)" "FabFilter Pro-Q 3.vst3" 0 "" 756089518{72C4DB717A4D459AB97E51745D84B39D} ""
        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
        AQAAAAAAAABGRmVkAAAAAAAAgD8=
        AAAQAAAA
      >
      MULTIFXLINK 0
      FLOATPOS 0 0 0 0
      WAK 0 0
      <COMMENT
        0LfQsCDRgdGC0LXQvdC+0Lkv0LTQstC10YDRjNGO
      >
      BYPASS 1 0 0
      <VST "VST: ReaPitch (Cockos)" reapitch.dll 0 "" 1919250531<56535472657063726561706974636800> ""
        Y3Blcu5e7f4CAAAAAQAAAAAAAAACAAAAAAAAAAIAAAABAAAAAAAAAAIAAAAAAAAATAAAAAEAAAAAABAA
        AAAAAP////8BAAAALAAAAAIAAAAAAAAAAACAPwAAAAAAAAAAAACAPwAAAD8AAAA/AAAAPwAAAD8AAAA/AAAAPwAAAD8AAIA/AAAAPw==
        AFByb2dyYW0gMQAQAAAA
      >
      MULTIFXLINK 0
      FLOATPOS 0 0 0 0
      WAK 0 0
      <COMMENT
        0LzQvtC90YHRgtGA0Ysg0Lgg0L/QvtC00L7QsdC90L7QtSAo0YHQsNC8INGA0YPQu9C4KQ==
      >
      BYPASS 1 0 0
      <VST "VST: ReaVerbate (Cockos)" reaverbate.dll 0 "" 1920361016<56535472766238726561766572626174> ""
        OGJ2cu9e7f4CAAAAAQAAAAAAAAACAAAAAAAAAAIAAAABAAAAAAAAAAIAAAAAAAAAKAAAAAAAAAAAABAA
        776t3g3wrd7vOzU/7zs1PxRa3j6srVg9EFhZPwAAAAAAAIA/d1mdOw==
        AFByb2dyYW0gMQAQAAAA
      >
      WET 0.349813 0
      MULTIFXLINK 0
      FLOATPOS 0 0 0 0
      WAK 0 0
      <COMMENT
        ItCy0L7RgdC/0L7QvNC40L3QsNC90LjRjyI=
      >
]==]
ANIME_CH["effv"]=[==[
      WNDRECT 643 168 1127 653
      SHOW 0
      LASTSEL 0
      DOCKED 0
      BYPASS 1 0 0
      <VST "VST3: Pro-Q 3 (FabFilter)" "FabFilter Pro-Q 3.vst3" 0 "" 756089518{72C4DB717A4D459AB97E51745D84B39D} ""
        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
        AQAAAAAAAABGRmVkAAAAAAAAgD8=
        AAAQAAAA
      >
      MULTIFXLINK 0
      FLOATPOS 0 0 0 0
      WAK 0 0
      <COMMENT
        0YLQtdC70LXRhNC+0L0v0YLQtdC70LXQstC40LfQvtGAL9GA0LDRhtC40Y8=
      >
      BYPASS 1 0 0
      <VST "VST3: Pro-Q 3 (FabFilter)" "FabFilter Pro-Q 3.vst3" 0 "" 756089518{72C4DB717A4D459AB97E51745D84B39D} ""
        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
        Q3VTVgEAAAAAAAAARkZlZAAAAAAAAIA/
        AAAQAAAA
      >
      MULTIFXLINK 0
      FLOATPOS 0 0 0 0
      WAK 0 0
      <COMMENT
        0LfQsCDRgdGC0LXQvdC+0Lkv0LTQstC10YDRjNGO
      >
      BYPASS 1 0 0
      <VST "VST: ReaPitch (Cockos)" reapitch.dll 0 "" 1919250531<56535472657063726561706974636800> ""
        Y3Blcu5e7f4CAAAAAQAAAAAAAAACAAAAAAAAAAIAAAABAAAAAAAAAAIAAAAAAAAATAAAAAEAAAAAABAA
        AAAAAP////8BAAAALAAAAAIAAAAAAAAAAACAPwAAAAAAAAAAAACAPwAAAD8AAAA/AAAAPwAAAD8AAAA/AAAAPwAAAD8AAIA/AAAAPw==
        AFByb2dyYW0gMQAQAAAA
      >
      MULTIFXLINK 0
      FLOATPOS 0 0 0 0
      WAK 0 0
      <COMMENT
        0LzQvtC90YHRgtGA0Ysg0Lgg0L/QvtC00L7QsdC90L7QtSAo0YHQsNC8INGA0YPQu9C4KQ==
      >
      BYPASS 1 0 0
      <VST "VST: ReaVerbate (Cockos)" reaverbate.dll 0 "" 1920361016<56535472766238726561766572626174> ""
        OGJ2cu9e7f4CAAAAAQAAAAAAAAACAAAAAAAAAAIAAAABAAAAAAAAAAIAAAAAAAAAKAAAAAAAAAAAABAA
        776t3g3wrd7vOzU/7zs1PxRa3j6srVg9EFhZPwAAAAAAAIA/d1mdOw==
        AFByb2dyYW0gMQAQAAAA
      >
      WET 0.349813 0
      MULTIFXLINK 0
      FLOATPOS 0 0 0 0
      WAK 0 0
      <COMMENT
        ItCy0L7RgdC/0L7QvNC40L3QsNC90LjRjyI=
      >
]==]
ANIME_CH["voice"]=[==[
      WNDRECT 643 168 1127 653
      SHOW 0
      LASTSEL 2
      DOCKED 0
      BYPASS 0 0 0
      <VST "VST3: RX 9 Spectral De-noise (iZotope)" "RX 9 Spectral De-noise.vst3" 0 "" 1851004663{56535472394E30525820392053706563} ""
        9xZUbu5e7f4CAAAAAQAAAAAAAAACAAAAAAAAAAQAAAABAAAAAAAAAAIAAAAAAAAABAAAAAAAAAAIAAAAAAAAAFQhAAABAAAA//8QAA==
        ohAAAAEAAADLvkMABgAAAJYQAABSdisAeJzt2F1z01YewOH7fIozvu60sG2h07skBDbTFCgJMHupOMeOFlnyyHLAy+S7r2yTdzvIjZ2Y8jw38U9++0s+lgWfN0IIre0i
        r+KnKuxXSRVb4ffwebx5fM/BqD/Z0HqWtqu0yJNy1Prh7M53STa88vDxxtdJmfQG17Z+7aVuvODpxR1nNyd/TyfPaD3bf72UYcevs5PFXsyrO498ZfvkxWNepINYvuqP
        nzvzMc3e5Ktv9eUBX/YkvEx6tz3uypvuV2Wad2e+4fW3vb5Ds59yOuelpgsjvIvl4JajcX28t7t51Wi4R3OmmbH5xrabI5/v6n4/tqsyye7h0zt7y7Cd5EV/FM578yip
        D/hJDHsxKfNwkDb/dJ9nRdLs+D3+8dcFP8+G845XV8Npt4oiazRsJ8kGcWnjZt2iTKvj3r2tycVHHFZFvQrTxl+bhzmSO5/aaVX/rc8pMe9Wx8tfpUs7os879a9d+r/G
        X6TGn/nPy5rw30nZC9tFWcb2bT8f1wdtfiyX9n3/I48x7B8nZT+Pgxk/o3cddImnpm/jjPTnMKvSMjY+lA815SC8HN8M+8N+v1zjBfp6MGofF6sa8/HSTkpvYhaTwQp+
        3H9b4oiD9Gg4/3ro+owPszTPpgzvj+sfpEW+8A+wOifLsj5x1if5sJfmH+LRCtbov1Yx7eTb/60Me7CK39DljXpwXA96XGRHK1sDSzsHXIy6ogWwgklX8ukvbc73h+FF
        Uq3kNPX0jjPu5MlhFusz6tFwch0atoflSePP/F5P/xczjr9CSx+xKod3nfDql3wdJryv/zJa9D+Ldj7V/94NW6Nqgavg+tLpyS/NxtoEAAAAAAAAAAAAAAAAAAAAAAAA
        AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
        AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
        AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
        AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
        AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
        AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
        AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
        AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
        AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
        AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
        AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
        AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
        AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
        AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
        AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
        AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
        AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
        AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
        AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
        AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
        AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
        AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
        AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
        AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
        AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
        AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
        AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAGbY7v711/RWd696cba1u/fb5ubu9k/1/ZsnH7+TvnY8Nv/Y2jo7HsXOznd8/875/enH/S/3bxV75cvp/Xvlm/eP3k6fXY2e
        vOmObz1LOk/P1tP25vDRf6Y3d7efTu+/vN6+z/sffL1rrbXWWmuttdZaa6211lprrbXWWmuttdZaa6211lprrbXWWmuttdZaa6211lprrbXWWmuttdZaa6211lprrbXW
        WmuttdZaa6211lprrbXWWmuttdZaa6211lprrbXWWmuttdZaa6211lprrbXWWmuttdZaa6211lprrbXWWmuttdZaa6211lprrbXWWmuttdZaa6211lprrbXWWmuttdZa
        a6211lprrbXWWmuttdZaa6211lprrbXWWmuttdZaa6211lprrbXWWmuttdZaa6211lprrbXWWmuttdZaa6211lprrbXWWmuttdZaa6211lprrbXWWmuttdZaa6211lpr
        rbXWWmuttdZaa6211lprrbXWWmuttdZaa6211lprrbXWWmuttdZaa6211lprrbXWWmuttdZaa6211lprrbXWWmuttdZaa6211lprrbXWWmuttdZaa6211lprrbXWWmut
        tdZaa6211lprrbXWWmuttdZaa6211lprrbXWWmuttdZaa6211lprrbXWWmuttdZaa6211lprrbXWWmuttdZaa6211lprrbXWWmuttdZaa6211lprrbXWWmuttdZaa621
        1lprrbXWWmuttdZaa6211lprrbXWWmuttdZaa6211lprrbXWWmuttdZaa6211lprrbXWWmuttdZaa6211lprrbXW+rtuAABYR62NMMvpD7O3t14nZdIL72I5SIu8FX4P
        n2c/cPzYg1E/jh/SerubV605rzh+4LskG04e+WTONDM239h2c+TWiySdO+PFdM/SdlXvTFKOZs54Md2cXW1tjfrJYND0YGwVRdboYHSSbBAX/Himo4Tbdvz6PM+zImn2
        6TxacJidLPZiXoWXSe+243dlmv2qTPNuo3GmH++CM42fE3bz/rAKe7FTPfxBujxQ0f4Qj9ZwpPCq0xnE9TpYb9Lu8bpM9GpYrdmCOptonVbUlZnWa0l9GW0N19RBmfbW
        b6KwkyeHWeOT+kp/8i5OVEsfpyqHi05zaZGvwzirvVybt4z+7uVaVhwm2T1csK38wmS6I4t+ySbPCmt0NflNrZ7JeWAvnsR/wgq6tDOLXnRPzsyhPTxM2yHNq1j2iywZ
        723oFOV0yyDp9evH9GPyIRzFKk4OxjqcruqlE7tlUtXXB3vF8CiP9b9lvvZZXBludT+B5/O8OollJys+rsU39HyqgyKLZZK31+BIfVNnjenv9T/ltHF5b5w3nDecN5Zz
        3tiYU2c3J3+nO9b6M/lv/X2ZsRtzhr4Y8fHlV0nzO73KxunG/wH/uxcJohAAAAAAAADLvkMABgAAAJYQAABSdisAeJzt2F1z01YewOH7fIozvu60sG2h07skBDbTFCgJ
        MHupOMeOFlnyyHLAy+S7r2yTdzvIjZ2Y8jw38U9++0s+lgWfN0IIre0ir+KnKuxXSRVb4ffwebx5fM/BqD/Z0HqWtqu0yJNy1Prh7M53STa88vDxxtdJmfQG17Z+7aVu
        vODpxR1nNyd/TyfPaD3bf72UYcevs5PFXsyrO498ZfvkxWNepINYvuqPnzvzMc3e5Ktv9eUBX/YkvEx6tz3uypvuV2Wad2e+4fW3vb5Ds59yOuelpgsjvIvl4JajcX28
        t7t51Wi4R3OmmbH5xrabI5/v6n4/tqsyye7h0zt7y7Cd5EV/FM578yipD/hJDHsxKfNwkDb/dJ9nRdLs+D3+8dcFP8+G845XV8Npt4oiazRsJ8kGcWnjZt2iTKvj3r2t
        ycVHHFZFvQrTxl+bhzmSO5/aaVX/rc8pMe9Wx8tfpUs7os879a9d+r/GX6TGn/nPy5rw30nZC9tFWcb2bT8f1wdtfiyX9n3/I48x7B8nZT+Pgxk/o3cddImnpm/jjPTn
        MKvSMjY+lA815SC8HN8M+8N+v1zjBfp6MGofF6sa8/HSTkpvYhaTwQp+3H9b4oiD9Gg4/3ro+owPszTPpgzvj+sfpEW+8A+wOifLsj5x1if5sJfmH+LRCtbov1Yx7eTb
        /60Me7CK39DljXpwXA96XGRHK1sDSzsHXIy6ogWwgklX8ukvbc73h+FFUq3kNPX0jjPu5MlhFusz6tFwch0atoflSePP/F5P/xczjr9CSx+xKod3nfDql3wdJryv/zJa
        9D+Ldj7V/94NW6Nqgavg+tLpyS/NxtoEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
        AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
        AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
        AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
        AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
        AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
        AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
        AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
        AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
        AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
        AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
        AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
        AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
        AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
        AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
        AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
        AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
        AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
        AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
        AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
        AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
        AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
        AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
        AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
        AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
        AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
        AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAGbY7v711/RWd696cba1u/fb5ubu9k/1/ZsnH7+T
        vnY8Nv/Y2jo7HsXOznd8/875/enH/S/3bxV75cvp/Xvlm/eP3k6fXY2evOmObz1LOk/P1tP25vDRf6Y3d7efTu+/vN6+z/sffL1rrbXWWmuttdZaa6211lprrbXWWmut
        tdZaa6211lprrbXWWmuttdZaa6211lprrbXWWmuttdZaa6211lprrbXWWmuttdZaa6211lprrbXWWmuttdZaa6211lprrbXWWmuttdZaa6211lprrbXWWmuttdZaa621
        1lprrbXWWmuttdZaa6211lprrbXWWmuttdZaa6211lprrbXWWmuttdZaa6211lprrbXWWmuttdZaa6211lprrbXWWmuttdZaa6211lprrbXWWmuttdZaa6211lprrbXW
        WmuttdZaa6211lprrbXWWmuttdZaa6211lprrbXWWmuttdZaa6211lprrbXWWmuttdZaa6211lprrbXWWmuttdZaa6211lprrbXWWmuttdZaa6211lprrbXWWmuttdZa
        a6211lprrbXWWmuttdZaa6211lprrbXWWmuttdZaa6211lprrbXWWmuttdZaa6211lprrbXWWmuttdZaa6211lprrbXWWmuttdZaa6211lprrbXWWmuttdZaa6211lpr
        rbXWWmuttdZaa6211lprrbXWWmuttdZaa6211lprrbXWWmuttdZaa6211lprrbXWWmuttdZaa6211lprrbXWWmuttdZaa6211lprrbXWWmuttdZaa6211lprrbXWWmut
        tdZaa6211lprrbXW+rtuAABYR62NMMvpD7O3t14nZdIL72I5SIu8FX4Pn2c/cPzYg1E/jh/SerubV605rzh+4LskG04e+WTONDM239h2c+TWiySdO+PFdM/SdlXvTFKO
        Zs54Md2cXW1tjfrJYND0YGwVRdboYHSSbBAX/Himo4Tbdvz6PM+zImn26TxacJidLPZiXoWXSe+243dlmv2qTPNuo3GmH++CM42fE3bz/rAKe7FTPfxBujxQ0f4Qj9Zw
        pPCq0xnE9TpYb9Lu8bpM9GpYrdmCOptonVbUlZnWa0l9GW0N19RBmfbWb6KwkyeHWeOT+kp/8i5OVEsfpyqHi05zaZGvwzirvVybt4z+7uVaVhwm2T1csK38wmS6I4t+
        ySbPCmt0NflNrZ7JeWAvnsR/wgq6tDOLXnRPzsyhPTxM2yHNq1j2iywZ723oFOV0yyDp9evH9GPyIRzFKk4OxjqcruqlE7tlUtXXB3vF8CiP9b9lvvZZXBludT+B5/O8
        OollJys+rsU39HyqgyKLZZK31+BIfVNnjenv9T/ltHF5b5w3nDecN5Zz3tiYU2c3J3+nO9b6M/lv/X2ZsRtzhr4Y8fHlV0nzO73KxunG/wH/uxcJ
        AAAQAAAA
      >
      MULTIFXLINK 0
      FLOATPOS 0 0 0 0
      WAK 0 0
      <COMMENT
        0KjRg9C80L7QtNCw0LIgKNGB0LrQvtGA0LzQuCDQvtCx0YDQsNC30LXRhiDRiNGD0LzQsCk=
      >
      BYPASS 0 0 0
      <VST "VST3: SPL De-Verb Plus (Plugin Alliance)" "SPL De-Verb Plus.vst3" 0 "" 1306188935{5653545350445073706C2064652D7665} ""
        h9zaTe5e7f4EAAAAAQAAAAAAAAACAAAAAAAAAAQAAAAAAAAACAAAAAAAAAAEAAAAAQAAAAAAAAACAAAAAAAAAAQAAAAAAAAACAAAAAAAAABoAQAAAQAAAP//EAA=
        rAAAAAEAAABCWENrAAAApEVmY3QAAACQUG10cgAAAIgAAACQAAAABgAAAAQAAAAAUHJlcwAAAAAAAAAAAAAAAAAAAABQb3dyP4AAAD+AAAA/gAAAP4AAAERlVmIAAAAA
        AAAAAAAAAAAAAAAAT3V0cD8AAAA/AAAAPwAAAD8AAABNaXh4P4AAAD+AAAA/gAAAP4AAAExpbXQ/gAAAP4AAAD+AAAA/gAAAQnlwYQAAAAQAAAAArAAAAAAAAABCWENr
        AAAApEVmY3QAAACQUG10cgAAAIgAAACQAAAABgAAAAQAAAAAUHJlcwAAAAAAAAAAAAAAAAAAAABQb3dyP4AAAD+AAAA/gAAAP4AAAERlVmIAAAAAAAAAAAAAAAAAAAAA
        T3V0cD8AAAA/AAAAPwAAAD8AAABNaXh4P4AAAD+AAAA/gAAAP4AAAExpbXQ/gAAAP4AAAD+AAAA/gAAAQnlwYQAAAAQAAAAA
        AAAQAAAA
      >
      MULTIFXLINK 0
      FLOATPOS 0 0 0 0
      WAK 0 0
      <COMMENT
        0JTQtS3QstC10YDQsSAtINGD0LHQuNGA0LDQtdGCICLQutC+0LzQvdCw0YLRgyIgKNC80LXQvdGM0YjQtSAtMTIg0YHRgtCw0LLQuNGC0Ywg0L3QsCDRgdCy0L7QuSDR
        gdGC0YDQsNGFINC4INGA0LjRgdC6KQ==
      >
      BYPASS 0 0 0
      <VST "VST3: Pro-Q 3 (FabFilter)" "FabFilter Pro-Q 3.vst3" 0 "" 756089518{72C4DB717A4D459AB97E51745D84B39D} ""
        rgIRLe5e7f4IAAAAAQAAAAAAAAACAAAAAAAAAAQAAAAAAAAACAAAAAAAAAAQAAAAAAAAACAAAAAAAAAAQAAAAAAAAACAAAAAAAAAAAQAAAABAAAAAAAAAAIAAAAAAAAA
        BAAAAAAAAAAIAAAAAAAAAAoGAAABAAAAAAAQAA==
        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
        ZWQAAAAAAACAPw==
        AAAQAAAA
      >
      MULTIFXLINK 0
      FLOATPOS 0 0 0 0
      WAK 0 0
      <COMMENT
        0K3QutCy0LDQu9Cw0LnQt9C10YAgLSDQv9GA0LDQstC40YLRjCDQkNCn0KU=
      >
      BYPASS 0 0 0
      <VST "VST3: Kramer PIE Stereo (Waves)" "WaveShell1-VST3 17.1_x64.vst3" 0 "" 850400258{565354505945536B72616D6572207069} ""
        AhSwMu5e7f4CAAAAAQAAAAAAAAACAAAAAAAAAAQAAAABAAAAAAAAAAIAAAAAAAAABAAAAAAAAAAIAAAAAAAAADoGAAABAAAA//8QAA==
        KgYAAAEAAAAAAAYIAAAAAwAAAAFQWUVTc2V0QQAABexYUHN0PFByZXNldENodW5rWE1MVHJlZSB2ZXJzaW9uPSIzIj4KIDxQcmVzZXQgTmFtZT0iIiBHZW5lcmljVHlw
        ZT0iUFlJRSI+CiAgPFByZXNldEhlYWRlcj4KICAgPFBsdWdpbk5hbWU+S3JhbWVyIFBJRTwvUGx1Z2luTmFtZT4KICAgPFBsdWdpblN1YkNvbXA+UFlFUzwvUGx1Z2lu
        U3ViQ29tcD4KICAgPFBsdWdpblZlcnNpb24+MTcuMS40Mi41MDwvUGx1Z2luVmVyc2lvbj4KICAgPEFjdGl2ZVNldHVwPlNFVFVQX0E8L0FjdGl2ZVNldHVwPgogICA8
        TG9hZE1lbnVDYXRlZ29yeT5GYWN0b3J5PC9Mb2FkTWVudUNhdGVnb3J5PgogICA8UmVhZE9ubHk+dHJ1ZTwvUmVhZE9ubHk+CiAgPC9QcmVzZXRIZWFkZXI+CiAgPFBy
        ZXNldERhdGEgU2V0dXA9IlNFVFVQX0EiPgogICA8UGFyYW1ldGVycyBUeXBlPSJSZWFsV29ybGQiPgoyIDIgMSAqICogKiAqICogKiAqCjMuMjcwMDAwMDAwMDAwMDAw
        MDE3OCAwLjc2MDAwMDAwMDAwMDAwMDAwODg4IDE5IDAuNTg0OTk5OTk5OTk5OTk5OTY0NDcgMiAtNzYuNzAwMDAwMDAwMDAwMDAyODQyIDEwMC41OTk5OTk5OTk5OTk5
        OTQzMiAwLjkwNzAwMDAwMDAwMDAwMDAyODQyIDE3IDIuMTAwMDAwMDAwMDAwMDAwMDg4OAo1MCAtMC41IC0wLjA5OTk5OTk5OTk5OTk5OTk3Nzc5NiAqIDAuMDI2OTk5
        OTk5OTk5OTk5OTk5Njk1IDEuODg3OTk5OTk5OTk5OTk5OTAwNSAxIDExLjMwMDAwMDAwMDAwMDAwMDcxMSAtNy45MDAwMDAwMDAwMDAwMDAzNTUzIC0yMC41Ci0xOCAw
        IDAuOTk0OTk5OTk5OTk5OTk5OTk1NTYgLTEwICogMSAtNzMuNTk5OTk5OTk5OTk5OTk0MzE2IDEyMjIgLTYuNSAxMDYKNS43OTk5OTk5OTk5OTk5OTk4MjI0IDUgMjcu
        ODAwMDAwMDAwMDAwMDAwNzExIDE4CjwvUGFyYW1ldGVycz4KICAgPFBsdWdpblNwZWNpZmljWE1MRGF0YSAvPgogIDwvUHJlc2V0RGF0YT4KICA8UHJlc2V0RGF0YSBT
        ZXR1cD0iU0VUVVBfQiIgU2V0dXBOYW1lPSJNeSBEZWZhdWx0IFByZXNldCI+CiAgIDxQYXJhbWV0ZXJzIFR5cGU9IlJlYWxXb3JsZCI+CjIgMiAxICogKiAqICogKiAq
        ICoKMy4yNzAwMDAwMDAwMDAwMDAwMTc4IDAuNzYwMDAwMDAwMDAwMDAwMDA4ODggMTkgMC41ODQ5OTk5OTk5OTk5OTk5NjQ0NyAyIC03Ni43MDAwMDAwMDAwMDAwMDI4
        NDIgMTAwLjU5OTk5OTk5OTk5OTk5NDMyIDAuOTA3MDAwMDAwMDAwMDAwMDI4NDIgMTcgMi4xMDAwMDAwMDAwMDAwMDAwODg4CjUwIC0wLjUgLTAuMDk5OTk5OTk5OTk5
        OTk5OTc3Nzk2ICogMC4wMjY5OTk5OTk5OTk5OTk5OTk2OTUgMS44ODc5OTk5OTk5OTk5OTk5MDA1IDEgNiAtNy45MDAwMDAwMDAwMDAwMDAzNTUzIC0yMC41Ci0xOCAw
        IDAuOTk0OTk5OTk5OTk5OTk5OTk1NTYgMCAqIDEgLTczLjU5OTk5OTk5OTk5OTk5NDMxNiAxMjIyIC02LjUgMTA2CjUuNzk5OTk5OTk5OTk5OTk5ODIyNCA1IDI3Ljgw
        MDAwMDAwMDAwMDAwMDcxMSAxOAo8L1BhcmFtZXRlcnM+CiAgIDxQbHVnaW5TcGVjaWZpY1hNTERhdGEgLz4KICA8L1ByZXNldERhdGE+CiA8L1ByZXNldD4KPC9QcmVz
        ZXRDaHVua1hNTFRyZWU+CjxCeXBhc3MgVmVyc2lvbj0iMSIgQnlwYXNzPSIwIiAvPgoAAAAAAAAAAA==
        AAAQAAAA
      >
      MULTIFXLINK 0
      FLOATPOS 0 0 0 0
      WAK 0 0
      <COMMENT
        0JrQvtC80L/RgNC10YHRgdC+0YAgLSDRgdC20LjQvNCw0LXRgiAo0YPQttC1INC90LDRgNGD0LvQtdC9KQ==
      >
      BYPASS 0 0 0
      <VST "VST3: SPL De-Esser (Plugin Alliance)" "SPL De-Esser.vst3" 0 "" 753351401{5653545350443173706C2064652D6573} ""
        6TrnLO5e7f4EAAAAAQAAAAAAAAACAAAAAAAAAAQAAAAAAAAACAAAAAAAAAAEAAAAAQAAAAAAAAACAAAAAAAAAAQAAAAAAAAACAAAAAAAAAAIAQAAAQAAAP//EAA=
        fAAAAAEAAABCWENrAAAAdEVmY3QAAABgUG10cgAAAFgAAABgAAAABgAAAAIAAAAAUHJlcwAAAAAAAAAATWlTaQAAAAAAAAAAQWN0MT+AAAA/gAAAUmVkMQAAAAAAAAAA
        QXV0MT+AAAA/gAAARmx0cgAAAAAAAAAAQnlwYQAAAAQAAAAAfAAAAAAAAABCWENrAAAAdEVmY3QAAABgUG10cgAAAFgAAABgAAAABgAAAAIAAAAAUHJlcwAAAAAAAAAA
        TWlTaQAAAAAAAAAAQWN0MT+AAAA/gAAAUmVkMQAAAAAAAAAAQXV0MT+AAAA/gAAARmx0cgAAAAAAAAAAQnlwYQAAAAQAAAAA
        AAAQAAAA
      >
      MULTIFXLINK 0
      FLOATPOS 0 0 0 0
      WAK 0 0
      <COMMENT
        0KPQsdC40YDQsNC10YIg0KEt0LrQuCAo0YHQvNC+0YLRgNC4INC90LUg0L/QtdGA0LXQtNCw0LLQuCDQuCDQvdC1INC30LDQsdGD0LTRjCDQstGL0LHRgNCw0YLRjCDQ
        v9Cw0YDQtdC90Ywg0LjQu9C4INC00LXQstGD0YjQutCwKQ==
      >
      BYPASS 0 0 0
      <VST "VST3: Pro-Q 3 (FabFilter)" "FabFilter Pro-Q 3.vst3" 0 "" 756089518{72C4DB717A4D459AB97E51745D84B39D} ""
        rgIRLe5e7f4IAAAAAQAAAAAAAAACAAAAAAAAAAQAAAAAAAAACAAAAAAAAAAQAAAAAAAAACAAAAAAAAAAQAAAAAAAAACAAAAAAAAAAAQAAAABAAAAAAAAAAIAAAAAAAAA
        BAAAAAAAAAAIAAAAAAAAAA4GAAABAAAAAAAQAA==
        sAUAAAEAAABGRkJTAQAAAGYBAAAAAAAAAACAP9pzH0EAAAAAAAAAAAAAgD8AAIA/AAAAPwAAAAAAAIA/AAAAQAAAgD8AAAAAAAAAAAAAgD/acx9BAAAAAAAAAAAAAIA/
        AACAPwAAAD8AAAAAAACAPwAAAEAAAIA/AAAAAAAAAAAAAIA/2nMfQQAAAAAAAAAAAACAPwAAgD8AAAA/AAAAAAAAgD8AAABAAACAPwAAAAAAAAAAAACAP9pzH0EAAAAA
        AAAAAAAAgD8AAIA/AAAAPwAAAAAAAIA/AAAAQAAAgD8AAAAAAAAAAAAAgD/acx9BAAAAAAAAAAAAAIA/AACAPwAAAD8AAAAAAACAPwAAAEAAAIA/AAAAAAAAAAAAAIA/
        2nMfQQAAAAAAAAAAAACAPwAAgD8AAAA/AAAAAAAAgD8AAABAAACAPwAAAAAAAAAAAACAP9pzH0EAAAAAAAAAAAAAgD8AAIA/AAAAPwAAAAAAAIA/AAAAQAAAgD8AAAAA
        AAAAAAAAgD/acx9BAAAAAAAAAAAAAIA/AACAPwAAAD8AAAAAAACAPwAAAEAAAIA/AAAAAAAAAAAAAIA/2nMfQQAAAAAAAAAAAACAPwAAgD8AAAA/AAAAAAAAgD8AAABA
        AACAPwAAAAAAAAAAAACAP9pzH0EAAAAAAAAAAAAAgD8AAIA/AAAAPwAAAAAAAIA/AAAAQAAAgD8AAAAAAAAAAAAAgD/acx9BAAAAAAAAAAAAAIA/AACAPwAAAD8AAAAA
        AACAPwAAAEAAAIA/AAAAAAAAAAAAAIA/2nMfQQAAAAAAAAAAAACAPwAAgD8AAAA/AAAAAAAAgD8AAABAAACAPwAAAAAAAAAAAACAP9pzH0EAAAAAAAAAAAAAgD8AAIA/
        AAAAPwAAAAAAAIA/AAAAQAAAgD8AAAAAAAAAAAAAgD/acx9BAAAAAAAAAAAAAIA/AACAPwAAAD8AAAAAAACAPwAAAEAAAIA/AAAAAAAAAAAAAIA/2nMfQQAAAAAAAAAA
        AACAPwAAgD8AAAA/AAAAAAAAgD8AAABAAACAPwAAAAAAAAAAAACAP9pzH0EAAAAAAAAAAAAAgD8AAIA/AAAAPwAAAAAAAIA/AAAAQAAAgD8AAAAAAAAAAAAAgD/acx9B
        AAAAAAAAAAAAAIA/AACAPwAAAD8AAAAAAACAPwAAAEAAAIA/AAAAAAAAAAAAAIA/2nMfQQAAAAAAAAAAAACAPwAAgD8AAAA/AAAAAAAAgD8AAABAAACAPwAAAAAAAAAA
        AACAP9pzH0EAAAAAAAAAAAAAgD8AAIA/AAAAPwAAAAAAAIA/AAAAQAAAgD8AAAAAAAAAAAAAgD/acx9BAAAAAAAAAAAAAIA/AACAPwAAAD8AAAAAAACAPwAAAEAAAIA/
        AAAAAAAAAAAAAIA/2nMfQQAAAAAAAAAAAACAPwAAgD8AAAA/AAAAAAAAgD8AAABAAACAPwAAAAAAAAAAAACAP9pzH0EAAAAAAAAAAAAAgD8AAIA/AAAAPwAAAAAAAIA/
        AAAAQAAAgD8AAAAAAAAAAAAAgD/acx9BAAAAAAAAAAAAAIA/AACAPwAAAD8AAAAAAACAPwAAAEAAAIA/AAAAAAAAAAAAAIA/2nMfQQAAAAAAAAAAAACAPwAAgD8AAAA/
        AAAAAAAAgD8AAABAAACAPwAAAAAAAAAAAACAPwAAgD8AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIA/AACAPwAAgL8AAIA/AAAAQAAAAEAAAEBAAAAAAAAAgD8AAIA/
        AAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
        AAAAAAAAAAAAAAAARkZwcgEAAAAAAAAATgAAAAAAAABGUTNwAwAAAA8AAABEZWZhdWx0IFNldHRpbmf/////AQAAAAsAAABWb2ljZSAxICgyKQAAAABDdVNWAQAAAAAA
        AABGRmVkAAAAAAAAgD8=
        AAAQAAAA
      >
      MULTIFXLINK 0
      FLOATPOS 0 0 0 0
      WAK 0 0
      <COMMENT
        0K3QutCy0LDQu9Cw0LnQt9C10YAgLSDQtdGB0LvQuCDRh9GC0L4t0YLQviDQvdC1INC90YDQsNCy0LjRgtGM0YHRjyDQv9C+0YHQu9C1INC60L7QvNC/0YDQtdGB0YHQ
        uNC4
      >
]==]

-- вставляет FXCHAIN из ANIME_CH[key] в трек-чанк; false, если не получилось
function anime_set_chain(tr,key)
 local ok,chunk=reaper.GetTrackStateChunk(tr,"",false)
 if not ok or not chunk or chunk=="" or chunk:find("<FXCHAIN") then return false end
 local body=ANIME_CH[key]
 local new,n=chunk:gsub(">%s*$",function() return "<FXCHAIN\n"..body.."\n>\n>\n" end)
 if n~=1 then return false end
 return reaper.SetTrackStateChunk(tr,new,false)
end

-- порядок дорожек как в проекте anime_mix; ch = цепочка; main = отправка в мастер
function anime_specs()
 local s={
  {name="Master",ch="master",main=true},
  {name="Raw",ch="raw",main=true},
  {name="Voice (ALL)",ch="voiceall",main=true},
  {name="Effects (All)",ch="effall",main=false},
 }
 for n=1,8 do s[#s+1]={name="Effects (Voice "..n..")",ch="effv",main=false} end
 for n=1,8 do s[#s+1]={name="Voice "..n,ch="voice",main=false} end
 return s
end

function anime_mix_exists()
 for i=0,reaper.CountTracks(0)-1 do
  local _,nm=reaper.GetSetMediaTrackInfo_String(reaper.GetTrack(0,i),"P_NAME","",false)
  if nm=="Voice (ALL)" then return true end
 end
 return false
end

function create_anime_mix()
 if anime_mix_exists() then status="Структура сведения аниме уже есть в проекте, дубль не создан"; return end
 local base=reaper.CountTracks(0)
 local specs=anime_specs()
 reaper.Undo_BeginBlock(); reaper.PreventUIRefresh(1)
 local tracks={}
 local missing={}
 for k,sp in ipairs(specs) do
  reaper.InsertTrackAtIndex(base+k-1,true)
  local tr=reaper.GetTrack(0,base+k-1)
  tracks[k]=tr
  reaper.GetSetMediaTrackInfo_String(tr,"P_NAME",sp.name,true)
  reaper.SetMediaTrackInfo_Value(tr,"B_MAINSEND",sp.main and 1 or 0)
  if not anime_set_chain(tr,sp.ch) then missing[#missing+1]=sp.name end
 end
 -- роутинг: Voice N -> Effects (Voice N) -> Effects (All) -> Voice (ALL) -> мастер
 local EFF_ALL,VOICE_ALL=tracks[4],tracks[3]
 for n=1,8 do
  local eff_v=tracks[4+n]
  local voice=tracks[12+n]
  reaper.CreateTrackSend(voice,eff_v)
  reaper.CreateTrackSend(eff_v,EFF_ALL)
 end
 reaper.CreateTrackSend(EFF_ALL,VOICE_ALL)
 reaper.PreventUIRefresh(-1); reaper.TrackList_AdjustWindows(false)
 reaper.Undo_EndBlock("Dubbing System: anime mix",-1)
 wins_dirty=true
 if #missing>0 then status="Сведение аниме создано, цепочка не записана у: "..table.concat(missing,", ")
 else status="Сведение аниме создано: 20 дорожек, роутинг и цепочки из проекта" end
end

function create_dub_track()
 local idx=reaper.CountTracks(0)
 reaper.Undo_BeginBlock(); reaper.PreventUIRefresh(1)
 reaper.InsertTrackAtIndex(idx,true)
 local tr=reaper.GetTrack(0,idx)
 reaper.GetSetMediaTrackInfo_String(tr,"P_NAME","Дубляж",true)
 local missing,nopreset={},{}
 local from_tpl=set_chain_from_rfx(tr)
 if not from_tpl then
  for _,c in ipairs(DUB_CHAIN) do
   local fi=reaper.TrackFX_AddByName(tr,c.fx,false,-1)
   if fi<0 then missing[#missing+1]=c.fx
   elseif c.preset and c.preset~="" and not reaper.TrackFX_SetPreset(tr,fi,c.preset) then nopreset[#nopreset+1]=c.fx end
  end
 end
 reaper.SetProjExtState(0,SEC,K.dub,track_guid(tr))
 reaper.PreventUIRefresh(-1); reaper.TrackList_AdjustWindows(false)
 reaper.Undo_EndBlock("Dubbing System: dub track",-1)
 wins_dirty=true; dub_time=-10
 if from_tpl then status="Дорожка дубляжа создана, цепочка из шаблона со всеми настройками"
 elseif #missing>0 then status="Дорожка создана, плагины не найдены: "..table.concat(missing,", ")
 elseif #nopreset>0 then status="Цепочка добавлена, пресет «Dubbing» не найден у: "..table.concat(nopreset,", ")
 else status="Дорожка дубляжа создана, цепочка эффектов добавлена" end
end

-- эффекты дорожки дубляжа выключены во время записи и включаются после неё
function set_dub_fx(on)
 local tr=find_track(extget(K.dub,""))
 if not tr then return end
 reaper.SetMediaTrackInfo_Value(tr,"I_FXEN",on and 1 or 0) -- кнопка FX/питание в заголовке дорожки
 for i=0,reaper.TrackFX_GetCount(tr)-1 do reaper.TrackFX_SetEnabled(tr,i,on) end
end
function dub_rec_guard()
 local rec=(reaper.GetPlayState()&4)~=0
 if rec~=dub_rec_off then dub_rec_off=rec; set_dub_fx(not rec) end
end
-- если окно закрыли во время записи, скрипт дальше тихо следит за записью и включит эффекты после остановки
function bg_guard()
 dub_rec_guard()
 if dub_rec_off then reaper.defer(bg_guard) end
end
-- при закрытии окна суфлёра убираем из проекта то, что создали из субтитров: регионы и дорожку с текстовыми итемами
-- (отключается: ExtState DubbingPrompter/clean_on_close = 0; все изменения можно отменить через Ctrl+Z)
function dub_clean_on_close()
 if dub_cleaned then return end
 dub_cleaned=true
 if reaper.GetExtState("DubbingPrompter","clean_on_close")=="0" then return end
 if not rows or #rows==0 then return end
 local want={}
 for _,r in ipairs(rows) do want[(r.text or "").."|"..string.format("%.2f",r.start or 0)]=true end
 reaper.Undo_BeginBlock(); reaper.PreventUIRefresh(1)
 local n,rg,tk=0,0,0
 local _,nm,nr=reaper.CountProjectMarkers(0)
 for i=nm+nr-1,0,-1 do
  local _,isrgn,pos,_,name,idx=reaper.EnumProjectMarkers3(0,i)
  if isrgn and want[(name or "").."|"..string.format("%.2f",pos)] then reaper.DeleteProjectMarkerByIndex(0,i); n=n+1; rg=rg+1 end
 end
 for i=reaper.CountTracks(0)-1,0,-1 do
  local tr=reaper.GetTrack(0,i)
  local _,tn=reaper.GetSetMediaTrackInfo_String(tr,"P_NAME","",false)
  if tn=="Dubbing Subtitles (text items)" then reaper.DeleteTrack(tr); n=n+1; tk=tk+1 end
 end
 reaper.PreventUIRefresh(-1); reaper.UpdateArrange(); reaper.UpdateTimeline()
 reaper.Undo_EndBlock("Dubbing System: убрать регионы и итемы субтитров",-1)
 -- запоминаем, что было, чтобы вернуть при следующем открытии суфлёра
 reaper.SetExtState("DubbingPrompter","restore_regions",rg>0 and "1" or "0",true)
 reaper.SetExtState("DubbingPrompter","restore_items",tk>0 and "1" or "0",true)
end
function quit_loop()
 dub_clean_on_close()
 if dub_rec_off then reaper.defer(bg_guard) end
end

-- ---------- versions ----------
local function ver_dir() return reaper.GetResourcePath().."/DubbingSystem_versions" end

local function list_versions()
 local t,i={},0
 while i<500 do
  local f=reaper.EnumerateFiles(ver_dir(),i)
  if not f then break end
  if type(f)=="string" and f:match("%.dub$") then t[#t+1]=f end
  i=i+1
 end
 table.sort(t)
 return t
end

local function save_version(tag)
 if #rows==0 then return false end
 reaper.RecursiveCreateDirectory(ver_dir(),0)
 local name=os.date("%Y%m%d_%H%M%S")..(tag and ("_"..tag) or "")..".dub"
 local f=io.open(ver_dir().."/"..name,"wb")
 if not f then return false end
 f:write(serialize_rows()); f:close()
 local t=list_versions()
 while #t>40 do os.remove(ver_dir().."/"..table.remove(t,1)) end
 return true
end

-- readable name of a saved version: date, time, kind and what is inside
local function version_label(f)
 local mo,dd,hh,mi,ss,tag=f:match("^%d%d%d%d(%d%d)(%d%d)_(%d%d)(%d%d)(%d%d)_?(%a*)%.dub$")
 if not mo then return f end
 local kind=(tag=="auto") and "авто" or (tag=="manual") and "вручную" or ""
 return string.format("%s.%s  %s:%s:%s%s",dd,mo,hh,mi,ss,kind~="" and ("  ("..kind..")") or "")
end

function restore_version()
 local t=list_versions()
 if #t==0 then status="Сохранённых версий пока нет"; return end
 local items,files={},{}
 local n=math.min(#t,12)
 for i=1,n do
  local f=t[#t-i+1]
  local fh=io.open(ver_dir().."/"..f,"rb")
  local raw=fh and fh:read("*a") or ""
  if fh then fh:close() end
  local list=parse_saved(raw)
  local nd=0
  for _,r in ipairs(list) do if r.done then nd=nd+1 end end
  items[i]=version_label(f).."   — реплик "..#list..", записано "..nd
  files[i]=f
 end
 local idx=popup(items)
 if idx==0 or not files[idx] then return end
 local f=io.open(ver_dir().."/"..files[idx],"rb")
 if not f then status="Не удалось открыть версию"; return end
 local raw=f:read("*a"); f:close()
 local list=parse_saved(raw)
 if #list==0 then status="Версия пуста"; return end
 local msg="Вернуть версию "..version_label(files[idx]).."?\n\nСейчас в сессии "..#rows.." реплик. Текущее состояние можно вернуть через отмену (↶ или Ctrl+Z).\n"
 if reaper.ShowMessageBox(msg,"Dubbing Prompter — восстановить версию",4)~=6 then status="Восстановление отменено"; return end
 push_undo(); rows=list; selected=1; scroll=0
 save(); mark_dirty(); status="Восстановлена версия "..version_label(files[idx])
end

local function autosave_version()
 local now=os.time()
 if now-last_ver_time<300 then return end
 last_ver_time=now
 local cur=serialize_rows()
 if cur~=last_ver_str and #rows>0 then
  if save_version("auto") then last_ver_str=cur end
 end
end

-- full factory reset of SETTINGS: Prompter values, per-track ducking, track assignments,
-- keys/columns and the overlay's own settings. Subtitles, takes and marks stay.
function factory_reset()
 local msg="Полный сброс настроек к заводским?\n\nСбросится: ducking и пре/пост-ролл, фейды, пороги QC, глубина по ролям и по дорожкам, назначение дорожек (оригинал и дубляж), горячие клавиши, колонки, таймкод, настройки оверлея.\n\nРеплики, записи, отметки и версии НЕ трогаются. Назначить дорожки заново придётся вручную."
 if reaper.ShowMessageBox(msg,"Dubbing Prompter — полный сброс настроек",4)~=6 then status="Сброс настроек отменён"; return end
 duck,pre,post,fi,fo=25,100,150,120,220
 only_dub,follow,win_from_dub=false,true,false
 preroll=3
 qc_cps,qc_gap,qc_short=20,0.08,1.0
 frames_mode=false
 role_duck={}
 PREF.keys={play_line=112,loop=108,done=100,mark=98,next_mark=110,best=109,actor=114}
 PREF.cols={takes=true,cps=true,dur=true,over=true,note=true,verdict=true}
 -- per-track ducking depths and track assignments (project level)
 for i=0,reaper.CountTracks(0)-1 do
  local g=track_guid(reaper.GetTrack(0,i))
  if g~="" then reaper.SetProjExtState(0,SEC,"odb_"..g,"") end
 end
 reaper.SetProjExtState(0,SEC,K.orig,"")
 reaper.SetProjExtState(0,SEC,K.dub,"")
 -- overlay settings (its own ExtState section)
 for _,k in ipairs(OV_KEYS) do reaper.DeleteExtState(OV_CFG,k,false) end
 save_prefs(); save(); mark_dirty()
 status="Все настройки сброшены к заводским (реплики сохранены)"
end

-- clears the session content: subtitles, takes marks, verdicts. Versions stay on disk.
function clear_session()
 if #rows==0 then status="Сессия уже пустая"; return end
 local msg="Очистить сессию?\n\nБудут удалены все реплики ("..#rows.."), отметки «записано», оценки и заметки. Настройки не меняются.\n\nСохранённые версии остаются на диске и восстанавливаются через «Восстановить версию»."
 if reaper.ShowMessageBox(msg,"Dubbing Prompter — очистка сессии",4)~=6 then status="Очистка отменена"; return end
 push_undo()
 rows={}; selected=1; scroll=0; search=""; role_filter=""; status_filter=""
 vis={}; roles={}; role_idx={}
 save(); mark_dirty(); rebuild_vis()
 status="Сессия очищена. Настройки и версии сохранены"
end

-- ---------- subtitles embedded in a video (MKV/MP4) via ffprobe / ffmpeg ----------
-- Needs ffmpeg.exe and ffprobe.exe either in Scripts\DubbingSystem or on PATH.
function ffq(x) return '"'..(tostring(x):gsub('"',''))..'"' end
function ff_tool(name)
 local exe=reaper.GetResourcePath().."/Scripts/DubbingSystem/"..name..".exe"
 local f=io.open(exe,"rb")
 if f then f:close(); return ffq(exe) end
 return name
end
-- runs a command and returns its output. ExecProcess passes Unicode paths (Cyrillic folders)
-- correctly; io.popen (cmd.exe) mangles them, so it is only a fallback
function ff_capture(cmd)
 if reaper.ExecProcess then
  local ok,out=pcall(reaper.ExecProcess,cmd,60000)
  if ok and type(out)=="string" then return out end
 end
 local ok,p=pcall(io.popen,cmd.." 2>&1")
 if not ok or not p then return nil end
 local out=p:read("*a"); p:close(); return out or ""
end
-- subtitle streams of the file: {index, codec, lang, title, default}
function probe_subs(video)
 local out=ff_capture(ff_tool("ffprobe").." -v error -select_streams s -show_entries stream=index,codec_name:stream_tags=language,title:stream_disposition=default -of flat "..ffq(video))
 out=out or ""
 if not out:find("streams%.stream") then
  if out:find("not recognized") or out:find("not found") or out:find("не является") then return nil,"Нужен ffprobe: положи ffmpeg.exe и ffprobe.exe в папку Scripts\\DubbingSystem" end
  return nil,"В файле нет дорожек субтитров (или ffprobe не запустился)"
 end
 local st={}
 for n,k,v in out:gmatch("streams%.stream%.(%d+)%.([%w_%.]+)=([^\r\n]*)") do
  local i=tonumber(n); st[i]=st[i] or {}
  st[i][k]=(v:gsub('^"(.*)"$','%1'))
 end
 local list={}
 for n=0,200 do
  local t=st[n]
  if t then
   list[#list+1]={index=tonumber(t["index"]),codec=t["codec_name"] or "?",lang=t["tags.language"] or "",
                  title=t["tags.title"] or "",default=(t["disposition.default"]=="1")}
  end
 end
 if #list==0 then return nil,"В файле нет дорожек субтитров" end
 return list
end
-- graphic subtitles (images) cannot be turned into text
function sub_is_graphic(codec)
 return codec=="hdmv_pgs_subtitle" or codec=="dvd_subtitle" or codec=="dvb_subtitle" or codec=="xsub"
end
function import_from_video(video,auto)
 if not video then
  local ok,v=reaper.GetUserFileNameForRead("","Видео со вшитыми субтитрами (MKV / MP4)","")
  if not ok then return end
  video=v
 end
 local list,err=probe_subs(video)
 if not list then status=err; return end
 local labels={}
 for i,t in ipairs(list) do
  local l=(t.lang~="" and t.lang or "?")
  local name=(t.title~="" and (" · "..t.title) or "")
  local tail=sub_is_graphic(t.codec) and " (картинки, не извлечь)" or ""
  labels[i]=((i..". "..l.." · "..t.codec..name..tail):gsub("|","/"))
 end
 local pick
 local ngood=0
 for _,t in ipairs(list) do if not sub_is_graphic(t.codec) then ngood=ngood+1 end end
 if auto and ngood<=1 then
  -- одна текстовая дорожка: берёт её сама; если дорожек несколько, спрашивает язык
  local function good(t) return not sub_is_graphic(t.codec) end
  for i,t in ipairs(list) do if good(t) and (t.lang=="rus" or t.lang=="ru") then pick=i; break end end
  if not pick then for i,t in ipairs(list) do if good(t) and t.default then pick=i; break end end end
  if not pick then for i,t in ipairs(list) do if good(t) then pick=i; break end end end
  if not pick then status="В файле только графические субтитры (картинки), текст не извлечь"; return end
 else
  pick=popup(labels)
 end
 if not pick or pick<1 then status="Дорожка не выбрана"; return end
 local t=list[pick]
 if sub_is_graphic(t.codec) then status="Дорожка «"..t.codec.."» — это картинки, текст из неё не извлечь"; return end
 local pp=reaper.GetProjectPath("")
 local outp=pp.."/Dubbing_subs_"..(t.lang~="" and t.lang or ("track"..t.index))..".srt"
 os.remove(outp)
 ff_capture(ff_tool("ffmpeg").." -v error -y -i "..ffq(video).." -map 0:"..t.index.." -c:s srt "..ffq(outp))
 local f=io.open(outp,"rb")
 if not f then status="ffmpeg не смог извлечь дорожку (проверь, что ffmpeg.exe на месте)"; return end
 local size=f:seek("end"); f:close()
 if not size or size==0 then status="ffmpeg создал пустой файл: дорожка не извлечена"; return end
 load_subs_path(outp,"Из видео, дорожка "..t.index.." ("..(t.lang~="" and t.lang or "?")..")")
end

-- одна кнопка: выбрать файл (видео или .srt/.ass/.ssa/.txt) → субтитры → регионы → текстовые итемы
function import_all()
 local ok,path=reaper.GetUserFileNameForRead("","Импорт: видео (MKV/MP4) или субтитры (SRT/ASS/SSA/TXT)","")
 if not ok then return end
 local ext=(path:match("%.([%w]+)$") or ""):lower()
 if ext=="srt" or ext=="ass" or ext=="ssa" or ext=="txt" then load_subs_path(path)
 else import_from_video(path,true) end
 if #rows==0 then return end
 local n=#rows
 to_regions(true); to_items(true)
 status="Готово: реплик "..n..", регионы и текстовые итемы созданы"
end

-- ---------- суфлёр на телефон / планшет (через веб-интерфейс REAPER) ----------
-- Prompter кладёт prompter.html с репликами в <папка ресурсов REAPER>/reaper_www_root.
-- Страница сама читает позицию с http://IP:ПОРТ/_/TRANSPORT. Всё в одной таблице Mobile,
-- чтобы не тратить локальные переменные главного блока (лимит Lua: 200).
Mobile={on=false,last=0,sport=8765,dir="",cfgSig=nil,sig=nil,voff=0,vname="",vpath="",vlen=0,enc=nil,ver="",url=nil,roles=true}
Mobile.TEMPLATE=[==[<!doctype html>
<html lang="ru"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover,user-scalable=no">
<meta name="theme-color" content="#0f141c">
<title>Суфлёр</title>
<link rel="preconnect" href="https://fonts.googleapis.com"><link href="https://fonts.googleapis.com/css2?family=Barlow+Condensed:wght@500;600;700&family=Golos+Text:wght@400;500;600;700&display=swap" rel="stylesheet">
<!--VER:@@VER@@-->
<style>
:root{color-scheme:dark;--fs:1;--bg:#0b0d12;--tx:#8b93a1;--cur:#3a3d44}
*{box-sizing:border-box;-webkit-tap-highlight-color:transparent}
html,body{margin:0;height:100%;background:var(--bg);color:var(--tx);font-family:system-ui,-apple-system,"Segoe UI",Roboto,sans-serif;overflow:hidden}
body{display:flex;flex-direction:column;padding:env(safe-area-inset-top) env(safe-area-inset-right) 0 env(safe-area-inset-left)}
#top{flex:none;height:40px;display:flex;align-items:center;gap:6px;overflow-x:auto;padding:0 10px;background:#12151c;border-bottom:1px solid #20242e;font-size:14px;white-space:nowrap}
#dot{width:10px;height:10px;border-radius:50%;background:#e5534b;flex:none}
#dot.ok{background:#3fb950}
#tm{font-variant-numeric:tabular-nums;color:#c9d1d9;min-width:58px}
#cnt{margin-left:auto;color:#8b93a1;font-variant-numeric:tabular-nums}
.tb{flex:none;background:#1c212b;color:#c9d1d9;border:1px solid #2a303c;border-radius:8px;height:28px;min-width:28px;font:inherit;font-size:13px;padding:0 4px}
.tb.on{background:#c9d1d9;color:#0b0d12}
#diag{flex:none;display:none;background:#3b1d1d;color:#ffb4ab;padding:8px 12px;font-size:13px;line-height:1.35}
#list{flex:1;overflow-y:auto;padding:10px 10px 40vh;-webkit-overflow-scrolling:touch;scroll-behavior:smooth}
.cue{padding:10px 12px 10px 14px;margin:6px 0;border-left:6px solid transparent;border-radius:6px;font-size:calc(1.05rem*var(--fs));line-height:1.3;color:var(--tx)}
.cue .r{display:block;font-size:.72em;font-weight:600;margin-bottom:2px;letter-spacing:.03em}
.cue .t{white-space:pre-wrap;overflow-wrap:anywhere}
.cue.past{opacity:.55}
body.noroles .cue .r{display:none}
body.single #list{display:flex;flex-direction:column;padding:16px;overflow-y:auto}
body.single .cue:not(.cur){display:none}
body.single .cue.cur{background:none;border-left:0;text-align:center;font-size:calc(2.6rem*var(--fs));line-height:1.2;padding:0;margin:auto 0;width:100%}
body.hasvid.single .cue.cur{font-size:calc(1.9rem*var(--fs))}
body.single .cue.cur .r{font-size:.4em;margin-bottom:.5em}
body.nobar #bar{display:none}
@media(max-width:430px){#cnt{display:none}}
#top{order:1}#diag{order:2}#list{order:3}#bar{order:4}
#vwrap{display:none;order:1;position:relative;flex:0 0 38vh;background:#000}
#vid{width:100%;height:100%;object-fit:contain;background:#000;display:block}
#vph{position:absolute;inset:0;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:12px;text-align:center;padding:12px;color:#8b93a1;font-size:14px}
#vmsg{white-space:pre-line}
#vph button{background:#2f4f8f;color:#fff;border:0;border-radius:10px;height:40px;padding:0 18px;font:inherit;font-weight:700}
#vsh{position:absolute;right:6px;bottom:6px;display:none;align-items:center;gap:4px;background:rgba(0,0,0,.6);border-radius:8px;padding:2px 4px;font-size:12px;color:#c9d1d9}
#vinfo{opacity:.75;margin-right:2px}
#vprog{position:absolute;left:8px;top:8px;display:none;background:rgba(0,0,0,.6);color:#c9d1d9;border-radius:8px;padding:3px 8px;font-size:12px}
#vnote{position:absolute;left:8px;right:8px;top:8px;display:none;background:rgba(0,0,0,.65);color:#ffd9a8;border-radius:8px;padding:6px 10px;font-size:13px;text-align:center}
#vsh button{background:#232936;color:#e6edf3;border:0;border-radius:6px;height:26px;min-width:28px;font:inherit}
body.hasvid #vwrap{display:block}
body.hasvid #top{order:2;border-top:1px solid #20242e}
body.hasvid #bar{order:3;padding:6px 10px;border-top:0;border-bottom:1px solid #20242e}
body.hasvid #bar button{height:46px;font-size:1rem}
body.hasvid #diag{order:4}
body.hasvid #list{order:5}
@media(orientation:landscape){
body.hasvid{display:grid;grid-template-columns:56% 44%;grid-template-rows:auto auto auto minmax(0,1fr)}
body.hasvid #vwrap{grid-column:1;grid-row:1/5;flex:none;order:0}
body.hasvid #top{grid-column:2;grid-row:1;order:0;border-top:0}
body.hasvid #bar{grid-column:2;grid-row:2;order:0}
body.hasvid #diag{grid-column:2;grid-row:3;order:0}
body.hasvid #list{grid-column:2;grid-row:4;order:0;min-height:0}
}
.cue.cur{background:var(--cur);border-left-color:#fff;color:#fff;font-weight:800;font-size:calc(1.75rem*var(--fs));line-height:1.25;opacity:1}
.cue.cur .r{font-size:.5em}
#empty{padding:30px 16px;text-align:center;font-size:1.1rem;color:#8b93a1}
#bar{flex:none;display:flex;gap:10px;padding:10px 10px calc(10px + env(safe-area-inset-bottom));background:#12151c;border-top:1px solid #20242e}
#bar button{flex:1;height:56px;border:0;border-radius:12px;background:#232936;color:#e6edf3;font:inherit;font-size:1.1rem;font-weight:700}
#bar button:active{background:#323a4a}
#bar #nx{background:#2f4f8f}
body.lock #bar button,body.lock #list .cue{pointer-events:none}
body.lock #bar{opacity:.4}
#top{display:none}body.showtop #top{display:flex}
#bar{display:none}body.showbar #bar{display:flex}
#dots{position:fixed;left:0;right:0;bottom:0;z-index:50;display:flex;justify-content:center;align-items:center;gap:6px;padding:4px 0 calc(6px + env(safe-area-inset-bottom));pointer-events:none}
#dots button{pointer-events:auto;width:44px;height:36px;border:0;background:none;padding:0;display:flex;align-items:center;justify-content:center;opacity:.55}
#dots button i{display:block;width:13px;height:13px;border-radius:50%}
#dots button.on{opacity:1}#dots button.on i{box-shadow:0 0 0 2px #0f141c,0 0 0 3.5px #fff}
#dots button.tx{font:600 15px system-ui;color:#c3cad6;opacity:.7}
body.showbar #dots{bottom:76px}
body.single #list{padding-bottom:60px}
.cue .t{white-space:normal}
/* ---- 2.0 новый вид ---- */
:root{--bg:#0f141c;--tx:#8a94a6;--cur:#1a2236;--cond:"Barlow Condensed","Roboto Condensed","Arial Narrow","Helvetica Neue",system-ui,sans-serif}
html,body{font-family:"Golos Text",system-ui,-apple-system,"Segoe UI",Roboto,sans-serif}
#top{height:48px;background:#0f141c;border-bottom:1px solid #232b38;gap:5px;padding:0 10px}
#dot{width:9px;height:9px;background:#5b6577}#dot.ok{background:#4ade80}
#tm{font:600 17px/1 var(--cond);letter-spacing:.02em;color:#c3cad6;min-width:52px}
#cnt{font:600 12px var(--cond);letter-spacing:.12em;color:#8a94a6}
.tb{background:transparent;border:1px solid #232b38;color:#8a94a6;border-radius:8px;height:30px;min-width:28px;padding:0 3px}
.tb.on{background:#4c5cff;border-color:#4c5cff;color:#fff}
#list{padding:6px 0 40vh}
.cue{margin:0;padding:13px 16px;border-left:3px solid transparent;border-bottom:1px solid #1b2230;border-radius:0;font-size:calc(1rem*var(--fs));color:#b9c1ce}
.cue .r{font:600 .7em var(--cond);letter-spacing:.16em;text-transform:uppercase;color:#7aa8ff}
.cue.cur{background:#1a2236;border-left-color:#4c5cff;color:#fff;font-weight:600;font-size:calc(1.3rem*var(--fs));line-height:1.3}
body.single #list{background:#0f141c}
body.single .cue.cur{background:none;border:0;font:700 calc(3.4rem*var(--fs))/1.02 var(--cond);letter-spacing:-.005em;color:#fff}
body.hasvid.single .cue.cur{font-size:calc(2.6rem*var(--fs))}
body.single .cue.cur .r{font:600 .26em var(--cond);letter-spacing:.16em;margin-bottom:.8em}
#bar{background:#151b25;border-top:1px solid #232b38;padding:10px 14px calc(12px + env(safe-area-inset-bottom))}
#bar button{height:52px;border-radius:14px;background:#1b2330;border:1px solid #2c3544;font-weight:600}
#bar #nx{background:#f5f7fa;color:#0f141c;border:0;font-weight:700}
#bar button:active{opacity:.8}
#vwrap{background:#000}
</style></head><body>
<div id="vwrap"><video id="vid" muted playsinline preload="auto"></video>
<div id="vph"><div id="vmsg">Видео не выбрано</div><button id="pcv" style="display:none">Повторить</button><button id="pick">Выбрать файл на телефоне</button></div>
<div id="vprog"></div><div id="vnote"></div>
<div id="vsh"><span id="vinfo"></span><button id="au" title="Звук">🔊</button><button id="vre" title="Другой файл">📁</button><button id="vm">−</button><span id="vs" title="Сдвиг видео, мс">+0</span><button id="vpl">+</button></div></div>
<input type="file" id="vfile" accept="video/*" hidden>
<div id="top"><span id="dot"></span><span id="tm">--:--.-</span><span id="cnt"></span>
<button class="tb" id="rl" title="Имена ролей">Роли</button><button class="tb" id="vw" title="Одна реплика / список">▭</button><button class="tb" id="vb" title="Видео">🎬</button><button class="tb" id="bt" title="Кнопки Назад / Следующая">◀▶</button><button class="tb" id="fm">A−</button><button class="tb" id="fp">A+</button><button class="tb" id="lk">🔒</button></div>
<div id="diag"></div>
<div id="list"></div>
<div id="bar"><button id="pv">◀ Назад</button><button id="nx">Следующая ▶</button></div>
<script>
"use strict";
var VER="@@VER@@";
var TPL="8.0.0";
var CUES=/*@@CUES@@*/[];
var ROLES=/*@@ROLES@@*/true;
var CLIPS=/*@@CLIPS@@*/[];
var VSRC=/*@@VSRC@@*/"";
var vbase="",vtag="";
var VURL=/*@@VURL@@*/"";
var $=function(s){return document.querySelector(s)};
var idx=-1,pos=0,fails=0,els=[],fs=1,lock=false,okOnce=false,showRoles=ROLES,single=false,bar=true,showVid=true,vshift=0,vready=false,tFetch=0,playing=false,vurl=null;
var vid=document.getElementById("vid");
var loadedName="",vgone=false,audioOn=true,soundBlocked=false;
var srvInfo=null,audioMsg="",audioDead=false,usingProxy=false,aTick=0;
try{fs=parseFloat(localStorage.getItem("dp_fs"))||1;lock=localStorage.getItem("dp_lock")==="1";single=localStorage.getItem("dp_view")!=="0";bar=true;showVid=localStorage.getItem("dp_video")!=="0";vshift=parseFloat(localStorage.getItem("dp_vshift"))||0;audioOn=localStorage.getItem("dp_audio")!=="0";
  var ro=localStorage.getItem("dp_roles"),rb=localStorage.getItem("dp_roles_base");
  if(ro!==null&&rb===(ROLES?"1":"0"))showRoles=(ro==="1")}catch(e){}
function applyFs(){document.documentElement.style.setProperty("--fs",fs);try{localStorage.setItem("dp_fs",fs)}catch(e){}}
function applyRoles(){document.body.classList.toggle("noroles",!showRoles);$("#rl").classList.toggle("on",showRoles);if(idx>=0&&els[idx])els[idx].scrollIntoView({block:"center"})}
function applyView(){document.body.classList.toggle("single",single);$("#vw").classList.toggle("on",single);if(!single&&idx>=0&&els[idx])els[idx].scrollIntoView({block:"center"})}
function applyBar(){document.body.classList.toggle("nobar",!bar);$("#bt").classList.toggle("on",bar)}
function applyVid(){document.body.classList.toggle("hasvid",showVid);$("#vb").classList.toggle("on",showVid);if(!showVid&&!vid.paused)vid.pause();vsync()}
function vshowShift(){$("#vs").textContent=(vshift>=0?"+":"")+Math.round(vshift*1000)}
function activeClip(p){var r=-1;for(var i=0;i<CLIPS.length;i++){var c=CLIPS[i];if(p>=c[0]-0.001&&p<c[0]+c[1])r=i}return r}
var clk={base:null,rtt:1e9},lead=0.12,seekT=0,calT=0,lastNote="",stIcon="";
function posNow(){return(playing&&clk.base!==null&&fails<3)?clk.base+performance.now()/1000:pos}
function vnote(t){if(t===lastNote)return;lastNote=t;var n=$("#vnote");n.textContent=t;n.style.display=t?"block":"none"}
var rAdj=0,rBase=1,rT=0;
// Подстройка скорости редкими ступенями: частая смена playbackRate сбрасывает растяжение звука и «съедает» ускорение
function ctrlRate(d,rate){
  var now=performance.now();
  if(rBase!==rate){rBase=rate;rAdj=0;vid.playbackRate=rate}
  var a=Math.abs(d),step=a>0.10?0.08:(a>0.05?0.04:0.02),need=0;
  if(rAdj!==0){
    var stop=(rAdj>0&&d>-0.004)||(rAdj<0&&d<0.004);       // дошли до нуля или перешли его
    need=stop?0:step*(d<0?1:-1)
  }else if(a>0.02)need=step*(d<0?1:-1);
  if(need===rAdj)return;
  if(need!==0&&rAdj!==0&&now-rT<500)return;               // менять ступень не чаще раза в полсекунды
  rAdj=need;rT=now;vid.playbackRate=rate*(1+need)
}
function hardSeek(t){seekT=performance.now();vid.currentTime=Math.max(0,t)}
function tryPlay(){
  var p=vid.play();
  if(p&&p.catch)p.catch(function(){
    if(!vid.muted){vid.muted=true;soundBlocked=true;$("#vinfo").textContent=vinfoText();var q=vid.play();if(q&&q.catch)q.catch(function(){})}
  })
}
vid.addEventListener("seeked",function(){
  if(seekT){var lat=(performance.now()-seekT)/1000;lead=Math.min(0.6,Math.max(0.02,lead*0.6+lat*0.4));seekT=0;calT=performance.now()+400}
});
function vsync(){
  if(!vready||!showVid||vgone)return;
  var P=posNow(),ci=activeClip(P),note="";
  if(CLIPS.length){
    if(ci<0)note="Нет видео в этой точке проекта";
    else if(CLIPS[ci][4]!==VSRC)note="Для клипа «"+CLIPS[ci][4]+"» нет копии";
  }
  vnote(note);
  var tag=(CLIPS.length>1&&ci>=0)?" · клип "+(ci+1)+"/"+CLIPS.length:"";
  if(tag!==vtag){vtag=tag;$("#vinfo").textContent=vinfoText()}
  if(note){if(!vid.paused)vid.pause();return}
  var c=ci>=0?CLIPS[ci]:[0,1e9,0,1,VSRC],rate=c[3]||1;
  var tgt=(P-c[0])*rate+c[2]+vshift,dur=vid.duration;
  if(playing){
    if(tgt<0||(dur&&tgt>dur)){if(!vid.paused)vid.pause();if(tgt<0&&vid.currentTime>0.05)vid.currentTime=0;return}
    if(vid.seeking){if(vid.paused)tryPlay();return}
    var d=vid.currentTime-tgt;                        // + : видео впереди, − : видео отстаёт
    if(calT&&performance.now()>=calT){                // самонастройка: куда приземлились после перемотки
      calT=0;if(Math.abs(d)<0.3)lead=Math.min(0.6,Math.max(0.02,lead-d*0.7))
    }
    if(Math.abs(d)>0.15||(vid.paused&&Math.abs(d)>0.05)){rAdj=0;hardSeek(tgt+lead*rate);if(vid.playbackRate!==rate)vid.playbackRate=rate}
    else ctrlRate(d,rate);
    if(vid.paused)tryPlay()
  }else{
    if(!vid.paused)vid.pause();
    rAdj=0;rBase=rate;if(vid.playbackRate!==rate)vid.playbackRate=rate;
    if(vid.seeking)return;
    var t=Math.max(0,tgt);if(dur&&t>dur)t=dur;
    if(Math.abs(vid.currentTime-t)>0.04)vid.currentTime=t
  }
}
function tick(){var P=posNow(),tm=stIcon+fmt(P);if(tm!==lastTm){lastTm=tm;$("#tm").textContent=tm}show(find(P));vsync()}
function setSrc(u,info,kind){
  if(kind==="proxy"&&(sKind==="server"||vurl))return;
  sKind=kind||"file";
  loadedName=VSRC;vgone=false;soundBlocked=false;audioDead=false;aTick=0;
  audioMsg=(kind==="server"&&srvInfo&&!usingProxy)?audioFromInfo(srvInfo):"";
  vready=false;vid.muted=!audioOn;vid.src=u;
  $("#vph").style.display="none";$("#vsh").style.display="flex";vbase=info||"";vtag="";$("#vinfo").textContent=vinfoText()
}
var A_OK={aac:1,mp3:1,opus:1,vorbis:1,flac:1,pcm_s16le:1,pcm_s24le:1,pcm_u8:1,pcm_f32le:1,pcm_s16be:1};
function audioFromInfo(j){
  var a=j&&j.audio;if(!a)return "";
  if(a.length===0)return "в файле нет звука";
  for(var i=0;i<a.length;i++)if(A_OK[a[i]])return "";
  return "формат звука "+a.join("/")+" может не играть на телефоне"
}
function vinfoText(){return vbase+vtag+((audioMsg&&audioOn)?" · "+audioMsg:"")+(soundBlocked?" · нажмите 🔊":"")}
function switchProxy(){
  usingProxy=true;
  setSrc(srvBase()+"/video?src=proxy","сервер · копия","server")
}
function vfail(t){$("#vph").style.display="flex";$("#vsh").style.display="none";$("#vmsg").textContent=t}
var SPORT=/*@@SPORT@@*/8765,sKind="",srvBad=false,srvMsg="",vbaseMsg="",probeFails=0,probeTimer=0,probeBusy=false,lastTm="";
var BACKOFF=[1500,3000,5000,10000,20000,30000];
function srvBase(){return location.protocol+"//"+location.hostname+":"+SPORT}
function srvHint(){
  if(vready||vurl||sKind)return;
  $("#vph").style.display="flex";$("#vsh").style.display="none";
  $("#vmsg").textContent=vbaseMsg+(srvMsg?"\n\n"+srvMsg:"")+"\nНа ПК: Prompter → «Суфлёр: сервер видео».";
  $("#pcv").style.display="inline-block"
}
function schedProbe(ms){clearTimeout(probeTimer);probeTimer=setTimeout(function(){ensureSource()},ms)}
function infoFetch(ms){
  var ctl=window.AbortController?new AbortController():null,to=ctl?setTimeout(function(){ctl.abort()},ms):0;
  return fetch(srvBase()+"/info",{cache:"no-store",signal:ctl?ctl.signal:undefined}).then(function(r){clearTimeout(to);return r.json()},function(e){clearTimeout(to);throw e})
}
// Единственная точка выбора источника: сервер на ПК -> копия напрямую из REAPER. Никаких «загрузок» на экране.
function ensureSource(force){
  if(vurl||sKind==="file")return;
  if(!CLIPS.length&&!force)return;                      // в проекте нет видео: ничего не ищем и не грузим
  if(sKind==="server"&&loadedName===VSRC&&!force)return;
  if(probeBusy)return;
  probeBusy=true;
  infoFetch(6000).then(function(j){
    probeBusy=false;probeFails=0;
    if(vurl||sKind==="file")return;
    if(j&&j.ok){
      srvInfo=j;srvMsg="";
      if(srvBad){                                       // оригинал не играет на телефоне: ждём копию на сервере
        if(j.proxy&&!usingProxy&&sKind!=="server")switchProxy();
        else schedProbe(15000);
        return
      }
      if(sKind==="server"&&loadedName===VSRC)return;
      usingProxy=false;
      setSrc(srvBase()+"/video"+(sKind==="server"?"?n="+encodeURIComponent(VSRC):""),"сервер","server");
      if(j.audio===null&&j.audio_ready===false)setTimeout(refreshInfo,2500)
    }else{
      srvMsg=(j&&j.error)||"Сервер ответил без видео.";
      if(!sKind&&VURL)useProxyDirect();else srvHint();
      schedProbe(5000)
    }
  }).catch(function(){
    probeBusy=false;probeFails++;srvMsg="Сервер видео не найден ("+location.hostname+":"+SPORT+").";
    if(!sKind&&VURL&&probeFails>=2)useProxyDirect();     // сервера нет: играем копию напрямую, без скачивания
    else if(!sKind)srvHint();
    schedProbe(BACKOFF[Math.min(probeFails-1,BACKOFF.length-1)])
  })
}
function vprog(t){var n=$("#vprog");n.textContent=t;n.style.display=t?"block":"none"}
var proxyBusy=false;
// Копия из REAPER: с Range играем потоком; без Range перемотка невозможна, поэтому качаем в фоне (счётчик в углу)
function useProxyDirect(){
  if(!VURL||sKind||vurl||proxyBusy)return;
  proxyBusy=true;
  var u="/"+VURL;
  fetch(u,{headers:{Range:"bytes=0-1"},cache:"no-store"}).then(function(r){
    if(sKind||vurl)return;
    if(r.status===206){setSrc(u,"копия","proxy");return}
    if(r.status===404)throw new Error("Копии видео нет на ПК (404). В Prompter выберите «Суфлёр: видео для телефона».");
    if(!r.ok)throw new Error("Копия видео недоступна (HTTP "+r.status+").");
    var total=parseInt(r.headers.get("Content-Length"),10)||0,type=r.headers.get("Content-Type")||"video/mp4";
    if(!r.body||!r.body.getReader)return r.blob().then(function(b){if(!sKind&&!vurl)setSrc(URL.createObjectURL(b),"копия · в памяти","proxy")});
    var rd=r.body.getReader(),parts=[],got=0;
    function pump(){
      return rd.read().then(function(x){
        if(sKind||vurl){rd.cancel();vprog("");return}        // за это время подключился сервер или выбран файл
        if(x.done){vprog("");setSrc(URL.createObjectURL(new Blob(parts,{type:type})),"копия · в памяти","proxy");return}
        parts.push(x.value);got+=x.value.length;
        vprog("копия: "+(total?Math.floor(got*100/total)+"%":(got/1048576).toFixed(0)+" МБ"));
        return pump()
      })
    }
    return pump()
  }).catch(function(e){
    vprog("");
    var m=e&&e.message&&/^Копи/.test(e.message)?e.message:"Не удалось получить копию видео с ПК.";
    if(!sKind&&!vurl){vfail(m);$("#pcv").style.display="inline-block"}
  }).then(function(){proxyBusy=false})
}
function refreshInfo(){
  if(sKind!=="server")return;
  infoFetch(6000).then(function(j){
    if(j&&j.ok&&sKind==="server"){
      srvInfo=j;audioMsg=usingProxy?"":audioFromInfo(j);$("#vinfo").textContent=vinfoText();
      if(j.audio===null&&j.audio_ready===false)setTimeout(refreshInfo,3000)
    }
  }).catch(function(){})
}
function pickVideo(){var f=$("#vfile");f.value="";f.click()}
function applyAudio(){$("#au").textContent=audioOn?"🔊":"🔇";if(!soundBlocked)vid.muted=!audioOn}
function projVideoState(){
  if(sKind==="file"||vurl)return;
  var has=CLIPS.length>0;
  if(!has){
    if(!vid.paused)vid.pause();
    if(sKind){vgone=true;vnote("");$("#vph").style.display="flex";$("#vsh").style.display="none";$("#pcv").style.display="none";$("#vmsg").textContent="В проекте нет видео"}
    return
  }
  if(vgone){
    vgone=false;
    if(vready&&loadedName===VSRC){$("#vph").style.display="none";$("#vsh").style.display="flex";vsync();return}
    sKind="";srvBad=false;vready=false;ensureSource();return
  }
  if(sKind==="server"&&VSRC&&loadedName!==VSRC){usingProxy=false;setSrc(srvBase()+"/video?n="+encodeURIComponent(VSRC),"сервер","server");return}
  if(!sKind)ensureSource()
}
function grab(re,t){var m=re.exec(t);return m?m[1]:null}
function applyData(t){
  var nv=grab(/\nvar VER="([^"]*)";\n/,t);
  if(nv===null||nv===VER)return;
  var cj=grab(/\nvar CUES=([\s\S]*?);\nvar ROLES=/,t),cl=grab(/\nvar CLIPS=([^\n]*);\n/,t),
      vs=grab(/\nvar VSRC=("(?:[^"\\]|\\.)*");\n/,t),ro=grab(/\nvar ROLES=(true|false);\n/,t),
      vu=grab(/\nvar VURL=("(?:[^"\\]|\\.)*");\n/,t);
  if(cj===null||cl===null||vs===null||ro===null||vu===null)return;
  var nc,ncl,nvs,nvu,nro=(ro==="true");
  try{nc=JSON.parse(cj);ncl=JSON.parse(cl);nvs=JSON.parse(vs);nvu=JSON.parse(vu)}catch(e){return}
  VER=nv;CUES=nc;CLIPS=ncl;VSRC=nvs;VURL=nvu;
  if(nro!==ROLES){ROLES=nro;showRoles=nro;try{localStorage.removeItem("dp_roles");localStorage.removeItem("dp_roles_base")}catch(e){}}
  vbaseMsg=VSRC?("Видео проекта: "+VSRC):"В проекте нет видео";
  build();idx=-2;show(find(pos));applyRoles();
  projVideoState()
}
setInterval(function(){
  if(!vready||vid.paused||vid.muted||!audioOn||audioDead||soundBlocked)return;
  if(!("webkitAudioDecodedByteCount" in vid))return;
  aTick++;if(aTick<3)return;
  if(vid.webkitAudioDecodedByteCount===0){
    audioDead=true;
    var none=!!(srvInfo&&srvInfo.audio&&srvInfo.audio.length===0);
    audioMsg=none?"в файле нет звука":"звук не воспроизводится (формат не поддерживается телефоном)";
    try{console.warn("звук: аудио не декодируется; кодеки: "+(srvInfo&&srvInfo.audio?srvInfo.audio.join(","):"неизвестно")+(usingProxy?"; копия":""))}catch(e){}
    $("#vinfo").textContent=vinfoText();
    if(sKind==="server"&&!usingProxy&&!none&&srvInfo&&srvInfo.proxy)switchProxy()
  }
},1000);
function applyLock(){document.body.classList.toggle("lock",lock);$("#lk").classList.toggle("on",lock);try{localStorage.setItem("dp_lock",lock?"1":"0")}catch(e){}}
function fmt(t){t=Math.max(0,t||0);var m=Math.floor(t/60),s=t-m*60;if(m>=60){var h=Math.floor(m/60);m=m%60;return h+":"+(m<10?"0":"")+m+":"+(s<10?"0":"")+s.toFixed(0)}return(m<10?"0":"")+m+":"+(s<10?"0":"")+s.toFixed(1)}
function color(r){var h=0;for(var i=0;i<r.length;i++)h=(h*31+r.charCodeAt(i))%360;return"hsl("+h+",70%,72%)"}
function build(){
  var L=$("#list");L.textContent="";els=[];
  if(!CUES.length){var e=document.createElement("div");e.id="empty";e.textContent="Нет реплик. В Dubbing Prompter импортируйте субтитры и снова выберите «Суфлёр на телефон».";L.appendChild(e);return}
  var fr=document.createDocumentFragment();
  CUES.forEach(function(c,i){
    var d=document.createElement("div");d.className="cue";
    if(c[2]){var r=document.createElement("span");r.className="r";r.textContent=c[2];r.style.color=color(c[2]);d.appendChild(r)}
    var t=document.createElement("span");t.className="t";t.textContent=c[3];d.appendChild(t);
    d.onclick=function(){go(c[0])};
    fr.appendChild(d);els.push(d)
  });
  L.appendChild(fr)
}
function find(p){var lo=0,hi=CUES.length-1,r=-1;while(lo<=hi){var m=(lo+hi)>>1;if(CUES[m][0]<=p+0.02){r=m;lo=m+1}else hi=m-1}return r}
function show(i){
  if(i===idx)return;
  var o=idx;idx=i;
  if(o>=0&&els[o])els[o].className="cue past";
  if(i>=0&&els[i])els[i].className="cue cur";
  var from=Math.max(0,(o<0?0:Math.min(o,i)));var to=Math.min(els.length-1,(o<0?i:Math.max(o,i)));
  for(var k=from;k<=to;k++){if(k<i)els[k].className="cue past";else if(k>i)els[k].className="cue"}
  if(i>=0&&els[i])els[i].scrollIntoView({block:"center",behavior:(o<0||Math.abs(i-o)>4)?"instant":"smooth"});
  $("#cnt").textContent=(i>=0?(i+1):"–")+" / "+CUES.length
}
function diag(msg){var d=$("#diag");if(msg){d.textContent=msg;d.style.display="block"}else d.style.display="none"}
function explain(kind,detail){
  var h=location.host||"?";
  if(location.protocol==="file:")return"Страница открыта как файл. Откройте её по адресу REAPER, например http://IP:8080/prompter.html";
  if(kind==="net")return"Нет связи с REAPER ("+h+"). Проверьте: 1) REAPER запущен, 2) включён веб-интерфейс (Preferences → Control/OSC/web → Web browser interface), 3) порт в адресе совпадает с портом в настройках, 4) телефон и ПК в одной Wi-Fi сети, 5) брандмауэр Windows разрешает reaper.exe в частной сети.";
  if(kind==="404")return"REAPER отвечает, но команда /_/TRANSPORT не найдена (HTTP 404). В настройках веб-интерфейса должен стоять именно «Web browser interface», а не OSC.";
  if(kind==="auth")return"REAPER требует пароль (HTTP "+detail+"). Уберите пароль веб-интерфейса в настройках REAPER.";
  if(kind==="fmt")return"REAPER ответил, но не в ожидаемом формате: "+String(detail).slice(0,60);
  return"Ошибка: "+detail
}
function poll(){
  var t0=performance.now();
  fetch("/_/TRANSPORT",{cache:"no-store"}).then(function(r){
    if(r.status===404)throw{k:"404"};
    if(r.status===401||r.status===403)throw{k:"auth",d:r.status};
    if(!r.ok)throw{k:"x",d:"HTTP "+r.status};
    return r.text()
  }).then(function(t){
    var f=t.replace(/^\s+/,"").split("\t");
    if(f[0].trim()!=="TRANSPORT"||isNaN(parseFloat(f[2])))throw{k:"fmt",d:t};
    var t1=performance.now(),rtt=t1-t0,mid=(t0+t1)/2;
    pos=parseFloat(f[2]);fails=0;okOnce=true;
    $("#dot").className="ok";diag("");
    var st=parseInt(f[1],10)||0,was=playing;
    stIcon=(st&1?"▶ ":(st&2?"❚❚ ":""));
    playing=!!(st&1);
    if(playing){
      // часы REAPER относительно часов телефона; берём только замеры с малой задержкой сети
      var b=pos-mid/1000;
      if(!was||clk.base===null||Math.abs(b-clk.base)>0.3){clk.base=b;clk.rtt=rtt}
      else{clk.rtt=Math.min(clk.rtt+0.5,rtt);if(rtt<=clk.rtt+20)clk.base+=(b-clk.base)*0.25}
    }
    tick()
  }).catch(function(e){
    fails++;$("#dot").className="";
    if(fails>=2){var k=e&&e.k?e.k:"net";diag(explain(k,e&&e.d))}
  }).then(function(){setTimeout(poll,fails?1000:100)})
}
function go(t){
  if(lock)return;
  fetch("/_/SET/POS/"+t.toFixed(3),{cache:"no-store"}).then(function(){pos=t;if(playing)clk.base=t-performance.now()/1000;tick()}).catch(function(){})
}
$("#nx").onclick=function(){var n=CUES[idx+1];if(n)go(n[0])};
$("#pv").onclick=function(){
  if(idx<0)return;var c=CUES[idx];
  if(idx===0||posNow()-c[0]>1.5)go(c[0]);else go(CUES[idx-1][0])
};
$("#fm").onclick=function(){fs=Math.max(.7,fs-.1);applyFs()};
$("#fp").onclick=function(){fs=Math.min(2,fs+.1);applyFs()};
$("#rl").onclick=function(){showRoles=!showRoles;try{localStorage.setItem("dp_roles",showRoles?"1":"0");localStorage.setItem("dp_roles_base",ROLES?"1":"0")}catch(e){}applyRoles()};
$("#vw").onclick=function(){single=!single;try{localStorage.setItem("dp_view",single?"1":"0")}catch(e){}applyView()};
$("#bt").onclick=function(){bar=!bar;try{localStorage.setItem("dp_bar",bar?"1":"0")}catch(e){}applyBar()};
$("#vb").onclick=function(){showVid=!showVid;try{localStorage.setItem("dp_video",showVid?"1":"0")}catch(e){}applyVid()};
$("#pcv").onclick=function(){srvBad=false;probeFails=0;$("#pcv").style.display="none";ensureSource(true)};$("#pick").onclick=pickVideo;$("#vre").onclick=pickVideo;
$("#vm").onclick=function(){vshift=Math.round((vshift-0.05)*100)/100;try{localStorage.setItem("dp_vshift",vshift)}catch(e){}vshowShift();vsync()};
$("#vpl").onclick=function(){vshift=Math.round((vshift+0.05)*100)/100;try{localStorage.setItem("dp_vshift",vshift)}catch(e){}vshowShift();vsync()};
$("#vfile").onchange=function(){
  var f=this.files&&this.files[0];if(!f)return;
  if(vurl)URL.revokeObjectURL(vurl);
  vurl=URL.createObjectURL(f);setSrc(vurl,"файл","file")
};
vid.onloadedmetadata=function(){vready=true;vsync()};
vid.onerror=function(){
  vready=false;
  var k=sKind;
  if(k==="server"){
    infoFetch(3000).then(function(j){
      if(sKind!=="server")return;
      if(j&&j.ok)srvInfo=j;
      if(j&&j.ok&&!usingProxy&&j.proxy){switchProxy();return}
      srvBad=true;sKind="";
      if(VURL){useProxyDirect();schedProbe(15000);return}
      vfail("Телефон не смог воспроизвести оригинальный файл (формат или кодек). Сделайте лёгкую копию: Prompter → «Суфлёр: видео для телефона».");
      schedProbe(15000)
    }).catch(function(){
      if(sKind!=="server")return;
      sKind="";probeFails=Math.max(probeFails,1);       // сервер пропал во время просмотра
      if(VURL)useProxyDirect();else{srvMsg="Сервер видео недоступен.";srvHint()}
      schedProbe(2000)
    });
    return
  }
  if(k==="proxy"){
    sKind="";
    fetch("/"+VURL,{headers:{Range:"bytes=0-1"},cache:"no-store"}).then(function(r){
      vfail(r.status===404?"Копии видео нет на ПК (404). В Prompter выберите «Суфлёр: видео для телефона».":"Телефон не смог воспроизвести копию видео (HTTP "+r.status+").")
    }).catch(function(){vfail("Нет связи с ПК для получения копии видео.")});
    $("#pcv").style.display="inline-block";
    schedProbe(5000);return
  }
  vfail("Не удалось воспроизвести видео. Нужен mp4 (H.264) или webm.")
};
$("#au").onclick=function(){
  if(soundBlocked){soundBlocked=false;audioOn=true;vid.muted=false;var p=vid.play();if(p&&p.then)p.then(function(){if(!playing)vid.pause()}).catch(function(){})}
  else audioOn=!audioOn;
  try{localStorage.setItem("dp_audio",audioOn?"1":"0")}catch(e){}
  applyAudio();$("#vinfo").textContent=vinfoText()
};
$("#lk").onclick=function(){lock=!lock;applyLock()};
function checkVer(){
  var ctl=window.AbortController?new AbortController():null;
  fetch(location.pathname,{cache:"no-store",signal:ctl?ctl.signal:undefined}).then(function(r){
    if(!r.ok)return null;
    if(!r.body||!r.body.getReader||!window.TextDecoder)return r.text().then(function(t){return{full:t}});
    var rd=r.body.getReader(),dec=new TextDecoder("utf-8"),acc="",hdr=false;
    function pump(){
      return rd.read().then(function(x){
        if(x.done)return{full:acc};
        acc+=dec.decode(x.value,{stream:true});
        if(!hdr){
          var tp=grab(/\nvar TPL="([^"]*)";\n/,acc),nv=grab(/\nvar VER="([^"]*)";\n/,acc);
          if(tp!==null&&nv!==null){
            hdr=true;
            if(tp===TPL&&nv===VER){if(ctl)ctl.abort();return{same:true}}   // ничего не изменилось: остальное не скачиваем
          }
        }
        return pump()
      })
    }
    return pump()
  }).then(function(res){
    if(!res||res.same)return;
    var t=res.full;
    if(!/<\/html>\s*$/.test(t))return;
    var tp=grab(/\nvar TPL="([^"]*)";\n/,t);
    if(tp!==null&&tp!==TPL){location.reload();return}
    applyData(t)
  }).catch(function(){}).then(function(){setTimeout(checkVer,2000)})
}
applyFs();applyLock();build();applyRoles();applyView();applyBar();vshowShift();applyVid();applyAudio();
vbaseMsg=VSRC?("Видео проекта: "+VSRC):"В проекте нет видео";
$("#vmsg").textContent=vbaseMsg+"\n\nНа ПК: Prompter → «Суфлёр: сервер видео» (оригинал без копий). Или выберите файл на телефоне.";
ensureSource();
show(-1);
setInterval(tick,40);
if(location.protocol!=="file:"){poll();setTimeout(checkVer,3000)}else diag(explain("net"));
</script>
<div id="dots"><button id="d1" title="Суфлёр"><i style="background:#3fb950"></i></button><button id="d2" title="Список"><i style="background:#eab339"></i></button><button id="d3" title="Видео"><i style="background:#e5534b"></i></button><button id="d4" title="Назад / Следующая"><i style="background:#4c8dff"></i></button><button id="d5" title="Верхняя строка"><i style="background:#fff"></i></button><button id="dm" class="tx" title="Меньше">−</button><button id="dp" class="tx" title="Больше">+</button></div>
<script>
(function(){
var b=document.body,$=function(i){return document.getElementById(i)};
function sync(){$("d1").classList.toggle("on",b.classList.contains("single"));$("d2").classList.toggle("on",!b.classList.contains("single"));$("d3").classList.toggle("on",b.classList.contains("hasvid"));$("d4").classList.toggle("on",b.classList.contains("showbar"));$("d5").classList.toggle("on",b.classList.contains("showtop"))}
$("d1").onclick=function(){if(!b.classList.contains("single"))$("vw").click();sync()};
$("d2").onclick=function(){if(b.classList.contains("single"))$("vw").click();sync()};
$("d3").onclick=function(){$("vb").click();setTimeout(sync,50)};
$("d4").onclick=function(){b.classList.toggle("showbar");sync()};
$("d5").onclick=function(){b.classList.toggle("showtop");sync()};
$("dm").onclick=function(){$("fm").click()};$("dp").onclick=function(){$("fp").click()};
setInterval(sync,500);sync();
})();
</script></body></html>
]==]

function Mobile.js(s)
 s=tostring(s or "")
 s=s:gsub("\\","\\\\")
 s=s:gsub('"','\\"')
 s=s:gsub("%c",function(c)
  if c=="\n" then return "\\n" elseif c=="\r" then return "\\r" elseif c=="\t" then return "\\t" end
  return string.format("\\u%04x",c:byte())
 end)
 s=s:gsub("</","<\\/")
 return '"'..s..'"'
end

function Mobile.www() return reaper.GetResourcePath().."/reaper_www_root/" end

function Mobile.cues()
 local t={}
 for i,r in ipairs(rows) do
  t[#t+1]="["..string.format("%.3f,%.3f",r.start,r.finish)..","..Mobile.js(r.role)..","..Mobile.js(r.text).."]"
 end
 return "["..table.concat(t,",").."]"
end

function Mobile.write(json,ver)
 local tpl=Mobile.TEMPLATE
 local a,b=tpl:find("/*@@CUES@@*/[]",1,true)
 if not a then return false,"в шаблоне нет метки реплик" end
 local head=tpl:sub(1,a-1):gsub("@@VER@@",function() return ver end)
 local tail=tpl:sub(b+1):gsub("@@VER@@",function() return ver end)
 local function put(str,mark,val)
  local x,y=str:find(mark,1,true)
  if not x then return str end
  return str:sub(1,x-1)..val..str:sub(y+1)
 end
 tail=put(tail,"/*@@ROLES@@*/true",Mobile.roles and "true" or "false")
 tail=put(tail,"/*@@CLIPS@@*/[]",Mobile.clipsJson or "[]")
 tail=put(tail,"/*@@SPORT@@*/8765",tostring(Mobile.sport))
 tail=put(tail,'/*@@VSRC@@*/""',Mobile.js(Mobile.vname or ""))
 tail=put(tail,'/*@@VURL@@*/""',Mobile.js(Mobile.vexists() and "prompter_video.mp4" or ""))
 local html=head..json..tail
 local dir=Mobile.www()
 reaper.RecursiveCreateDirectory(dir,0)
 local path=dir.."prompter.html"
 local tmp=dir.."prompter.tmp"
 local f=io.open(tmp,"wb")
 if not f then return false,"не могу писать в "..dir end
 f:write(html); f:close()
 os.remove(path)
 if not os.rename(tmp,path) then
  local g=io.open(path,"wb")
  if not g then return false,"не могу записать "..path end
  g:write(html); g:close(); os.remove(tmp)
 end
 return true,path
end

-- видео проекта: первый видео-айтем; VOFF = время REAPER, которому соответствует начало файла
function Mobile.meta(force)
 local now=reaper.time_precise()
 if not force and Mobile.metaS and now-(Mobile.metaT or 0)<2 then return Mobile.metaS end
 local VEXT={mp4=1,mkv=1,mov=1,avi=1,webm=1,m4v=1,mxf=1,wmv=1,mpg=1,mpeg=1}
 local clips,total,path,slen={},{},{},{}
 for i=0,reaper.CountMediaItems(0)-1 do
  local it=reaper.GetMediaItem(0,i)
  local tk=reaper.GetActiveTake(it)
  local src=tk and reaper.GetMediaItemTake_Source(tk)
  if src then
   local fn=reaper.GetMediaSourceFileName(src,"") or ""
   local ext=(fn:lower():match("%.(%w+)$")) or ""
   if reaper.GetMediaSourceType(src,"")=="VIDEO" or VEXT[ext] then
    local name=fn:match("([^\\/]+)$") or fn
    local ilen=reaper.GetMediaItemInfo_Value(it,"D_LENGTH")
    local rate=reaper.GetMediaItemTakeInfo_Value(tk,"D_PLAYRATE")
    if not rate or rate<=0 then rate=1 end
    clips[#clips+1]={pos=reaper.GetMediaItemInfo_Value(it,"D_POSITION"),len=ilen,
     so=reaper.GetMediaItemTakeInfo_Value(tk,"D_STARTOFFS"),rate=rate,name=name}
    total[name]=(total[name] or 0)+ilen
    path[name]=fn
    slen[name]=reaper.GetMediaSourceLength(src) or 0
   end
  end
 end
 table.sort(clips,function(a,b) return a.pos<b.pos end)
 local main,best="",-1
 for _,c in ipairs(clips) do
  if total[c.name]>best then main,best=c.name,total[c.name] end
 end
 local nsrc=0
 for _ in pairs(total) do nsrc=nsrc+1 end
 local parts={}
 for _,c in ipairs(clips) do
  parts[#parts+1]=string.format("[%.3f,%.3f,%.3f,%.4f,",c.pos,c.len,c.so,c.rate)..Mobile.js(c.name).."]"
 end
 Mobile.metaT=now
 Mobile.clipsJson="["..table.concat(parts,",").."]"
 Mobile.vname,Mobile.vpath,Mobile.vlen=main,path[main] or "",slen[main] or 0
 Mobile.nclips,Mobile.nsrc=#clips,nsrc
 Mobile.metaS=Mobile.clipsJson.."\1"..main
 return Mobile.metaS
end

function Mobile.vfile() return Mobile.www().."prompter_video.mp4" end
function Mobile.vexists()
 local f=io.open(Mobile.vfile(),"rb")
 if f then f:close(); return true end
 return false
end

-- лёгкая копия видео (mp4 480p без звука) в reaper_www_root; ffmpeg работает в фоне
function Mobile.makevideo()
 Mobile.meta(true)
 local T="Видео для телефона"
 if (Mobile.vpath or "")=="" then
  reaper.ShowMessageBox("В проекте не найден видео-элемент.",T,0); return
 end
 if Mobile.enc then
  reaper.ShowMessageBox("Подготовка уже идёт, прогресс показан в строке состояния.",T,0); return
 end
 local ans=reaper.ShowMessageBox("Создать лёгкую копию видео для телефона?\n\n"..Mobile.vname..(((Mobile.nsrc or 1)>1) and "\n\n(В проекте несколько видеофайлов: копия делается только для основного, самого длинного. Для остальных клипов на телефоне будет пометка «нет копии».)" or "").."\n\nmp4 480p со звуком. ffmpeg работает в фоне (несколько минут, REAPER можно использовать). Копия кладётся в reaper_www_root и отдаётся телефону с ПК. Нужен ffmpeg.exe в Scripts\\DubbingSystem или в PATH.",T,1)
 if ans~=1 then return end
 local www=Mobile.www()
 reaper.RecursiveCreateDirectory(www,0)
 local res=reaper.GetResourcePath().."/"
 local function W(p) return (p:gsub("/","\\")) end
 local e={out=W(www.."prompter_video.mp4"),tmp=W(www.."prompter_video.tmp.mp4"),
  prog=W(res.."prompter_video.progress"),fail=W(res.."prompter_video.fail"),
  log=W(res.."prompter_video.log"),bat=W(res.."prompter_video.bat"),len=Mobile.vlen}
 os.remove(e.out); os.remove(e.tmp); os.remove(e.fail); os.remove(e.prog)
 local lines={
  "@echo off","chcp 65001 >nul",
  ff_tool("ffmpeg").." -v error -y -i "..ffq(W(Mobile.vpath)).." -vf \"scale=-2:'min(480,ih)'\" -c:v libx264 -profile:v main -preset veryfast -crf 28 -pix_fmt yuv420p -c:a aac -b:a 96k -ac 2 -movflags +faststart -progress "..ffq(e.prog).." -nostats "..ffq(e.tmp).." > "..ffq(e.log).." 2>&1",
  "if %errorlevel% neq 0 (",
  " echo fail> "..ffq(e.fail),
  " del "..ffq(e.tmp).." 2>nul",
  ") else (",
  " move /y "..ffq(e.tmp).." "..ffq(e.out).." >nul",
  ")"}
 local f=io.open(e.bat,"wb")
 if not f then reaper.ShowMessageBox("Не могу записать "..e.bat,T,0); return end
 f:write(table.concat(lines,"\r\n").."\r\n"); f:close()
 if not Mobile.launch(e.bat) then
  reaper.ShowMessageBox("Не удалось запустить ffmpeg автоматически. Запустите вручную двойным щелчком:\n"..e.bat,T,0)
 end
 Mobile.enc=e
 Mobile.on=true
 reaper.SetExtState(SEC,"mobile_on","1",true)
 status="Видео для телефона: подготовка…"
end

function Mobile.check_enc()
 local e=Mobile.enc
 if not e then return end
 local function has(p) local f=io.open(p,"rb"); if f then f:close(); return true end return false end
 if has(e.out) then
  Mobile.enc=nil; status="Видео для телефона готово: страница сама подхватит его"; Mobile.refresh(true); return
 end
 if has(e.fail) then
  Mobile.enc=nil; status="Видео для телефона: ffmpeg не справился (лог: "..e.log..")"; return
 end
 local f=io.open(e.prog,"rb")
 if f then
  local t=f:read("a") or ""; f:close()
  local us; for v in t:gmatch("out_time_us=(%d+)") do us=tonumber(v) end
  if us and (e.len or 0)>0 then
   status=string.format("Видео для телефона: %d%%",math.min(99,math.floor(us/1e6/e.len*100)))
  end
 end
end

function Mobile.cfgfile() return reaper.GetResourcePath().."/prompter_server.json" end

-- настройки для Python-сервера: путь к основному видеофайлу проекта
-- куда писать настройки: папка ресурсов REAPER и папка MobileServer рядом со скриптом
function Mobile.cfgfiles()
 local t={Mobile.cfgfile()}
 if (Mobile.dir or "")~="" then t[#t+1]=Mobile.dir.."/MobileServer/prompter_server.json" end
 return t
end

function Mobile.writecfg()
 local sig=Mobile.vpath or ""
 if sig==Mobile.cfgSig then return end
 local body='{"video":'..Mobile.js(Mobile.vpath or "")..',"name":'..Mobile.js(Mobile.vname or "")..',"proxy":'..Mobile.js(Mobile.vfile())..',"updated":'..os.time()..'}'
 for _,p in ipairs(Mobile.cfgfiles()) do
  local f=io.open(p,"wb")
  if f then f:write(body); f:close() end
 end
 Mobile.cfgSig=sig
end

-- открыть .bat как двойным щелчком (отдельное окно, REAPER не блокируется, Unicode-пути работают)
function Mobile.launch(path)
 if reaper.CF_ShellExecute then
  if pcall(reaper.CF_ShellExecute,path) then return true end
 end
 if reaper.ExecProcess then
  local ok,res=pcall(reaper.ExecProcess,'explorer.exe "'..path..'"',3000)
  if ok and res~=nil then return true end
 end
 return false
end

-- запуск сервера видео (Python) в отдельном окне; сервер отдаёт на телефон оригинальный файл
function Mobile.server_start()
 local T="Сервер видео"
 Mobile.on=true
 reaper.SetExtState(SEC,"mobile_on","1",true)
 Mobile.cfgSig=nil
 Mobile.refresh(true)
 local bat=(Mobile.dir or "").."/MobileServer/start_server.bat"
 local f=io.open(bat,"rb")
 if not f then
  reaper.ShowMessageBox("Не найден start_server.bat:\n"..bat.."\n\nПереустановите Dubbing System или скопируйте папку MobileServer рядом со скриптом.",T,0)
  return
 end
 f:close()
 local function W(p) return (p:gsub("/","\\")) end
 local started=Mobile.launch(W(bat))
 local ips=Mobile.ips()
 local addr={}
 for _,ip in ipairs(ips) do addr[#addr+1]="http://"..ip..":"..Mobile.sport.."/" end
 local msg="Сервер видео запускается в отдельном окне.\n\n"
 if (Mobile.vpath or "")=="" then
  msg=msg.."ВНИМАНИЕ: в проекте не найден видео-элемент — сервер нечего отдавать.\n\n"
 else
  msg=msg.."Видео: "..Mobile.vpath.."\n\n"
 end
 msg=msg.."Проверка в браузере ПК: "..(addr[1] or ("http://IP-ПК:"..Mobile.sport.."/")).."\n"
 msg=msg.."Телефон подхватит видео сам (страница суфлёра ищет сервер на этом же ПК, порт "..Mobile.sport..").\n\n"
 msg=msg.."Нужен Python 3 (python.org, галочка Add to PATH). При первом запуске разрешите python.exe в брандмауэре Windows (частная сеть).\n"
 msg=msg.."Если окно сервера сразу закрылось или показало ошибку, прочитайте её: там указана причина."
 if not started then
  msg=msg.."\n\nОкно сервера открыть не удалось. Запустите вручную двойным щелчком:\n"..W(bat)
 end
 status="Сервер видео: "..(addr[1] or ("порт "..Mobile.sport))
 reaper.ShowMessageBox(msg,T,0)
end

function Mobile.refresh(force)
 local json=Mobile.cues()
 Mobile.meta(force)
 Mobile.writecfg()
 local sig=json.."\2"..Mobile.metaS..(Mobile.vexists() and "\3v" or "")
 if not force and sig==Mobile.sig then return true end
 Mobile.sig=sig
 Mobile.n=(Mobile.n or 0)+1
 Mobile.ver=tostring(os.time()).."-"..Mobile.n
 local ok,info=Mobile.write(json,Mobile.ver)
 if not ok then status="Суфлёр на телефон: "..tostring(info) end
 return ok,info
end

-- порт веб-интерфейса из reaper.ini (строка csurf_N=HTTP 0 8080 ...); nil, если не найден
function Mobile.port()
 local ini=reaper.get_ini_file and reaper.get_ini_file()
 local f=ini and io.open(ini,"rb")
 if not f then return nil end
 local s=f:read("a"); f:close()
 for line in s:gmatch("[^\r\n]+") do
  local rest=line:match("^csurf_%d+=HTTP%s+(.*)$")
  if rest then
   local p=rest:match("^%d+%s+(%d+)") or rest:match("^(%d+)")
   return tonumber(p) or 8080
  end
 end
 return nil
end

function Mobile.ips()
 local seen,res={},{}
 if reaper.ExecProcess and (reaper.GetOS() or ""):match("Win") then
  local ok,txt=pcall(reaper.ExecProcess,"cmd.exe /c ipconfig",5000)
  if ok and txt then
   for line in tostring(txt):gmatch("[^\r\n]+") do
    if line:find("IPv4",1,true) then
     local ip=line:match("(%d+%.%d+%.%d+%.%d+)")
     if ip and not seen[ip] and not ip:match("^169%.254%.") and not ip:match("^127%.") then
      seen[ip]=true; res[#res+1]=ip
     end
    end
   end
  end
 end
 return res
end

function Mobile.open()
 Mobile.on=true
 reaper.SetExtState(SEC,"mobile_on","1",true)
 if #rows==0 then status="Суфлёр на телефон: сначала импортируйте субтитры"; end
 local ok,info=Mobile.refresh(true)
 if not ok then
  reaper.ShowMessageBox("Не удалось создать страницу суфлёра:\n"..tostring(info),"Суфлёр на телефон",0)
  return
 end
 local port=Mobile.port()
 local ips=Mobile.ips()
 local p=port or 8080
 local lines={}
 if #ips>0 then
  for _,ip in ipairs(ips) do lines[#lines+1]="http://"..ip..":"..p.."/prompter.html" end
 else
  lines[1]="http://IP-ПК:"..p.."/prompter.html   (IP смотрите командой ipconfig)"
 end
 Mobile.url=lines[1]
 if reaper.CF_SetClipboard and #ips>0 then pcall(reaper.CF_SetClipboard,lines[1]) end
 local msg="Страница суфлёра создана:\n"..tostring(info).."\n\nАдрес для телефона / планшета (одна Wi-Fi сеть с ПК):\n"..table.concat(lines,"\n").."\n\n"
 if port then
  msg=msg.."Веб-интерфейс REAPER найден в настройках, порт "..port..".\n"
 else
  msg=msg.."ВНИМАНИЕ: веб-интерфейс REAPER не найден в reaper.ini. Включите его один раз:\nPreferences → Control/OSC/web → Add → «Web browser interface», порт 8080, нажмите OK.\n(Если вы только что включили его — адрес выше всё равно верный.)\n"
 end
 msg=msg.."\nЕсли телефон не подключается: разрешите reaper.exe в брандмауэре Windows для частной сети.\nСтраница обновляется сама при изменении реплик."
 status="Суфлёр на телефон: "..lines[1]
 reaper.ShowMessageBox(msg,"Суфлёр на телефон",0)
end

function Mobile.toggle_roles()
 Mobile.roles=not Mobile.roles
 reaper.SetExtState(SEC,"mobile_roles",Mobile.roles and "1" or "0",true)
 Mobile.refresh(true)
 status="Суфлёр на телефон: имена ролей "..(Mobile.roles and "включены" or "выключены")
end

function Mobile.init()
 local _,sp=reaper.get_action_context()
 Mobile.dir=((sp or ""):match("^(.*)[\\/][^\\/]*$")) or ""
 Mobile.roles=(reaper.GetExtState(SEC,"mobile_roles")~="0")
 if reaper.GetExtState(SEC,"mobile_on")=="1" then Mobile.on=true; Mobile.last=reaper.time_precise()-10 end
end

function Mobile.tick()
 if not Mobile.on and not Mobile.enc then return end
 local now=reaper.time_precise()
 if now-Mobile.last<2 then return end
 Mobile.last=now
 if Mobile.enc then Mobile.check_enc() end
 if Mobile.on then Mobile.refresh(false) end
end

function run_tool(idx)
 if idx==1 then import_orig()
 elseif idx==2 then fit_to_takes(true)
 elseif idx==3 then shift_time()
 elseif idx==4 then replace_text()
 elseif idx==5 then rename_role()
 elseif idx==6 then edit_role_duck()
 elseif idx==7 then edit_track_duck()
 elseif idx==8 then win_from_dub=not win_from_dub; save(); status=win_from_dub and "Окна приглушения берутся из записей на дорожке дубляжа" or "Окна приглушения берутся из субтитров"
 elseif idx==9 then set_preroll()
 elseif idx==10 then reset_done()
 elseif idx==11 then export_srt_roles()
 elseif idx==12 then export_project()
 elseif idx==13 then import_project()
 elseif idx==14 then if save_version("manual") then status="Версия сохранена в "..ver_dir() else status="Не удалось сохранить версию" end
 elseif idx==15 then restore_version()
 elseif idx==16 then qc_report()
 elseif idx==17 then export_role_scripts()
 elseif idx==18 then shift_dub_takes()
 elseif idx==19 then cycle_best_take()
 elseif idx==20 then show_help=true
 elseif idx==21 then mark_recorded_from_dub()
 elseif idx==22 then check_take_levels()
 elseif idx==23 then export_role_html()
 elseif idx==50 then create_anime_mix()
 elseif idx==24 then toggle_frames()
 elseif idx==25 then edit_qc_thresholds()
 elseif idx==26 then actor_summary()
 elseif idx==27 then export_session_csv()
 elseif idx==28 then export_vtt()
 elseif idx==29 then cycle_status_filter()
 elseif idx==31 then session_summary()
 elseif idx==32 then level_takes()
 elseif idx==33 then batch_shift()
 elseif idx==34 then batch_role()
 elseif idx==35 then batch_done(true)
 elseif idx==36 then batch_done(false)
 elseif idx==37 then clear_picks()
 elseif idx==38 then check_env()
 elseif idx==39 then hotkeys_menu()
 elseif idx==40 then cols_menu()
 elseif idx==41 then profile_save()
 elseif idx==42 then profile_load()
 elseif idx==43 then problem_jump()
 elseif idx==44 then take_compare()
 elseif idx==45 then lufs_track()
 elseif idx==30 then export_call_sheet()
 elseif idx==46 then factory_reset()
 elseif idx==47 then clear_session()
 elseif idx==48 then import_from_video()
 elseif idx==49 then create_dub_track()
 elseif idx==51 then Mobile.open()
 elseif idx==53 then Mobile.makevideo()
 elseif idx==54 then Mobile.server_start() end
end

-- ---------- keyboard ----------
local function printable(ch) return ch>=32 and ch<=0xFFFF and ch~=127 and ch~=30064 and not (ch>=26161 and ch<=26176) end
local function lc(ch) if ch>=65 and ch<=90 then return ch+32 elseif ch>=0x410 and ch<=0x42F then return ch+32 end; return ch end

local function handle_key(ch)
 if ch<=0 then return false end
 if edit_mode then
  if ch==27 then end_edit(false)
  elseif ch==13 then end_edit(true)
  elseif ch==10 then edit_buf=edit_buf.."\n"
  elseif ch==8 then edit_buf=utf8_pop(edit_buf)
  elseif ch==22 then
   local ok,clip=pcall(reaper.CF_GetClipboard,"")
   if ok and clip then clip=clip:gsub("[\r\n]+"," "); edit_buf=edit_buf..clip end
  elseif printable(ch) then edit_buf=edit_buf..utf8.char(ch) end
  return true
 end
 if show_help then
  if ch==27 or ch==13 or ch==26161 then show_help=false end
  return true
 end
 if ch==26161 then show_help=true; return true end                  -- F1: help
 if search_focus then
  if ch==27 then
   if search~="" then search=""; mark_dirty() else search_focus=false end
  elseif ch==13 then search_focus=false
  elseif ch==8 then search=utf8_pop(search); mark_dirty(); scroll=0
  elseif printable(ch) then search=search..utf8.char(ch); mark_dirty(); scroll=0 end
  return true
 end
 if ch==26 then undo(); return true end
 if ch==32 then reaper.Main_OnCommand(40044,0); return true end -- transport: play/stop
 local k=lc(ch)
 if k==PREF.keys.play_line or k==0x437 then play_line(false); return true end      -- p / з
 if k==PREF.keys.loop or k==0x434 then play_line(true); return true end       -- l / д
 if k==PREF.keys.done or k==0x432 then toggle_done(); return true end         -- d / в
 if k==PREF.keys.mark or k==0x438 then toggle_mark(); return true end         -- b / и
 if k==PREF.keys.next_mark or k==0x442 then next_mark(); return true end           -- n / т
 if k==PREF.keys.best or k==0x44C then cycle_best_take(); return true end     -- m / ь  (лучший дубль)
 if k==PREF.keys.actor or k==0x43A then cycle_role_filter(); return true end   -- r / к  (следующий актёр)
 if ch==49 then set_verdict("ok"); return true end                 -- 1: ок
 if ch==50 then set_verdict("redo"); return true end               -- 2: переписать
 if ch==51 then set_verdict("check"); return true end              -- 3: спорно
 if ch==52 then set_verdict("lip"); return true end                -- 4: губы не совпадают
 return false
end

-- ---------- drawing ----------
-- resizable window: layout is written on a W x H canvas and mapped to the real window size
-- (KX, KY stretch positions; KF scales text so it never distorts)
local KX,KY,KF=1,1,1
local MX,MY=0,0
local function grect(x,y,w,h,fill) gfx.rect(x*KX,y*KY,w*KX,h*KY,fill) end
local function gline(x1,y1,x2,y2) gfx.line(x1*KX,y1*KY,x2*KX,y2*KY) end
local function setf(size) gfx.setfont(1,"Arial",math.max(8,math.floor((size or 16)*KF+0.5))) end
local function rect(x,y,w,h,c) gfx.set(c[1],c[2],c[3],c[4] or 1); grect(x,y,w,h,1) end
local C={bg={.040,.040,.047},panel={.075,.075,.085},panel2={.115,.110,.122},line={.22,.16,.17},text={.96,.94,.90},muted={.60,.56,.53},blue={.88,.70,.24},green={.89,.70,.24},red={.88,.20,.24},yellow={.88,.70,.24}}
local function txt(x,y,s,size,col) setf(size or 16); gfx.set(col[1],col[2],col[3],col[4] or 1); gfx.x=x*KX; gfx.y=y*KY; gfx.drawstr(tostring(s or "")) end
-- draw text and return the x where the next piece should start
local function txt_adv(x,y,s,size,col) txt(x,y,s,size,col); setf(size); local w=gfx.measurestr(tostring(s)); return x+((w or 0)/KX)+8 end

local function inside(x,y,w,h) return MX>=x and MX<=x+w and MY>=y and MY<=y+h end
local function raw_pressed() return gfx.mouse_cap&1==1 and lastcap&1==0 end
local function pressed() return (not ui_locked) and raw_pressed() end

local function button(x,y,w,h,label,kind,id,size)
 if CLIP_B and y+h>CLIP_B then return nil end   -- never draw or click below the status bar / panel edge
 local c=kind=="primary" and C.blue or kind=="green" and C.green or C.panel2
 if (not ui_locked) and inside(x,y,w,h) then c={math.min(1,c[1]+.06),math.min(1,c[2]+.06),math.min(1,c[3]+.06)} end
 local sz=size or 15
 rect(x,y,w,h,c); txt(x+8,y+(h-sz-4)/2,fit_text(label,sz,w-14),sz,C.text)
 if pressed() and inside(x,y,w,h) then return id end
end

local function wrap_gfx(s,size,maxw)
 setf(size)
 local out={}
 for para in (s.."\n"):gmatch("(.-)\n") do
  local cur=""
  for word in para:gmatch("%S+") do
   local test=(cur=="") and word or (cur.." "..word)
   if gfx.measurestr(test)/KX>maxw and cur~="" then out[#out+1]=cur; cur=word else cur=test end
  end
  out[#out+1]=cur
 end
 return out
end

-- cut text to fit maxw pixels (adds an ellipsis); used so labels never run past their box
function fit_text(s,size,maxw)
 s=tostring(s or "")
 setf(size or 13)
 if (gfx.measurestr(s) or 0)<=maxw then return s end
 local n=utf8.len(s) or #s
 local lo,hi=0,n
 while lo<hi do
  local mid=math.floor((lo+hi+1)/2)
  local cut=utf8.offset(s,mid+1) or (#s+1)
  if (gfx.measurestr(s:sub(1,cut-1).."…") or 0)<=maxw then lo=mid else hi=mid-1 end
 end
 local cut=utf8.offset(s,lo+1) or (#s+1)
 return s:sub(1,cut-1).."…"
end

-- how many rows a flow of buttons needs at this width
local function count_rows(items,maxw,size,gap)
 local x,rows=0,1
 for _,it in ipairs(items) do
  setf(size); local w=math.max(64,math.floor((gfx.measurestr(it.l) or 0)+24))
  if w>maxw then w=maxw end
  if x>0 and x+w>maxw then rows=rows+1; x=0 end
  x=x+w+gap
 end
 return rows
end

-- keep only the buttons that fit in maxrows rows; "Ещё" (id 30) always stays visible
function trim_rows(items,maxw,size,gap,maxrows)
 local more,rest=nil,{}
 for _,it in ipairs(items) do if it.id==30 then more=it else rest[#rest+1]=it end end
 local list={}
 for _,it in ipairs(rest) do list[#list+1]=it end
 local function full(l) local t={}; for _,it in ipairs(l) do t[#t+1]=it end; if more then t[#t+1]=more end; return t end
 while #list>0 and count_rows(full(list),maxw,size,gap)>maxrows do table.remove(list) end
 return full(list)
end

local function draw_preview(x,y,w,h,pos)
 rect(x,y,w,h,C.panel2)
 local total=0
 for _,s in ipairs(rows) do if s.finish>total then total=s.finish end end
 if total<=0 then return end
 for _,wn in ipairs(get_wins()) do
  local x1=x+w*math.min(1,wn.ds/total)
  local x2=x+w*math.min(1,(wn.hold_end+fo/1000)/total)
  gfx.set(.88,.20,.24,math.min(.85,.25+wn.db/60))
  grect(x1,y+4,math.max(1,x2-x1),h-8,1)
 end
 txt(x+6,y+2,"превью приглушения оригинала",10,C.muted)
 gfx.set(.05,.80,.45,1)
 local cx=x+w*math.max(0,math.min(1,pos/total))
 gline(cx,y,cx,y+h)
end

-- ---------- responsive layout ----------
-- Everything is laid out on the real window size (W x H). Positions are computed from the
-- window, so the interface fits any size. Below 900 px wide (or 680 px high) the window uses
-- a single column with tabs; from there up it shows the wide two-column layout.
LAY={}
side_tab=side_tab or 1
tools_scroll=tools_scroll or 0
tools_max=tools_max or 0
function clampf(v,a,b) if v<a then return a elseif v>b then return b end return v end
function refresh_layout()
 W=(gfx.w>0) and gfx.w or 518
 H=(gfx.h>0) and gfx.h or 367
 KX,KY=1,1
 KF=clampf(math.min(W/900,H/640),1.3,1.6)   -- font scale: never below 1.3x (readable on small windows), up to 1.6x on 4K
 LAY.narrow=(W<900) or (H<680)
 LAY.wide=not LAY.narrow
end

-- buttons flow left to right and wrap to the next line; returns pressed id and bottom y
-- items: {l=label, k=kind, id=id}; dry=true only measures (returns the bottom y)
function flow_buttons(items,x0,y0,maxw,bh,gap,size,dry)
 gap=gap or 8; size=size or 15
 local x,y,got=x0,y0,nil
 for _,it in ipairs(items) do
  setf(size)
  local w=math.floor((gfx.measurestr(it.l) or 0)+24)
  if w<64 then w=64 end
  if w>maxw then w=maxw end
  if x>x0 and x+w>x0+maxw then x=x0; y=y+bh+gap end
  if not dry then local r=button(x,y,w,bh,it.l,it.k,it.id,size); if r then got=r end end
  x=x+w+gap
 end
 return got, y+bh
end

function list_actions()
 return {
  {l="Текст",id=11},{l="Время",id=12},{l="Разбить",id=13},{l="Склеить",id=14},{l="Удалить",id=15},{l="↶",id=16},
  {l="Следить",k=follow and "green" or nil,id=17},{l="Играть",id=22},
  {l="Цикл",k=loop_active and "green" or nil,id=23},
  {l="Записано",id=24},{l="Заметка",id=25},{l="Закладка",id=26},{l="Подогнать",id=27}}
end

local function draw_edit_modal()
 rect(0,0,W,H,{0,0,0,.6})
 local bw=math.min(840,W-30); local bh=math.min(300,H-20)
 local bx=math.floor((W-bw)/2); local by=math.floor((H-bh)/2)
 rect(bx,by,bw,bh,C.panel)
 gfx.set(.88,.20,.24,1); grect(bx,by,bw,bh,0)
 txt(bx+16,by+12,(edit_target=="note" and "Заметка к реплике №" or "Правка реплики №")..selected,17,C.text)
 local lines=wrap_gfx(edit_buf,20,bw-50)
 local caret=(math.floor(reaper.time_precise()*2)%2==0) and "|" or " "
 lines[#lines]=lines[#lines]..caret
 local maxl=math.max(1,math.floor((bh-130)/26))
 for i,l in ipairs(lines) do
  if i>maxl then break end
  txt(bx+24,by+46+(i-1)*26,l,20,C.text)
 end
 txt(bx+16,by+bh-80,"Enter — сохранить · Ctrl+Enter — перенос строки · Esc — отмена",12,C.muted)
 local function mbtn(x,label,kind,id)
  local c=kind=="primary" and C.blue or C.panel2
  local y=by+bh-44
  if inside(x,y,150,34) then c={math.min(1,c[1]+.06),math.min(1,c[2]+.06),math.min(1,c[3]+.06)} end
  rect(x,y,150,34,c); txt(x+14,y+8,label,15,C.text)
  if raw_pressed() and inside(x,y,150,34) then return id end
 end
 local a=mbtn(bx+bw-340,"Сохранить","primary",1)
 local b=mbtn(bx+bw-170,"Отмена",nil,2)
 if a==1 then end_edit(true) elseif b==2 then end_edit(false) end
end

-- значки кнопок в строке: рисуются фигурами (не зависят от шрифта); возвращает true, если нарисовал
function row_icon(name,cx,cy,c)
 gfx.set(c[1],c[2],c[3],1)
 local function L(x1,y1,x2,y2) gfx.line((cx+x1)*KX,(cy+y1)*KY,(cx+x2)*KX,(cy+y2)*KY) end
 if name=="▶" then gfx.triangle((cx-4)*KX,(cy-6)*KY,(cx-4)*KX,(cy+6)*KY,(cx+6)*KX,cy*KY)
 elseif name=="✓" then for d=0,1 do L(-6,0+d,-2,4+d); L(-2,4+d,6,-5+d) end
 elseif name=="⚑" then L(-4,-7,-4,7); L(-3,-7,-3,7); gfx.triangle((cx-3)*KX,(cy-7)*KY,(cx+6)*KX,(cy-3)*KY,(cx-3)*KX,(cy+1)*KY)
 elseif name=="✎" then for d=0,1 do L(-5,5+d,5,-5+d) end; L(-6,6,-3,6)
 else return false end
 return true
end
-- list of replies: header with search and filters, column titles, rows.
-- rb = bottom of the rows area (the action buttons may sit below it in the wide layout)
-- returns the act code of a row button / row click (or nil)
function draw_list(x,y,w,h,narrow,items,cur_idx,rb)
 -- верхняя строка: поиск, роль, счётчик
 local sy,sh=y+8,32
 local hasroles=(#roles>0)
 local rw=hasroles and (narrow and 96 or 130) or 0
 local sx=x+4
 local sw1=math.max(80,w-8-(hasroles and (rw+8) or 0)-(narrow and 0 or 70))
 rect(sx,sy,sw1,sh,C.panel)
 gfx.set(C.line[1],C.line[2],C.line[3],1); grect(sx,sy,sw1,sh,0)
 if search_focus then gfx.set(.88,.20,.24,1); grect(sx,sy,sw1,sh,0) end
 if search=="" and not search_focus then txt(sx+12,sy+9,"Поиск по тексту…",13,C.muted)
 else txt(sx+12,sy+9,tail(search,28)..((search_focus and (math.floor(os.clock()*2)%2==0)) and "|" or ""),13,C.text) end
 local hdr_down=(gfx.mouse_cap&1)==1
 local hdr_click=hdr_down and not HDR_WAS and not ui_locked
 HDR_WAS=hdr_down
 if hdr_click then search_focus=inside(sx,sy,sw1,sh) end
 local rx=sx+sw1+8
 if hasroles then
 local rcol=role_filter~="" and role_rgb(role_filter) or nil
 local rov=(not ui_locked) and inside(rx,sy,rw,sh)
 rect(rx,sy,rw,sh,rov and C.panel2 or C.panel)
 gfx.set(C.line[1],C.line[2],C.line[3],1); grect(rx,sy,rw,sh,0)
 if rcol then rect(rx+10,sy+12,8,8,rcol) end
 txt(rx+(rcol and 26 or 12),sy+9,fit_text(role_filter=="" and "Все роли" or short(role_filter,12),13,rw-34),13,C.text)
 if hdr_click and rov then
  if role_filter=="" then role_filter=roles[1]
  else
   local i=role_idx[role_filter] or 0
   role_filter=roles[i+1] or ""
  end
  rebuild_vis(); scroll=0
 end
 end
 if not narrow then
  txt(rx+rw+(hasroles and 12 or 8),sy+10,#vis.."/"..#rows,12,C.muted)
  if status_filter~="" then txt(rx+rw+(hasroles and 12 or 8),sy+22,STATUS_NAME[status_filter],11,C.yellow) end
 end
 local ROWH_=LIST_COMPACT and 46 or (narrow and 58 or 64)
 ROWH=ROWH_
 local RT=sy+sh+8
 rb=rb or (y+h-4)
 VISIBLE=math.max(1,math.floor((rb-RT)/ROWH))
 local maxscroll=math.max(0,#vis-VISIBLE)
 if scroll>maxscroll then scroll=maxscroll end
 if scroll<0 then scroll=0 end
 local ract=nil
 -- кнопки выбранной реплики: коды 100000+idx*10+k
 local mini=narrow or w<950
 local bdef=mini and {{"▶",0},{"✓",1},{"⚑",2},{"✎",4}} or {{"▶ Играть",0},{"✓ Записано",1},{"⚑ Заметка",2},{"★ Лучший",3},{"✎ Текст",4},{"ок",5},{"↺",6},{"?",7},{"губы",8}}
 local bw,bg=0,6
 local abw=0
 local bws={}
 for j,b in ipairs(bdef) do
  setf(13); bws[j]=mini and 30 or math.max(30,math.floor((gfx.measurestr(b[1]) or 0)/KX+20))
  abw=abw+bws[j]+bg
 end
 for i=1,VISIBLE do
  local idx=vis[i+scroll]
  local s=idx and rows[idx]
  if s then
   local ry=RT+(i-1)*ROWH
   local rxl,rwid=x+4,w-8
   local sel=(idx==selected)
   if sel then rect(rxl,ry,rwid,ROWH-2,{.10,.14,.22}) end
   rect(rxl,ry+ROWH-2,rwid,1,{.11,.14,.19})
   if sel then rect(rxl,ry,3,ROWH-2,C.blue)
   elseif idx==cur_idx then rect(rxl,ry,3,ROWH-2,C.green) end
   if s.pick then rect(rxl,ry,6,ROWH-2,C.yellow) end
   local rc=role_rgb(s.role)
   -- кружок «записано»
   local cx,cy=rxl+22,ry+ROWH/2-9
   if s.done then gfx.set(C.green[1],C.green[2],C.green[3],1); gfx.circle((cx+10)*KX,(cy+10)*KY,10*KX,1,1); txt(cx+5,cy+3,"✓",12,{.02,.13,.06})
   else gfx.set(sel and .5 or .27,sel and .6 or .32,sel and 1 or .40,1); gfx.circle((cx+10)*KX,(cy+10)*KY,10*KX,0,1); gfx.circle((cx+10)*KX,(cy+10)*KY,9*KX,0,1) end
   -- номер и время
   local nx=cx+30
   txt(nx,LIST_COMPACT and (ry+(ROWH-13)/2-1) or (ry+10),string.format("%03d",idx),12,C.muted)
   if not LIST_COMPACT then txt(nx,ry+ROWH-26,ftime(s.start):sub(-9),11,C.muted) end
   local textx=nx+(narrow and 70 or 86)
   local showact=sel and not edit_mode and (not ui_locked) and inside(rxl,ry,rwid,ROWH-2)   -- кнопки строки видны только при наведении
   local rmax=x+w-14-((LIST_COMPACT and showact) and (abw+8) or 0)
   LAY.stat_max=rmax
   local tn=math.max(6,math.floor((rmax-textx)/(sel and 8 or 7)))
   txt(textx,LIST_COMPACT and (ry+(ROWH-17)/2-1) or (ry+9),short(s.text,tn),sel and 17 or 15,sel and {1,1,1} or {.76,.80,.87})
   if not LIST_COMPACT then
   -- строка статистики
   local dur=s.finish-s.start
   local cps=ulen((s.text:gsub("\n","")))/math.max(dur,0.05)
   local stx=textx
   local L2=ry+ROWH-26
   if (s.role or "")~="" then
    if rc then gfx.set(rc[1],rc[2],rc[3],1); gfx.circle((stx+4)*KX,(L2+7)*KY,3.5*KX,1,1); stx=stx+12 end
    stx=sadv(stx,L2,short(s.role,12),11,rc or {.48,.66,1})
   end
   local ccol=(cps>=qc_cps*1.25) and C.red or (cps>=qc_cps) and C.yellow or C.muted
   if PREF.cols.cps then stx=sadv(stx,L2,string.format("%.0f зн/с",cps),11,ccol) end
   if PREF.cols.dur then stx=sadv(stx,L2,string.format("%.1f с",dur),11,C.muted) end
   local n,over=row_takes(s,items)
   if PREF.cols.takes then
    if n>0 then stx=sadv(stx,L2,"×"..n,11,C.green)
    elseif not s.done then stx=sadv(stx,L2,"нет дубля",11,{.75,.40,.40}) end
   end
   if s.mark then stx=sadv(stx,L2,"⚑",11,C.yellow) end
   if PREF.cols.verdict and s.verdict=="ok" then stx=sadv(stx,L2,"✓ ок",11,C.green)
   elseif s.verdict=="redo" then stx=sadv(stx,L2,"↺ переписать",11,C.red)
   elseif s.verdict=="check" then stx=sadv(stx,L2,"? спорно",11,C.yellow)
   elseif s.verdict=="lip" then stx=sadv(stx,L2,"губы",11,C.yellow) end
   if PREF.cols.over and n>0 and over>0.25 then stx=sadv(stx,L2,string.format("+%.1f с",over),11,C.red) end
   if PREF.cols.note and (s.note or "")~="" then stx=sadv(stx,L2,"✎ "..short(s.note,18),11,C.yellow) end
   if s.take then stx=sadv(stx,L2,"★ лучший",11,C.green) end
   end
   local rowbtn=false
   if showact then
    local bx=x+w-12-abw+bg
    local by=LIST_COMPACT and (ry+(ROWH-24)/2) or (ry+ROWH-31)
    local bxx=bx-bg
    for j,b in ipairs(bdef) do
     local k=b[2]
     local bw=bws[j]
     bxx=bxx+(j==1 and bg or bws[j-1]+bg)
     local on=(k==1 and s.done) or (k==2 and s.mark) or (k==3 and s.take) or (k>=5 and s.verdict==VKEY_ROW[k])
     local hov=(not ui_locked) and inside(bxx,by,bw,24)
     rect(bxx,by,bw,24,on and C.green or (hov and {.24,.30,.42} or {.17,.21,.30}))
     local fg=on and {.02,.13,.06} or C.text
     if row_icon(b[1],bxx+bw/2,by+12,fg) then else
      setf(13); local tw=(gfx.measurestr(b[1]) or 0)/KX
      txt(bxx+(bw-tw)/2,by+5,b[1],12,fg)
     end
     if pressed() and inside(bxx,by,bw,24) then ract=100000+idx*10+k; rowbtn=true end
    end
   end
   if pressed() and not rowbtn and inside(rxl,ry,rwid,ROWH-2) then
    if gfx.mouse_cap&4==4 then ract=500+idx
    elseif MX<cx+24 then ract=300+idx else ract=100+idx end
   end
  end
 end
 if #vis==0 then txt(x+24,RT+8,fit_text((#rows==0) and "Импортируй субтитры" or "Ничего не найдено",14,w-48),14,C.muted) end
 return ract
end

-- ducking (volume automation) panel; returns pressed button id
function draw_duck(x,y,w,h,pos)
 local a=nil
 -- everything inside the panel is clipped: an element is drawn only if it fits above the bottom edge
 local bottom=y+h-4
 local function B(bx,by,bw,bh,label,kind,id,size)
  if by+bh<=bottom then local r=button(bx,by,bw,bh,label,kind,id,size); if r then a=r end end
 end
 if h<150 then
  -- compact layout for short windows
  rect(x,y,w,h,C.panel)
  txt(x+10,y+5,"Ducking −"..duck.." dB",13,C.text)
  B(x+w-132,y+2,60,22,"−5 dB",nil,6,12)
  B(x+w-68,y+2,56,22,"＋5 dB",nil,7,12)
  B(x+10,y+28,w-20,22,"Только под дубляжом: "..(only_dub and "ВКЛ" or "ВЫКЛ"),only_dub and "green" or nil,18,12)
  local line="Перед "..pre.." ms · После "..post.." ms · Плавно "..fi.." ms · Возврат "..fo.." ms"
  if y+56+14<=bottom then txt(x+10,y+56,fit_text(line,12,w-20),12,C.muted) end
  return a
 end
 rect(x,y,w,h,C.panel); txt(x+12,y+8,"АВТОМАТИЗАЦИЯ ГРОМКОСТИ",14,C.text)
 local k=clampf(math.floor((h-100)/5),12,26)
 local y0=y+34
 local L={{"Приглушить оригинал","−"..duck.." dB"},{"Перед репликой",pre.." ms"},{"После реплики",post.." ms"},
          {"Плавное снижение",fi.." ms"},{"Возврат громкости",fo.." ms"}}
 for i,p in ipairs(L) do
  local ry=y0+(i-1)*k
  if ry+14<=bottom then
   txt(x+12,ry,p[1],13,C.muted)
   txt(x+w-110,ry,p[2],13,C.text)
  end
 end
 local by=y0+5*k+4
 local hw=math.floor((w-36)/2)
 B(x+12,by,hw,28,"−5 dB",nil,6,13)
 B(x+24+hw,by,hw,28,"＋5 dB",nil,7,13)
 B(x+12,by+34,w-24,28,"Только под дубляжом: "..(only_dub and "ВКЛ" or "ВЫКЛ"),only_dub and "green" or nil,18,13)
 if by+34+28+36<=y+h then draw_preview(x+12,by+70,w-24,math.min(34,y+h-(by+70)-6),pos) end
 return a
end

-- subtitles panel (overlay and exports); returns pressed button id
function draw_subs(x,y,w,h)
 local a=nil
 local bottom=y+h-4
 local function B(bx,by,bw,bh,label,kind,id,size)
  if by+bh<=bottom then local r=button(bx,by,bw,bh,label,kind,id,size); if r then a=r end end
 end
 if h<150 then
  rect(x,y,w,h,C.panel)
  local hw=math.floor((w-30)/2)
  B(x+10,y+4,w-20,22,"Оверлей на видео: вкл / выкл","primary",8,12)
  B(x+10,y+30,hw,22,"Экспорт SRT",nil,19,12)
  B(x+20+hw,y+30,hw,22,"В регионы",nil,20,12)
  B(x+10,y+56,hw,22,"В текстовые итемы",nil,21,12)
  B(x+20+hw,y+56,hw,22,"Восстановить оверлей",nil,31,12)
  return a
 end
 rect(x,y,w,h,C.panel); txt(x+12,y+8,"СУБТИТРЫ",14,C.text)
 local by=y+34
 local hw=math.floor((w-36)/2)
 B(x+12,by,w-24,28,"Оверлей на видео: вкл / выкл","primary",8,13)
 B(x+12,by+34,hw,28,"Экспорт SRT",nil,19,13)
 B(x+24+hw,by+34,hw,28,"В регионы",nil,20,13)
 B(x+12,by+68,hw,28,"В текстовые итемы",nil,21,13)
 B(x+24+hw,by+68,hw,28,"Восстановить оверлей",nil,31,13)
 return a
end

-- stats text stops before the row buttons column (x > 548 is reserved for buttons)
function sadv(x,y,t,size,col) if x>(LAY.stat_max or 548) then return x end return txt_adv(x,y,t,size,col) end
VKEY_ROW={[5]="ok",[6]="redo",[7]="check",[8]="lip"}


-- all tools: label (short), help (what it does)
TOOL_ITEMS={
 [1]={l="Импорт оригинала",h="Загрузить второй файл субтитров для сравнения с переводом."},
 [2]={l="Подогнать под дубли",h="Подогнать тайминг всех реплик под записи дубляжа на дорожке (по takes)."},
 [3]={l="Сдвинуть время",h="Сдвинуть все реплики (или выбранные) на заданное время."},
 [4]={l="Замена текста",h="Глобальная замена слова или фразы в тексте всех реплик."},
 [5]={l="Переименовать роль",h="Поменять имя роли во всех репликах."},
 [6]={l="Приглушение по ролям",h="Глубина приглушения оригинала (дБ) отдельно для каждой роли."},
 [7]={l="Приглушение по дорожкам",h="Глубина приглушения по дорожкам оригинала."},
 [8]={l="Окна приглушения",h="Переключить: брать окна приглушения из записей дубляжа или из субтитров."},
 [9]={l="Пре-ролл",h="Сколько секунд звучит перед репликой при воспроизведении (задаётся числом)."},
 [10]={l="Сбросить «записано»",h="Снять отметку «записано» со всех реплик."},
 [11]={l="SRT по ролям",h="Экспорт субтитров SRT отдельным файлом на каждую роль."},
 [12]={l="Экспорт проекта",h="Сохранить всю сессию (реплики, роли, настройки) в файл .dubproj."},
 [13]={l="Импорт проекта",h="Загрузить сессию из файла .dubproj."},
 [14]={l="Сохранить версию",h="Записать текущее состояние сессии как версию сейчас."},
 [15]={l="Восстановить версию",h="Выбрать сохранённую версию и вернуть сессию к ней."},
 [16]={l="Проверка QC",h="Отчёт: скорость речи, паузы, дубли, выход дубля за окно реплики."},
 [17]={l="Сценарии (текст)",h="Текстовые сценарии для каждого актёра, по одному файлу на роль."},
 [18]={l="Дубли на N кадров",h="Сдвинуть дубли выбранной реплики на заданное число кадров."},
 [19]={l="Лучший дубль",h="Выбрать лучший дубль выбранной реплики, остальные приглушить."},
 [20]={l="Справка (F1)",h="Открыть окно с горячими клавишами и описанием."},
 [21]={l="Записано по дорожке",h="Отметить как записанные реплики, по которым на дорожке дубляжа уже есть запись."},
 [22]={l="Громкость дублей",h="Проверить клиппинг и тишину в дублях, записать отчёт."},
 [23]={l="Сценарии (HTML)",h="HTML-сценарии по ролям, открываются для печати в PDF."},
 [24]={l="Таймкод: кадры",h="Переключить таймкод между секундами и кадрами."},
 [25]={l="Пороги проверки",h="Изменить пороги скорости, паузы и короткой реплики для проверки QC."},
 [26]={l="Сводка по актёрам",h="Сколько реплик записано и осталось у каждого актёра."},
 [27]={l="Лист сессии (CSV)",h="Таблица сессии для Excel (разделитель «;», запятая в числах)."},
 [28]={l="Экспорт VTT",h="Субтитры в формате WebVTT."},
 [29]={l="Фильтр по статусу",h="Показать только реплики с выбранным статусом: все, переписать, спорно, ок, не записано."},
 [30]={l="Вызывной лист",h="HTML-лист для актёра с ещё не записанными репликами."},
 [31]={l="Сводка за день",h="Сколько записано, листов и оценок сделано в сессии."},
 [32]={l="Выровнять громкость",h="Привести громкость дублей к медиане, не больше ±6 дБ от неё."},
 [33]={l="Сдвинуть выбранные",h="Сдвинуть все отмеченные (Ctrl+клик) реплики на N секунд."},
 [34]={l="Назначить роль",h="Назначить одну роль всем отмеченным репликам."},
 [35]={l="Отметить записано",h="Отметить все отмеченные реплики как записанные."},
 [36]={l="Снять «записано»",h="Снять отметку «записано» с отмеченных реплик."},
 [37]={l="Снять выбор",h="Убрать все отмеченные реплики (Ctrl+клик)."},
 [38]={l="Проверка окружения",h="Проверить ReaImGui, js_ReaScriptAPI, аудио и файл оверлея."},
 [39]={l="Горячие клавиши",h="Задать свои латинские буквы для действий (1–4 оценки не меняются)."},
 [40]={l="Колонки в списке",h="Включить или выключить колонки статистики в строках."},
 [41]={l="Сохранить профиль",h="Сохранить настройки ducking, пре/пост-ролла, фейдов и порогов в файл."},
 [42]={l="Загрузить профиль",h="Загрузить сохранённый профиль настроек."},
 [43]={l="Проблемы проверки",h="Список реплик, требующих проверки, с переходом к выбранной."},
 [44]={l="Сравнение takes",h="Громкость каждого дубля внутри элемента относительно медианы."},
 [45]={l="LUFS по дубляжу",h="Интегральная и пиковая громкость каждого дубля по BS.1770."},
 [46]={l="Полный сброс настроек",h="Все настройки к заводским, включая оверлей и назначение дорожек. Реплики не трогаются."},
 [47]={l="Очистить сессию",h="Удалить все реплики, отметки и оценки. Настройки и версии остаются."},
 [49]={l="Новая дорожка дубляжа",h="Создать НОВУЮ дорожку «Дубляж» с цепочкой эффектов из DUB_CHAIN (не назначает существующую). Эффекты выключаются на время записи и включаются после неё."},
 [50]={l="Сведение аниме",h="Создать структуру сведения из проекта anime_mix: Master, Raw, Voice (ALL), Effects (All), Effects (Voice 1–8), Voice 1–8. Роутинг и цепочки эффектов из проекта. Если структура уже есть, дубль не создаётся."},
 [51]={l="Суфлёр на телефон / планшет",h="Создать страницу суфлёра с репликами проекта и показать адрес для телефона. Нужен включённый веб-интерфейс REAPER (Preferences → Control/OSC/web → Web browser interface, порт 8080). Страница сама следит за курсором REAPER; кнопки «Назад / Следующая» переставляют курсор."},
 [54]={l="Суфлёр: сервер видео",h="Запустить Python-сервер, который отдаёт на телефон ОРИГИНАЛЬНОЕ видео проекта (без копий и ffmpeg). Нужен Python 3. Страница суфлёра на телефоне находит сервер сама."},
 [53]={l="Суфлёр: видео для телефона",h="Сделать лёгкую копию видео проекта (mp4 480p со звуком, ffmpeg в фоне) в reaper_www_root. Телефон сам заберёт её с ПК, копировать файл на телефон не нужно. Прогресс в строке состояния."},
 [48]={l="Субтитры из видео",h="Выбрать дорожку субтитров, вшитую в MKV/MP4, и импортировать её. Нужны ffmpeg и ffprobe."},
}
-- panel layout: groups stacked inside columns (col 1..4)
TOOL_GROUPS={
 {name="Импорт и тайминг",col=1,ids={1,48,49,2,3,18,4,5,9}},
 {name="Профили",col=1,ids={41,42}},
 {name="Записи и громкость",col=2,ids={10,21,19,6,7,8,32}},
 {name="Пакетные действия",col=2,ids={33,34,35,36,37}},
 {name="Проверка качества",col=3,ids={16,22,44,45,43,25}},
 {name="Сессия и сводки",col=3,ids={12,13,14,15,26,31,47}},
 {name="Экспорт",col=4,ids={11,17,23,27,28,30}},
 {name="Настройки",col=4,ids={29,20,24,38,39,40,46}},
 {name="Сведение аниме",col=4,ids={50}},
 {name="Телефон / планшет",col=4,ids={51,53,54}},
}

-- full-window panel with every tool as a visible button (columns follow the window width)
tools_panel=false
pending_tool=nil
-- ---------- новый главный экран: суфлёр ----------
HOME=true; HOME_FS=0.55
function home_btn(x,y,w,h,label,fill,col,size)
 if (not ui_locked) and inside(x,y,w,h) then fill={math.min(1,fill[1]+.05),math.min(1,fill[2]+.05),math.min(1,fill[3]+.05)} end
 rect(x,y,w,h,fill)
 setf(size); local tw=(gfx.measurestr(label) or 0)/KX
 txt(x+(w-tw)/2,y+(h-size-3)/2,label,size,col)
 return pressed() and inside(x,y,w,h)
end
HOME_LOCK=false
function home_rrect(x,y,w,h,r,c)
 gfx.set(c[1],c[2],c[3],c[4] or 1)
 r=math.max(0,math.min(r,math.floor(h/2),math.floor(w/2)))
 grect(x+r,y,w-2*r,h,1); grect(x,y+r,w,h-2*r,1)
 gfx.circle((x+r)*KX,(y+r)*KY,r*KX,1,1); gfx.circle((x+w-r-1)*KX,(y+r)*KY,r*KX,1,1)
 gfx.circle((x+r)*KX,(y+h-r-1)*KY,r*KX,1,1); gfx.circle((x+w-r-1)*KX,(y+h-r-1)*KY,r*KX,1,1)
end
-- скруглённая кнопка; возвращает true по нажатию
function home_rbtn(x,y,w,h,label,fill,col,size)
 local f=fill
 if (not ui_locked) and inside(x,y,w,h) then f={math.min(1,fill[1]+.06),math.min(1,fill[2]+.06),math.min(1,fill[3]+.07)} end
 home_rrect(x,y,w,h,math.floor(h*0.22),f)
 setf(size); local tw=(gfx.measurestr(label) or 0)/KX
 txt(x+(w-tw)/2,y+(h-size-3)/2,label,size,col)
 return pressed() and inside(x,y,w,h)
end
-- маленькая кнопка в верхней строке (Aa, Ещё, замок); работает даже при блокировке
function home_ibtn(x,y,w,h,label,on)
 local hov=(not edit_mode) and inside(x,y,w,h)
 local bg=on and {.87,.90,.93} or (hov and {.12,.15,.20} or {.07,.09,.13})
 home_rrect(x,y,w,h,9,on and bg or {.14,.17,.22})
 home_rrect(x+1,y+1,w-2,h-2,8,bg)
 if label~="" then
  setf(13); local tw=(gfx.measurestr(label) or 0)/KX
  txt(x+(w-tw)/2,y+(h-16)/2,label,13,on and {.05,.07,.10} or {.72,.76,.82})
 end
 return (not edit_mode) and raw_pressed() and inside(x,y,w,h)
end
function home_lock_icon(x,y,w,h,on)
 local cx,cy,k=x+w/2,y+h/2,h*0.2
 local c=on and {.05,.07,.10} or {.72,.76,.82}
 gfx.set(c[1],c[2],c[3],1)
 grect(cx-k,cy-k*0.2,k*2,k*1.6,0)
 gline(cx-k*0.6,cy-k*0.2,cx-k*0.6,cy-k*1.2); gline(cx-k*0.6,cy-k*1.2,cx+k*0.6,cy-k*1.2)
 gline(cx+k*0.6,on and cy-k*0.2 or cy-k*0.7,cx+k*0.6,cy-k*1.2)
end
function home_up(str)
 local ok,res=pcall(function()
  local t={}
  for _,c in utf8.codes(str) do
   if c>=0x61 and c<=0x7A then c=c-32
   elseif c>=0x430 and c<=0x44F then c=c-32
   elseif c==0x451 then c=0x401 end
   t[#t+1]=utf8.char(c)
  end
  return table.concat(t)
 end)
 return ok and res or str:upper()
end
-- текст с разрядкой; dry=true только измеряет; возвращает ширину
function home_spaced(x,y,str,size,col,sp,dry,bold)
 gfx.setfont(1,"Arial",math.max(8,math.floor(size*KF+0.5)),bold and 98 or 0)
 local chars={}
 for _,c in utf8.codes(str) do chars[#chars+1]=utf8.char(c) end
 local w=0
 for i,ch in ipairs(chars) do w=w+(gfx.measurestr(ch) or 0)/KX+(i<#chars and sp or 0) end
 if dry then return w end
 gfx.set(col[1],col[2],col[3],col[4] or 1)
 local cx=x
 for _,ch in ipairs(chars) do gfx.x=cx*KX; gfx.y=y*KY; gfx.drawstr(ch); cx=cx+(gfx.measurestr(ch) or 0)/KX+sp end
 return w
end
function home_big(s,x,y,w,h)
 s=tostring(s or ""):gsub("%s*\n%s*"," ")   -- переносы из субтитров не нужны: текст сам перестраивается по ширине окна
 local sz=math.floor(math.min(h*0.5,w*0.16,52)*HOME_FS)
 local lines
 while true do
  gfx.setfont(1,"Arial",math.max(8,math.floor(sz*KF+0.5)),98)
  lines={}
  for para in (s.."\n"):gmatch("(.-)\n") do
   local cur=""
   for word in para:gmatch("%S+") do
    local t=(cur=="") and word or (cur.." "..word)
    if gfx.measurestr(t)/KX>w and cur~="" then lines[#lines+1]=cur; cur=word else cur=t end
   end
   lines[#lines+1]=cur
  end
  if sz<=16 or #lines*sz*1.12<=h then break end
  sz=sz-2
 end
 local lh=sz*1.12
 local y0=y+(h-#lines*lh)/2
 HOME_Y0=y0
 for i,l in ipairs(lines) do
  local tw=(gfx.measurestr(l) or 0)/KX
  gfx.set(1,1,1,1); gfx.x=(x+(w-tw)/2)*KX; gfx.y=(y0+(i-1)*lh)*KY; gfx.drawstr(l)
 end
end
function do_act(act)
 if act and act>=100000 then
  local idx,k=math.floor((act-100000)/10),(act-100000)%10
  if rows[idx] then goto_row(idx) end
  if k==0 then play_line(false)
  elseif k==1 then toggle_done(idx)
  elseif k==2 then toggle_mark()
  elseif k==3 then cycle_best_take()
  elseif k==4 then begin_edit("note")
  else set_verdict(VKEY_ROW[k]) end
 elseif act and act>=500 then toggle_pick(act-500)
 elseif act and act>=300 then toggle_done(act-300)
 elseif act and act>100 and act<300 then goto_row(act-100)
 elseif act==1 then import_all()
 elseif act==2 then set_track("orig")
 elseif act==3 then set_track("dub")
 elseif act==4 then edit_settings()
 elseif act==5 then generate_duck()
 elseif act==6 then duck=math.max(0,duck-5); save()
 elseif act==7 then duck=math.min(100,duck+5); save()
 elseif act==8 then launch_overlay()
 elseif act==11 then begin_edit("text")
 elseif act==12 then edit_time()
 elseif act==13 then split_row()
 elseif act==14 then merge_row()
 elseif act==15 then delete_row()
 elseif act==16 then undo()
 elseif act==17 then follow=not follow; save(); status=follow and "Слежение за воспроизведением: вкл" or "Слежение за воспроизведением: выкл"
 elseif act==18 then only_dub=not only_dub; save(); status=only_dub and "Приглушение только там, где на дорожке дубляжа есть звук" or "Приглушение по всем репликам"
 elseif act==19 then export_srt()
 elseif act==20 then to_regions()
 elseif act==21 then to_items()
 elseif act==22 then play_line(false)
 elseif act==23 then play_line(true)
 elseif act==24 then toggle_done()
 elseif act==25 then begin_edit("note")
 elseif act==26 then toggle_mark()
 elseif act==27 then fit_to_takes(false)
 elseif act==32 then import_from_video()
 elseif act==30 then TAB=4
 elseif act==31 then restore_overlay()
 elseif act==60 then TAB=1
 elseif act==49 then run_tool(49) end
end


-- ---------- универсальная оболочка: верх, вкладки, содержимое ----------
TAB=1; TOPBAR=false
function tools_embedded(top,bottom)
 local cols=(W>=1000) and 3 or ((W>=600) and 2 or 1)
 local gap=14
 local colw=math.floor((W-40-(cols-1)*gap)/cols)
 tools_scroll=clampf(tools_scroll,0,tools_max)
 local help=""
 local yc={}
 for c=1,cols do yc[c]=top+8-tools_scroll end
 local n=0
 for _,g in ipairs(TOOL_GROUPS) do
  n=n+1
  local m=((n-1)%cols)+1
  local x=20+(m-1)*(colw+gap)
  local y=yc[m]
  if y>=top-6 and y<=bottom-44 then txt(x,y,g.name,12,{.48,.66,1}) end
  y=y+22
  for _,id in ipairs(g.ids) do
   local t=TOOL_ITEMS[id]
   local shown=(y>=top) and (y+30<=bottom-30)
   local over=shown and inside(x,y,colw,30)
   if shown then
    rect(x,y,colw,30,(over and not ui_locked) and {.15,.19,.27} or C.panel)
    txt(x+12,y+8,fit_text(t.l,13,colw-40),13,C.text)
    txt(x+colw-18,y+8,"›",13,C.muted)
   end
   if over then help=t.h end
   if over and pressed() then pending_tool=id end
   y=y+32
  end
  yc[m]=y+12
 end
 local content=0
 for c=1,cols do content=math.max(content,yc[c]-(top+8-tools_scroll)) end
 tools_max=math.max(0,content-(bottom-top-38))
 if help~="" then
  rect(0,bottom-28,W,28,{.082,.105,.145}); txt(20,bottom-22,fit_text(help,12,W-40),12,C.text)
 end
 if pending_tool then local id=pending_tool; pending_tool=nil; run_tool(id) end
end

function draw_shell()
 local playing=(reaper.GetPlayState()&1)==1
 local pos=playing and reaper.GetPlayPosition() or reaper.GetCursorPosition()
 local cur_idx=row_at(pos)
 if follow and playing and cur_idx>0 and cur_idx~=last_cur then
  local vp=vpos_of(cur_idx)
  if vp>0 then scroll=math.max(0,vp-3) end
 end
 last_cur=cur_idx
 local ci=cur_idx
 if ci<=0 then
  -- курсор между репликами: показываем ближайшую следующую (если её нет — последнюю)
  ci=#rows
  local best=nil
  for i,r in ipairs(rows) do
   if r.start>=pos and (not best or r.start<rows[best].start) then best=i end
  end
  if best then ci=best end
  if ci<1 then ci=1 end
 end
 rect(0,0,W,H,C.bg)
 local act=nil
 local TH=(H<300) and 34 or 48
 local TB=(H<300) and 30 or 38
 -- верхняя строка
 local showtop=(TAB~=1) or TOPBAR
 if showtop then
 rect(0,0,W,TH,C.panel); rect(0,TH-1,W,1,C.line)
 if TAB~=1 then
  local dc=(playing or #rows>0) and C.green or {.93,.36,.36}
  gfx.set(dc[1],dc[2],dc[3],1); gfx.circle(24*KX,TH/2*KY,4.5*KX,1,1)
  local tsz=22
  gfx.setfont(1,"Arial",math.max(8,math.floor(tsz*KF+0.5)),98)
  local tstr=ftime(pos)
  gfx.set(.95,.92,.88,1); gfx.x=40*KX; gfx.y=(TH/2-tsz/2-2)*KY; gfx.drawstr(tstr)
  local tend=40+(gfx.measurestr(tstr) or 0)/KX
  if #rows>0 and W>=640 then home_spaced(tend+14,TH/2-7,string.format("РЕПЛИКА %03d / %d",ci,#rows),11,C.muted,1.4,false,true) end
 else
  -- верх экрана «Суфлёр»: точка, время, номер реплики; справа Ещё / Aa / замок
  rect(0,0,W,TH,C.bg)
  local dc=(playing or #rows>0) and C.green or {.93,.36,.36}
  gfx.set(dc[1],dc[2],dc[3],1); gfx.circle(24*KX,TH/2*KY,4.5*KX,1,1)
  local tsz=22
  gfx.setfont(1,"Arial",math.max(8,math.floor(tsz*KF+0.5)),98)
  local tstr=ftime(pos)
  gfx.set(.95,.92,.88,1); gfx.x=40*KX; gfx.y=(TH/2-tsz/2-2)*KY; gfx.drawstr(tstr)
  local tend=40+(gfx.measurestr(tstr) or 0)/KX
  local bh,bgp=math.min(32,TH-12),8
  local by0=(TH-bh)/2
  local xr=W-14
  xr=xr-32; local rl=home_ibtn(xr,by0,32,bh,"",HOME_LOCK); home_lock_icon(xr,by0,32,bh,HOME_LOCK)
  xr=xr-bgp-32; local ra=home_ibtn(xr,by0,32,bh,"Aa",false)
  xr=xr-bgp-54; local rm=home_ibtn(xr,by0,54,bh,"Ещё ▾",false)
  if #rows>0 then
   local full=string.format("РЕПЛИКА %03d / %d",ci,#rows)
   local cx=tend+14
   if cx+home_spaced(0,0,full,11,C.muted,1.4,true,true)>xr-10 then full=string.format("%03d / %d",ci,#rows) end
   if cx+home_spaced(0,0,full,11,C.muted,1.4,true,true)<=xr-10 then home_spaced(cx,TH/2-7,full,11,C.muted,1.4,false,true) end
  end
  if rl then HOME_LOCK=not HOME_LOCK; status=HOME_LOCK and "Кнопки заблокированы — замок справа сверху снимает блокировку" or "Кнопки разблокированы" end
  if ra then
   local m=popup({"Текст крупнее","Текст мельче",(frames_mode and "!" or "").."Таймкод в кадрах"})
   if m==1 then HOME_FS=math.min(3.2,HOME_FS+0.15) elseif m==2 then HOME_FS=math.max(0.4,HOME_FS-0.15) elseif m==3 then toggle_frames() end
  end
  if rm then
   local m=popup({"Реплики (список)","Громкость","Инструменты","","Экспорт…","Субтитры из видео (выбор дорожки)",(TOPBAR and "!" or "").."Верхняя строка"})
   if m==1 then TAB=2 elseif m==2 then TAB=3 elseif m==3 then TAB=4
   elseif m==5 then act=19 elseif m==6 then act=32 elseif m==7 then TOPBAR=not TOPBAR end
  end
 end
 end


 setf(13)
 local ibw=math.floor((gfx.measurestr("+ Импорт субтитров") or 0)/KX)+28
 local by=H-TB
 if TAB~=1 then
  if home_btn(W-18-ibw,TH/2-14,ibw,28,"+ Импорт субтитров",C.blue,{1,1,1},13) then act=1 end
 end
 -- нижняя полоса: на «Суфлёре» вкладки и A−/A+ прячутся и появляются при наведении
 local hover=(TAB~=1) or (MY>=by-8 and MY<=H)
 if hover and TAB~=1 then rect(0,by,W,TB,C.panel); rect(0,by,W,1,C.line) end
 local names={"Суфлёр","Реплики","Громкость","Инструменты"}
 local dcol={{.25,.78,.35},{.93,.68,.22},{.88,.31,.30},{.30,.52,1}}
 if TAB==1 then
  setf(13)
  local b1=math.floor((gfx.measurestr("Импорт…") or 0)/KX)+28
  local b2=math.floor((gfx.measurestr("Экспорт…") or 0)/KX)+28
  if home_btn(16,by+(TB-28)/2,b1,28,"Импорт…",{.17,.17,.18},{.85,.87,.90},13) then act=1 end
  if home_btn(16+b1+8,by+(TB-28)/2,b2,28,"Экспорт…",{.17,.17,.18},{.85,.87,.90},13) then act=19 end
  if hover then
   for j,d in ipairs({{"−",-0.15},{"+",0.15}}) do
    local cx=W-70+(j-1)*34
    local ov=(not ui_locked) and ((MX-cx)^2+(MY-(by+TB/2))^2<=144)
    gfx.set(ov and .30 or .20,ov and .35 or .24,ov and .46 or .33,1); gfx.circle(cx*KX,(by+TB/2)*KY,11*KX,1,1)
    setf(14); local tw=(gfx.measurestr(d[1]) or 0)/KX; txt(cx-tw/2,by+TB/2-9,d[1],14,C.text)
    if ov and pressed() then HOME_FS=math.max(0.5,math.min(3.2,HOME_FS+d[2])) end
   end
  end
 end
 if hover and TAB~=1 then   -- точки-вкладки скрыты на экране суфлёра (переключение: F2–F5, F6 — верхняя строка)
  local gap=34
  local nn=#names+((TAB==1) and 1 or 0)
  local x0=W/2-(nn-1)*gap/2
  if TAB==1 then
   setf(13)
   local lend=16+math.floor((gfx.measurestr("Импорт…") or 0)/KX)+28+8+math.floor((gfx.measurestr("Экспорт…") or 0)/KX)+28
   x0=math.max(x0,lend+28)
  end
  local label=nil
  if TAB==1 then
   local cx,cy=x0+(nn-1)*gap,by+TB/2
   local ov=(not ui_locked) and ((MX-cx)^2+(MY-cy)^2<=170)
   if TOPBAR then gfx.set(1,1,1,.9); gfx.circle(cx*KX,cy*KY,10*KX,0,1) end
   gfx.set(1,1,1,(TOPBAR or ov) and 1 or .75); gfx.circle(cx*KX,cy*KY,(ov and 9 or 7.5)*KX,1,1)
   if ov then label="Верхняя строка"; if pressed() then TOPBAR=not TOPBAR end end
  end
  for i,nm in ipairs(names) do
   local cx=x0+(i-1)*gap
   local cy=by+TB/2
   local ov=(not ui_locked) and ((MX-cx)^2+(MY-cy)^2<=170)
   local c=dcol[i]
   local r=(TAB==i) and 10 or (ov and 9 or 7.5)
   if TAB==i then gfx.set(1,1,1,.9); gfx.circle(cx*KX,cy*KY,(r+3)*KX,0,1) end
   gfx.set(c[1],c[2],c[3],(TAB==i or ov) and 1 or .75); gfx.circle(cx*KX,cy*KY,r*KX,1,1)
   if ov then label=nm; if pressed() then TAB=i end end
  end
  label=label or names[TAB]
  setf(12); local lw=(gfx.measurestr(label) or 0)/KX
  if x0+(nn-1)*gap+26+lw < W-90 then txt(x0+(nn-1)*gap+26,by+TB/2-7,label,12,C.muted) end
 end
 local top,bot=((TAB==1) and not TOPBAR) and 0 or TH,by
 if TAB==1 then
  local s=rows[ci]
  local ty,th=top,H-top
  if s then
   home_big(s.text or "",30,ty,W-60,th)
   local r=s.role or ""
   if r~="" then setf(13); local rw=(gfx.measurestr(r) or 0)/KX; txt((W-rw)/2,math.max(ty,HOME_Y0-26),r,13,{.48,.66,1}) end
  else
  end
 elseif TAB==2 then
  CLIP_B=bot-2
  local items=dub_items_cached()
  local acts=list_actions()
  local LB=bot-4
  LIST_COMPACT=(bot-top)<360
  local ab,aget=0,nil
  if not LIST_COMPACT then
   local _,h=flow_buttons(acts,28,0,W-56,30,6,13,true)
   ab=h
  end
  local ract=draw_list(20,top+8,W-40,LB-top-8,W<700 or LIST_COMPACT,items,cur_idx,(LIST_COMPACT and LB-4) or (LB-8-ab-6))
  if not LIST_COMPACT then aget=flow_buttons(acts,28,LB-8-ab,W-56,30,6,13) end
  act=act or ract or aget
 elseif TAB==3 then
  CLIP_B=bot-2
  local wide=W>=900
  local dw=wide and math.floor((W-60)*0.5) or (W-40)
  local dact=draw_duck(20,top+12,dw,bot-top-24-46,pos)
  act=act or dact
  if home_btn(20,bot-12-38,dw,38,"Создать автоматизацию",C.green,{.02,.13,.06},14) then act=5 end
  if wide then
   local sact=draw_subs(20+dw+20,top+12,W-dw-60,bot-top-24)
   act=act or sact
  end
 else
  tools_embedded(top,bot)
 end
 return act
end

local function draw()
 ui_locked=edit_mode or (HOME_LOCK and TAB==1)
 local a=draw_shell()
 if a then do_act(a) end
 if edit_mode then draw_edit_modal() end
end

-- перетаскивание файлов в окно суфлёра: видео вставляется в проект, субтитры импортируются и показываются регионами
function dub_handle_drop()
 local ok,f=gfx.getdropfile(0)
 if not ok or not f or f=="" then return end
 local files,i={},0
 while true do
  local o,p=gfx.getdropfile(i)
  if not o or not p or p=="" then break end
  files[#files+1]=p; i=i+1
 end
 gfx.getdropfile(-1)
 local subs,media
 for _,p in ipairs(files) do
  local e=(p:match("%.([^%.\\/]+)$") or ""):lower()
  if e=="srt" or e=="ass" or e=="ssa" or e=="vtt" then subs=subs or p
  elseif e=="mkv" or e=="mp4" or e=="avi" or e=="mov" or e=="webm" or e=="m4v" or e=="wmv" or e=="mpg" or e=="mpeg" or e=="ts" or e=="wav" or e=="mp3" or e=="flac" then media=media or p end
 end
 if media then
  reaper.Undo_BeginBlock(); reaper.PreventUIRefresh(1)
  reaper.SetEditCurPos(0,false,false)
  reaper.InsertMedia(media,1)
  reaper.PreventUIRefresh(-1); reaper.UpdateArrange()
  reaper.Undo_EndBlock("Dubbing System: добавить видео",-1)
  status="Видео добавлено: "..(media:match("([^\\/]+)$") or media)
 end
 -- как у кнопки «Импорт…»: субтитры из файла или из вшитой в видео дорожки (если их несколько, спросит язык) → регионы и итемы
 if subs then load_subs_path(subs)
 elseif media then
  local e=(media:match("%.([^%.\\/]+)$") or ""):lower()
  if e~="wav" and e~="mp3" and e~="flac" then import_from_video(media,true) end
 end
 if (subs or media) and #rows>0 then
  local _,nm,nr=reaper.CountProjectMarkers(0)
  if nr==0 then to_regions(true) end
  local has=false
  for i=0,reaper.CountTracks(0)-1 do
   local _,tn=reaper.GetSetMediaTrackInfo_String(reaper.GetTrack(0,i),"P_NAME","",false)
   if tn=="Dubbing Subtitles (text items)" then has=true end
  end
  if not has then to_items(true) end
  status="Готово: реплик "..#rows..", регионы и текстовые итемы созданы"
 end
end

local function loop()
 local ch=gfx.getchar()
 dub_handle_drop()
 if ch==-1 then quit_loop(); return end
 -- map the real window onto the W x H canvas: positions stretch, text keeps its proportions
 refresh_layout()
 MX=gfx.mouse_x; MY=gfx.mouse_y
 if ov_restore_at and reaper.time_precise()>=ov_restore_at then
  ov_restore_at=nil; launch_overlay(); status="Оверлей восстановлен с настройками по умолчанию"
 end
 if not edit_mode then
  if ch==26162 then TAB=1 elseif ch==26163 then TAB=2 elseif ch==26164 then TAB=3 elseif ch==26165 then TAB=4
  elseif ch==26166 then TOPBAR=not TOPBAR end
 end
 local handled=handle_key(ch)
 if not handled then
  if ch==27 then quit_loop(); return end
  if ch==30064 then move_sel(-1)
  elseif ch==1685026670 then move_sel(1)
  elseif ch==13 then begin_edit("text") end
 end
 if gfx.mouse_wheel~=0 then
  if tools_panel or TAB==4 then tools_scroll=tools_scroll-(gfx.mouse_wheel>0 and 40 or -40)
  elseif not edit_mode then scroll=scroll-(gfx.mouse_wheel>0 and 1 or -1) end
  gfx.mouse_wheel=0
 end
 gfx.set(0,0,0,1); gfx.rect(0,0,gfx.w,gfx.h,1)
 dub_rec_guard()
 draw()
 Mobile.tick()
 autosave_version()
 lastcap=gfx.mouse_cap
 do local t=reaper.time_precise()
  reaper.SetExtState("DubbingPrompter","alive",string.format("%.3f",t),false)
  if t-(DK_T or 0)>1 then DK_T=t
   local d=gfx.dock(-1)
   if d~=DK_LAST then DK_LAST=d; reaper.SetExtState("DubbingPrompter","dock",tostring(d),true)
    local _,x,y,w,h=gfx.dock(-1,0,0,0,0)
    if x then reaper.SetExtState("DubbingPrompter","pos",x..","..y..","..w..","..h,true) end end
  end end
 gfx.update()
 reaper.defer(loop)
end

-- при открытии суфлёра возвращаем регионы и итемы, которые были убраны при закрытии
function dub_restore_on_open()
 if #rows==0 then return end
 local wr=reaper.GetExtState("DubbingPrompter","restore_regions")=="1"
 local wi=reaper.GetExtState("DubbingPrompter","restore_items")=="1"
 if not wr and not wi then return end
 local _,nm,nr=reaper.CountProjectMarkers(0)
 if wr and nr==0 then to_regions(true) end
 local has=false
 for i=0,reaper.CountTracks(0)-1 do
  local _,tn=reaper.GetSetMediaTrackInfo_String(reaper.GetTrack(0,i),"P_NAME","",false)
  if tn=="Dubbing Subtitles (text items)" then has=true end
 end
 if wi and not has then to_items(true) end
 reaper.SetExtState("DubbingPrompter","restore_regions","0",true)
 reaper.SetExtState("DubbingPrompter","restore_items","0",true)
end
load_saved(); mark_dirty(); last_ver_str=serialize_rows(); load_prefs()
dub_restore_on_open()
Mobile.init()
function dub_gfx_init()
 local dk=tonumber(reaper.GetExtState("DubbingPrompter","dock")) or 0
 local px,py,pw,ph=(reaper.GetExtState("DubbingPrompter","pos") or ""):match("(-?%d+),(-?%d+),(%d+),(%d+)")
 if dk==0 and px then gfx.init("Dubbing Prompter",tonumber(pw),tonumber(ph),0,tonumber(px),tonumber(py))
 else gfx.init("Dubbing Prompter",518,367,dk) end
end
dub_gfx_init() -- default window size; resizable, layout scales with it
reaper.atexit(function() save(); dub_clean_on_close(); if dub_rec_off then set_dub_fx(true) end end)
loop()
