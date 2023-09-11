-- @noindex

-- This is generated code. See https://reapertoolkit.dev/ for more info.
-- version: 1.2.0
-- build: Wed Mar 23 00:22:10 UTC 2022
__RTK_VERSION='1.2.0'
rtk=(function()
__mod_rtk_core=(function()
__mod_rtk_log=(function()
local log={levels={[50]='CRITICAL',[40]='ERROR',[30]='WARNING',[20]='INFO',[10]='DEBUG',[9]='DEBUG2',},level=40,timer_threshold=20,named_timers=nil,timers={},queue={},lua_time_start=os.time(),reaper_time_start=reaper.time_precise(),}log.CRITICAL=50
log.ERROR=40
log.WARNING=30
log.INFO=20
log.DEBUG=10
log.DEBUG2=9
function log.critical(fmt,...)log._log(log.CRITICAL,nil,fmt,...)end
function log.error(fmt,...)log._log(log.ERROR,nil,fmt,...)end
function log.warning(fmt,...)log._log(log.WARNING,nil,fmt,...)end
function log.info(fmt,...)log._log(log.INFO,nil,fmt,...)end
function log.debug(fmt,...)log._log(log.DEBUG,nil,fmt,...)end
function log.debug2(fmt,...)log._log(log.DEBUG2,nil,fmt,...)end
local function enqueue(msg)local qlen=#log.queue
if qlen==0 then
reaper.defer(log.flush)end
log.queue[qlen+1]=msg
end
local function _get_precise_duration_string(t)if t<0.1 then
return string.format('%.03f', t)elseif t<1 then
return string.format('%.02f', t)elseif t<10 then
return string.format('%.01f', t)else
return string.format('%.0f', t)end
end
function log.exception(fmt,...)log._log(log.ERROR,debug.traceback(),fmt,...)log.flush()end
function log.trace(level)if log.level<=(level or log.DEBUG)then
enqueue(debug.traceback() .. '\n')end
end
function log._log(level,tail,fmt,...)if level<log.level then
return
end
local r,err=pcall(string.format,fmt,...)if not r then
log.exception("exception formatting log string '%s': %s", fmt, err)return
end
local now=reaper.time_precise()local time=log.lua_time_start+(now-log.reaper_time_start)local ftime=math.floor(time)local msecs=string.sub(time-ftime,3,5)local label='[' .. log.level_name(level) .. ']'local prefix=string.format('%s.%s %-9s ', os.date('%H:%M:%S', ftime), msecs, label)if level<=log.timer_threshold and #log.timers>0 then
local timer=log.timers[#log.timers]
local total=_get_precise_duration_string((now-timer[1])*1000)local last=_get_precise_duration_string((now-timer[2])*1000)local name=timer[3] and string.format(' [%s]', timer[3]) or ''prefix=prefix .. string.format('(%s / %s ms%s) ', last, total, name)timer[2]=now
end
local msg=prefix .. err .. '\n'if tail then
msg=msg .. tail .. '\n'end
enqueue(msg)end
function log.log(level,fmt,...)return log._log(level,nil,fmt,...)end
function log.logf(level,fmt,func)if level>=log.level then
return log._log(level,nil,fmt,func())end
end
function log.flush()local str=table.concat(log.queue)if #str>0 then
reaper.ShowConsoleMsg(str)end
log.queue={}end
function log.level_name(level)return log.levels[level or log.level] or 'UNKNOWN'end
function log.clear(level)if not level or log.level<=level then
reaper.ShowConsoleMsg("")log.queue={}end
end
function log.time_start(name)if log.level>log.timer_threshold then
return
end
local now=reaper.time_precise()table.insert(log.timers,{now,now,name})if name then
if not log.named_timers then
log.named_timers={}log.named_timers_order={}end
if not log.named_timers[name] then
log.named_timers[name]={0,0}log.named_timers_order[#log.named_timers_order+1]=name
end
end
end
function log.time_end(fmt,...)if fmt then
log._log(log.DEBUG,nil,fmt,...)end
log.time_end_report_if(false)end
function log.time_end_report(fmt,...)if fmt then
log._log(log.DEBUG,nil,fmt,...)end
log.time_end_report_if(true)end
function log.time_end_report_if(show,fmt,...)if log.level>log.timer_threshold then
return
end
if fmt and show then
log._log(log.DEBUG,nil,fmt,...)end
assert(#log.timers > 0, "time_end() with no previous time_start()")local t0,_,name=table.unpack(table.remove(log.timers))if log.named_timers then
if name then
local delta=reaper.time_precise()-t0
local current=log.named_timers[name]
if not current then
log.named_timers[name]={current+delta,1}else
log.named_timers[name]={current[1]+delta,current[2]+1}end
end
if show and log.level<=log.INFO then
local output=''local maxname=0
local maxtime=0
local times={}for i,name in ipairs(log.named_timers_order)do
local duration,_=table.unpack(log.named_timers[name])times[#times+1]=string.format('%.4f ms', duration * 1000)maxtime=math.max(maxtime,#times[#times])maxname=math.max(maxname,#name)end
local fmt=string.format('       %%2d. %%%ds: %%%ds  (%%d)\n', maxname, maxtime)for i,name in ipairs(log.named_timers_order)do
local _,count=table.unpack(log.named_timers[name])output=output..string.format(fmt,i,name,times[i],count)end
enqueue(output)end
end
if #log.timers==0 then
log.named_timers=nil
end
end
return log
end)()

local log=__mod_rtk_log
local rtk={touchscroll=false,smoothscroll=true,touch_activate_delay=0.1,long_press_delay=0.5,double_click_delay=0.5,tooltip_delay=0.5,light_luma_threshold=0.6,debug=false,has_js_reascript_api=(reaper.JS_Window_GetFocus~=nil),has_sws_extension=(reaper.BR_Win32_GetMonitorRectFromRect~=nil),script_path=nil,reaper_hwnd=nil,fps=30,focused_hwnd=nil,focused=nil,theme=nil,_dest_stack={},_image_paths={},_animations={},_animations_len=0,_easing_functions={},_frame_count=0,_frame_time=nil,_modal=nil,_touch_activate_event=nil,_last_traceback=nil,_last_error=nil,_quit=false,_refs=setmetatable({}, {__mode='v'}),_run_soon=nil,_reactive_attr={},}rtk.scale=setmetatable({user=nil,_user=1.0,system=nil,reaper=1.0,framebuffer=nil,value=1.0,_discover=function()local inifile=reaper.get_ini_file()local ini,err=rtk.file.read(inifile)if not err then
rtk.scale.reaper = ini:match('uiscale=([^\n]*)') or 1.0
end
local ok, dpi=reaper.ThemeLayout_GetLayout("mcp", -3)if not ok then
return
end
dpi=tonumber(dpi)rtk.scale.system=dpi/256.0
if not rtk.scale.framebuffer then
if rtk.os.mac and dpi==512 then
rtk.scale.framebuffer=2
else
rtk.scale.framebuffer=1
end
end
rtk.scale._calc()end,_calc=function()local value=rtk.scale.user*rtk.scale.system*rtk.scale.reaper
rtk.scale.value=math.ceil(value*100)/100.0
end,},{__index=function(t,key)return key=='user' and t._user or nil
end,__newindex=function(t,key,value)if key=='user' then
if value~=t._user then
t._user=value
rtk.scale._calc()if rtk.window then
rtk.window:queue_reflow()end
end
else
rawset(t,key,value)end
end
})rtk.dnd={dragging=nil,droppable=nil,dropping=nil,arg=nil,buttons=nil,}local _os=reaper.GetOS():lower():sub(1,3)rtk.os={mac = (_os == 'osx' or _os == 'mac'),windows=(_os=='win'),linux = (_os == 'lin' or _os == 'oth'),bits=32,}rtk.mouse={BUTTON_LEFT=1,BUTTON_MIDDLE=64,BUTTON_RIGHT=2,BUTTON_MASK=(1|2|64),x=0,y=0,down=0,state={order={}}}local _load_cursor
if rtk.has_js_reascript_api then
function _load_cursor(cursor)return reaper.JS_Mouse_LoadCursor(cursor)end
else
function _load_cursor(cursor)return cursor
end
end
rtk.mouse.cursors={UNDEFINED=0,POINTER=_load_cursor(32512),BEAM=_load_cursor(32513),LOADING=_load_cursor(32514),CROSSHAIR=_load_cursor(32515),UP_ARROW=_load_cursor(32516),SIZE_NW_SE=_load_cursor(rtk.os.linux and 32643 or 32642),SIZE_SW_NE=_load_cursor(rtk.os.linux and 32642 or 32643),SIZE_EW=_load_cursor(32644),SIZE_NS=_load_cursor(32645),MOVE=_load_cursor(32646),INVALID=_load_cursor(32648),HAND=_load_cursor(32649),POINTER_LOADING=_load_cursor(32650),POINTER_HELP=_load_cursor(32651),REAPER_FADEIN_CURVE=_load_cursor(105),REAPER_FADEOUT_CURVE=_load_cursor(184),REAPER_CROSSFADE=_load_cursor(463),REAPER_DRAGDROP_COPY=_load_cursor(182),REAPER_DRAGDROP_RIGHT=_load_cursor(1011),REAPER_POINTER_ROUTING=_load_cursor(186),REAPER_POINTER_MOVE=_load_cursor(187),REAPER_POINTER_MARQUEE_SELECT=_load_cursor(488),REAPER_POINTER_DELETE=_load_cursor(464),REAPER_POINTER_LEFTRIGHT=_load_cursor(465),REAPER_POINTER_ARMED_ACTION=_load_cursor(434),REAPER_MARKER_HORIZ=_load_cursor(188),REAPER_MARKER_VERT=_load_cursor(189),REAPER_ADD_TAKE_MARKER=_load_cursor(190),REAPER_TREBLE_CLEF=_load_cursor(191),REAPER_BORDER_LEFT=_load_cursor(417),REAPER_BORDER_RIGHT=_load_cursor(418),REAPER_BORDER_TOP=_load_cursor(419),REAPER_BORDER_BOTTOM=_load_cursor(421),REAPER_BORDER_LEFTRIGHT=_load_cursor(450),REAPER_VERTICAL_LEFTRIGHT=_load_cursor(462),REAPER_GRID_RIGHT=_load_cursor(460),REAPER_GRID_LEFT=_load_cursor(461),REAPER_HAND_SCROLL=_load_cursor(429),REAPER_FIST_LEFT=_load_cursor(430),REAPER_FIST_RIGHT=_load_cursor(431),REAPER_FIST_BOTH=_load_cursor(453),REAPER_PENCIL=_load_cursor(185),REAPER_PENCIL_DRAW=_load_cursor(433),REAPER_ERASER=_load_cursor(472),REAPER_BRUSH=_load_cursor(473),REAPER_ARP=_load_cursor(502),REAPER_CHORD=_load_cursor(503),REAPER_TOUCHSEL=_load_cursor(515),REAPER_SWEEP=_load_cursor(517),REAPER_FADEIN_CURVE_ALT=_load_cursor(525),REAPER_FADEOUT_CURVE_ALT=_load_cursor(526),REAPER_XFADE_WIDTH=_load_cursor(528),REAPER_XFADE_CURVE=_load_cursor(529),REAPER_EXTMIX_SECTION_RESIZE=_load_cursor(530),REAPER_EXTMIX_MULTI_RESIZE=_load_cursor(531),REAPER_EXTMIX_MULTISECTION_RESIZE=_load_cursor(532),REAPER_EXTMIX_RESIZE=_load_cursor(533),REAPER_EXTMIX_ALLSECTION_RESIZE=_load_cursor(534),REAPER_EXTMIX_ALL_RESIZE=_load_cursor(535),REAPER_ZOOM=_load_cursor(1009),REAPER_INSERT_ROW=_load_cursor(1010),REAPER_RAZOR=_load_cursor(599),REAPER_RAZOR_MOVE=_load_cursor(600),REAPER_RAZOR_ADD=_load_cursor(601),REAPER_RAZOR_ENVELOPE_VERTICAL=_load_cursor(202),REAPER_RAZOR_ENVELOPE_RIGHT_TILT=_load_cursor(203),REAPER_RAZOR_ENVELOPE_LEFT_TILT=_load_cursor(204),}local FONT_FLAG_BOLD=string.byte('b')local FONT_FLAG_ITALICS=string.byte('i') << 8
local FONT_FLAG_UNDERLINE=string.byte('u') << 16
rtk.font={BOLD=FONT_FLAG_BOLD,ITALICS=FONT_FLAG_ITALICS,UNDERLINE=FONT_FLAG_UNDERLINE,multiplier=1.0
}rtk.keycodes={UP=30064,DOWN=1685026670,LEFT=1818584692,RIGHT=1919379572,RETURN=13,ENTER=13,SPACE=32,BACKSPACE=8,ESCAPE=27,TAB=9,HOME=1752132965,END=6647396,INSERT=6909555,DELETE=6579564,F1=26161,F2=26162,F3=26163,F4=26164,F5=26165,F6=26166,F7=26167,F8=26168,F9=26169,F10=6697264,F11=6697265,F12=6697266,}rtk.themes={dark={name='dark',dark=true,light=false,bg='#252525',default_font={'Calibri', 18},tooltip_font={'Segoe UI (TrueType)', 16},tooltip_bg='#ffffff',tooltip_text='#000000',accent='#47abff',accent_subtle='#306088',text='#ffffff',text_faded='#bbbbbb',button='#555555',heading=nil,button_label='#ffffff',button_font=nil,button_gradient_mul=1,button_tag_alpha=0.32,button_normal_gradient=-0.37,button_normal_border_mul=0.7,button_hover_gradient=0.17,button_hover_brightness=0.9,button_hover_mul=1,button_hover_border_mul=1.1,button_clicked_gradient=0.47,button_clicked_brightness=0.9,button_clicked_mul=0.85,button_clicked_border_mul=1,text_font=nil,heading_font={'Calibri', 26},entry_font=nil,entry_bg='#5f5f5f7f',entry_placeholder='#ffffff7f',entry_border_hover='#3a508e',entry_border_focused='#4960b8',entry_selection_bg='#0066bb',popup_bg=nil,popup_bg_brightness=1.5,popup_shadow='#11111166',popup_border='#385074',slider_font=nil,slider='#2196f3',slider_track='#5a5a5a',slider_tick_label=nil,},light={name='light',light=true,dark=false,accent='#47abff',accent_subtle='#a1d3fc',bg='#dddddd',default_font={'Calibri', 18},tooltip_font={'Segoe UI (TrueType)', 16},tooltip_bg='#ffffff',tooltip_text='#000000',button='#dedede',button_label='#000000',button_gradient_mul=1,button_tag_alpha=0.15,button_normal_gradient=-0.28,button_normal_border_mul=0.85,button_hover_gradient=0.12,button_hover_brightness=1,button_hover_mul=1,button_hover_border_mul=0.9,button_clicked_gradient=0.3,button_clicked_brightness=1.0,button_clicked_mul=0.9,button_clicked_border_mul=0.7,text='#000000',text_faded='#555555',heading_font={'Calibri', 26},entry_border_hover='#3a508e',entry_border_focused='#4960b8',entry_bg='#00000020',entry_placeholder='#0000007f',entry_selection_bg='#9fcef4',popup_bg=nil,popup_bg_brightness=1.5,popup_shadow='#11111122',popup_border='#385074',slider='#2196f3',slider_track='#5a5a5a',}}local function _postprocess_theme()local iconstyle=rtk.color.get_icon_style(rtk.theme.bg)rtk.theme.iconstyle=iconstyle
for k,v in pairs(rtk.theme)do
if type(v) == 'string' and v:byte(1) == 35 then
local x={rtk.color.rgba(v)}rtk.theme[k]={rtk.color.rgba(v)}end
end
end
function rtk.add_image_search_path(path,iconstyle)if not path:match('^%a:') and not path:match('^[\\/]') then
path=rtk.script_path..path
end
if iconstyle then
assert(iconstyle == 'dark' or iconstyle == 'light', 'iconstyle must be either light or dark')local paths=rtk._image_paths[iconstyle] or {}paths[#paths+1]=path
rtk._image_paths[iconstyle]=paths
else
rtk._image_paths[#rtk._image_paths+1]=path
end
end
function rtk.set_theme(name,overrides)name=name or rtk.theme.name
assert(rtk.themes[name], 'rtk: theme "' .. name .. '" does not exist in rtk.themes')rtk.theme={}table.merge(rtk.theme,rtk.themes[name])if overrides then
table.merge(rtk.theme,overrides)end
_postprocess_theme()end
function rtk.set_theme_by_bgcolor(color,overrides)local name=rtk.color.luma(color) > rtk.light_luma_threshold and 'light' or 'dark'overrides=overrides or {}overrides.bg=color
rtk.set_theme(name,overrides)end
function rtk.set_theme_overrides(overrides)for _, name in ipairs({'dark', 'light'}) do
if overrides[name] then
rtk.themes[name]=table.merge(rtk.themes[name],overrides[name])if rtk.theme[name] then
rtk.theme=table.merge(rtk.theme,overrides[name])end
overrides[name]=nil
end
end
rtk.themes.dark=table.merge(rtk.themes.dark,overrides)rtk.themes.light=table.merge(rtk.themes.light,overrides)rtk.theme=table.merge(rtk.theme,overrides)_postprocess_theme()end
function rtk.new_theme(name,base,overrides)assert(not base or rtk.themes[base], string.format('base theme %s not found', base))assert(not rtk.themes[name], string.format('theme %s already exists', name))local theme=base and table.shallow_copy(rtk.themes[base])or {}rtk.themes[name]=table.merge(theme,overrides or {})end
function rtk.add_modal(...)if rtk._modal==nil then
rtk._modal={}end
local widgets={...}for _,widget in ipairs(widgets)do
rtk._modal[widget.id]=widget
end
end
function rtk.is_modal(widget)if widget==nil then
return rtk._modal~=nil
elseif rtk._modal then
local w=widget
while w do
if rtk._modal[w.id]~=nil then
return true
end
w=w.parent
end
end
return false
end
function rtk.reset_modal()rtk._modal=nil
end
function rtk.pushdest(dest)rtk._dest_stack[#rtk._dest_stack+1]=gfx.dest
gfx.dest=dest
end
function rtk.popdest(expect)gfx.dest=table.remove(rtk._dest_stack,#rtk._dest_stack)end
local function _handle_error(err)rtk._last_error=err
rtk._last_traceback=debug.traceback()end
function rtk.onerror(err,traceback)log.error("fatal: %s\n%s", err, traceback)log.flush()error(err)end
function rtk.call(func,...)if rtk._quit then
return
end
local ok,result=xpcall(func,_handle_error,...)if not ok then
rtk.onerror(rtk._last_error,rtk._last_traceback)return
end
return result
end
function rtk.defer(func,...)if rtk._quit then
return
end
local args=table.pack(...)reaper.defer(function()rtk.call(func,table.unpack(args,1,args.n))end)end
function rtk.callsoon(func,...)if not rtk.window or not rtk.window.running then
return rtk.defer(func,...)end
local funcs=rtk._soon_funcs
if not funcs then
funcs={}rtk._soon_funcs=funcs
end
funcs[#funcs+1]={func,table.pack(...)}end
function rtk._run_soon()local funcs=rtk._soon_funcs
rtk._soon_funcs=nil
for i=1,#funcs do
local func,args=table.unpack(funcs[i])func(table.unpack(args,1,args.n))end
end
function rtk.callafter(duration,func,...)local args=table.pack(...)local start=reaper.time_precise()local function sched()if reaper.time_precise()-start>=duration then
rtk.call(func,table.unpack(args,1,args.n))elseif not rtk._quit then
reaper.defer(sched)end
end
sched()end
function rtk.quit()if rtk.window and rtk.window.running then
rtk.window:close()end
rtk._quit=true
end
rtk.version={_DEFAULT_API=1,string=nil,api=nil,major=nil,minor=nil,patch=nil,}function rtk.version.parse()local ver=__RTK_VERSION or string.format('%s.99.99', rtk.version._DEFAULT_API)local parts=ver:split('.')rtk.version.major=tonumber(parts[1])rtk.version.minor=tonumber(parts[2])rtk.version.patch=tonumber(parts[3])rtk.version.api=rtk.version.major
rtk.version.string=ver
end
function rtk.version.check(major,minor,patch)local v=rtk.version
return v.major>major or
(v.major==major and(not minor or v.minor>minor))or
(v.major==major and v.minor==minor and(not patch or v.patch>=patch))end
return rtk
end)()

local rtk=__mod_rtk_core
__mod_rtk_type=(function()
local rtk=__mod_rtk_core
__mod_rtk_middleclass=(function()
local middleclass={_VERSION='middleclass v4.1.1',}local function _createIndexWrapper(aClass,f)if f==nil then
return aClass.__instanceDict
else
return function(self,name)local value=aClass.__instanceDict[name]
if value~=nil then
return value
elseif type(f)=="function" then
return(f(self,name))else
return f[name]
end
end
end
end
local function _propagateInstanceMethod(aClass,name,f)f=name=="__index" and _createIndexWrapper(aClass, f) or f
aClass.__instanceDict[name]=f
for subclass in pairs(aClass.subclasses)do
if rawget(subclass.__declaredMethods,name)==nil then
_propagateInstanceMethod(subclass,name,f)end
end
end
local function _declareInstanceMethod(aClass,name,f)aClass.__declaredMethods[name]=f
if f==nil and aClass.super then
f=aClass.super.__instanceDict[name]
end
_propagateInstanceMethod(aClass,name,f)end
local function _tostring(self) return "class " .. self.name end
local function _call(self,...)return self:new(...)end
local function _createClass(name,super)local dict={}dict.__index=dict
local aClass={ name=name,super=super,static={},__instanceDict=dict,__declaredMethods={},subclasses=setmetatable({}, {__mode='k'})  }if super then
setmetatable(aClass.static,{__index=function(_,k)local result=rawget(dict,k)if result==nil then
return super.static[k]
end
return result
end
})else
setmetatable(aClass.static,{ __index=function(_,k)return rawget(dict,k)end })end
setmetatable(aClass,{ __index=aClass.static,__tostring=_tostring,__call=_call,__newindex=_declareInstanceMethod })return aClass
end
local function _includeMixin(aClass,mixin)assert(type(mixin)=='table', "mixin must be a table")for name,method in pairs(mixin)do
if name ~= "included" and name ~= "static" then aClass[name] = method end
end
for name,method in pairs(mixin.static or {})do
aClass.static[name]=method
end
if type(mixin.included)=="function" then mixin:included(aClass) end
return aClass
end
local DefaultMixin={__tostring=function(self) return "instance of " .. tostring(self.class) end,__gc=function(self)if type(self) == 'table' and type(self.class) == 'table' and type(self.class.finalize) == 'function' then
self:finalize()end
end,initialize=function(self,...)end,isInstanceOf=function(self,aClass)return type(aClass)=='table'and type(self)=='table'and(self.class==aClass
or type(self.class)=='table'and type(self.class.isSubclassOf)=='function'and self.class:isSubclassOf(aClass))end,static={allocate=function(self)assert(type(self)=='table', "Make sure that you are using 'Class:allocate' instead of 'Class.allocate'")local instance=setmetatable({ class=self },self.__instanceDict)if instance.__allocate then
instance:__allocate()end
return instance
end,new=function(self,...)assert(type(self)=='table', "Make sure that you are using 'Class:new' instead of 'Class.new'")local instance=self:allocate()instance:initialize(...)return instance
end,subclass=function(self,name)assert(type(self)=='table', "Make sure that you are using 'Class:subclass' instead of 'Class.subclass'")assert(type(name)=="string", "You must provide a name(string) for your class")local subclass=_createClass(name,self)for methodName,f in pairs(self.__instanceDict)do
_propagateInstanceMethod(subclass,methodName,f)end
subclass.initialize=function(instance,...)return self.initialize(instance,...)end
self.subclasses[subclass]=true
self:subclassed(subclass)return subclass
end,subclassed=function(self,other)end,isSubclassOf=function(self,other)return type(other)=='table' and
type(self.super)=='table' and
(self.super==other or self.super:isSubclassOf(other))end,include=function(self,...)assert(type(self)=='table', "Make sure you that you are using 'Class:include' instead of 'Class.include'")for _,mixin in ipairs({...})do _includeMixin(self,mixin)end
return self
end
}}function middleclass.class(name,super)assert(type(name)=='string', "A name (string) is needed for the new class")return super and super:subclass(name)or _includeMixin(_createClass(name),DefaultMixin)end
setmetatable(middleclass,{ __call=function(_,...)return middleclass.class(...)end })return middleclass
end)()

local class=__mod_rtk_middleclass
rtk.Attribute={FUNCTION={},NIL={},DEFAULT={},default=nil,type=nil,calculate=nil,priority=nil,reflow=nil,redraw=nil,replaces=nil,animate=nil,get=nil,set=nil,}setmetatable(rtk.Attribute,{__call=function(self,attrs)attrs._is_rtk_attr=true
return attrs
end
})local falsemap={[false]=true,[0]=true,['0']=true,['false']=true,['False']=true,['FALSE']=true
}local typemaps={number=function(v)local n=tonumber(v)if n then
return n
elseif v == 'true' or v == true then
return 1
elseif v == 'false' or v == false then
return 0
end
end,string=tostring,boolean=function(v)if falsemap[v] then
return false
elseif v then
return true
end
end,}function rtk.Reference(attr)return {_is_rtk_reference=true,attr=attr
}end
local function register(cls,attrs)local attributes=cls.static.attributes
if attributes and attributes.__class==cls.name then
elseif cls.super then
attributes={}for k,v in pairs(cls.super.static.attributes)do
if k ~= '__class' and k ~= 'get' then
attributes[k]=table.shallow_copy(v)end
end
else
attributes={defaults={}}end
local refs={}for attr,attrtable in pairs(attrs)do
assert(attr ~= 'id' and attr ~= 'get' and attr ~= 'defaults',"attempted to assign a reserved attribute")if type(attrtable)=='table' and attrtable._is_rtk_reference then
local srcattr=attrtable.attr
attrtable={}refs[#refs+1]={attrtable,nil,srcattr,attr}else
if type(attrtable) ~='table' or not attrtable._is_rtk_attr then
attrtable={default=attrtable}end
if attributes[attr] then
attrtable=table.merge(attributes[attr],attrtable)end
for field,v in pairs(attrtable)do
if type(v)=='table' and v._is_rtk_reference then
refs[#refs+1]={attrtable,field,v.attr,attr}end
end
local deftype=type(attrtable.default)if deftype=='function' then
attrtable.default_func=attrtable.default
attrtable.default=rtk.Attribute.FUNCTION
end
if (not attrtable.type and not attrtable.calculate) or type(attrtable.type)=='string' then
attrtable.type=typemaps[attrtable.type or deftype]
end
end
attributes[attr]=attrtable
attributes.defaults[attr]=attrtable.default
end
for _,ref in ipairs(refs)do
local attrtable,field,srcattr,dstattr=table.unpack(ref)local src=attributes[srcattr]
if not attributes.defaults[dstattr] and not field then
attributes.defaults[dstattr]=attributes.defaults[srcattr]
end
if field then
attrtable[field]=src[field]
else
for k,v in pairs(src)do
attrtable[k]=v
end
end
end
attributes.__class=cls.name
attributes.get=function(attr)return attributes[attr] or rtk.Attribute.NIL
end
cls.static.attributes=attributes
end
function rtk.class(name,super,attributes)local cls=class(name,super)cls.static.register=function(attrs)register(cls,attrs)end
if attributes then
register(cls,attributes)end
return cls
end
function rtk.isa(v,cls)if type(v)=='table' and v.isInstanceOf then
return v:isInstanceOf(cls)end
return false
end
end)()

__mod_rtk_utils=(function()
local rtk=__mod_rtk_core
rtk.file={}rtk.clipboard={}rtk.gfx={}UNDO_STATE_ALL=-1
UNDO_STATE_TRACKCFG=1
UNDO_STATE_FX=2
UNDO_STATE_ITEMS=4
UNDO_STATE_MISCCFG=8
UNDO_STATE_FREEZE=16
UNDO_STATE_TRACKENV=32
UNDO_STATE_FXENV=64
UNDO_STATE_POOLEDENVS=128
UNDO_STATE_FX_ARA=256
function rtk.check_reaper_version(major,minor,exact)local curmaj=rtk._reaper_version_major
local curmin=rtk._reaper_version_minor
minor=minor<100 and minor or minor/10
if exact then
return curmaj==major and curmin==minor
else
return(curmaj>major)or(curmaj==major and curmin>=minor)end
end
function rtk.clamp(value,min,max)if min and max then
return math.max(min,math.min(max,value))elseif min then
return math.max(min,value)elseif max then
return math.min(max,value)else
return value
end
end
function rtk.clamprel(value,min,max)min=min and min<1.0 and min*value or min
max=max and max<1.0 and max*value or max
if min and max then
return math.max(min,math.min(max,value))elseif min then
return math.max(min,value)elseif max then
return math.min(max,value)else
return value
end
end
function rtk.point_in_box(x,y,bx,by,bw,bh)return x>=bx and y>=by and x<=bx+bw and y<=by+bh
end
function rtk.point_in_circle(x,y,cirx,ciry,radius)local dx=x-cirx
local dy=y-ciry
return dx*dx+dy*dy<=radius*radius
end
function rtk.open_url(url)if rtk.os.windows then
reaper.ExecProcess(string.format('cmd.exe /C start /B "" "%s"', url), -2)elseif rtk.os.mac then
os.execute(string.format('open "%s"', url))elseif rtk.os.linux then
reaper.ExecProcess(string.format('xdg-open "%s"', url), -2)else
reaper.ShowMessageBox("Sorry, I don't know how to open URLs on this operating system.","Unsupported operating system", 0
)end
end
function rtk.uuid4()return reaper.genGuid():sub(2,-2):lower()end
function rtk.file.read(fname)local f,err=io.open(fname)if f then
local contents=f:read("*all")f:close()return contents,nil
else
return nil,err
end
end
function rtk.file.write(fname,contents)local f, err=io.open(fname, "w")if f then
f:write(contents)f:close()else
return err
end
end
function rtk.file.size(fname)local f,err=io.open(fname)if f then
local size=f:seek("end")f:close()return size,nil
else
return nil,err
end
end
function rtk.file.exists(fname)return reaper.file_exists(fname)end
function rtk.clipboard.get()if not reaper.CF_GetClipboardBig then
return
end
local fast=reaper.SNM_CreateFastString("")local data=reaper.CF_GetClipboardBig(fast)reaper.SNM_DeleteFastString(fast)return data
end
function rtk.clipboard.set(data)if not reaper.CF_SetClipboard then
return false
end
reaper.CF_SetClipboard(data)return true
end
function rtk.gfx.roundrect(x,y,w,h,r,thickness,aa)thickness=thickness or 1
aa=aa or 1
w=w-1
h=h-1
if thickness==1 then
gfx.roundrect(x,y,w,h,r,aa)elseif thickness>1 then
for i=0,thickness-1 do
gfx.roundrect(x+i,y+i,w-i*2,h-i*2,r,aa)end
elseif h>=2*r then
gfx.circle(x+r,y+r,r,1,aa)gfx.circle(x+w-r,y+r,r,1,aa)gfx.circle(x+r,y+h-r,r,1,aa)gfx.circle(x+w-r,y+h-r,r,1,aa)gfx.rect(x,y+r,r,h-r*2)gfx.rect(x+w-r,y+r,r+1,h-r*2)gfx.rect(x+r,y,w-r*2,h+1)else
r=h/2-1
gfx.circle(x+r,y+r,r,1,aa)gfx.circle(x+w-r,y+r,r,1,aa)gfx.rect(x+r,y,w-r*2,h)end
end
rtk.IndexManager=rtk.class('rtk.IndexManager')function rtk.IndexManager:initialize(first,last)self.first=first
self.last=last
self._last=last-first
self._bitmaps={}self._tail_idx=nil
self._last_idx=nil
end
function rtk.IndexManager:_set(idx,value)local elem=math.floor(idx/32)+1
local count=#self._bitmaps
if elem>count then
for n=1,elem-count do
self._bitmaps[#self._bitmaps+1]=0
end
end
local bit=idx%32
if value~=0 then
self._bitmaps[elem]=self._bitmaps[elem]|(1<<bit)else
self._bitmaps[elem]=self._bitmaps[elem]&~(1<<bit)end
end
function rtk.IndexManager:set(idx,value)return self:_set(idx-self.first,value)end
function rtk.IndexManager:_get(idx)local elem=math.floor(idx/32)+1
if elem>#self._bitmaps then
return false
end
local bit=idx%32
return self._bitmaps[elem]&(1<<bit)~=0
end
function rtk.IndexManager:get(idx)return self:_get(idx-self.first)end
function rtk.IndexManager:_search_free()local start=self._last_idx<self._last and self._last_idx or 0
local bit=start%32
local startelem=math.floor(start/32)+1
for elem=1,#self._bitmaps do
local bitmap=self._bitmaps[elem]
if bitmap~=0xffffffff then
for bit=bit,32 do
if bitmap&(1<<bit)==0 then
return elem,bit
end
end
end
bit=0
end
end
function rtk.IndexManager:_next()local idx
if not self._tail_idx then
idx=0
elseif self._tail_idx<self._last then
idx=self._tail_idx+1
else
local elem,bit=self:_search_free()if elem==#self._bitmaps and bit>=self._last%32 then
return nil
end
idx=(elem-1)*32+bit
end
self._last_idx=idx
self._tail_idx=self._tail_idx and math.max(self._tail_idx,idx)or idx
self:_set(idx,1)return idx+self.first
end
function rtk.IndexManager:next(gc)local idx=self:_next()if not idx and gc then
collectgarbage('collect')idx=self:_next()end
return idx
end
function rtk.IndexManager:release(idx)self:_set(idx-self.first,0)end
math.inf=1/0
function math.round(n)return n and(n%1>=0.5 and math.ceil(n)or math.floor(n))end
function string.startswith(s,prefix,insensitive)if insensitive==true then
return s:lower():sub(1,string.len(prefix))==prefix:lower()else
return s:sub(1,string.len(prefix))==prefix
end
end
function string.split(s,delim,filter)local parts={}for word in s:gmatch('[^' .. (delim or '%s') .. ']' .. (filter and '+' or '*')) do
parts[#parts+1]=word
end
return parts
end
function string.strip(s)return s:match('^%s*(.-)%s*$')end
function string.hash(s)local hash=5381
for i=1,#s do
hash=((hash<<5)+hash)+s:byte(i)end
return hash&0x7fffffffffffffff
end
local function val_to_str(v,seen)if "string" == type(v) then
v=string.gsub(v, "\n", "\\n")if string.match(string.gsub(v,"[^'\"]",""), '^"+$') then
return "'" .. v .. "'"end
return '"' .. string.gsub(v, '"', '\\"') .. '"'else
if type(v)=='table' and not v.__tostring then
return seen[tostring(v)] and '<recursed>' or table.tostring(v, seen)else
return tostring(v)end
return "table" == type(v) and table.tostring(v, seen) or tostring(v)end
end
local function key_to_str(k,seen)if "string" == type(k) and string.match(k, "^[_%a][_%a%d]*$") then
return k
else
return "[" .. val_to_str(k, seen) .. "]"end
end
local function _table_tostring(tbl,seen)local result,done={},{}seen=seen or {}local id=tostring(tbl)seen[id]=1
for k,v in ipairs(tbl)do
table.insert(result,val_to_str(v,seen))done[k]=true
end
for k,v in pairs(tbl)do
if not done[k] then
table.insert(result, key_to_str(k, seen) .. "=" .. val_to_str(v, seen))end
end
seen[id]=nil
return "{" .. table.concat( result, "," ) .. "}"end
function table.tostring(tbl)return _table_tostring(tbl)end
function table.fromstring(str)return load('return ' .. str)()end
function table.merge(dst,src)for k,v in pairs(src)do
dst[k]=v
end
return dst
end
function table.shallow_copy(t,merge)local copy={}for k,v in pairs(t)do
copy[k]=v
end
if merge then
table.merge(copy,merge)end
return copy
end
function table.keys(t)local keys={}for k,_ in pairs(t)do
keys[#keys+1]=k
end
return keys
end
function table.values(t)local values={}for _,v in pairs(t)do
values[#values+1]=v
end
return values
end
end)()

__mod_rtk_future=(function()
local rtk=__mod_rtk_core
rtk.Future=rtk.class('rtk.Future')rtk.Future.static.PENDING=false
rtk.Future.static.DONE=true
rtk.Future.static.CANCELLED=0
function rtk.Future:initialize()self.state=rtk.Future.PENDING
self.result=nil
self.cancellable=false
end
function rtk.Future:after(func)if not self._after then
self._after={func}else
self._after[#self._after+1]=func
end
self:_check_defer_resolved_callbacks(rtk.Future.DONE)return self
end
function rtk.Future:done(func)if not self._done then
self._done={func}else
self._done[#self._done+1]=func
end
self:_check_defer_resolved_callbacks(rtk.Future.DONE)return self
end
function rtk.Future:cancelled(func)self.cancellable=true
if self.state==rtk.Future.CANCELLED then
func(self.result)elseif not self._cancelled then
self._cancelled={func}else
self._cancelled[#self._cancelled+1]=func
end
return self
end
function rtk.Future:cancel(v)assert(self._cancelled, 'Future is not cancelleable')assert(self.state==rtk.Future.PENDING, 'Future has already been resolved or cancelled')self.state=rtk.Future.CANCELLED
self.result=v
for i=1,#self._cancelled do
self._cancelled[i](v)end
self._cancelled=nil
return self
end
function rtk.Future:_resolve(value)self.result=value
self:_invoke_resolved_callbacks(value)end
function rtk.Future:_check_defer_resolved_callbacks(state,value)if self.state==state and not self._deferred then
self._deferred=true
rtk.defer(rtk.Future._invoke_resolved_callbacks,self,value or self.value)end
end
function rtk.Future:_invoke_resolved_callbacks(value)self._deferred=false
self.result=value
local nextval=value
if self._after then
while #self._after>0 do
local func=table.remove(self._after,1)nextval=func(nextval)or nextval
if rtk.isa(nextval,rtk.Future)then
nextval:done(function(v)self:_resolve(v)end)self:cancelled(function(v)nextval:cancel(v)end)return
end
end
end
self.state=rtk.Future.DONE
if self._done and(not self._after or #self._after==0)then
for i=1,#self._done do
self._done[i](nextval)end
end
self._done=nil
self._after=nil
return self
end
function rtk.Future:resolve(value)assert(self.state==rtk.Future.PENDING, 'Future has already been resolved or cancelled')if not self._after and not self._done and not self._deferred then
self._deferred=true
rtk.defer(self._resolve,self,value,true)else
self:_resolve(value)end
return self
end
end)()

__mod_rtk_animate=(function()
local rtk=__mod_rtk_core
local log=__mod_rtk_log
local c1=1.70158
local c2=c1*1.525
local c3=c1+1
local c4=(2*math.pi)/3
local c5=(2*math.pi)/4.5
local n1=7.5625
local d1=2.75
rtk.easing={['linear'] = function(x)return x
end,['in-sine'] = function(x)return 1-math.cos((x*math.pi)/2)end,['out-sine'] = function(x)return math.sin((x*math.pi)/2)end,['in-out-sine'] = function(x)return-(math.cos(math.pi*x)-1)/2
end,['in-quad'] = function(x)return x*x
end,['out-quad'] = function(x)return 1-(1-x)*(1-x)end,['in-out-quad'] = function(x)return(x<0.5)and(2*x*x)or(1-(-2*x+2)^2/2)end,['in-cubic'] = function(x)return x*x*x
end,['out-cubic'] = function(x)return 1-(1-x)^4
end,['in-out-cubic'] = function(x)return(x<0.5)and(4*x*x*x)or(1-(-2*x+2)^3/2)end,['in-quart'] = function(x)return x*x*x*x
end,['out-quart'] = function(x)return 1-(1-x)^4
end,['in-out-quart'] = function(x)return(x<0.5)and(8*x*x*x*x)or(1-(-2*x+2)^4/2)end,['in-quint'] = function(x)return x*x*x*x*x
end,['out-quint'] = function(x)return 1-(1-x)^5
end,['in-out-quint'] = function(x)return(x<0.5)and(16*x*x*x*x*x)or(1-(-2*x+2)^5/2)end,['in-expo'] = function(x)return(x==0)and 0 or 2^(10*x-10)end,['out-expo'] = function(x)return(x==1)and 1 or(1-2^(-10*x))end,['in-out-expo'] = function(x)return(x==0)and 0 or
(x==1)and 1 or
(x<0.5)and 2^(20*x-10)/2 or(2-2^(-20*x+10))/2
end,['in-circ'] = function(x)return 1-math.sqrt(1-x^2)end,['out-circ'] = function(x)return math.sqrt(1-(x-1)^2)end,['in-out-circ'] = function(x)return(x<0.5)and(1-math.sqrt(1-(2*x)^2))/2 or(math.sqrt(1-(-2*x+2)^2)+1)/2
end,['in-back'] = function(x)return c3*x*x*x-c1*x*x
end,['out-back'] = function(x)return 1+(c3*(x-1)^3)+(c1*(x-1)^2)end,['in-out-back'] = function(x)return(x<0.5)and
((2*x)^2*((c2+1)*2*x-c2))/2 or
((2*x-2)^2*((c2+1)*(x*2-2)+c2)+2)/2
end,['in-elastic'] = function(x)return(x==0)and 0 or
(x==1)and 1 or
-2^(10*x-10)*math.sin((x*10-10.75)*c4)end,['out-elastic'] = function(x)return(x==0)and 0 or
(x==1)and 1 or
2^(-10*x)*math.sin((x*10-0.75)*c4)+1
end,['in-out-elastic'] = function(x)return(x==0)and 0 or
(x==1)and 1 or
(x<0.5)and-(2^(20*x-10)*math.sin((20*x-11.125)*c5))/2 or
(2^(-20*x+10)*math.sin((20*x-11.125)*c5))/2+1
end,['in-bounce'] = function(x)return 1 - rtk.easing['out-bounce'](1 - x)end,['out-bounce'] = function(x)if x<1/d1 then
return n1*x*x
elseif x<(2/d1)then
x=x-1.5/d1
return n1*x*x+0.75
elseif x<(2.5/d1)then
x=x-2.25/d1
return n1*x*x+0.9375
else
x=x-2.625/d1
return n1*x*x+0.984375
end
end,['in-out-bounce'] = function(x)return(x<0.5)and
(1 - rtk.easing['out-bounce'](1 - 2 * x)) / 2 or
(1 + rtk.easing['out-bounce'](2 * x - 1)) / 2
end,}local function _resolve(x,src,dst)return src+x*(dst-src)end
local _table_stepfuncs={[1]=function(widget,anim)local x=anim.easingfunc(anim.pct)return {_resolve(x,anim.src[1],anim.dst[1])}end,[2]=function(widget,anim)local x=anim.easingfunc(anim.pct)local src,dst=anim.src,anim.dst
local f1=_resolve(x,src[1],dst[1])local f2=_resolve(x,src[2],dst[2])return {f1,f2}end,[3]=function(widget,anim)local x=anim.easingfunc(anim.pct)local src,dst=anim.src,anim.dst
local f1=_resolve(x,src[1],dst[1])local f2=_resolve(x,src[2],dst[2])local f3=_resolve(x,src[3],dst[3])return {f1,f2,f3}end,[4]=function(widget,anim)local x=anim.easingfunc(anim.pct)local src,dst=anim.src,anim.dst
local f1=_resolve(x,src[1],dst[1])local f2=_resolve(x,src[2],dst[2])local f3=_resolve(x,src[3],dst[3])local f4=_resolve(x,src[4],dst[4])return {f1,f2,f3,f4}end,any=function(widget,anim)local x=anim.easingfunc(anim.pct)local src,dst=anim.src,anim.dst
local result={}for i=1,#src do
result[i]=_resolve(x,src[i],dst[i])end
return result
end
}function rtk._do_animations(now)if not rtk._frame_times then
rtk._frame_times={now}else
local times=rtk._frame_times
local c=#times
times[c+1]=now
if c>30 then
table.remove(times,1)end
rtk.fps=c/(times[c]-times[1])end
if rtk._animations_len>0 then
local donefuncs=nil
local done=nil
for key,anim in pairs(rtk._animations)do
local widget=anim.widget
local target=anim.target or anim.widget
local attr=anim.attr
local finished=anim.pct>=1.0
local elapsed=now-anim._start_time
local newval
if anim.stepfunc then
newval=anim.stepfunc(target,anim)else
newval=anim.resolve(anim.easingfunc(anim.pct))end
anim.frames=anim.frames+1
if not finished and elapsed>anim.duration*1.5 then
log.warning('animation: %s %s - failed to complete within 1.5x of duration (fps: current=%s expected=%s)',target,attr,rtk.fps,anim.startfps)finished=true
end
if anim.update then
anim.update(finished and anim.doneval or newval,target,attr,anim)end
if widget then
if not finished then
local value=anim.calculate and anim.calculate(widget,attr,newval,widget.calc)or newval
widget.calc[attr]=value
if anim.sync_surface_value then
widget[attr]=value
end
else
widget:attr(attr,anim.doneval)end
local reflow=anim.reflow or(anim.attrmeta and anim.attrmeta.reflow)or rtk.Widget.REFLOW_PARTIAL
if reflow and reflow~=rtk.Widget.REFLOW_NONE then
widget:queue_reflow(reflow)end
if anim.attrmeta and anim.attrmeta.window_sync then
widget._sync_window_attrs_on_update=true
end
end
if finished then
rtk._animations[key]=nil
rtk._animations_len=rtk._animations_len-1
if not done then
done={}end
done[#done+1]=anim
else
anim.pct=anim.pct+anim.pctstep
end
end
if done then
for _,anim in ipairs(done)do
anim.future:resolve(anim.widget or anim.target)local took=reaper.time_precise()-anim._start_time
local missed=took-anim.duration
log.log(math.abs(missed)>0.05 and log.DEBUG or log.DEBUG2,'animation: done %s: %s -> %s on %s frames=%s current-fps=%s expected-fps=%s took=%.1f (missed by %.3f)',anim.attr,anim.src,anim.dst,anim.target or anim.widget,anim.frames,rtk.fps,anim.startfps,took,missed
)end
end
return true
end
end
local function _is_equal(a,b)local ta=type(a)if ta~=type(b)then
return false
elseif ta=='table' then
if #a~=#b then
return false
end
for i=1,#a do
if a[i]~=b[i] then
return false
end
end
return true
end
return a==b
end
function rtk.queue_animation(kwargs)assert(kwargs and kwargs.key, 'animation table missing key field')local future=rtk.Future()local key=kwargs.key
local anim=rtk._animations[key]
if anim then
if _is_equal(anim.dst,kwargs.dst)then
return anim.future
else
anim.future:cancel()end
end
if _is_equal(kwargs.src,kwargs.dst)then
future:resolve()return future
end
future:cancelled(function()rtk._animations[key]=nil
rtk._animations_len=rtk._animations_len-1
end)local duration=kwargs.duration or 0.5
local easingfunc=rtk.easing[kwargs.easing or 'linear']
assert(type(easingfunc)=='function', string.format('unknown easing function: %s', kwargs.easing))if not kwargs.stepfunc then
local tp=type(kwargs.src or 0)if tp=='table' then
local sz=#kwargs.src
for i=1,sz do
assert(type(kwargs.src[i])=='number', 'animation src value table must not have non-numeric elements')end
kwargs.stepfunc=_table_stepfuncs[sz]
if not kwargs.stepfunc then
kwargs.stepfunc=_table_stepfuncs.any
end
else
assert(tp=='number', string.format('animation src value %s is invalid', kwargs.src))end
end
if not rtk._animations[kwargs.key] then
rtk._animations_len=rtk._animations_len+1
end
local step=1.0/(rtk.fps*duration)anim=table.shallow_copy(kwargs,{easingfunc=easingfunc,src=kwargs.src or(not kwargs.stepfunc and 0 or nil),dst=kwargs.dst or 0,doneval=kwargs.doneval or kwargs.dst,pct=step,pctstep=step,duration=duration,future=future,frames=0,startfps=rtk.fps,_start_time=reaper.time_precise()})anim.resolve=function(x)return _resolve(x,anim.src,anim.dst)end
rtk._animations[kwargs.key]=anim
log.debug2('animation: scheduled %s', kwargs.key)return future
end
end)()

__mod_rtk_color=(function()
local rtk=__mod_rtk_core
local log=__mod_rtk_log
rtk.color={}function rtk.color.set(color,amul)local r,g,b,a=rtk.color.rgba(color)if amul then
a=a*amul
end
gfx.set(r,g,b,a)end
function rtk.color.rgba(color)local tp=type(color)if tp=='table' then
local r,g,b,a=table.unpack(color)return r,g,b,a or 1
elseif tp=='string' then
local hash=color:find('#')if hash==1 then
return rtk.color.hex2rgba(color)else
local a=1
if hash then
a=(tonumber(color:sub(hash+1),16)or 0)/255
color=color:sub(1,hash-1)end
local resolved=rtk.color.names[color:lower()]
if not resolved then
log.warning('rtk: color "%s" is invalid, defaulting to black', color)return 0,0,0,a
end
local r,g,b,_=rtk.color.hex2rgba(resolved)return r,g,b,a
end
elseif tp=='number' then
local r,g,b=color&0xff,(color>>8)&0xff,(color>>16)&0xff
return r/255,g/255,b/255,1
else
error('invalid type ' .. tp .. ' passed to rtk.color.rgba()')end
end
function rtk.color.luma(color,under)local r,g,b,a=rtk.color.rgba(color)local luma=(0.2126*r+0.7152*g+0.0722*b)if a<1.0 and under then
luma=math.abs((luma*a)+rtk.color.luma(under)*(1-a))end
return luma
end
function rtk.color.hsv(color)local r,g,b,a=rtk.color.rgba(color)local h,s,v
local max=math.max(r,g,b)local min=math.min(r,g,b)local delta=max-min
if delta==0 then
h=0
elseif max==r then
h=60*(((g-b)/delta)%6)elseif max==g then
h=60*(((b-r)/delta)+2)elseif max==b then
h=60*(((r-g)/delta)+4)end
s=(max==0)and 0 or(delta/max)v=max
return h/360.0,s,v,a
end
function rtk.color.hsl(color)local r,g,b,a=rtk.color.rgba(color)local h,s,l
local max=math.max(r,g,b)local min=math.min(r,g,b)l=(max+min)/2
if max==min then
h=0
s=0
else
local delta=max-min
if l>0.5 then
s=delta/(2-max-min)else
s=delta/(max+min)end
if max==r then
h=(g-b)/delta+(g<b and 6 or 0)elseif max==g then
h=(b-r)/delta+2
else
h=(r-g)/delta+4
end
h=h/6
end
return h,s,l,a
end
function rtk.color.int(color,native)local r,g,b,_=rtk.color.rgba(color)local n=(r*255)+((g*255)<<8)+((b*255)<<16)return native and rtk.color.convert_native(n)or n
end
function rtk.color.mod(color,hmul,smul,vmul,amul)local h,s,v,a=rtk.color.hsv(color)return rtk.color.hsv2rgb(rtk.clamp(h*(hmul or 1),0,1),rtk.clamp(s*(smul or 1),0,1),rtk.clamp(v*(vmul or 1),0,1),rtk.clamp(a*(amul or 1),0,1))end
function rtk.color.convert_native(n)if rtk.os.mac or rtk.os.linux then
return rtk.color.flip_byte_order(n)else
return n
end
end
function rtk.color.flip_byte_order(color)return((color&0xff)<<16)|(color&0xff00)|((color>>16)&0xff)end
function rtk.color.get_reaper_theme_bg()if reaper.GetThemeColor then
local r=reaper.GetThemeColor('col_tracklistbg', 0)if r~=-1 then
return rtk.color.int2hex(r)end
end
if reaper.GSC_mainwnd then
local idx=(rtk.os.mac or rtk.os.linux)and 5 or 20
return rtk.color.int2hex(reaper.GSC_mainwnd(idx))end
end
function rtk.color.get_icon_style(color,under)return rtk.color.luma(color, under) > rtk.light_luma_threshold and 'dark' or 'light'end
function rtk.color.hex2rgba(s)local r=tonumber(s:sub(2,3),16)or 0
local g=tonumber(s:sub(4,5),16)or 0
local b=tonumber(s:sub(6,7),16)or 0
local a=tonumber(s:sub(8,9),16)return r/255,g/255,b/255,a and a/255 or 1.0
end
function rtk.color.rgba2hex(r,g,b,a)r=math.ceil(r*255)b=math.ceil(b*255)g=math.ceil(g*255)if not a or a==1.0 then
return string.format('#%02x%02x%02x', r, g, b)else
return string.format('#%02x%02x%02x%02x', r, g, b, math.ceil(a * 255))end
end
function rtk.color.int2hex(n,native)if native then
n=rtk.color.convert_native(n)end
local r,g,b=n&0xff,(n>>8)&0xff,(n>>16)&0xff
return string.format('#%02x%02x%02x', r, g, b)end
function rtk.color.hsv2rgb(h,s,v,a)if s==0 then
return v,v,v,a or 1.0
end
local i=math.floor(h*6)local f=(h*6)-i
local p=v*(1-s)local q=v*(1-s*f)local t=v*(1-s*(1-f))if i==0 or i==6 then
return v,t,p,a or 1.0
elseif i==1 then
return q,v,p,a or 1.0
elseif i==2 then
return p,v,t,a or 1.0
elseif i==3 then
return p,q,v,a or 1.0
elseif i==4 then
return t,p,v,a or 1.0
elseif i==5 then
return v,p,q,a or 1.0
else
log.error('invalid hsv (%s %s %s) i=%s', h, s, v, i)end
end
local function hue2rgb(p,q,t)if t<0 then
t=t+1
elseif t>1 then
t=t-1
end
if t<1/6 then
return p+(q-p)*6*t
elseif t<1/2 then
return q
elseif t<2/3 then
return p+(q-p)*(2/3-t)*6
else
return p
end
end
function rtk.color.hsl2rgb(h,s,l,a)local r,g,b
if s==0 then
r,g,b=l,l,l
else
local q=(l<0.5)and(l*(1+s))or(l+s-l*s)local p=2*l-q
r=hue2rgb(p,q,h+1/3)g=hue2rgb(p,q,h)b=hue2rgb(p,q,h-1/3)end
return r,g,b,a or 1.0
end
rtk.color.names={black='#000000',silver='#c0c0c0',gray='#808080',white='#ffffff',maroon='#800000',red='#ff0000',purple='#800080',fuchsia='#ff00ff',green='#008000',lime='#00ff00',olive='#808000',yellow='#ffff00',navy='#000080',blue='#0000ff',teal='#008080',aqua='#00ffff',orange='#ffa500',aliceblue='#f0f8ff',antiquewhite='#faebd7',aquamarine='#7fffd4',azure='#f0ffff',beige='#f5f5dc',bisque='#ffe4c4',blanchedalmond='#ffebcd',blueviolet='#8a2be2',brown='#a52a2a',burlywood='#deb887',cadetblue='#5f9ea0',chartreuse='#7fff00',chocolate='#d2691e',coral='#ff7f50',cornflowerblue='#6495ed',cornsilk='#fff8dc',crimson='#dc143c',cyan='#00ffff',darkblue='#00008b',darkcyan='#008b8b',darkgoldenrod='#b8860b',darkgray='#a9a9a9',darkgreen='#006400',darkgrey='#a9a9a9',darkkhaki='#bdb76b',darkmagenta='#8b008b',darkolivegreen='#556b2f',darkorange='#ff8c00',darkorchid='#9932cc',darkred='#8b0000',darksalmon='#e9967a',darkseagreen='#8fbc8f',darkslateblue='#483d8b',darkslategray='#2f4f4f',darkslategrey='#2f4f4f',darkturquoise='#00ced1',darkviolet='#9400d3',deeppink='#ff1493',deepskyblue='#00bfff',dimgray='#696969',dimgrey='#696969',dodgerblue='#1e90ff',firebrick='#b22222',floralwhite='#fffaf0',forestgreen='#228b22',gainsboro='#dcdcdc',ghostwhite='#f8f8ff',gold='#ffd700',goldenrod='#daa520',greenyellow='#adff2f',grey='#808080',honeydew='#f0fff0',hotpink='#ff69b4',indianred='#cd5c5c',indigo='#4b0082',ivory='#fffff0',khaki='#f0e68c',lavender='#e6e6fa',lavenderblush='#fff0f5',lawngreen='#7cfc00',lemonchiffon='#fffacd',lightblue='#add8e6',lightcoral='#f08080',lightcyan='#e0ffff',lightgoldenrodyellow='#fafad2',lightgray='#d3d3d3',lightgreen='#90ee90',lightgrey='#d3d3d3',lightpink='#ffb6c1',lightsalmon='#ffa07a',lightseagreen='#20b2aa',lightskyblue='#87cefa',lightslategray='#778899',lightslategrey='#778899',lightsteelblue='#b0c4de',lightyellow='#ffffe0',limegreen='#32cd32',linen='#faf0e6',magenta='#ff00ff',mediumaquamarine='#66cdaa',mediumblue='#0000cd',mediumorchid='#ba55d3',mediumpurple='#9370db',mediumseagreen='#3cb371',mediumslateblue='#7b68ee',mediumspringgreen='#00fa9a',mediumturquoise='#48d1cc',mediumvioletred='#c71585',midnightblue='#191970',mintcream='#f5fffa',mistyrose='#ffe4e1',moccasin='#ffe4b5',navajowhite='#ffdead',oldlace='#fdf5e6',olivedrab='#6b8e23',orangered='#ff4500',orchid='#da70d6',palegoldenrod='#eee8aa',palegreen='#98fb98',paleturquoise='#afeeee',palevioletred='#db7093',papayawhip='#ffefd5',peachpuff='#ffdab9',peru='#cd853f',pink='#ffc0cb',plum='#dda0dd',powderblue='#b0e0e6',rosybrown='#bc8f8f',royalblue='#4169e1',saddlebrown='#8b4513',salmon='#fa8072',sandybrown='#f4a460',seagreen='#2e8b57',seashell='#fff5ee',sienna='#a0522d',skyblue='#87ceeb',slateblue='#6a5acd',slategray='#708090',slategrey='#708090',snow='#fffafa',springgreen='#00ff7f',steelblue='#4682b4',tan='#d2b48c',thistle='#d8bfd8',tomato='#ff6347',turquoise='#40e0d0',violet='#ee82ee',wheat='#f5deb3',whitesmoke='#f5f5f5',yellowgreen='#9acd32',rebeccapurple='#663399',}end)()
__mod_rtk_font=(function()
local rtk=__mod_rtk_core
local _fontcache={}local _idmgr=rtk.IndexManager(2,127)rtk.Font=rtk.class('rtk.Font')rtk.Font.register{name=nil,size=nil,scale=nil,flags=nil,texth=nil,}function rtk.Font:initialize(name,size,scale,flags)if size then
self:set(name,size,scale,flags)end
end
function rtk.Font:finalize()if self._idx then
self:_decref()end
end
function rtk.Font:_decref()if not self._idx or self._idx==1 then
return
end
local refcount=_fontcache[self._key][2]
if refcount<=1 then
_idmgr:release(self._idx)_fontcache[self._key]=nil
else
_fontcache[self._key][2]=refcount-1
end
end
function rtk.Font:_get_id()local idx=_idmgr:next(true)if idx then
return idx
end
return 1
end
function rtk.Font:draw(text,x,y,clipw,cliph,flags)if rtk.os.mac then
local fudge=1*rtk.scale.value
y=y+fudge
if cliph then
cliph=cliph-fudge
end
end
flags=flags or 0
self:set()if type(text)=='string' then
gfx.x=x
gfx.y=y
if cliph then
gfx.drawstr(text,flags,x+clipw,y+cliph)else
gfx.drawstr(text,flags)end
elseif #text==1 then
local segment,sx,sy,sw,sh=table.unpack(text[1])gfx.x=x+sx
gfx.y=y+sy
if cliph then
gfx.drawstr(segment,flags,x+clipw,y+cliph)else
gfx.drawstr(segment,flags)end
else
flags=flags|(cliph and 0 or 256)local checkh=cliph
clipw=x+(clipw or 0)cliph=y+(cliph or 0)for n=1,#text do
local segment,sx,sy,sw,sh=table.unpack(text[n])local offy=y+sy
if checkh and offy>cliph then
break
elseif offy+sh>=0 then
gfx.x=x+sx
gfx.y=offy
gfx.drawstr(segment,flags,clipw,cliph)end
end
end
end
function rtk.Font:measure(s)self:set()return gfx.measurestr(s)end
local _wrap_characters={[' '] = true,['-'] = true,[','] = true,['.'] = true,['!'] = true,['?'] = true,['\n'] = true,['/'] = true,['\\'] = true,[';'] = true,[':'] = true,}function rtk.Font:layout(text,boxw,boxh,wrap,align,relative,spacing,breakword)self:set()local segments={text=text,boxw=boxw,boxh=boxh,wrap=wrap,align=align,relative=relative,spacing=spacing,multiplier=rtk.font.multiplier,scale=rtk.scale.value,dirty=false,isvalid=function()return not self.dirty and self.scale==rtk.scale.value and self.multiplier==rtk.font.multiplier
end
}align=align or rtk.Widget.LEFT
spacing=(spacing or 0)+math.ceil((rtk.os.mac and 3 or 0)*rtk.scale.value)if not text:find('\n') then
local w,h=gfx.measurestr(text)if w<=boxw or not wrap then
segments[1]={text,0,0,w,h}return segments,w,h
end
end
local maxwidth=0
local y=0
local function addsegment(segment)local w,h=gfx.measurestr(segment)segments[#segments+1]={segment,0,y,w,h}maxwidth=math.max(w,maxwidth)y=y+h+spacing
end
if not wrap then
for n, line in ipairs(text:split('\n')) do
if #line>0 then
addsegment(line)else
y=y+self.texth+spacing
end
end
else
local startpos=1
local wrappos=1
local len=text:len()for endpos=1,len do
local substr=text:sub(startpos,endpos)local ch=text:sub(endpos,endpos)local w,h=gfx.measurestr(substr)if _wrap_characters[ch] then
wrappos=endpos
end
if w > boxw or ch=='\n' then
local wrapchar=_wrap_characters[text:sub(wrappos,wrappos)]
if breakword and(wrappos==startpos or not wrapchar)then
wrappos=endpos-1
end
if wrappos>startpos and(breakword or wrapchar)then
addsegment(text:sub(startpos,wrappos):strip())startpos=wrappos+1
wrappos=endpos
elseif ch=='\n' then
y=y+self.texth+spacing
end
end
end
if startpos<=len then
addsegment(string.strip(text:sub(startpos,len)))end
end
if align==rtk.Widget.CENTER then
maxwidth=relative and maxwidth or boxw
for n,segment in ipairs(segments)do
segment[2]=(maxwidth-segment[4])/2
end
end
if align==rtk.Widget.RIGHT then
maxwidth=relative and maxwidth or boxw
for n,segment in ipairs(segments)do
segment[2]=maxwidth-segment[4]
end
end
return segments,maxwidth,y
end
function rtk.Font:set(name,size,scale,flags)local global_scale=rtk.scale.value
if not size and self._last_global_scale~=global_scale then
name=name or self.name
size=self.size
scale=scale or self.scale
flags=flags or self.flags
else
scale=scale or 1
flags=flags or 0
end
local sz=size and math.ceil(size*scale*global_scale*rtk.font.multiplier)local newfont=name and(name~=self.name or sz~=self.calcsize or flags~=self.flags)if self._idx and self._idx>1 then
if not newfont then
gfx.setfont(self._idx)return false
else
self:_decref()end
elseif self._idx==1 then
gfx.setfont(1,self.name,self.calcsize,self.flags)return true
end
if not newfont then
error('rtk.Font:set() called without arguments and no font parameters previously set')end
local key=name..tostring(sz)..tostring(flags)local cache=_fontcache[key]
local idx
if not cache then
idx=self:_get_id()if idx>1 then
_fontcache[key]={idx,1}end
else
cache[2]=cache[2]+1
idx=cache[1]
end
gfx.setfont(idx,name,sz,flags)self._key=key
self._idx=idx
self._last_global_scale=global_scale
self.name=name
self.size=size
self.scale=scale
self.flags=flags
self.calcsize=sz
self.texth=gfx.texth
return true
end
end)()

__mod_rtk_event=(function()
local rtk=__mod_rtk_core
local log=__mod_rtk_log
rtk.Event=rtk.class('rtk.Event')rtk.Event.static.MOUSEDOWN=1
rtk.Event.static.MOUSEUP=2
rtk.Event.static.MOUSEMOVE=3
rtk.Event.static.MOUSEWHEEL=4
rtk.Event.static.KEY=5
rtk.Event.static.DROPFILE=6
rtk.Event.static.typenames={[rtk.Event.MOUSEDOWN]='mousedown',[rtk.Event.MOUSEUP]='mouseup',[rtk.Event.MOUSEMOVE]='mousemove',[rtk.Event.MOUSEWHEEL]='mousewheel',[rtk.Event.KEY]='key',[rtk.Event.DROPFILE]='dropfile',}rtk.Event.register{type=nil,handled=nil,button=0,buttons=0,wheel=0,hwheel=0,keycode=nil,char=nil,ctrl=false,shift=false,alt=false,meta=false,modifiers=nil,files=nil,x=nil,y=nil,time=0,simulated=nil,debug=nil,}function rtk.Event:initialize(attrs)self:reset()if attrs then
table.merge(self,attrs)end
end
function rtk.Event:__tostring()local custom
if self.type>=1 and self.type<=3 then
custom = string.format(' button=%s buttons=%s', self.button, self.buttons)elseif self.type==4 then
custom = string.format(' wheel=%s,%s', self.hwheel, self.wheel)elseif self.type==5 then
custom = string.format(' char=%s keycode=%s', self.char, self.keycode)elseif self.type==6 then
custom=' ' .. table.tostring(self.files)end
return string.format('Event<%s xy=%s,%s handled=%s sim=%s%s>',rtk.Event.typenames[self.type] or 'unknown',self.x,self.y,self.handled,self.simulated,custom or '')end
function rtk.Event:reset(type)table.merge(self,self.class.attributes.defaults)self.type=type
self.handled=nil
self.debug=nil
self.files=nil
self.simulated=nil
self.time=nil
self.char=nil
self.x=gfx.mouse_x
self.y=gfx.mouse_y
return self
end
function rtk.Event:is_mouse_event()return self.type<=rtk.Event.MOUSEWHEEL
end
function rtk.Event:get_button_duration(button)local buttonstate=rtk.mouse.state[button or self.button]
if buttonstate then
return self.time-buttonstate.time
end
end
function rtk.Event:set_widget_mouseover(widget)if rtk.debug and not self.debug then
self.debug=widget
end
if widget.tooltip and not rtk._mouseover_widget and self.type==rtk.Event.MOUSEMOVE and not self.simulated then
rtk._mouseover_widget=widget
end
end
function rtk.Event:set_widget_pressed(widget)if not rtk._pressed_widgets then
rtk._pressed_widgets={order={}}end
table.insert(rtk._pressed_widgets.order,widget)rtk._pressed_widgets[widget.id]={self.x,self.y,self.time}if not rtk._drag_candidates then
rtk._drag_candidates={}end
table.insert(rtk._drag_candidates,{widget,false})end
function rtk.Event:is_widget_pressed(widget)return rtk._pressed_widgets and rtk._pressed_widgets[widget.id] and true or false
end
function rtk.Event:set_button_state(key,value)rtk.mouse.state[self.button][key]=value
end
function rtk.Event:get_button_state(key)local s=rtk.mouse.state[self.button]
return s and s[key]
end
function rtk.Event:set_modifiers(cap,button)self.modifiers=cap&(4|8|16|32)self.ctrl=cap&4~=0
self.shift=cap&8~=0
self.alt=cap&16~=0
self.meta=cap&32~=0
self.buttons=cap&(1|2|64)self.button=button
end
function rtk.Event:set_handled(widget)self.handled=widget or true
end
function rtk.Event:clone(overrides)local event=rtk.Event()for k,v in pairs(self)do
event[k]=v
end
event.handled=nil
table.merge(event,overrides or {})return event
end
end)()

__mod_rtk_image=(function()
local rtk=__mod_rtk_core
local log=__mod_rtk_log
rtk.Image=rtk.class('rtk.Image')rtk.Image.static._icons={}rtk.Image.static.DEFAULT=0
rtk.Image.static.ADDITIVE_BLEND=1
rtk.Image.static.SUBTRACTIVE_BLEND=128
rtk.Image.static.NO_SOURCE_ALPHA=2
rtk.Image.static.NO_FILTERING=4
rtk.Image.static.FAST_BLIT=2|4
rtk.Image.static.ids=rtk.IndexManager(0,1023)local function _search_image_paths_list(fname,paths)if not paths or #paths==0 then
return
end
local path=string.format('%s/%s', paths[1], fname)if rtk.file.exists(path)then
return path
end
if #paths>1 then
for i=2,#paths do
path=string.format('%s/%s', paths[i], fname)if rtk.file.exists(path)then
return path
end
end
end
end
function rtk.Image.static._search_image_paths(fname,style)if not style then
local path=_search_image_paths_list(fname,rtk._image_paths)if path then
return path,true
end
style=rtk.theme.iconstyle
end
local path=_search_image_paths_list(fname,rtk._image_paths[style])if path then
return path,true
end
local otherstyle=style=='light' and 'dark' or 'light'local path=_search_image_paths_list(fname,rtk._image_paths[otherstyle])if path then
return path,false
end
end
function rtk.Image.static.icon(name,style)style=style or rtk.theme.iconstyle
local img
local pack=rtk.Image._icons[name]
if pack then
img=pack:get(name,style)if img then
return img
end
end
local path, matched=rtk.Image._search_image_paths(name .. '.png', style)if path then
img=rtk.Image():load(path)if not matched then
img:recolor(style=='light' and '#ffffff' or '#000000')end
img.style=style
end
if not img then
log.error('rtk: rtk.Image.icon("%s"): icon not found in any icon path', name)end
return img
end
rtk.Image.static.make_icon=rtk.Image.static.icon
function rtk.Image.static.make_placeholder_icon(w,h,style)local img=rtk.Image(w or 24,h or 24)img:pushdest()rtk.color.set({1,0.2,0.2,1})gfx.setfont(1, 'Sans', w or 24)gfx.x,gfx.y=5,0
gfx.drawstr('?')img:popdest()img.style=style or 'dark'return img
end
rtk.Image.register{x=0,y=0,w=nil,h=nil,density=1.0,path=nil,rotation=0,id=nil,}function rtk.Image:initialize(w,h,density)table.merge(self,self.class.attributes.defaults)if h then
self:create(w,h,density)end
end
function rtk.Image:finalize()if self.id and not self._ref then
gfx.setimgdim(self.id,0,0)rtk.Image.static.ids:release(self.id)end
end
function rtk.Image:__tostring()local clsname=self.class.name:gsub('rtk.', '')return string.format('<%s %s,%s %sx%s id=%s density=%s path=%s ref=%s>',clsname,self.x,self.y,self.w,self.h,self.id,self.density,self.path,self._ref
)end
function rtk.Image:create(w,h,density)if not self.id then
self.id=rtk.Image.static.ids:next(true)if not self.id then
error("unable to allocate image: ran out of available REAPER image buffers")end
end
if h~=nil then
self:resize(w,h,false)end
self.density=density or 1.0
return self
end
function rtk.Image:load(path,density)local found=path
if not rtk.file.exists(path)then
found=rtk.script_path..path
if not rtk.file.exists(found)then
found=rtk.Image._search_image_paths(path)end
end
self._path=found
local id=self.id
if not id or self._ref then
id=rtk.Image.static.ids:next()end
local res=gfx.loadimg(id,found)if res~=-1 then
self.id=id
self.path=found
self.w,self.h=gfx.getimgdim(self.id)self.density=density or 1.0
return self
else
rtk.Image.static.ids:release(id)self.w,self.h=nil,nil
self.id=nil
log.warning('rtk: rtk.Image:load("%s"): no such file found in any search paths', path)return nil
end
end
function rtk.Image:pushdest()assert(self.id, 'create() or load() must be called first')rtk.pushdest(self.id)end
function rtk.Image:popdest()assert(gfx.dest==self.id, 'rtk.Image.popdest() called on image that is not the current drawing target')rtk.popdest(self.id)end
function rtk.Image:clone()local newimg=rtk.Image(self.w,self.h)if self.id then
newimg:blit{src=self,sx=self.x,sy=self.y}end
newimg.density=self.density
return newimg
end
function rtk.Image:resize(w,h,clear)w=math.ceil(w)h=math.ceil(h)if self.w~=w or self.h~=h then
if not self.id then
return self:create(w,h)end
self.w,self.h=w,h
gfx.setimgdim(self.id,0,0)gfx.setimgdim(self.id,w,h)end
if clear~=false then
self:clear()end
return self
end
function rtk.Image:scale(w,h,mode,density)assert(w or h, 'one or both of w or h parameters must be specified')if not self.id then
return rtk.Image(w,h)end
local aspect=self.w/self.h
w=w or(h/aspect)h=h or(w*aspect)local newimg=rtk.Image(w,h)newimg:blit{src=self,sx=self.x,sy=self.y,sw=self.w,sh=self.h,dw=newimg.w,dh=newimg.h,mode=mode}newimg.density=density or self.density
return newimg
end
function rtk.Image:clear(color)self:pushdest()if not color then
gfx.set(0,0,0,0,rtk.Image.DEFAULT,self.id,0)gfx.setimgdim(self.id,0,0)gfx.setimgdim(self.id,self.w,self.h)else
rtk.color.set(color)gfx.mode=rtk.Image.DEFAULT
end
gfx.rect(self.x,self.y,self.w,self.h,1)gfx.set(0,0,0,1,rtk.Image.DEFAULT,self.id,1)self:popdest()return self
end
function rtk.Image:viewport(x,y,w,h,density)local new=rtk.Image()new.id=self.id
new.density=density or self.density
new.path=self.path
new.x=x or 0
new.y=y or 0
new.w=w or(self.w-new.x)new.h=h or(self.h-new.y)new._ref=self
return new
end
function rtk.Image:draw(dx,dy,a,scale,clipw,cliph,mode)return self:blit{dx=dx,dy=dy,alpha=a,clipw=clipw,cliph=cliph,mode=mode,scale=scale
}end
function rtk.Image:blit(attrs)attrs=attrs or {}gfx.a=attrs.alpha or 1.0
local mode=attrs.mode or rtk.Image.DEFAULT
if mode&rtk.Image.SUBTRACTIVE_BLEND~=0 then
mode=(mode&~rtk.Image.SUBTRACTIVE_BLEND)|rtk.Image.ADDITIVE_BLEND
gfx.a=-gfx.a
end
gfx.mode=mode
local src=attrs.src
if src and type(src)=='table' then
assert(rtk.isa(src, rtk.Image), 'src must be an rtk.Image or numeric image id')src=src.id
end
if src then
self:pushdest()end
local scale=(attrs.scale or 1.0)/self.density
local sx=attrs.sx or self.x
local sy=attrs.sy or self.y
local sw=attrs.sw or self.w
local sh=attrs.sh or self.h
local dx=attrs.dx or 0
local dy=attrs.dy or 0
local dw=attrs.dw or(sw*scale)local dh=attrs.dh or(sh*scale)if attrs.clipw and dw>attrs.clipw then
sw=sw-(dw-attrs.clipw)/(dw/sw)dw=attrs.clipw
end
if attrs.cliph and dh>attrs.cliph then
sh=sh-(dh-attrs.cliph)/(dh/sh)dh=attrs.cliph
end
if self.rotation==0 then
gfx.blit(src or self.id,1.0,0,sx,sy,sw,sh,dx or 0,dy or 0,dw,dh,0,0)else
gfx.blit(src or self.id,1.0,self.rotation,sx-(self._soffx or 0),sy-(self._soffy or 0),self._dw,self._dh,dx-(self._doffx or 0),dy-(self._doffy or 0),self._dw,self._dh,0,0
)end
gfx.mode=0
if src then
self:popdest()end
return self
end
function rtk.Image:recolor(color)local r,g,b,_=rtk.color.rgba(color)return self:filter(0,0,0,1.0,r,g,b,0)end
function rtk.Image:filter(mr,mg,mb,ma,ar,ag,ab,aa)self:pushdest()gfx.muladdrect(self.x,self.y,self.w,self.h,mr,mg,mb,ma,ar,ag,ab,aa)self:popdest()return self
end
function rtk.Image:rect(color,x,y,w,h,fill)self:pushdest()rtk.color.set(color)gfx.rect(x,y,w,h,fill)self:popdest()return self
end
function rtk.Image:blur(strength,x,y,w,h)if not self.w then
end
self:pushdest()gfx.mode=6
x=x or 0
y=y or 0
for i=1,strength or 20 do
gfx.x=x
gfx.y=y
gfx.blurto(x+(w or self.w),y+(h or self.h))end
self:popdest()return self
end
function rtk.Image:flip_vertical()self:pushdest()gfx.mode=6
gfx.a=1
gfx.transformblit(self.id,self.x,self.y,self.w,self.h,2,2,{self.x,self.y+self.h,self.x+self.w,self.y+self.h,self.x,self.y,self.x+self.w,self.y
})rtk.popdest()return self
end
local function _xlate(x,y,theta)return x*math.cos(theta)-y*math.sin(theta),x*math.sin(theta)+y*math.cos(theta)end
function rtk.Image:rotate(degrees)self.rotation=math.rad(degrees)local x1,y1=0,0
local xt1,yt1=_xlate(x1,y1,self.rotation)local x2,y2=0+self.w,0
local xt2,yt2=_xlate(x2,y2,self.rotation)local x3,y3=0,self.h
local xt3,yt3=_xlate(x3,y3,self.rotation)local x4,y4=0+self.w,self.h
local xt4,yt4=_xlate(x4,y4,self.rotation)local xmin=math.min(xt1,xt2,xt3,xt4)local xmax=math.max(xt1,xt2,xt3,xt4)local ymin=math.min(yt1,yt2,yt3,yt4)local ymax=math.max(yt1,yt2,yt3,yt4)local dw=xmax-xmin
local dh=ymax-ymin
local dmax=math.max(dw,dh)self._dw=dmax
self._dh=dmax
self._soffx=(dmax-self.w)/2
self._soffy=(dmax-self.h)/2
self._doffx=math.max(0,(dh-dw)/2)self._doffy=math.max(0,(dw-dh)/2)return self
end
function rtk.Image:refresh_scale()end
end)()

__mod_rtk_multiimage=(function()
local rtk=__mod_rtk_core
local log=__mod_rtk_log
rtk.MultiImage=rtk.class('rtk.MultiImage', rtk.Image)function rtk.MultiImage:initialize(...)rtk.Image.initialize(self)self._variants={}local images={...}for _,img in ipairs(images)do
self:add(img)end
end
function rtk.MultiImage:finalize()end
function rtk.MultiImage:add(path_or_image,density)local img
if rtk.isa(path_or_image,rtk.Image)then
assert(not rtk.isa(path_or_image, rtk.MultiImage), 'cannot add an rtk.MultiImage to an rtk.MultiImage')img=path_or_image
else
assert(density, 'density must be supplied when path is passed to add()')img=rtk.Image:load(path_or_image,density)end
assert(not self._variants[img.density], 'replacing existing density not supported')self._variants[img.density]=img
if not self.id or self.density==img.density then
self:_set(img)end
if not self._max or img.density>self._max.density then
self._max=img
end
return img
end
function rtk.MultiImage:load(path,density)if self:add(path,density)then
return self
end
end
function rtk.MultiImage:_set(img)self.current=img
self.id=img.id
self.x=img.x
self.y=img.y
self.w=img.w
self.h=img.h
self.density=img.density
self.path=img.path
self.rotation=img.rotation
end
function rtk.MultiImage:refresh_scale(scale)local best=self._max
scale=scale or rtk.scale.value
for density,img in pairs(self._variants)do
if density==scale then
best=img
break
elseif density>scale and density<best.density then
best=img
end
end
self:_set(best)return self
end
function rtk.MultiImage:clone()local new=rtk.MultiImage()for density,img in pairs(self._variants)do
new:add(img:clone())end
new:_set(new._variants[self.density])return new
end
function rtk.MultiImage:resize(w,h,clear)for density,img in pairs(self._variants)do
img:resize(w*density,h*density,clear)end
self:_set(self.current)return self
end
function rtk.MultiImage:scale(w,h,mode)local new=rtk.MultiImage()for density,img in pairs(self._variants)do
new:add(img:scale(w and w*density,h and h*density,mode))end
new:_set(new._variants[self.density])return new
end
function rtk.MultiImage:clear(color)for density,img in pairs(self._variants)do
img:clear(color)end
end
function rtk.MultiImage:viewport(x,y,w,h)local new=rtk.MultiImage()for density,img in pairs(self._variants)do
new:add(img:viewport(x*density,y*density,w*density,h*density))end
new:_set(new._variants[self.density])return new
end
function rtk.MultiImage:filter(mr,mg,mb,ma,ar,ag,ab,aa)for density,img in pairs(self._variants)do
img:filter(mr,mg,mb,ma,ar,ag,ab,aa)end
return self
end
function rtk.MultiImage:rect(color,x,y,w,h,fill)for density,img in pairs(self._variants)do
img:rect(color,x*density,y*density,w*density,h*density,fill)end
return self
end
function rtk.MultiImage:blur(strength,x,y,w,h)for density,img in pairs(self._variants)do
img:blur(strength,x*density,y*density,w*density,h*density)end
return self
end
function rtk.MultiImage:flip_vertical()for density,img in pairs(self._variants)do
img:flip_vertical()end
return self
end
function rtk.MultiImage:rotate(degrees)for density,img in pairs(self._variants)do
img:rotate(degrees)end
return self
end
end)()

__mod_rtk_imagepack=(function()
local rtk=__mod_rtk_core
local log=__mod_rtk_log
rtk.ImagePack=rtk.class('rtk.ImagePack')rtk.ImagePack.register{default_size='medium',}function rtk.ImagePack:initialize(attrs)table.merge(self,self.class.attributes.defaults)self._last_id=0
self._sources={}self._regions={}self._cache={}if attrs then
self.default_size=attrs.default_size or self.default_size
if attrs.src then
self:add(attrs)if attrs.register then
self:register_as_icons()end
end
end
end
function rtk.ImagePack:add(attrs)assert(type(attrs)=='table', 'ImagePack:add() expects a table')assert(type(attrs.src)=='string' or rtk.isa(attrs.src, rtk.Image), '"src" field is missing or is not string or rtk.Image')assert(not attrs.strips or type(attrs.strips)=='table', '"strips" field must be a table')local strips=attrs.strips or attrs
assert(#strips > 0, 'no strips provided (either as a "strips" field or as positional elements elements)')local src_idx=#self._sources+1
self._sources[src_idx]={src=attrs.src,recolors={}}local y=0
for _,strip in ipairs(strips)do
assert(type(strip)=='table', 'ImagePack strip definition must be a table')assert(type(strip.w) == 'number' or type(strip.h) == 'number', 'ImagePack strip requires either "w" or "h" fields')local names=strip.names or attrs.names
assert(type(names)=='table', 'ImagePack strip missing "names" field or is not table')local sizes=strip.sizes
if not sizes then
local density=strip.density or attrs.density or 1
if strip.size then
sizes={{strip.size,density}}elseif attrs.sizes then
sizes=attrs.sizes
elseif attrs.size then
sizes={{attrs.size,density}}else
sizes={{self.default_size,density}}end
end
strip.w=strip.w or strip.h
strip.h=strip.h or strip.w
local columns=strip.columns or attrs.columns
local rowwidth=columns and(columns*strip.w)local style=strip.style or attrs.style
local x=0
for _,name in ipairs(names)do
local subregion={id=self._last_id,src_idx=src_idx,x=x,y=y,w=strip.w,h=strip.h,}self._last_id=self._last_id+1
for _,sizedensity in ipairs(sizes)do
local size,density=table.unpack(sizedensity)local key=string.format('%s:%s:%s', style, name, size)local densities=self._regions[key]
if not densities then
densities={}self._regions[key]=densities
elseif densities[density] then
error(string.format('duplicate image name "%s" for style=%s size=%s density=%s',name,style,size,density
))end
densities[density]=subregion
end
x=x+strip.w
if rowwidth and x>=rowwidth then
x=0
y=y+strip.h
end
end
y=y+strip.h
end
return self
end
function rtk.ImagePack:_get_densities(name,style)local key
if not name:find(':') then
key=string.format('%s:%s:%s', style, name, self.default_size)else
key=string.format('%s:%s', style, name)end
return key,self._regions[key]
end
function rtk.ImagePack:get(name,style)if not name then
return
end
local key,densities=self:_get_densities(name,style)local multi=self._cache[key]
if multi then
return multi
end
local recolor=false
if not densities and not style then
style=rtk.theme.iconstyle
densities=self:_get_densities(name,style)end
if not densities and style then
local otherstyle=style=='light' and 'dark' or 'light'recolor=true
_,densities=self:_get_densities(name,otherstyle)if not densities then
_,densities=self:_get_densities(name,nil)recolor=true
end
end
if not densities then
return
end
local multi=rtk.MultiImage()for density,region in pairs(densities)do
local src=self._sources[region.src_idx]
local img=src.img
if not img then
img=rtk.Image():load(src.src)src.img=img
end
if recolor then
img=src.recolors[style]
if not img then
img=src.img:clone():recolor(style=='light' and '#ffffff' or '#000000')src.recolors[style]=img
end
end
assert(img, string.format('could not read "%s"', src.src))multi:add(img:viewport(region.x,region.y,region.w,region.h,density))end
multi.style=style
self._cache[key]=multi
return multi
end
function rtk.ImagePack:register_as_icons()local default_size=self.default_size
for key,_ in pairs(self._regions)do
local idx=key:find(':')local name=key:sub(idx+1)rtk.Image._icons[name]=self
idx=name:find(':')local size=name:sub(idx+1)if size==default_size then
name=name:sub(1,idx-1)rtk.Image._icons[name]=self
end
end
return self
end
end)()

__mod_rtk_shadow=(function()
local rtk=__mod_rtk_core
rtk.Shadow=rtk.class('rtk.Shadow')rtk.Shadow.static.RECTANGLE=0
rtk.Shadow.static.CIRCLE=1
rtk.Shadow.register{type=nil,color='#00000055',w=nil,h=nil,radius=nil,elevation=nil,}function rtk.Shadow:initialize(color)self.color=color or self.class.attributes.color.default
self._image=nil
self._last_draw_params=nil
end
function rtk.Shadow:set_rectangle(w,h,elevation,t,r,b,l)self.type=rtk.Shadow.RECTANGLE
self.w=w
self.h=h
self.tt=t or elevation
self.tr=r or elevation
self.tb=b or elevation
self.tl=l or elevation
assert(self.tt or self.tr or self.tb or self.tl, 'missing elevation for at least one edge')self.elevation=elevation or math.max(self.tt,self.tr,self.tb,self.tl)self.radius=nil
self._check_generate=true
end
function rtk.Shadow:set_circle(radius,elevation)self.type=rtk.Shadow.CIRCLE
elevation=elevation or radius/1.5
if self.radius==radius and self.elevation==elevation then
return
end
self.radius=radius
self.elevation=elevation
self._check_generate=true
end
function rtk.Shadow:draw(x,y,alpha)if self.radius then
self:_draw_circle(x,y,alpha or 1.0)else
self:_draw_rectangle(x,y,alpha or 1.0)end
end
function rtk.Shadow:_needs_generate()if self._check_generate==false then
return false
end
local params=self._last_draw_params
local gen=not params or
self.w~=params.w or
self.h~=params.h or
self.tt~=params.tt or
self.tr~=params.tr or
self.tb~=params.tb or
self.tl~=params.tl or
self.elevation~=params.elevation or
self.radius~=params.radius
if gen then
self._last_draw_params={w=self.w,h=self.h,tt=self.tt,tr=self.tr,tb=self.tb,tl=self.tl,elevation=self.elevation,radius=self.radius
}end
self._check_generate=false
return gen
end
function rtk.Shadow:_draw_circle(x,y,alpha)local pad=self.elevation*3
if self:_needs_generate()then
local radius=math.ceil(self.radius)local sz=(radius+2+pad)*2
if not self._image then
self._image=rtk.Image(sz,sz)else
self._image:resize(sz,sz,true)end
self._image:pushdest()rtk.color.set(self.color)local a=0.65-0.5*(1-1/self.elevation)local inflection=radius
local origin=-math.log(1/(pad))for i=radius+pad,1,-1 do
if i>inflection then
gfx.a2=-math.log((i-inflection)/(pad))/origin*a
else
end
gfx.circle(pad+radius,pad+radius,i,1,1)end
gfx.a2=1
gfx.set(0,0,0,1)self._image:popdest()self._needs_draw=false
end
self._image:draw(x-pad,y-pad,alpha)end
function rtk.Shadow:_draw_rectangle(x,y,alpha)local tt,tr,tb,tl=self.tt,self.tr,self.tb,self.tl
local pad=math.max(tl,tr,tt,tb)if self:_needs_generate()then
local w=self.w+(tl+tr)+pad*2
local h=self.h+(tt+tb)+pad*2
if not self._image then
self._image=rtk.Image(w,h)else
self._image:resize(w,h,true)end
self._image:pushdest()rtk.color.set(self.color)local a=gfx.a
gfx.a=1
for i=0,pad do
gfx.a2=a*(i+1)/pad
rtk.gfx.roundrect(pad+i,pad+i,self.w+tl+tr-i*2,self.h+tt+tb-i*2,self.elevation,0)end
self._image:popdest()self._needs_draw=false
end
if tr>0 then
self._image:blit{sx=pad+tl+self.w,sw=tr+pad,sh=h,dx=x+self.w,dy=y-tt-pad,alpha=alpha
}end
if tb>0 then
self._image:blit{sy=pad+tt+self.h,sw=self.w+tl+pad,sh=tb+pad,dx=x-tl-pad,dy=y+self.h,alpha=alpha
}end
if tt>0 then
self._image:blit{sx=0,sy=0,sw=self.w+tl+pad,sh=pad+tt,dx=x-tl-pad,dy=y-tt-pad,alpha=alpha
}end
if tl>0 then
self._image:blit{sx=0,sy=pad+tt,sw=pad+tl,sh=self.h,dx=x-tl-pad,dy=y,alpha=alpha
}end
end
end)()

__mod_rtk_nativemenu=(function()
local rtk=__mod_rtk_core
rtk.NativeMenu=rtk.class('rtk.NativeMenu')rtk.NativeMenu.static.SEPARATOR=0
function rtk.NativeMenu:initialize(menu)self._menustr=nil
if menu then
self:set(menu)end
end
function rtk.NativeMenu:set(menu)self.menu=menu
if menu then
self:_parse()end
end
function rtk.NativeMenu:_parse(submenu)self._item_by_idx={}self._item_by_id={}self._order=self:_parse_submenu(self.menu)end
function rtk.NativeMenu:_parse_submenu(submenu,baseitem)local order=baseitem or {}for n,menuitem in ipairs(submenu)do
if type(menuitem) ~='table' then
menuitem={label=menuitem}else
menuitem=table.shallow_copy(menuitem)if not menuitem.label then
menuitem.label=table.remove(menuitem,1)end
end
if menuitem.submenu then
menuitem=self:_parse_submenu(menuitem.submenu,menuitem)menuitem.submenu=nil
elseif menuitem.label~=rtk.NativeMenu.SEPARATOR then
local idx=#self._item_by_idx+1
menuitem.index=idx
self._item_by_idx[idx]=menuitem
end
if menuitem.id then
self._item_by_id[tostring(menuitem.id)]=menuitem
end
order[#order+1]=menuitem
end
return order
end
local function _get_item_attr(item,attr)local val=item[attr]
if type(val)=='function' then
return val()else
return val
end
end
function rtk.NativeMenu:_build_menustr(submenu,items)items=items or {}local menustr=''for n,item in ipairs(submenu)do
if not _get_item_attr(item, 'hidden') then
local flags=''if _get_item_attr(item, 'disabled') then
flags=flags .. '#'end
if _get_item_attr(item, 'checked') then
flags=flags .. '!'end
if item.label==rtk.NativeMenu.SEPARATOR then
menustr=menustr .. '|'elseif #item>0 then
menustr=menustr .. flags .. '>' .. item.label .. '|' .. self:_build_menustr(item, items) .. '<|'else
items[#items+1]=item
menustr=menustr .. flags .. item.label .. '|'end
end
end
return menustr,items
end
function rtk.NativeMenu:item(idx_or_id)if not idx_or_id or not self._item_by_idx then
return nil
end
local item=self._item_by_id[tostring(idx_or_id)] or self._item_by_id[idx_or_id]
if item then
return item
end
return self._item_by_idx[idx_or_id]
end
function rtk.NativeMenu:items()if not self._item_by_idx then
return function()end
end
local i=0
local n=#self._item_by_idx
return function()i=i+1
if i<=n then
return self._item_by_idx[i]
end
end
end
function rtk.NativeMenu:open(x,y)rtk.window:request_mouse_cursor(rtk.mouse.cursors.POINTER)assert(self.menu, 'menu must be set before open()')if not self._order then
self:_parse()end
local menustr,items=self:_build_menustr(self._order)local future=rtk.Future()rtk.defer(function()gfx.x=x
gfx.y=y
local choice=gfx.showmenu(menustr)local item
if choice>0 then
item=items[tonumber(choice)]
end
rtk._drag_candidates=nil
rtk.window:queue_mouse_refresh()future:resolve(item)end)return future
end
function rtk.NativeMenu:open_at_mouse()return self:open(gfx.mouse_x,gfx.mouse_y)end
function rtk.NativeMenu:open_at_widget(widget,halign,valign)assert(widget.drawn, "rtk.NativeMenu.open_at_widget() called before widget was drawn")local x=widget.clientx
local y=widget.clienty
if halign=='right' then
x=x+widget.calc.w
end
if valign ~='top' then
y=y+widget.calc.h
end
return self:open(x,y)end
end)()

__mod_rtk_widget=(function()
local rtk=__mod_rtk_core
local log=__mod_rtk_log
rtk.Widget=rtk.class('rtk.Widget')rtk.Widget.static.LEFT=0
rtk.Widget.static.TOP=0
rtk.Widget.static.CENTER=1
rtk.Widget.static.RIGHT=2
rtk.Widget.static.BOTTOM=2
rtk.Widget.static.POSITION_INFLOW=0x01
rtk.Widget.static.POSITION_FIXED=0x02
rtk.Widget.static.RELATIVE=rtk.Widget.POSITION_INFLOW|0x10
rtk.Widget.static.ABSOLUTE=0x20
rtk.Widget.static.FIXED=rtk.Widget.POSITION_FIXED|0x40
rtk.Widget.static.FIXED_FLOW=rtk.Widget.POSITION_INFLOW|rtk.Widget.POSITION_FIXED|0x80
rtk.Widget.static.BOX=1
rtk.Widget.static.FULL=rtk.Widget.BOX|2
rtk.Widget.static.REFLOW_DEFAULT=nil
rtk.Widget.static.REFLOW_NONE=0
rtk.Widget.static.REFLOW_PARTIAL=1
rtk.Widget.static.REFLOW_FULL=2
rtk.Widget.static._calc_border=function(self,value)if type(value)=='string' then
local parts=string.split(value)if #parts==1 then
return {{rtk.color.rgba(parts[1])},1}elseif #parts==2 then
local width=parts[1]:gsub('px', '')return {{rtk.color.rgba(parts[2])},tonumber(width)}else
error('invalid border format')end
elseif value then
assert(type(value)=='table', 'border must be string or table')if #value==1 then
return {rtk.color.rgba({value[1]}),1}elseif #value==2 then
return value
elseif #value==4 then
return {value,1}else
log.exception('invalid border value: %s', table.tostring(value))error('invalid border value')end
end
end
rtk.Widget.static._calc_padding_or_margin=function(value)if not value then
return 0,0,0,0
elseif type(value)=='number' then
return value,value,value,value
else
if type(value)=='string' then
local parts=string.split(value)value={}for i=1,#parts do
local sz=parts[i]:gsub('px', '')value[#value+1]=tonumber(sz)end
end
if #value==1 then
return value[1],value[1],value[1],value[1]
elseif #value==2 then
return value[1],value[2],value[1],value[2]
elseif #value==3 then
return value[1],value[2],value[3],value[2]
elseif #value==4 then
return value[1],value[2],value[3],value[4]
else
error('invalid value')end
end
end
rtk.Widget.register{x=rtk.Attribute{default=0,reflow=rtk.Widget.REFLOW_FULL},y=rtk.Attribute{default=0,reflow=rtk.Widget.REFLOW_FULL},w=rtk.Attribute{type='number',reflow=rtk.Widget.REFLOW_FULL,animate=function(self,anim)local val=anim.resolve(anim.easingfunc(anim.pct))return(anim.dst>1.0 and val>0 and val<=1.0)and 1.01 or val,val==anim.dst
end
},h=rtk.Attribute{type='number',reflow=rtk.Widget.REFLOW_FULL,animate=rtk.Reference('w'),},z=rtk.Attribute{default=0,reflow=rtk.Widget.REFLOW_FULL},minw = rtk.Attribute{type='number', reflow=rtk.Widget.REFLOW_FULL},minh = rtk.Attribute{type='number', reflow=rtk.Widget.REFLOW_FULL},maxw = rtk.Attribute{type='number', reflow=rtk.Widget.REFLOW_FULL},maxh = rtk.Attribute{type='number', reflow=rtk.Widget.REFLOW_FULL},halign=rtk.Attribute{default=rtk.Widget.LEFT,calculate={left=rtk.Widget.LEFT,center=rtk.Widget.CENTER,right=rtk.Widget.RIGHT},},valign=rtk.Attribute{default=rtk.Widget.TOP,calculate={top=rtk.Widget.TOP,center=rtk.Widget.CENTER,bottom=rtk.Widget.BOTTOM},},scalability=rtk.Attribute{default=rtk.Widget.FULL,reflow=rtk.Widget.REFLOW_FULL,calculate={box=rtk.Widget.BOX,full=rtk.Widget.FULL},},position=rtk.Attribute{default=rtk.Widget.RELATIVE,reflow=rtk.Widget.REFLOW_FULL,calculate={relative=rtk.Widget.RELATIVE,absolute=rtk.Widget.ABSOLUTE,fixed=rtk.Widget.FIXED,['fixed-flow']=rtk.Widget.FIXED_FLOW
},},box=nil,offx=nil,offy=nil,clientx=nil,clienty=nil,padding=rtk.Attribute{replaces={'tpadding', 'rpadding', 'bpadding', 'lpadding'},get=function(self,attr,target)return {target.tpadding,target.rpadding,target.bpadding,target.lpadding}end,reflow=rtk.Widget.REFLOW_FULL,calculate=function(self,attr,value,target)local t,r,b,l=rtk.Widget.static._calc_padding_or_margin(value)target.tpadding,target.rpadding,target.bpadding,target.lpadding=t,r,b,l
return {t,r,b,l}end
},tpadding=rtk.Attribute{priority=true,reflow=rtk.Widget.REFLOW_FULL},rpadding=rtk.Reference('tpadding'),bpadding=rtk.Reference('tpadding'),lpadding=rtk.Reference('tpadding'),margin=rtk.Attribute{default=0,replaces={'tmargin', 'rmargin', 'bmargin', 'lmargin'},get=function(self,attr,target)return {target.tmargin,target.rmargin,target.bmargin,target.lmargin}end,reflow=rtk.Widget.REFLOW_FULL,calculate=function(self,attr,value,target)local t,r,b,l=rtk.Widget.static._calc_padding_or_margin(value)target.tmargin,target.rmargin,target.bmargin,target.lmargin=t,r,b,l
return {t,r,b,l}end
},tmargin=rtk.Attribute{priority=true,reflow=rtk.Widget.REFLOW_FULL},rmargin=rtk.Reference('tmargin'),bmargin=rtk.Reference('tmargin'),lmargin=rtk.Reference('tmargin'),border=rtk.Attribute{reflow=rtk.Widget.REFLOW_FULL,calculate=function(self,attr,value,target)local border=rtk.Widget.static._calc_border(self,value)target.tborder=border
target.rborder=border
target.bborder=border
target.lborder=border
target.border_uniform=true
return border
end
},tborder=rtk.Attribute{priority=true,reflow=rtk.Widget.REFLOW_FULL,calculate=function(self,attr,value,target)target.border_uniform=false
return rtk.Widget.static._calc_border(self,value)end,},rborder=rtk.Reference('tborder'),bborder=rtk.Reference('tborder'),lborder=rtk.Reference('tborder'),visible=rtk.Attribute{default=true,reflow=rtk.Widget.REFLOW_FULL},disabled=false,ghost=false,tooltip=nil,cursor=nil,alpha=rtk.Attribute{default=1.0,reflow=rtk.Widget.REFLOW_NONE,},autofocus=false,bg=rtk.Attribute{calculate=function(self,attr,value,target)return value and {rtk.color.rgba(value)}end,},scroll_on_drag=true,show_scrollbar_on_drag=true,touch_activate_delay=nil,realized=false,drawn=false,viewport=nil,window=nil,mouseover=false,hovering=false,debug=nil,id=nil,ref=nil,refs=nil,}rtk.Widget.static.last_index=0
function rtk.Widget:__allocate()self.__id=tostring(rtk.Widget.static.last_index)rtk.Widget.static.last_index=rtk.Widget.static.last_index+1
end
function rtk.Widget:initialize(attrs,...)self.refs={__empty=true}setmetatable(self.refs,{__mode='v',__index=function(table,key)return self:_ref(table,key)end,__newindex=function(table,key,value)rawset(table,key,value)table.__empty=false
end
})self.calc={border_uniform=true
}setmetatable(self.calc,{__call=function(_,_,attr,instant)return self:_calc(attr,instant)end
})local tables={self.class.attributes.defaults,...}local merged={}for n=1,#tables do
table.merge(merged,tables[n])end
if attrs then
for k,v in pairs(attrs)do
local meta=self.class.attributes.get(k)local attr=meta.alias
if attr then
merged[attr]=v
end
local replaces=meta.replaces
if replaces then
for n=1,#replaces do
merged[replaces[n]]=nil
end
end
end
table.merge(merged,attrs)if attrs.ref then
rtk._refs[attrs.ref]=self
self.refs[attrs.ref]=self
end
end
self.id=self.__id
self:_setattrs(merged)self._last_mousedown_time=0
self._last_reflow_scale=nil
end
function rtk.Widget:__tostring()local clsname=self.class.name:gsub('rtk.', '')if not self.calc then
return string.format('<%s (uninitialized)>', clsname)end
local info=self:__tostring_info()info=info and string.format('<%s>', info) or ''return string.format('%s%s[%s] (%s,%s %sx%s)',clsname,info,self.id,self.calc.x,self.calc.y,self.calc.w,self.calc.h
)end
function rtk.Widget:__tostring_info()end
function rtk.Widget:_setattrs(attrs)if not attrs then
return
end
local get=self.class.attributes.get
local priority={}local calc=self.calc
for k,v in pairs(attrs)do
if not tonumber(k)then
local meta=get(k)if not meta.priority then
if v==rtk.Attribute.FUNCTION then
v=self.class.attributes[k].default_func(self,k)elseif v==rtk.Attribute.NIL then
v=nil
end
local calculated=self:_calc_attr(k,v,nil,meta)self:_set_calc_attr(k,v,calculated,calc,meta)else
priority[#priority+1]=k
end
self[k]=v
end
end
for _,k in ipairs(priority)do
local v=self[k]
if v==rtk.Attribute.FUNCTION then
v=self.class.attributes[k].default_func(self,k)self[k]=v
end
if v~=nil then
if v==rtk.Attribute.NIL then
v=nil
self[k]=nil
end
local calculated=self:_calc_attr(k,v)self:_set_calc_attr(k,v,calculated,calc)end
end
end
function rtk.Widget:_ref(table,key)if self.parent then
return self.parent.refs[key]
else
return rtk._refs[key]
end
end
function rtk.Widget:_get_debug_color()if not self.debug_color then
local function hashint(i,seed)math.randomseed(i*(seed*53))return math.random(40,235)/255.0
end
local id=self.id:hash()self.debug_color={hashint(id,1),hashint(id,2),hashint(id,3),}end
return self.debug_color
end
function rtk.Widget:_draw_debug_box(offx,offy,event)local calc=self.calc
if not self.debug and not rtk.debug or not calc.w then
return false
end
if not self.debug and event.debug~=self then
return false
end
local color=self:_get_debug_color()gfx.set(color[1],color[2],color[3],0.2)local x=calc.x+offx
local y=calc.y+offy
gfx.rect(x,y,calc.w,calc.h,1)gfx.set(color[1],color[2],color[3],0.4)gfx.rect(x,y,calc.w,calc.h,0)local tp,rp,bp,lp=self:_get_padding_and_border()if tp>0 or rp>0 or bp>0 or lp>0 then
gfx.set(color[1],color[2],color[3],0.8)gfx.rect(x+lp,y+tp,calc.w-lp-rp,calc.h-tp-bp,0)end
return true
end
function rtk.Widget:_draw_debug_info(event)local calc=self.calc
local parts={{ 15, "#6e2e2e", tostring(self.class.name:gsub("rtk.", "")) },{ 15, "#378b48", string.format('#%s', self.id) },{ 17, "#cccccc", " | " },{ 15, "#555555", string.format("%.1f", calc.x) },{ 15,  "#777777", " , " },{ 15, "#555555", string.format("%.1f", calc.y) },{ 17, "#cccccc", " | " },{ 15, "#555555", string.format("%.1f", calc.w) },{ 13,  "#777777", "  x  " },{ 15, "#555555", string.format("%.1f", calc.h) },}local sizes={}local bw,bh=0,0
for n,part in ipairs(parts)do
local sz,_,str=table.unpack(part)gfx.setfont(1,rtk.theme.default_font,sz)local w,h=gfx.measurestr(str)sizes[n]={w,h}bw=bw+w
bh=math.max(bh,h)end
bw=bw+20
bh=bh+10
local x=self.clientx
local y=self.clienty
if x+bw>self.window.w then
x=self.window.w-bw
elseif x<0 then
x=0
end
if y-bh>=0 then
y=math.max(0,y-bh)else
y=math.min(y+calc.h,self.window.calc.h-bh)end
rtk.color.set('#ffffff')gfx.rect(x,y,bw,bh,1)rtk.color.set('#777777')gfx.rect(x,y,bw,bh,0)gfx.x=x+10
for n,part in ipairs(parts)do
local sz,color,str=table.unpack(part)rtk.color.set(color)gfx.y=y+(bh-sizes[n][2])/2
gfx.setfont(1,rtk.theme.default_font,sz)gfx.drawstr(str)end
end
function rtk.Widget:attr(attr,value,trigger,reflow)return self:_attr(attr,value,trigger,reflow,nil,false)end
function rtk.Widget:sync(attr,value,calculated,trigger,reflow)return self:_attr(attr,value,trigger,reflow,calculated,true)end
function rtk.Widget:_attr(attr,value,trigger,reflow,calculated,sync)local meta=self.class.attributes.get(attr)if value==rtk.Attribute.DEFAULT then
if meta.default==rtk.Attribute.FUNCTION then
value=meta.default_func(self,attr)else
value=meta.default
end
elseif value==rtk.Attribute.NIL then
value=nil
end
local oldval=self[attr]
local oldcalc=self.calc[attr]
local replaces=meta.replaces
if replaces then
for i=1,#replaces do
self[replaces[i]]=nil
end
end
if calculated==nil then
calculated=self:_calc_attr(attr,value,nil,meta)end
if not rawequal(value,oldval)or calculated~=oldcalc or replaces or trigger then
self[attr]=value
self:_set_calc_attr(attr,value,calculated,self.calc,meta)self:_handle_attr(attr,calculated,oldcalc,trigger==nil or trigger,reflow,sync)end
return self
end
function rtk.Widget:_calc_attr(attr,value,target,meta,namespace,widget)target=target or self.calc
meta=meta or self.class.attributes.get(attr)if meta.type then
value=meta.type(value)end
local calculate=meta.calculate
if calculate then
local tp=type(calculate)if tp=='table' then
if value==nil then
value=calculate[rtk.Attribute.NIL]
else
value=calculate[value] or value
end
elseif tp=='function' then
if value==rtk.Attribute.NIL then
value=nil
end
value=calculate(self,attr,value,target)end
end
return value
end
function rtk.Widget:_set_calc_attr(attr,value,calculated,target,meta)meta=meta or self.class.attributes.get(attr)if meta.set then
meta.set(self,attr,value,calculated,target)else
self.calc[attr]=calculated
end
end
function rtk.Widget:_calc(attr,instant)if not instant then
local anim=self:get_animation(attr)if anim and anim.dst then
return anim.dst
end
end
local meta=self.class.attributes.get(attr)if meta.get then
return meta.get(self,attr,self.calc)else
return self.calc[attr]
end
end
function rtk.Widget:move(x,y)self:attr('x', x)self:attr('y', y)return self
end
function rtk.Widget:resize(w,h)self:attr('w', w)self:attr('h', h)return self
end
function rtk.Widget:_get_relative_pos_to_viewport()local x,y=0,0
local widget=self
while widget do
x=x+widget.calc.x
y=y+widget.calc.y
if widget.viewport and widget.viewport==widget.parent then
break
end
widget=widget.parent
end
return x,y
end
function rtk.Widget:scrolltoview(margin,allowh,allowv,smooth)if not self.visible or not self.box or not self.viewport then
return self
end
local calc=self.calc
local vcalc=self.viewport.calc
local tmargin,rmargin,bmargin,lmargin=rtk.Widget.static._calc_padding_or_margin(margin or 0)local left,top=nil,nil
local absx,absy=self:_get_relative_pos_to_viewport()if allowh~=false then
if absx-lmargin<self.viewport.scroll_left then
left=absx-lmargin
elseif absx+calc.w+rmargin>self.viewport.scroll_left+vcalc.w then
left=absx+calc.w+rmargin-vcalc.w
end
end
if allowv~=false then
if absy-tmargin<self.viewport.scroll_top then
top=absy-tmargin
elseif absy+calc.h+bmargin>self.viewport.scroll_top+vcalc.h then
top=absy+calc.h+bmargin-vcalc.h
end
end
self.viewport:scrollto(left,top,smooth)return self
end
function rtk.Widget:hide()if self.calc.visible~=false then
return self:attr('visible', false)end
return self
end
function rtk.Widget:show()if self.calc.visible~=true then
return self:attr('visible', true)end
return self
end
function rtk.Widget:toggle()if self.calc.visible==true then
return self:hide()else
return self:show()end
end
function rtk.Widget:focused()return rtk.focused==self
end
function rtk.Widget:focus(event)if rtk.focused and rtk.focused~=self then
rtk.focused:blur(event,self)end
if rtk.focused==nil and self:_handle_focus(event)~=false then
rtk.focused=self
self:queue_draw()return true
end
return false
end
function rtk.Widget:blur(event,other)if not self:focused()then
return true
end
if self:_handle_blur(event,other)~=false then
rtk.focused=nil
self:queue_draw()return true
end
return false
end
function rtk.Widget:animate(kwargs)assert(kwargs and (kwargs.attr or #kwargs > 0), 'missing animation arguments')local calc=self.calc
local attr=kwargs.attr or kwargs[1]
local meta=self.class.attributes.get(attr)local key=string.format('%s.%s', self.id, attr)local curanim=rtk._animations[key]
local curdst=curanim and curanim.dst or self.calc[attr]
if curdst == kwargs.dst and not meta.calculate and attr ~= 'w' and attr ~= 'h' then
if curanim then
return curanim.future
elseif not kwargs.src then
return rtk.Future():resolve(self)end
end
kwargs.attr=attr
kwargs.key=key
kwargs.widget=self
kwargs.attrmeta=meta
kwargs.stepfunc=meta.animate
kwargs.calculate=meta.calculate
if kwargs.dst==rtk.Attribute.DEFAULT then
if meta.default==rtk.Attribute.FUNCTION then
kwargs.dst=meta.default_func(self,attr)else
kwargs.dst=meta.default
end
end
local doneval=kwargs.dst or rtk.Attribute.DEFAULT
if attr == 'w' or attr == 'h' then
kwargs.sync_surface_value=true
if not kwargs.src or kwargs.src<=1.0 then
kwargs.src=((attr=='w') and calc.w or calc.h or 0) * (kwargs.src or 1)end
if not kwargs.dst or kwargs.dst<=1.0 then
local current=self[attr]
self[attr]=kwargs.dst
local window=self:_slow_get_window()if not window then
return rtk.Future():resolve(self)end
window:reflow(rtk.Widget.REFLOW_FULL)kwargs.dst=(calc[attr] or 0)/rtk.scale.value
self[attr]=current
window:reflow(rtk.Widget.REFLOW_FULL)end
else
if meta.calculate then
kwargs.dst=meta.calculate(self,attr,kwargs.dst,{})doneval=kwargs.dst or rtk.Attribute.DEFAULT
end
end
if curdst==kwargs.dst then
if curanim then
return curanim.future
elseif not kwargs.src then
return rtk.Future():resolve(self)end
end
if kwargs.doneval==nil then
kwargs.doneval=doneval
end
if not kwargs.src then
kwargs.src=self:calc(attr,true)elseif meta.calculate then
kwargs.src=meta.calculate(self,attr,kwargs.src,{})end
return rtk.queue_animation(kwargs)end
function rtk.Widget:cancel_animation(attr)local anim=self:get_animation(attr)if anim then
anim.future:cancel()end
return anim
end
function rtk.Widget:get_animation(attr)local key=self.id .. '.' .. attr
return rtk._animations[key]
end
function rtk.Widget:setcolor(color,amul)rtk.color.set(color,(amul or 1)*self.calc.alpha)return self
end
function rtk.Widget:queue_draw()if self.window then
self.window:queue_draw()end
return self
end
function rtk.Widget:queue_reflow(mode,widget)local window=self:_slow_get_window()if window then
window:queue_reflow(mode,widget or self)end
return self
end
function rtk.Widget:reflow(boxx,boxy,boxw,boxh,fillw,fillh,clampw,clamph,uiscale,viewport,window)local expw,exph
if not boxx then
if self.box then
expw,exph=self:_reflow(table.unpack(self.box))else
return
end
else
self.viewport=viewport
self.window=window
self.box={boxx,boxy,boxw,boxh,fillw,fillh,clampw,clamph,uiscale,viewport,window}expw,exph=self:_reflow(boxx,boxy,boxw,boxh,fillw,fillh,clampw,clamph,uiscale,viewport,window)end
local calc=self.calc
self:onreflow()self.realized=true
return calc.x,calc.y,calc.w,calc.h,expw or fillw,exph or fillh
end
function rtk.Widget:_get_padding()local calc=self.calc
local scale=rtk.scale.value
return
(calc.tpadding or 0)*scale,(calc.rpadding or 0)*scale,(calc.bpadding or 0)*scale,(calc.lpadding or 0)*scale
end
function rtk.Widget:_get_border_sizes()local calc=self.calc
return
calc.tborder and calc.tborder[2] or 0,calc.rborder and calc.rborder[2] or 0,calc.bborder and calc.bborder[2] or 0,calc.lborder and calc.lborder[2] or 0
end
function rtk.Widget:_get_padding_and_border()local tp,rp,bp,lp=self:_get_padding()local tb,rb,bb,lb=self:_get_border_sizes()return tp+tb,rp+rb,bp+bb,lp+lb
end
function rtk.Widget:_get_box_pos(boxx,boxy)if self.calc.scalability&rtk.Widget.FULL==rtk.Widget.FULL then
local scale=rtk.scale.value
return scale*self.x+boxx,scale*self.y+boxy
else
return self.x+boxx,self.y+boxy
end
end
local function _get_content_dimension(size,bounds,padding,fill,clamp,flags,scale)scale=flags&rtk.Widget.FULL==rtk.Widget.FULL and(rtk.scale.value*(scale or 1))or scale or 1
if size then
if bounds and size<-1 then
return bounds+(size*scale)-padding
elseif bounds and size<=1.0 then
return math.abs(bounds*size)-padding
else
return(size*scale)-padding
end
end
if fill and bounds then
return bounds-padding
end
end
function rtk.Widget:_get_content_size(boxw,boxh,fillw,fillh,clampw,clamph,scale)local calc=self.calc
local tp,rp,bp,lp=self:_get_padding_and_border()local w=_get_content_dimension(self.w,boxw,lp+rp,fillw,clampw,calc.scalability,scale)local h=_get_content_dimension(self.h,boxh,tp+bp,fillh,clamph,calc.scalability,scale)if w and(calc.minw or calc.maxw)then
w=rtk.clamp(w,calc.minw,calc.maxw)end
if h and(calc.minh or calc.maxh)then
h=rtk.clamp(h,calc.minh,calc.maxh)end
return w,h,tp,rp,bp,lp
end
function rtk.Widget:_reflow(boxx,boxy,boxw,boxh,fillw,fillh,clampw,clamph,uiscale,viewport,window)local calc=self.calc
calc.x,calc.y=self:_get_box_pos(boxx,boxy)local w,h,tp,rp,bp,lp=self:_get_content_size(boxw,boxh,fillw,fillh,clampw,clamph)calc.w=w or(fillw and(boxw-lp-rp)or 0)calc.h=h or(fillh and(boxh-tp-bp)or 0)return fillw,fillh
end
function rtk.Widget:_realize_geometry()self.realized=true
end
function rtk.Widget:_slow_get_window()if self.window then
return self.window
end
local w=self.parent
while w do
if w.window then
return w.window
end
w=w.parent
end
end
function rtk.Widget:_is_mouse_over(clparentx,clparenty,event)local calc=self.calc
local x,y=calc.x+clparentx,calc.y+clparenty
return self.window and self.window.in_window and
rtk.point_in_box(event.x,event.y,x,y,calc.w,calc.h)end
function rtk.Widget:_draw(offx,offy,alpha,event,clipw,cliph,cltargetx,cltargety,parentx,parenty)self.offx=offx
self.offy=offy
self.clientx=cltargetx+offx+self.calc.x
self.clienty=cltargety+offy+self.calc.y
self.drawn=true
end
function rtk.Widget:_draw_bg(offx,offy,alpha,event)local calc=self.calc
if calc.bg and not calc.ghost then
self:setcolor(calc.bg,alpha)gfx.rect(calc.x+offx,calc.y+offy,calc.w,calc.h,1)end
end
function rtk.Widget:_draw_tooltip(clientx,clienty,clientw,clienth)local font=rtk.Font(table.unpack(rtk.theme.tooltip_font))local segments,w,h=font:layout(self.calc.tooltip,clientw-10,clienth-10,true)rtk.color.set(rtk.theme.tooltip_bg)local x=rtk.clamp(clientx,0,clientw-w-10)local y=rtk.clamp(clienty+16,0,clienth-h-10-self.calc.h)gfx.rect(x,y,w+10,h+10,1)rtk.color.set(rtk.theme.tooltip_text)gfx.rect(x,y,w+10,h+10,0)font:draw(segments,x+5,y+5,w,h)end
function rtk.Widget:_unpack_border(border,alpha)local color,thickness=table.unpack(border)if color then
self:setcolor(color or rtk.theme.button,alpha*self.calc.alpha)end
return thickness or 1
end
function rtk.Widget:_draw_borders(offx,offy,alpha,all)if self.ghost then
return
end
local calc=self.calc
if not all and calc.border_uniform and not calc.tborder then
return
end
local x,y,w,h=calc.x+offx,calc.y+offy,calc.w,calc.h
local tb,rb,bb,lb
local all=all or(calc.border_uniform and calc.tborder)if all then
local thickness=self:_unpack_border(all,alpha)if thickness==1 then
gfx.rect(x,y,w,h,0)return
else
tb,rb,bb,lb=all,all,all,all
end
else
tb,rb,bb,lb=calc.tborder,calc.rborder,calc.bborder,calc.lborder
end
if tb then
local thickness=self:_unpack_border(tb,alpha)gfx.rect(x,y,w,thickness,1)end
if rb and w>0 then
local thickness=self:_unpack_border(rb,alpha)gfx.rect(x+w-thickness,y,thickness,h,1)end
if bb and h>0 then
local thickness=self:_unpack_border(bb,alpha)gfx.rect(x,y+h-thickness,w,thickness,1)end
if lb then
local thickness=self:_unpack_border(lb,alpha)gfx.rect(x,y,thickness,h,1)end
end
function rtk.Widget:_get_touch_activate_delay(event)if not rtk.touchscroll then
return self.touch_activate_delay or 0
else
if not self.viewport or not self.viewport:scrollable()then
return 0
end
return(not self:focused()and event.button==rtk.mouse.BUTTON_LEFT)and
self.touch_activate_delay or rtk.touch_activate_delay
end
end
function rtk.Widget:_should_handle_event(listen)if not listen and rtk._modal and rtk._modal[self.id]~=nil then
return true
else
return listen
end
end
function rtk.Widget:_handle_event(clparentx,clparenty,event,clipped,listen)local calc=self.calc
if not listen and rtk._modal and rtk._modal[self.id]==nil then
return false
end
local dnd=rtk.dnd
if not clipped and self:_is_mouse_over(clparentx,clparenty,event)then
event:set_widget_mouseover(self,clparentx,clparenty)if event.type==rtk.Event.MOUSEMOVE and not calc.disabled then
if dnd.dragging==self then
if calc.cursor then
self.window:request_mouse_cursor(calc.cursor)end
self:_handle_dragmousemove(event,dnd.arg)elseif self.hovering==false then
if event.buttons==0 or self:focused()then
if not event.handled and not self.mouseover and self:_handle_mouseenter(event)then
self.hovering=true
self:_handle_mousemove(event)self:queue_draw()elseif rtk.debug then
self:queue_draw()end
else
if dnd.arg and not event.simulated and rtk.dnd.droppable then
if dnd.dropping==self or self:_handle_dropfocus(event,dnd.dragging,dnd.arg)then
if dnd.dropping then
if dnd.dropping~=self then
dnd.dropping:_handle_dropblur(event,dnd.dragging,dnd.arg)elseif not event.simulated then
dnd.dropping:_handle_dropmousemove(event,dnd.dragging,dnd.arg)end
end
event:set_handled(self)self:queue_draw()dnd.dropping=self
end
end
end
if not self.mouseover and(not event.handled or event.handled==self)and event.buttons==0 then
self.mouseover=true
self:queue_draw()end
if self.mouseover and calc.cursor then
self.window:request_mouse_cursor(calc.cursor)end
else
if event.handled then
self:_handle_mouseleave(event)self.hovering=false
self.mouseover=false
self:queue_draw()else
self.mouseover=true
self.window:request_mouse_cursor(calc.cursor)self:_handle_mousemove(event)event:set_handled(self)end
end
elseif event.type==rtk.Event.MOUSEDOWN and not calc.disabled then
local duration=event:get_button_duration()if duration==0 then
event:set_widget_pressed(self)end
if not event.handled then
local state=event:get_button_state(self)or 0
local threshold=self:_get_touch_activate_delay(event)if duration>=threshold and state==0 and event:is_widget_pressed(self)then
event:set_button_state(self,1)if self:_handle_mousedown(event)then
self:_accept_mousedown(event,duration,state)end
elseif state&8==0 then
if duration>=rtk.long_press_delay then
if self:_handle_longpress(event)then
self:queue_draw()event:set_button_state(self,state|8|16)else
event:set_button_state(self,state|8)end
end
end
if self:focused()then
event:set_handled(self)end
end
if self.mouseover and calc.cursor then
self.window:request_mouse_cursor(calc.cursor)end
elseif event.type==rtk.Event.MOUSEUP and not calc.disabled then
if not event.handled then
if not dnd.dragging then
self:_deferred_mousedown(event)end
if self:_handle_mouseup(event)then
event:set_handled(self)self:queue_draw()end
local state=event:get_button_state(self)or 0
if state>0 or event:is_widget_pressed(self)then
if state&16==0 and not dnd.dragging then
if self:_handle_click(event)then
event:set_handled(self)self:queue_draw()end
if state&4~=0 then
if self:_handle_doubleclick(event)then
event:set_handled(self)self:queue_draw()end
self._last_mousedown_time=0
end
end
end
if self.mouseover and calc.cursor then
self.window:request_mouse_cursor(calc.cursor)end
end
if dnd.dropping==self then
self:_handle_dropblur(event,dnd.dragging,dnd.arg)if self:_handle_drop(event,dnd.dragging,dnd.arg)then
event:set_handled(self)self:queue_draw()end
end
self:queue_draw()elseif event.type==rtk.Event.MOUSEWHEEL and not calc.disabled then
if not event.handled and self:_handle_mousewheel(event)then
event:set_handled(self)self:queue_draw()end
elseif event.type==rtk.Event.DROPFILE and not calc.disabled then
if not event.handled and self:_handle_dropfile(event)then
event:set_handled(self)self:queue_draw()end
end
elseif event.type==rtk.Event.MOUSEMOVE then
self.mouseover=false
if dnd.dragging==self then
self.window:request_mouse_cursor(calc.cursor)self:_handle_dragmousemove(event,dnd.arg)end
if self.hovering==true then
if dnd.dragging~=self then
self:_handle_mouseleave(event)self:queue_draw()self.hovering=false
end
elseif event.buttons~=0 and dnd.dropping then
if dnd.dropping==self then
self:_handle_dropblur(event,dnd.dragging,dnd.arg)dnd.dropping=nil
end
self:queue_draw()end
end
if rtk.touchscroll and event.type==rtk.Event.MOUSEUP and self:focused()then
if event:get_button_state('mousedown-handled') == self then
event:set_handled(self)self:queue_draw()end
end
if event.type==rtk.Event.KEY and not event.handled and self:focused()then
if self:_handle_keypress(event)then
event:set_handled(self)self:queue_draw()end
if self.mouseover and calc.cursor then
self.window:request_mouse_cursor(calc.cursor)end
end
return true
end
function rtk.Widget:_deferred_mousedown(event,x,y)local mousedown_handled=event:get_button_state('mousedown-handled')if not mousedown_handled and event:is_widget_pressed(self)and not event:get_button_state(self)then
local downevent=event:clone{type=rtk.Event.MOUSEDOWN,simulated=true,x=x or event.x,y=y or event.y}if self:_handle_mousedown(downevent)then
self:_accept_mousedown(event)end
end
end
function rtk.Widget:_accept_mousedown(event,duration,state)event:set_button_state('mousedown-handled', self)event:set_handled(self)if not event.simulated and event.time-self._last_mousedown_time<=rtk.double_click_delay then
event:set_button_state(self,(state or 0)|4)self._last_mousedown_time=0
else
self._last_mousedown_time=event.time
end
self:queue_draw()end
function rtk.Widget:_unrealize()self.realized=false
end
function rtk.Widget:_release_modal(event)end
function rtk.Widget:onattr(attr,value,oldval,trigger,sync)return true end
function rtk.Widget:_handle_attr(attr,value,oldval,trigger,reflow,sync)local ok=self:onattr(attr,value,oldval,trigger,sync)if ok~=false then
local redraw
if reflow==rtk.Widget.REFLOW_DEFAULT then
local meta=self.class.attributes.get(attr)reflow=meta.reflow or rtk.Widget.REFLOW_PARTIAL
redraw=meta.redraw
end
if reflow~=rtk.Widget.REFLOW_NONE then
self:queue_reflow(reflow)elseif redraw~=false then
self:queue_draw()end
if attr=='visible' then
if not value then
self:_unrealize()end
self.realized=false
self.drawn=false
elseif attr=='ref' then
assert(not oldval, 'ref cannot be changed')self.refs[self.ref]=self
rtk._refs[self.ref]=self
if self.parent then
self.parent:_sync_child_refs(self, 'add')end
end
end
return ok
end
function rtk.Widget:ondrawpre(offx,offy,alpha,event)end
function rtk.Widget:_handle_drawpre(offx,offy,alpha,event)return self:ondrawpre(offx,offy,alpha,event)end
function rtk.Widget:ondraw(offx,offy,alpha,event)end
function rtk.Widget:_handle_draw(offx,offy,alpha,event)return self:ondraw(offx,offy,alpha,event)end
function rtk.Widget:onmousedown(event)end
function rtk.Widget:_handle_mousedown(event)local ok=self:onmousedown(event)if ok~=false then
if self.calc.autofocus then
self:focus(event)return ok or self:focused()else
return ok or false
end
end
return ok
end
function rtk.Widget:onmouseup(event)end
function rtk.Widget:_handle_mouseup(event)return self:onmouseup(event)end
function rtk.Widget:onmousewheel(event)end
function rtk.Widget:_handle_mousewheel(event)return self:onmousewheel(event)end
function rtk.Widget:onclick(event)end
function rtk.Widget:_handle_click(event)return self:onclick(event)end
function rtk.Widget:ondoubleclick(event)end
function rtk.Widget:_handle_doubleclick(event)return self:ondoubleclick(event)end
function rtk.Widget:onlongpress(event)end
function rtk.Widget:_handle_longpress(event)return self:onlongpress(event)end
function rtk.Widget:onmouseenter(event)end
function rtk.Widget:_handle_mouseenter(event)local ok=self:onmouseenter(event)if ok~=false then
return self.calc.autofocus or ok
end
return ok
end
function rtk.Widget:onmouseleave(event)end
function rtk.Widget:_handle_mouseleave(event)return self:onmouseleave(event)end
function rtk.Widget:onmousemove(event)end
rtk.Widget.onmousemove=nil
function rtk.Widget:_handle_mousemove(event)if self.onmousemove then
return self:onmousemove(event)end
end
function rtk.Widget:onkeypress(event)end
function rtk.Widget:_handle_keypress(event)return self:onkeypress(event)end
function rtk.Widget:onfocus(event)return true
end
function rtk.Widget:_handle_focus(event)return self:onfocus(event)end
function rtk.Widget:onblur(event,other)return true
end
function rtk.Widget:_handle_blur(event,other)return self:onblur(event,other)end
function rtk.Widget:ondragstart(event,x,y,t)end
function rtk.Widget:_handle_dragstart(event,x,y,t)local draggable,droppable=self:ondragstart(event,x,y,t)if draggable==nil then
return false,false
end
return draggable,droppable
end
function rtk.Widget:ondragend(event,dragarg)end
function rtk.Widget:_handle_dragend(event,dragarg)self._last_mousedown_time=0
return self:ondragend(event,dragarg)end
function rtk.Widget:ondragmousemove(event,dragarg)end
function rtk.Widget:_handle_dragmousemove(event,dragarg)return self:ondragmousemove(event,dragarg)end
function rtk.Widget:ondropfocus(event,source,dragarg)return false
end
function rtk.Widget:_handle_dropfocus(event,source,dragarg)return self:ondropfocus(event,source,dragarg)end
function rtk.Widget:ondropmousemove(event,source,dragarg)end
function rtk.Widget:_handle_dropmousemove(event,source,dragarg)return self:ondropmousemove(event,source,dragarg)end
function rtk.Widget:ondropblur(event,source,dragarg)end
function rtk.Widget:_handle_dropblur(event,source,dragarg)return self:ondropblur(event,source,dragarg)end
function rtk.Widget:ondrop(event,source,dragarg)return false
end
function rtk.Widget:_handle_drop(event,source,dragarg)return self:ondrop(event,source,dragarg)end
function rtk.Widget:onreflow()end
function rtk.Widget:_handle_reflow()return self:onreflow()end
function rtk.Widget:ondropfile(event)end
function rtk.Widget:_handle_dropfile(event)return self:ondropfile(event)end
end)()

__mod_rtk_viewport=(function()
local rtk=__mod_rtk_core
rtk.Viewport=rtk.class('rtk.Viewport', rtk.Widget)rtk.Viewport.static.SCROLLBAR_NEVER=0
rtk.Viewport.static.SCROLLBAR_HOVER=1
rtk.Viewport.static.SCROLLBAR_ALWAYS=2
rtk.Viewport.register{[1]=rtk.Attribute{alias='child'},child=rtk.Attribute{reflow=rtk.Widget.REFLOW_FULL},scroll_left=rtk.Attribute{default=0,reflow=rtk.Widget.REFLOW_NONE,calculate=function(self,attr,value,target)return math.round(value)end,},scroll_top=rtk.Reference('scroll_left'),smoothscroll=rtk.Attribute{reflow=rtk.Widget.REFLOW_NONE},scrollbar_size=15,vscrollbar=rtk.Attribute{default=rtk.Viewport.SCROLLBAR_HOVER,calculate={never=rtk.Viewport.SCROLLBAR_NEVER,always=rtk.Viewport.SCROLLBAR_ALWAYS,hover=rtk.Viewport.SCROLLBAR_HOVER,},},vscrollbar_offset=rtk.Attribute{default=0,reflow=rtk.Widget.REFLOW_NONE,},vscrollbar_gutter=25,hscrollbar=rtk.Attribute{default=rtk.Viewport.SCROLLBAR_NEVER,calculate=rtk.Reference('vscrollbar'),},hscrollbar_offset=0,hscrollbar_gutter=25,flexw=false,flexh=true,shadow=nil,elevation=20,show_scrollbar_on_drag=false,touch_activate_delay=0,}function rtk.Viewport:initialize(attrs,...)rtk.Widget.initialize(self,attrs,self.class.attributes.defaults,...)self:_handle_attr('child', self.calc.child, nil, true)self:_handle_attr('bg', self.calc.bg)self._backingstore=nil
self._needs_clamping=false
self._last_draw_scroll_left=nil
self._last_draw_scroll_top=nil
self._vscrollx=0
self._vscrolly=0
self._vscrollh=0
self._vscrolla={current=self.calc.vscrollbar==rtk.Viewport.SCROLLBAR_ALWAYS and 0.1 or 0,target=0,delta=0.05
}self._vscroll_in_gutter=false
end
function rtk.Viewport:_handle_attr(attr,value,oldval,trigger,reflow,sync)local ok=rtk.Widget._handle_attr(self,attr,value,oldval,trigger,reflow,sync)if ok==false then
return ok
end
if attr=='child' then
if oldval then
oldval:_unrealize()oldval.viewport=nil
oldval.parent=nil
oldval.window=nil
self:_sync_child_refs(oldval, 'remove')end
if value then
value.viewport=self
value.parent=self
value.window=self.window
self:_sync_child_refs(value, 'add')end
elseif attr=='bg' then
value=value or rtk.theme.bg
local luma=rtk.color.luma(value)local offset=math.max(0,1-(1.5-3*luma)^2)self._scrollbar_alpha_proximity=0.19*(1+offset^0.2)self._scrollbar_alpha_hover=0.44*(1+offset^0.4)self._scrollbar_color=luma < 0.5 and '#ffffff' or '#000000'elseif attr=='shadow' then
self._shadow=nil
elseif attr == 'scroll_top' or attr == 'scroll_left' then
self._needs_clamping=true
end
return true
end
function rtk.Viewport:_sync_child_refs(child,action)return rtk.Container._sync_child_refs(self,child,action)end
function rtk.Viewport:_reflow(boxx,boxy,boxw,boxh,fillw,fillh,clampw,clamph,uiscale,viewport,window)local calc=self.calc
calc.x,calc.y=self:_get_box_pos(boxx,boxy)local w,h,tp,rp,bp,lp=self:_get_content_size(boxw,boxh,fillw,fillh,clampw,clamph)local hpadding=lp+rp
local vpadding=tp+bp
local inner_maxw=w or(boxw-hpadding)local inner_maxh=h or(boxh-vpadding)local scrollw,scrollh=0,0
if calc.vscrollbar==rtk.Viewport.SCROLLBAR_ALWAYS then
scrollw=calc.scrollbar_size*rtk.scale.value
inner_maxw=inner_maxw-scrollw
end
if calc.hscrollbar==rtk.Viewport.SCROLLBAR_ALWAYS then
scrollh=calc.scrollbar_size*rtk.scale.value
inner_maxh=inner_maxh-scrollh
end
local child=calc.child
local innerw,innerh
local hmargin,vmargin
local ccalc
if child and child.visible==true then
ccalc=child.calc
hmargin=ccalc.lmargin+ccalc.rmargin
vmargin=ccalc.tmargin+ccalc.bmargin
inner_maxw=inner_maxw-hmargin
inner_maxh=inner_maxh-vmargin
local wx,wy,ww,wh=child:reflow(0,0,inner_maxw,inner_maxh,false,false,not calc.flexw,not calc.flexh,uiscale,self,window
)if calc.halign==rtk.Widget.CENTER then
wx=wx+math.max(0,inner_maxw-ccalc.w)/2
elseif calc.halign==rtk.Widget.RIGHT then
wx=wx+math.max(0,(inner_maxw-ccalc.w)-rp)end
if calc.valign==rtk.Widget.CENTER then
wy=wy+math.max(0,inner_maxh-ccalc.h)/2
elseif calc.valign==rtk.Widget.BOTTOM then
wy=wy+math.max(0,(inner_maxh-ccalc.h)-bp)end
ccalc.x=wx
ccalc.y=wy
child:_realize_geometry()innerw=math.ceil(rtk.clamp(ww+wx,fillw and inner_maxw,inner_maxw))innerh=math.ceil(rtk.clamp(wh+wy,fillh and inner_maxh,inner_maxh))else
innerw,innerh=inner_maxw,inner_maxh
hmargin,vmargin=0,0
end
calc.w=(w or(innerw+scrollw+hmargin))+hpadding
calc.h=(h or(innerh+scrollh+vmargin))+vpadding
if not self._backingstore then
self._backingstore=rtk.Image(innerw,innerh)else
self._backingstore:resize(innerw,innerh,false)end
self._vscrollh=0
self._needs_clamping=true
if ccalc then
self._scroll_clamp_left=math.max(0,ccalc.w-calc.w+lp+rp+ccalc.lmargin+ccalc.rmargin)self._scroll_clamp_top=math.max(0,ccalc.h-calc.h+tp+bp+ccalc.tmargin+ccalc.bmargin)end
end
function rtk.Viewport:_realize_geometry()local calc=self.calc
local tp,rp,bp,lp=self:_get_padding_and_border()if self.child then
local innerh=self._backingstore.h
local ch=self.child.calc.h
if calc.vscrollbar~=rtk.Viewport.SCROLLBAR_NEVER and ch>innerh then
self._vscrollx=calc.x+calc.w-calc.scrollbar_size*rtk.scale.value-calc.vscrollbar_offset
self._vscrolly=calc.y+calc.h*calc.scroll_top/ch+tp
self._vscrollh=calc.h*innerh/ch
end
end
if self.shadow then
if not self._shadow then
self._shadow=rtk.Shadow(calc.shadow)end
self._shadow:set_rectangle(calc.w,calc.h,calc.elevation)end
self._pre={tp=tp,rp=rp,bp=bp,lp=lp}end
function rtk.Viewport:_unrealize()self._backingstore=nil
if self.child then
self.child:_unrealize()end
end
function rtk.Viewport:_draw(offx,offy,alpha,event,clipw,cliph,cltargetx,cltargety,parentx,parenty)rtk.Widget._draw(self,offx,offy,alpha,event,clipw,cliph,cltargetx,cltargety,parentx,parenty)local calc=self.calc
local pre=self._pre
self.cltargetx=cltargetx
self.cltargety=cltargety
local x=calc.x+offx+pre.lp
local y=calc.y+offy+pre.tp
local lastleft,lasttop
local scrolled=calc.scroll_left~=self._last_draw_scroll_left or
calc.scroll_top~=self._last_draw_scroll_top
if scrolled then
lastleft,lasttop=self._last_draw_scroll_left or 0,self._last_draw_scroll_top or 0
if self:onscrollpre(lastleft,lasttop,event)==false then
calc.scroll_left=lastleft or 0
calc.scroll_top=lasttop
scrolled=false
else
self._last_draw_scroll_left=calc.scroll_left
self._last_draw_scroll_top=calc.scroll_top
end
end
if y+calc.h<0 or y>cliph or calc.ghost then
return false
end
self:_handle_drawpre(offx,offy,alpha,event)self:_draw_bg(offx,offy,1.0,event)local child=calc.child
if child and child.realized then
self:_clamp()x=x+child.calc.lmargin
y=y+child.calc.tmargin
self._backingstore:blit{src=gfx.dest,sx=x,sy=y,mode=rtk.Image.FAST_BLIT}self._backingstore:pushdest()child:_draw(-calc.scroll_left,-calc.scroll_top,1.0,event,calc.w,calc.h,cltargetx+x,cltargety+y,0,0
)child:_draw_debug_box(-calc.scroll_left,-calc.scroll_top,event)self._backingstore:popdest()self._backingstore:blit{dx=x,dy=y,alpha=alpha*calc.alpha}self:_draw_scrollbars(offx,offy,cltargetx,cltargety,alpha*calc.alpha,event)end
if calc.shadow then
self._shadow:draw(calc.x+offx,calc.y+offy,alpha*calc.alpha)end
self:_draw_borders(offx,offy,alpha)if scrolled then
self:onscroll(lastleft,lasttop,event)end
self:_handle_draw(offx,offy,alpha,event)end
function rtk.Viewport:_draw_scrollbars(offx,offy,cltargetx,cltargety,alpha,event)local calc=self.calc
local animate=self._vscrolla.current~=self._vscrolla.target
if calc.vscrollbar==rtk.Viewport.SCROLLBAR_ALWAYS or
(calc.vscrollbar==rtk.Viewport.SCROLLBAR_HOVER and self._vscrollh>0 and
((not rtk.dnd.dragging and self._vscroll_in_gutter)or animate or self._vscrolla.target>0))then
local scrx=offx+self._vscrollx
local scry=offy+calc.y+calc.h*calc.scroll_top/self.child.calc.h
local should_handle_hovering=rtk.point_in_box(event.x,event.y,scrx+cltargetx,scry+cltargety,calc.scrollbar_size*rtk.scale.value,self._vscrollh
)if(should_handle_hovering and self._vscroll_in_gutter)or rtk.dnd.dragging==self then
self._vscrolla.target=self._scrollbar_alpha_hover
self._vscrolla.delta=0.1
elseif self._vscroll_in_gutter or calc.vscrollbar==rtk.Viewport.SCROLLBAR_ALWAYS then
self._vscrolla.target=self._scrollbar_alpha_proximity
self._vscrolla.delta=0.1
end
if animate then
local newval
if self._vscrolla.current<self._vscrolla.target then
newval=math.min(self._vscrolla.current+self._vscrolla.delta,self._vscrolla.target)else
newval=math.max(self._vscrolla.current-self._vscrolla.delta,self._vscrolla.target)end
self._vscrolla.current=newval
self:queue_draw()end
self:setcolor(self._scrollbar_color)gfx.a=self._vscrolla.current*alpha
gfx.rect(scrx,scry,calc.scrollbar_size*rtk.scale.value,self._vscrollh+1,1)end
end
function rtk.Viewport:_handle_event(clparentx,clparenty,event,clipped,listen)local calc=self.calc
local pre=self._pre
listen=self:_should_handle_event(listen)local x=calc.x+clparentx
local y=calc.y+clparenty
local hovering=rtk.point_in_box(event.x,event.y,x,y,calc.w,calc.h)local dragging=rtk.dnd.dragging
local is_child_dragging=dragging and dragging.viewport==self
local child=self.child
if event.type==rtk.Event.MOUSEMOVE then
local vscroll_in_gutter=false
if listen and is_child_dragging and dragging.scroll_on_drag then
if event.y-20<y then
self:scrollby(0,-math.max(5,math.abs(y-event.y)),false)elseif event.y+20>y+calc.h then
self:scrollby(0,math.max(5,math.abs(y+calc.h-event.y)),false)end
if dragging.show_scrollbar_on_drag then
self._vscrolla.target=self._scrollbar_alpha_proximity
self._vscrolla.delta=0.03
end
elseif listen and not dragging and not event.handled and hovering then
if calc.vscrollbar~=rtk.Viewport.SCROLLBAR_NEVER and self._vscrollh>0 then
local gutterx=self._vscrollx+clparentx-calc.vscrollbar_gutter
local guttery=calc.y+clparenty
if rtk.point_in_box(event.x,event.y,gutterx,guttery,calc.vscrollbar_gutter+calc.scrollbar_size*rtk.scale.value,calc.h)then
vscroll_in_gutter=true
if event.x>=self._vscrollx+clparentx then
event:set_handled(self)end
self:queue_draw()end
end
end
if vscroll_in_gutter~=self._vscroll_in_gutter or self._vscrolla.current>0 then
self._vscroll_in_gutter=vscroll_in_gutter
if calc.vscrollbar==rtk.Viewport.SCROLLBAR_HOVER then
if not vscroll_in_gutter and not is_child_dragging then
self._vscrolla.target=0
self._vscrolla.delta=0.02
end
self:queue_draw()end
end
elseif listen and not event.handled and event.type==rtk.Event.MOUSEDOWN then
if not self:cancel_animation('scroll_top') then
self:_reset_touch_scroll()end
if self._vscroll_in_gutter and event.x>=self._vscrollx+clparentx then
local scrolly=self:_get_vscrollbar_client_pos()if event.y<scrolly or event.y>scrolly+self._vscrollh then
self:_handle_scrollbar(event,nil,self._vscrollh/2,true)end
event:set_handled(self)end
end
if(not event.handled or event.type==rtk.Event.MOUSEMOVE)and
not(event.type==rtk.Event.MOUSEMOVE and self.window:_is_touch_scrolling(self))and
self.child and self.child.visible and self.child.realized then
self:_clamp()self.child:_handle_event(x-calc.scroll_left+pre.lp+child.calc.lmargin,y-calc.scroll_top+pre.tp+child.calc.tmargin,event,clipped or not hovering,listen
)end
if listen and hovering and not event.handled and event.type==rtk.Event.MOUSEWHEEL then
if self.child and self._vscrollh>0 and event.wheel~=0 then
local distance=event.wheel*math.min(calc.h/2,120)self:scrollby(0,distance)event:set_handled(self)end
end
rtk.Widget._handle_event(self,clparentx,clparenty,event,clipped,listen)end
function rtk.Viewport:_get_vscrollbar_client_pos()local calc=self.calc
return self.clienty+calc.h*calc.scroll_top/self.child.calc.h
end
function rtk.Viewport:_handle_scrollbar(event,hoffset,voffset,gutteronly,natural)local calc=self.calc
local pre=self._pre
if voffset~=nil then
self:cancel_animation('scroll_top')if gutteronly then
local ssy=self:_get_vscrollbar_client_pos()if event.y>=ssy and event.y<=ssy+self._vscrollh then
return false
end
end
local innerh=calc.h-pre.tp-pre.bp
local target
if natural then
target=calc.scroll_top+(voffset-event.y)else
local pct=rtk.clamp(event.y-self.clienty-voffset,0,innerh)/innerh
target=pct*(self.child.calc.h)end
self:scrollto(calc.scroll_left,target,false)end
end
function rtk.Viewport:_handle_dragstart(event,x,y,t)local draggable,droppable=self:ondragstart(self,event,x,y,t)if draggable~=nil then
return draggable,droppable
end
if math.abs(y-event.y)>0 then
if self._vscroll_in_gutter and event.x>=self._vscrollx+self.offx+self.cltargetx then
return {true,y-self:_get_vscrollbar_client_pos(),nil,false},false
elseif rtk.touchscroll and event.buttons&rtk.mouse.BUTTON_LEFT~=0 and self._vscrollh>0 then
self.window:_set_touch_scrolling(self,true)return {true,y,{{x,y,t}},true},false
end
end
return false,false
end
function rtk.Viewport:_handle_dragmousemove(event,arg)local ok=rtk.Widget._handle_dragmousemove(self,event)if ok==false or event.simulated then
return ok
end
local vscrollbar,lasty,samples,natural=table.unpack(arg)if vscrollbar then
self:_handle_scrollbar(event,nil,lasty,false,natural)if natural then
arg[2]=event.y
samples[#samples+1]={event.x,event.y,event.time}end
self.window:request_mouse_cursor(rtk.mouse.cursors.POINTER,true)end
return true
end
function rtk.Viewport:_reset_touch_scroll()if self.window then
self.window:_set_touch_scrolling(self,false)end
end
function rtk.Viewport:_handle_dragend(event,arg)local ok=rtk.Widget._handle_dragend(self,event)if ok==false then
return ok
end
local vscrollbar,lasty,samples,natural=table.unpack(arg)if natural then
local now=event.time
local x1,y1,t1=event.x,event.y,event.time
for i=#samples,1,-1 do
local x,y,t=table.unpack(samples[i])if now-t>0.2 then
break
end
x1,y1,t1=x,y,t
end
local v=0
if t1~=event.time then
v=(event.y-y1)-(event.time-t1)end
local distance=v*rtk.scale.value
local x,y=self:_get_clamped_scroll(self.calc.scroll_left,self.calc.scroll_top-distance)local duration=1
self:animate{attr='scroll_top', dst=y, duration=duration, easing='out-cubic'}:done(function()self:_reset_touch_scroll()end):cancelled(function()self:_reset_touch_scroll()end)end
self:queue_draw()event:set_handled(self)return true
end
function rtk.Viewport:_scrollto(x,y,smooth,animx,animy)local calc=self.calc
if not smooth or not self.realized then
x=x or self.scroll_left
y=y or self.scroll_top
if x==calc.scroll_left and y==calc.scroll_top then
return
end
self._needs_clamping=true
calc.scroll_left=x
calc.scroll_top=y
self.scroll_left=calc.scroll_left
self.scroll_top=calc.scroll_top
self:queue_draw()else
x,y=self:_get_clamped_scroll(x or calc.scroll_left,y or calc.scroll_top)animx=animx or self:get_animation('scroll_left')animy=animy or self:get_animation('scroll_top')if calc.scroll_left~=x and(not animx or animx.dst~=x)then
self:animate{attr='scroll_left', dst=x, duration=0.15}end
if calc.scroll_top~=y and(not animy or animy.dst~=y)then
self:animate{attr='scroll_top', dst=y, duration=0.2, easing='out-sine'}end
end
end
function rtk.Viewport:_get_smoothscroll(override)if override~=nil then
return override
end
local calc=self.calc
if calc.smoothscroll~=nil then
return calc.smoothscroll
end
return rtk.smoothscroll
end
function rtk.Viewport:scrollto(x,y,smooth)self:_scrollto(x,y,self:_get_smoothscroll(smooth))end
function rtk.Viewport:scrollby(offx,offy,smooth)local calc=self.calc
local x,y,animx,animy
smooth=self:_get_smoothscroll(smooth)if smooth then
animx=self:get_animation('scroll_left')animy=self:get_animation('scroll_top')x=(animx and animx.dst or calc.scroll_left)+(offx or 0)y=(animy and animy.dst or calc.scroll_top)+(offy or 0)else
x=calc.scroll_left+(offx or 0)y=calc.scroll_top+(offy or 0)end
self:_scrollto(x,y,smooth,animx,animy)end
function rtk.Viewport:scrollable()if not self.child then
return false
end
local vcalc=self.calc
local ccalc=self.child.calc
return ccalc.w>vcalc.w or ccalc.h>vcalc.h
end
function rtk.Viewport:_get_clamped_scroll(left,top)return rtk.clamp(left,0,self._scroll_clamp_left),rtk.clamp(top,0,self._scroll_clamp_top)end
function rtk.Viewport:_clamp()if self._needs_clamping then
local calc=self.calc
calc.scroll_left,calc.scroll_top=self:_get_clamped_scroll(self.scroll_left,self.scroll_top)self.scroll_left,self.scroll_top=calc.scroll_left,calc.scroll_top
self._needs_clamping=false
end
end
function rtk.Viewport:onscrollpre(last_left,last_top,event)end
function rtk.Viewport:onscroll(last_left,last_top,event)end
end)()

__mod_rtk_popup=(function()
local rtk=__mod_rtk_core
rtk.Popup=rtk.class('rtk.Popup', rtk.Viewport)rtk.Popup.register{anchor=rtk.Attribute{reflow=rtk.Widget.REFLOW_FULL},margin=rtk.Attribute{default=20,reflow=rtk.Widget.REFLOW_FULL,},width_from_anchor=rtk.Attribute{default=true,reflow=rtk.Widget.REFLOW_FULL,},overlay=rtk.Reference('bg'),autoclose=true,opened=false,bg=rtk.Attribute{default=function(self,attr)return rtk.theme.popup_bg or {rtk.color.mod(rtk.theme.bg,1,1,rtk.theme.popup_bg_brightness,0.96)}end,},border=rtk.Attribute{default=function(self,attr)return rtk.theme.popup_border
end,},shadow=rtk.Attribute{default=function()return rtk.theme.popup_shadow
end,},visible=false,elevation=35,padding=10,z=1000,}function rtk.Popup:initialize(attrs,...)rtk.Viewport.initialize(self,attrs,self.class.attributes.defaults,...)end
function rtk.Popup:_handle_event(clparentx,clparenty,event,clipped,listen)rtk.Viewport._handle_event(self,clparentx,clparenty,event,clipped,listen)if event.type==rtk._touch_activate_event and self.mouseover then
event:set_handled(self)end
end
function rtk.Popup:_reflow(boxx,boxy,boxw,boxh,fillw,fillh,clampw,clamph,rescale,viewport,window)local calc=self.calc
local anchor=calc.anchor
if anchor then
y=anchor.clienty
if y<window.h/2 then
y=y+anchor.calc.h
boxh=math.floor(math.min(boxh,window.h-y-calc.bmargin))else
boxh=math.floor(math.min(boxh,y-calc.tmargin))end
if self.width_from_anchor then
self.w=math.floor(anchor.calc.w)end
end
rtk.Viewport._reflow(self,boxx,boxy,boxw,boxh,fillw,fillh,clampw,clamph,rescale,viewport,window)if anchor then
self._realize_on_draw=true
end
end
function rtk.Popup:_realize_geometry()local calc=self.calc
local anchor=calc.anchor
local st,sb=calc.elevation,calc.elevation
if anchor and anchor.realized then
calc.x=anchor.clientx
if anchor.clienty+anchor.calc.h+calc.h<self.window.calc.h then
calc.y=anchor.clienty+anchor.calc.h
if calc.width_from_anchor then
calc.tborder=nil
calc.bborder=calc.rborder
calc.border_uniform=false
end
st=5
else
calc.y=anchor.clienty-calc.h
if calc.width_from_anchor then
calc.tborder=calc.rborder
calc.bborder=nil
calc.border_uniform=false
end
sb=5
end
end
rtk.Viewport._realize_geometry(self)self._shadow:set_rectangle(calc.w,calc.h,nil,st,calc.elevation,sb,calc.elevation)end
function rtk.Popup:_draw(offx,offy,alpha,event,clipw,cliph,cltargetx,cltargety,parentx,parenty)if self.calc.overlay then
self:setcolor(self.calc.overlay,alpha)gfx.rect(0,0,self.window.calc.w,self.window.calc.h,1)end
if self._realize_on_draw then
self:_realize_geometry()self._realize_on_draw=false
end
rtk.Viewport._draw(self,offx,offy,alpha,event,clipw,cliph,cltargetx,cltargety,parentx,parenty)end
function rtk.Popup:_release_modal()if self.calc.autoclose then
self:close()end
end
function rtk.Popup:open(attrs)local calc=self.calc
local anchor=calc.anchor
self.closed=false
if not attrs and not anchor then
attrs = {valign='center', halign='center'}end
if calc.visible and not self:get_animation('alpha') then
return self
end
rtk.reset_modal()if not self.parent then
local window=(anchor and anchor.window)or(attrs and attrs.window)or rtk.window
assert(window, 'no rtk.Window has been created or explicitly passed to open()')window:add(self,attrs)rtk.defer(self._open,self)else
self:_open()end
return self
end
function rtk.Popup:_open()local anchor=self.calc.anchor
if self:get_animation('alpha') then
self:cancel_animation('alpha')self:attr('alpha', 1)elseif anchor and not anchor.realized then
return
end
rtk.add_modal(self,anchor)self:show()self:focus()self:scrollto(0,0)end
function rtk.Popup:close()if not self.calc.visible or self.closed then
return
end
self.closed=true
self:animate{attr='alpha', dst=0, duration=0.15}:done(function()self:hide()self:attr('alpha', 1)self.window:remove(self)end)rtk.reset_modal()end
end)()

__mod_rtk_container=(function()
local rtk=__mod_rtk_core
rtk.Container=rtk.class('rtk.Container', rtk.Widget)rtk.Container.register{fillw=nil,fillh=nil,halign=nil,valign=nil,padding=nil,tpadding=nil,rpadding=nil,bpadding=nil,lpadding=nil,minw=nil,minh=nil,maxw=nil,maxh=nil,bg=nil,z=nil,children=nil,}function rtk.Container:initialize(attrs,...)self.children={}self._child_index_by_id=nil
self._reflowed_children={}self._z_indexes={}rtk.Widget.initialize(self,attrs,self.class.attributes.defaults,...)if attrs and #attrs>0 then
for i=1,#attrs do
local w=attrs[i]
self:add(w)end
end
end
function rtk.Container:_handle_mouseenter(event)local ret=self:onmouseenter(event)if ret~=false then
if self.bg or self.autofocus then
return true
end
end
return ret
end
function rtk.Container:_handle_mousemove(event)local ret=rtk.Widget._handle_mousemove(self,event)if ret~=false and self.hovering then
event:set_handled(self)return true
end
return ret
end
function rtk.Container:_draw_debug_box(offx,offy,event)if not rtk.Widget._draw_debug_box(self,offx,offy,event)then
return
end
gfx.set(1,1,1,1)for i=1,#self.children do
local widget,attrs=table.unpack(self.children[i])local cb=attrs._cellbox
if cb and widget.visible then
gfx.rect(offx+self.calc.x+cb[1],offy+self.calc.y+cb[2],cb[3],cb[4],0)end
end
end
function rtk.Container:_sync_child_refs(child,action)if child.refs and not child.refs.__empty then
if action=='add' then
local w=self
while w do
table.merge(w.refs,child.refs)w=w.parent
end
else
for k in pairs(child.refs)do
self.refs[k]=nil
end
end
end
end
function rtk.Container:_validate_child(child)assert(rtk.isa(child, rtk.Widget), 'object being added to container is not subclassed from rtk.Widget')end
function rtk.Container:_reparent_child(child)self:_validate_child(child)if child.parent and child.parent~=self then
child.parent:remove(child)end
child.parent=self
child.window=self.window
self:_sync_child_refs(child, 'add')end
function rtk.Container:_unparent_child(pos)local child=self.children[pos][1]
if child then
if child.visible then
child:_unrealize()end
child.parent=nil
child.window=nil
self:_sync_child_refs(child, 'remove')return child
end
end
function rtk.Container:add(widget,attrs)self:_reparent_child(widget)self.children[#self.children+1]={widget,self:_calc_cell_attrs(widget,attrs)}self._child_index_by_id=nil
self:queue_reflow(rtk.Widget.REFLOW_FULL)return widget
end
function rtk.Container:update(widget,attrs,merge)local n=self:get_child_index(widget)assert(n, 'Widget not found in container')attrs=self:_calc_cell_attrs(widget,attrs)if merge then
local cellattrs=self.children[n][2]
table.merge(cellattrs,attrs)else
self.children[n][2]=attrs
end
self:queue_reflow(rtk.Widget.REFLOW_FULL)end
function rtk.Container:insert(pos,widget,attrs)self:_reparent_child(widget)table.insert(self.children,pos,{widget,self:_calc_cell_attrs(widget,attrs)})self._child_index_by_id=nil
self:queue_reflow(rtk.Widget.REFLOW_FULL)end
function rtk.Container:replace(index,widget,attrs)if index<=0 or index>#self.children then
return
end
local prev=self:_unparent_child(index)self:_reparent_child(widget)self.children[index]={widget,self:_calc_cell_attrs(widget,attrs)}self._child_index_by_id=nil
self:queue_reflow(rtk.Widget.REFLOW_FULL)return prev
end
function rtk.Container:remove_index(index)if index<=0 or index>#self.children then
return
end
local child=self:_unparent_child(index)table.remove(self.children,index)self._child_index_by_id=nil
self:queue_reflow(rtk.Widget.REFLOW_FULL)return child
end
function rtk.Container:remove(widget)local n=self:get_child_index(widget)if n~=nil then
self:remove_index(n)return n
end
end
function rtk.Container:remove_all()for i=1,#self.children do
local widget=self.children[i][1]
if widget and widget.visible then
widget:_unrealize()end
end
self.children={}self._child_index_by_id=nil
self:queue_reflow(rtk.Widget.REFLOW_FULL)end
function rtk.Container:_calc_cell_attrs(widget,attrs)attrs=attrs or widget.cell
if not attrs then
return {}end
local keys=table.keys(attrs)local calculated={}for n=1,#keys do
local k=keys[n]
calculated[k]=self:_calc_attr(k, attrs[k], attrs, nil, 'cell', widget)end
return calculated
end
function rtk.Container:reorder(widget,targetidx)local srcidx=self:get_child_index(widget)if srcidx~=nil and srcidx~=targetidx and(targetidx<=srcidx or targetidx-1~=srcidx)then
local widgetattrs=table.remove(self.children,srcidx)local org=targetidx
if targetidx>srcidx then
targetidx=targetidx-1
end
table.insert(self.children,rtk.clamp(targetidx,1,#self.children+1),widgetattrs)self._child_index_by_id=nil
self:queue_reflow(rtk.Widget.REFLOW_FULL)return true
else
return false
end
end
function rtk.Container:reorder_before(widget,target)local targetidx=self:get_child_index(target)return self:reorder(widget,targetidx)end
function rtk.Container:reorder_after(widget,target)local targetidx=self:get_child_index(target)return self:reorder(widget,targetidx+1)end
function rtk.Container:get_child(idx)if idx<0 then
idx=#self.children+idx+1
end
local child=self.children[idx]
if child then
return child[1]
end
end
function rtk.Container:get_child_index(widget)if not self._child_index_by_id then
local cache={}for i=1,#self.children do
local widgetattrs=self.children[i]
if widgetattrs and widgetattrs[1].id then
cache[widgetattrs[1].id]=i
end
end
self._child_index_by_id=cache
end
return self._child_index_by_id[widget.id]
end
function rtk.Container:_handle_event(clparentx,clparenty,event,clipped,listen)local calc=self.calc
local x=calc.x+clparentx
local y=calc.y+clparenty
self.clientx,self.clienty=x,y
listen=self:_should_handle_event(listen)if y+calc.h<0 or y>self.window.calc.h or calc.ghost then
return false
end
local zs=self._z_indexes
for zidx=#zs,1,-1 do
local zchildren=self._reflowed_children[zs[zidx]]
local nzchildren=zchildren and #zchildren or 0
for cidx=nzchildren,1,-1 do
local widget,attrs=table.unpack(zchildren[cidx])if widget and widget.realized and widget.parent then
if widget.calc.position&rtk.Widget.POSITION_FIXED~=0 and self.viewport then
local vcalc=self.viewport.calc
widget:_handle_event(x+vcalc.scroll_left,y+vcalc.scroll_top,event,clipped,listen)else
widget:_handle_event(x,y,event,clipped,listen)end
end
end
end
rtk.Widget._handle_event(self,clparentx,clparenty,event,clipped,listen)end
function rtk.Container:_add_reflowed_child(widgetattrs,z)local z_children=self._reflowed_children[z]
if z_children then
z_children[#z_children+1]=widgetattrs
else
self._reflowed_children[z]={widgetattrs}end
end
function rtk.Container:_determine_zorders()local zs={}for z in pairs(self._reflowed_children)do
zs[#zs+1]=z
end
table.sort(zs)self._z_indexes=zs
end
function rtk.Container:_get_cell_padding(widget,attrs)local calc=widget.calc
local scale=rtk.scale.value
return
((attrs.tpadding or 0)+(calc.tmargin or 0))*scale,((attrs.rpadding or 0)+(calc.rmargin or 0))*scale,((attrs.bpadding or 0)+(calc.bmargin or 0))*scale,((attrs.lpadding or 0)+(calc.lmargin or 0))*scale
end
function rtk.Container:_set_cell_box(attrs,x,y,w,h)attrs._cellbox={math.round(x),math.round(y),math.round(w),math.round(h)}end
function rtk.Container:_reflow(boxx,boxy,boxw,boxh,fillw,fillh,clampw,clamph,uiscale,viewport,window)local calc=self.calc
local x,y=self:_get_box_pos(boxx,boxy)local w,h,tp,rp,bp,lp=self:_get_content_size(boxw,boxh,fillw,fillh,clampw,clamph,nil)local inner_maxw=w or(boxw-lp-rp)local inner_maxh=h or(boxh-tp-bp)local innerw=w or 0
local innerh=h or 0
clampw=clampw or w~=nil or fillw
clamph=clamph or h~=nil or fillh
self._reflowed_children={}self._child_index_by_id={}for n,widgetattrs in ipairs(self.children)do
local widget,attrs=table.unpack(widgetattrs)local wcalc=widget.calc
attrs._cellbox=nil
self._child_index_by_id[widget.id]=n
if widget.visible==true then
local ctp,crp,cbp,clp=self:_get_cell_padding(widget,attrs)local wx,wy,ww,wh=widget:reflow(0,0,rtk.clamprel(inner_maxw-widget.x-clp-crp,attrs.minw or wcalc.minw,attrs.maxw or wcalc.maxw),rtk.clamprel(inner_maxh-widget.y-ctp-cbp,attrs.minh or wcalc.minh,attrs.maxh or wcalc.maxh),attrs.fillw,attrs.fillh,clampw or attrs.maxw~=nil,clamph or attrs.maxh~=nil,uiscale,viewport,window
)ww=math.max(ww,attrs.minw or wcalc.minw or 0)wh=math.max(wh,attrs.minh or wcalc.minh or 0)attrs._halign=attrs.halign or calc.halign
attrs._valign=attrs.valign or calc.valign
if not attrs._halign or attrs._halign==rtk.Widget.LEFT then
wx=lp+clp
elseif attrs._halign==rtk.Widget.CENTER then
wx=lp+clp+math.max(0,(math.min(innerw,inner_maxw)-ww-clp-crp)/2)else
wx=lp+math.max(0,math.min(innerw,inner_maxw)-ww-crp)end
if not attrs._valign or attrs._valign==rtk.Widget.TOP then
wy=tp+ctp
elseif attrs._valign==rtk.Widget.CENTER then
wy=tp+ctp+math.max(0,(math.min(innerh,inner_maxh)-wh-ctp-cbp)/2)else
wy=tp+math.max(0,math.min(innerh,inner_maxh)-wh-cbp)end
wcalc.x=wcalc.x+wx
widget.box[1]=wx
wcalc.y=wcalc.y+wy
widget.box[2]=wy
self:_set_cell_box(attrs,wcalc.x,wcalc.y,ww+clp+crp,wh+ctp+cbp)widget:_realize_geometry()innerw=math.max(innerw,wcalc.x+ww-lp+crp)innerh=math.max(innerh,wcalc.y+wh-tp+cbp)self:_add_reflowed_child(widgetattrs,attrs.z or wcalc.z or 0)else
widget.realized=false
end
end
self:_determine_zorders()calc.x=x
calc.y=y
calc.w=(w or innerw)+lp+rp
calc.h=(h or innerh)+tp+bp
end
function rtk.Container:_draw(offx,offy,alpha,event,clipw,cliph,cltargetx,cltargety,parentx,parenty)local calc=self.calc
rtk.Widget._draw(self,offx,offy,alpha,event,clipw,cliph,cltargetx,cltargety,parentx,parenty)local x,y=calc.x+offx,calc.y+offy
if y+calc.h<0 or y>cliph or calc.ghost then
return false
end
local wpx=parentx+calc.x
local wpy=parenty+calc.y
self:_handle_drawpre(offx,offy,alpha,event)self:_draw_bg(offx,offy,alpha,event)local child_alpha=alpha*self.alpha
for _,z in ipairs(self._z_indexes)do
for _,widgetattrs in ipairs(self._reflowed_children[z])do
local widget,attrs=table.unpack(widgetattrs)if attrs.bg and attrs._cellbox then
local cb=attrs._cellbox
self:setcolor(attrs.bg,child_alpha)gfx.rect(x+cb[1],y+cb[2],cb[3],cb[4],1)end
if widget and widget.realized then
local wx,wy=x,y
if widget.calc.position&rtk.Widget.POSITION_FIXED~=0 then
wx,wy=wpx,wpy
end
widget:_draw(wx,wy,child_alpha,event,clipw,cliph,cltargetx,cltargety,wpx,wpy)widget:_draw_debug_box(wx,wy,event)end
end
end
self:_draw_borders(offx,offy,alpha)self:_handle_draw(offx,offy,alpha,event)end
function rtk.Container:_unrealize()rtk.Widget._unrealize(self)for i=1,#self.children do
local widget=self.children[i][1]
if widget and widget.realized then
widget:_unrealize()end
end
end
end)()

__mod_rtk_window=(function()
local rtk=__mod_rtk_core
local log=__mod_rtk_log
rtk.Window=rtk.class('rtk.Window', rtk.Container)rtk.Window.static.DOCK_BOTTOM=(function()return {0} end)()rtk.Window.static.DOCK_LEFT=(function()return {1} end)()rtk.Window.static.DOCK_TOP=(function()return {2} end)()rtk.Window.static.DOCK_RIGHT=(function()return {3} end)()rtk.Window.static.DOCK_FLOATING=(function()return {4} end)()function rtk.Window.static._make_icons()local w,h=12,12
local sz=2
local icon=rtk.Image(w,h)icon:pushdest()rtk.color.set(rtk.theme.dark and {1,1,1,1} or {0,0,0,1})for row=0,2 do
for col=0,2 do
local n=row*3+col
if n==2 or n>=4 then
gfx.rect(2*col*sz,2*row*sz,sz,sz,1)end
end
end
icon:popdest()rtk.Window.static._icon_resize_grip=icon
end
rtk.Window.register{x=rtk.Attribute{type='number',reflow=rtk.Widget.REFLOW_NONE,redraw=false,window_sync=true,},y=rtk.Attribute{type='number',reflow=rtk.Widget.REFLOW_NONE,redraw=false,window_sync=true,},w=rtk.Attribute{priority=true,type='number',window_sync=true,calculate=function(self,attr,value,target)return value and math.max(self.minw or 0,value)*rtk.scale.framebuffer
end,},h=rtk.Attribute{priority=true,window_sync=true,calculate=function(self,attr,value,target)return math.max(self.minh or 0,value or 0)*rtk.scale.framebuffer
end,},minw=rtk.Attribute{default=100,calculate=function(self,attr,value,target)return value and value*rtk.scale.framebuffer or 0
end,},minh=rtk.Attribute{default=30,calculate=rtk.Reference('minw'),},maxw=rtk.Attribute{default=800,calculate=function(self,attr,value,target)return value and value*rtk.scale.framebuffer
end,},maxh=rtk.Attribute{default=600,calculate=rtk.Reference('maxw'),},visible=rtk.Attribute{window_sync=true,},docked=rtk.Attribute{default=false,window_sync=true,reflow=rtk.Widget.REFLOW_NONE,},dock=rtk.Attribute{default=rtk.Window.DOCK_RIGHT,calculate={bottom=rtk.Window.DOCK_BOTTOM,left=rtk.Window.DOCK_LEFT,top=rtk.Window.DOCK_TOP,right=rtk.Window.DOCK_RIGHT,floating=rtk.Window.DOCK_FLOATING
},window_sync=true,reflow=rtk.Widget.REFLOW_NONE,},pinned=rtk.Attribute{default=false,window_sync=true,calculate=function(self,attr,value,target)return rtk.has_js_reascript_api and value
end,},borderless=rtk.Attribute{default=false,window_sync=true,calculate=rtk.Reference('pinned')},[1]=rtk.Attribute{alias='title'},title=rtk.Attribute{default='REAPER application',reflow=rtk.Widget.REFLOW_NONE,window_sync=true,redraw=false,},opacity=rtk.Attribute{default=1.0,reflow=rtk.Widget.REFLOW_NONE,window_sync=true,redraw=false,},resizable=rtk.Attribute{default=true,reflow=rtk.Widget.REFLOW_NONE,window_sync=true,},hwnd=nil,in_window=false,is_focused=not rtk.has_js_reascript_api and true or false,running=false,cursor=rtk.mouse.cursors.POINTER,scalability=rtk.Widget.BOX,}function rtk.Window:initialize(attrs,...)rtk.Container.initialize(self,attrs,self.class.attributes.defaults,...)rtk.window=self
self.window=self
if self.id==0 and self.calc.bg and rtk.theme.default then
rtk.set_theme_by_bgcolor(self.calc.bg)end
if rtk.Window.static._icon_resize_grip==nil then
rtk.Window._make_icons()end
if not rtk.has_js_reascript_api then
self:sync('borderless', false)self:sync('pinned', false)end
self._dockstate=0
self._backingstore=rtk.Image()self._event=rtk.Event()self._reflow_queued=false
self._reflow_widgets=nil
self._blits_queued=0
self._draw_queued=false
self._mouse_refresh_queued=false
self._sync_window_attrs_on_update=false
self._resize_grip=nil
self._move_grip=nil
self._os_window_frame_width=0
self._os_window_frame_height=0
self._undocked_geometry=nil
self._unmaximized_geometry=nil
self._last_mousemove_time=nil
self._last_mouseup_time=0
self._touch_scrolling={count=0}self._last_synced_attrs={}end
function rtk.Window:_handle_attr(attr,value,oldval,trigger,reflow,sync)local ok=rtk.Widget._handle_attr(self,attr,value,oldval,trigger,reflow,sync)if ok==false then
return ok
end
if attr=='bg' then
local color=rtk.color.int(value or rtk.theme.bg)gfx.clear=color
if rtk.has_js_reascript_api then
if self._gdi_brush then
reaper.JS_GDI_DeleteObject(self._gdi_brush)reaper.JS_GDI_DeleteObject(self._gdi_pen)else
reaper.atexit(function()reaper.JS_GDI_DeleteObject(self._gdi_brush)reaper.JS_GDI_DeleteObject(self._gdi_pen)end)end
color=rtk.color.flip_byte_order(color)self._gdi_brush=reaper.JS_GDI_CreateFillBrush(color)self._gdi_pen=reaper.JS_GDI_CreatePen(1,color)end
end
if self.class.attributes.get(attr).window_sync and not sync then
self._sync_window_attrs_on_update=true
end
return true
end
function rtk.Window:_get_dockstate_from_attrs()local calc=self.calc
local dock=calc.dock
if type(dock)=='table' then
dock=self:_get_docker_at_pos(dock[1])end
local dockstate=(dock or 0)<<8
if calc.docked and calc.docked~=0 then
dockstate=dockstate|1
end
return dockstate
end
function rtk.Window:_get_docker_at_pos(pos)if not reaper.DockGetPosition then
return 0
end
for i=1,20 do
if reaper.DockGetPosition(i)==pos then
return i
end
end
end
function rtk.Window:_clear_gdi(startw,starth)if not rtk.os.windows or not rtk.has_js_reascript_api or not self.hwnd then
return
end
local calc=self.calc
local dc=reaper.JS_GDI_GetWindowDC(self.hwnd)reaper.JS_GDI_SelectObject(dc,self._gdi_brush)reaper.JS_GDI_SelectObject(dc,self._gdi_pen)local x=0
local y=0
local r,w,h=reaper.JS_Window_GetClientSize(self.hwnd)if not startw then
reaper.JS_GDI_FillRect(dc,x,y,w*2,h*2)elseif w>startw or h>starth then
if not calc.docked and not calc.borderless then
startw=startw+self._os_window_frame_width
starth=starth+self._os_window_frame_height
end
reaper.JS_GDI_FillRect(dc,x+math.round(startw),y,w*2,h*2)reaper.JS_GDI_FillRect(dc,x,y+math.round(starth),w*2,h*2)end
reaper.JS_GDI_ReleaseDC(self.hwnd,dc)end
function rtk.Window:focus()if self.hwnd and rtk.has_js_reascript_api then
reaper.JS_Window_SetFocus(self.hwnd)self:queue_draw()return true
else
return false
end
end
function rtk.Window:_run()self:_update()if self.running then
rtk.defer(self._run,self)end
end
function rtk.Window:_get_display_resolution(working)local x=math.floor(self.x)local y=math.floor(self.y)local w=math.floor(x+(self.w or 1))local h=math.floor(y+(self.h or 1))local l,t,r,b=reaper.my_getViewport(0,0,0,0,x,y,w,h,working and 1 or 0)return l,t,r-l,math.abs(b-t)end
function rtk.Window:_get_geometry_from_attrs(overrides)local scale=rtk.scale.framebuffer or 1
local x=self.x
local y=self.y
local w=self.calc.w/scale
local h=self.calc.h/scale
if overrides then
local sx,sy,sw,sh=self:_get_display_resolution(true)if sw and sh then
if overrides.halign==rtk.Widget.LEFT then
x=sx
elseif overrides.halign==rtk.Widget.CENTER then
x=sx+(overrides.x or 0)+(sw-w)/2
elseif overrides.halign==rtk.Widget.RIGHT then
x=sx+(overrides.x or 0)+(sw-w)end
if rtk.os.mac then
if overrides.valign==rtk.Widget.TOP then
y=sy+(overrides.y or 0)+(sh-h)elseif overrides.valign==rtk.Widget.CENTER then
y=sy+(overrides.y or 0)+(sh-h)/2
elseif overrides.valign==rtk.Widget.BOTTOM then
y=sy+(overrides.y or 0)end
else
if overrides.valign==rtk.Widget.TOP then
y=sy
elseif overrides.valign==rtk.Widget.CENTER then
y=sy+(overrides.y or 0)+(sh-h)/2
elseif overrides.valign==rtk.Widget.BOTTOM then
y=sy+(overrides.y or 0)+(sh-h)end
end
if overrides.constrain then
x=rtk.clamp(x,sx,sx+sw-w)y=rtk.clamp(y,sy,sy+sh-h)w=rtk.clamp(w,self.minw or 0,sw-(x-sx))h=rtk.clamp(h,self.minh or 0,sh-(rtk.os.mac and y-sy-h or y-sy))end
end
end
return math.round(x),math.round(y),math.round(w),math.round(h)end
function rtk.Window:_shrinkwrap()local calc=self.calc
if #self.children==0 then
calc.w=self.w and calc.w or calc.maxw
calc.h=self.h and calc.h or calc.maxh
else
self:reflow(rtk.Widget.REFLOW_FULL,not self.w,not self.h)end
end
function rtk.Window:_sync_window_attrs(overrides)local calc=self.calc
local lastw,lasth=self.w,self.h
local resized
local dockstate=self:_get_dockstate_from_attrs()if not rtk.has_js_reascript_api or not self.hwnd then
if dockstate~=self._dockstate then
gfx.dock(dockstate)self:_handle_dock_change(dockstate)self:onresize(lastw,lasth)return 1
else
return 0
end
end
if not self.w or not self.h then
self:_shrinkwrap()end
if dockstate~=self._dockstate then
gfx.dock(dockstate)local r,w,h=reaper.JS_Window_GetClientSize(self.hwnd)self:_handle_dock_change(dockstate)if calc.docked then
gfx.w,gfx.h=w,h
self:sync('w', w / rtk.scale.framebuffer, w)self:sync('h', h / rtk.scale.framebuffer, h)end
self:onresize(lastw,lasth)return 1
end
if self._resize_grip then
self._resize_grip:attr('visible', calc.borderless and calc.resizable and not calc.docked)end
if not calc.docked then
if not calc.visible then
reaper.JS_Window_Show(self.hwnd, 'HIDE')return 0
end
local style='SYSMENU,DLGSTYLE,BORDER,CAPTION'if calc.resizable then
style=style .. ',THICKFRAME'end
if calc.borderless then
style='POPUP'self:_setup_borderless()if not self.realized then
local sw=math.ceil(self.calc.w/rtk.scale.framebuffer)local sh=math.ceil(self.calc.h/rtk.scale.framebuffer)reaper.JS_Window_Resize(self.hwnd,sw,sh)end
end
local function restyle()reaper.JS_Window_SetStyle(self.hwnd,style)if rtk.os.bits~=32 then
local n=reaper.JS_Window_GetLong(self.hwnd, 'STYLE')reaper.JS_Window_SetLong(self.hwnd, 'STYLE', n | 0x80000000)end
reaper.JS_Window_SetZOrder(self.hwnd, calc.pinned and 'TOPMOST' or 'NOTOPMOST')local r,x1,y1,x2,y2=reaper.JS_Window_GetClientRect(self.hwnd)if r then
reaper.JS_Window_Resize(self.hwnd,x2-x1,y2-y1)self:_discover_os_window_frame_size(self.hwnd)end
end
if reaper.JS_Window_IsVisible(self.hwnd)then
restyle()else
rtk.defer(restyle)end
local x,y,w,h=self:_get_geometry_from_attrs(overrides)local scaled_gfxw=gfx.w/rtk.scale.framebuffer
local scaled_gfxh=gfx.h/rtk.scale.framebuffer
if not resized then
if w==scaled_gfxw and h==scaled_gfxh then
resized=0
elseif w<=scaled_gfxw and h<=scaled_gfxh then
resized=-1
elseif w>scaled_gfxw or h>scaled_gfxh then
resized=1
end
end
local r,lastx,lasty,x2,y2=reaper.JS_Window_GetClientRect(self.hwnd)local moved=r and(self.x~=lastx or self.y~=lasty)local borderless_toggled=calc.borderless~=self._last_synced_attrs.borderless
if moved or resized~=0 or borderless_toggled then
local sw,sh=w,h
if not calc.borderless then
sw=w+self._os_window_frame_width/rtk.scale.framebuffer
sh=h+self._os_window_frame_height/rtk.scale.framebuffer
end
sw=math.ceil(sw)sh=math.ceil(sh)reaper.JS_Window_SetPosition(self.hwnd,x,y,sw,sh)end
if resized~=0 then
gfx.w=w*rtk.scale.framebuffer
gfx.h=h*rtk.scale.framebuffer
self:queue_blit()self:onresize(scaled_gfxw,scaled_gfxh)end
if moved then
self:sync('x', x, 0)self:sync('y', y, 0)self:onmove(lastx,lasty)end
reaper.JS_Window_SetOpacity(self.hwnd, 'ALPHA', calc.opacity)reaper.JS_Window_SetTitle(self.hwnd,calc.title)else
local flags=reaper.JS_Window_GetLong(self.hwnd, 'EXSTYLE')flags=flags&~0x00080000
reaper.JS_Window_SetLong(self.hwnd, 'EXSTYLE', flags)end
self._last_synced_attrs.borderless=calc.borderless
return resized or 0
end
function rtk.Window:open(options)if self.running or rtk._quit then
return
end
rtk.window=self
if options then
options.halign=options.halign or options.align
options.valign=options.valign or options.align
end
if not self.w or not self.h then
self:_shrinkwrap()end
local calc=self.calc
self.running=true
gfx.ext_retina=1
self:_handle_attr('bg', calc.bg or rtk.theme.bg)options=self:_calc_cell_attrs(self,options)local x,y,w,h=self:_get_geometry_from_attrs(options)self:sync('x', x, 0)self:sync('y', y, 0)self:sync('w', w)self:sync('h', h)local dockstate=self:_get_dockstate_from_attrs()gfx.init(calc.title,calc.w/rtk.scale.framebuffer,calc.h/rtk.scale.framebuffer,dockstate,x,y)gfx.update()if gfx.ext_retina==2 and rtk.os.mac and rtk.scale.framebuffer~=2 then
log.warning('rtk.Window:open(): unexpected adjustment to rtk.scale.framebuffer: %s -> 2', rtk.scale.framebuffer)rtk.scale.framebuffer=2
calc.w=calc.w*rtk.scale.framebuffer
calc.h=calc.h*rtk.scale.framebuffer
end
dockstate,_,_=gfx.dock(-1,true,true)self:_handle_dock_change(dockstate)if rtk.has_js_reascript_api then
self:_clear_gdi()else
rtk.color.set(rtk.theme.bg)gfx.rect(0,0,w,h,1)end
self._draw_queued=true
self:_run()end
function rtk.Window:_close()self.running=false
gfx.quit()end
function rtk.Window:close()self.running=false
self.hwnd=nil
gfx.quit()self:onclose()end
function rtk.Window:_setup_borderless()if self._move_grip then
return
end
local calc=self.calc
local move=rtk.Spacer{z=-10000,w=1.0,h=30,touch_activate_delay=0}move.onmousedown=function(this,event)if not calc.docked and calc.borderless then
local _,wx,wy,_,_=reaper.JS_Window_GetClientRect(self.hwnd)local mx,my=reaper.GetMousePosition()this._drag_start_mx=mx
this._drag_start_my=my
this._drag_start_wx=wx
this._drag_start_wy=wy
this._drag_start_ww=gfx.w/rtk.scale.framebuffer
this._drag_start_wh=gfx.h/rtk.scale.framebuffer
this._drag_start_dx=mx-wx
this._drag_start_dy=my-wy
end
return true
end
move.ondragstart=function(this,event)if not calc.docked and calc.borderless and this._drag_start_mx then
return true
else
return false
end
end
move.ondragend=function(this,event)this._drag_start_mx=nil
end
move.ondragmousemove=function(this,event)local _,wx,wy,_,wy2=reaper.JS_Window_GetClientRect(self.hwnd)local mx,my=reaper.GetMousePosition()local x=mx-this._drag_start_dx
local y
if rtk.os.mac then
local h=wy-wy2
y=my-this._drag_start_dy-h
else
y=my-this._drag_start_dy
end
if self._unmaximized_geometry then
local _,_,w,h=table.unpack(self._unmaximized_geometry)local sx,_,sw,sh=self:_get_display_resolution()local xoffset=event.x/rtk.scale.framebuffer
local dx=math.ceil(w*xoffset/this._drag_start_ww)x=rtk.clamp(sx+xoffset-dx,sx,sx+sw-w)self._unmaximized_geometry=nil
this._drag_start_ww=w
this._drag_start_wh=h
this._drag_start_dx=dx
if rtk.os.mac then
y=(wy-h)+(my-this._drag_start_my)end
reaper.JS_Window_SetPosition(self.hwnd,x,y,w,h)else
reaper.JS_Window_Move(self.hwnd,x,y)end
end
move.ondoubleclick=function(this,event)if calc.docked or not calc.borderless then
return
end
local x,y,w,h=self:_get_display_resolution(true)if self._unmaximized_geometry then
if math.abs(w-self.w)<w*0.05 and math.abs(h-self.h)<h*0.05 then
x,y,w,h=table.unpack(self._unmaximized_geometry)end
self._unmaximized_geometry=nil
else
self._unmaximized_geometry={self.x,self.y,self.w,self.h}end
self:move(x,y)self:resize(w,h)return true
end
local resize=rtk.ImageBox{image=rtk.Window._icon_resize_grip,z=10000,visible=calc.resizable,cursor=rtk.mouse.cursors.SIZE_NW_SE,alpha=0.4,autofocus=true,touch_activate_delay=0,tooltip='Resize window',}resize.onmouseenter=function(this)if calc.borderless then
this:animate{attr='alpha', dst=1, duration=0.1}return true
end
end
resize.onmouseleave=function(this,event)if calc.borderless then
this:animate{attr='alpha', dst=0.4, duration=0.25}end
end
resize.onmousedown=move.onmousedown
resize.ondragstart=move.ondragstart
resize.ondragmousemove=function(this,event)local _,ww,wh=reaper.JS_Window_GetClientSize(self.hwnd)local mx,my=reaper.GetMousePosition()local dx=mx-this._drag_start_mx
local dy=(my-this._drag_start_my)*(rtk.os.mac and-1 or 1)local w=math.max(self.calc.minw,this._drag_start_ww+dx)local h=math.max(self.calc.minh,this._drag_start_wh+dy)reaper.JS_Window_Resize(self.hwnd,w,h)self:_clear_gdi(calc.w,calc.h)if rtk.os.mac then
reaper.JS_Window_Move(self.hwnd,this._drag_start_wx,this._drag_start_wy-h)end
end
self:add(move)self:add(resize, {valign='bottom', halign='right'})self._move_grip=move
self._resize_grip=resize
end
local function verify_hwnd_coords(hwnd,x,y)local _,hx,hy,_,_=reaper.JS_Window_GetClientRect(hwnd)return hx==x and hy==y
end
local function search_hwnd_addresses(list,title,x,y)for _,addr in ipairs(list)do
addr=tonumber(addr)if addr then
local hwnd=reaper.JS_Window_HandleFromAddress(addr)if(not title or reaper.JS_Window_GetTitle(hwnd)==title)and verify_hwnd_coords(hwnd,x,y)then
return hwnd
end
end
end
end
function rtk.Window:_discover_os_window_frame_size(hwnd)local _,w,h=reaper.JS_Window_GetClientSize(hwnd)local _,l,t,r,b=reaper.JS_Window_GetRect(hwnd)self._os_window_frame_width=(r-l)-w
self._os_window_frame_height=math.abs(b-t)-h
self._os_window_frame_width=self._os_window_frame_width*rtk.scale.framebuffer
self._os_window_frame_height=self._os_window_frame_height*rtk.scale.framebuffer
end
function rtk.Window:_get_hwnd()if not rtk.has_js_reascript_api then
return
end
local x,y=gfx.clienttoscreen(0,0)local title=self.calc.title
local hwnd=reaper.JS_Window_Find(title,true)if hwnd and not verify_hwnd_coords(hwnd,x,y)then
hwnd=nil
if self.calc.docked then
local _,addrs=reaper.JS_Window_ListAllChild(rtk.reaper_hwnd)hwnd=search_hwnd_addresses((addrs or ''):split(','), title, x, y)end
if not hwnd then
log.time_start()local a=reaper.new_array({},50)reaper.JS_Window_ArrayFind(title,true,a)hwnd=search_hwnd_addresses(a.table(),nil,x,y)log.time_end('rtk.Window:_get_hwnd(): needed to take slow path: title=%s', title)end
end
if hwnd then
self:_discover_os_window_frame_size(hwnd)end
return hwnd
end
function rtk.Window:_handle_dock_change(dockstate)local calc=self.calc
local was_docked=(self._dockstate&0x01)~=0
calc.docked=dockstate&0x01~=0
calc.dock=(dockstate>>8)&0xff
self:sync('dock', calc.dock)self:sync('docked', calc.docked)self._dockstate=dockstate
self.hwnd=self:_get_hwnd()self:queue_reflow(rtk.Widget.REFLOW_FULL)if was_docked~=calc.docked then
self:_clear_gdi()if calc.docked then
self._undocked_geometry={self.x,self.y,self.w,self.h}elseif self._undocked_geometry then
local x,y,w,h=table.unpack(self._undocked_geometry)local gw=w*rtk.scale.framebuffer
local gh=h*rtk.scale.framebuffer
self:sync('x', x, 0)self:sync('y', y, 0)self:sync('w', w, gw)self:sync('h', h, gh)gfx.w=gw
gfx.h=gh
end
end
self:_sync_window_attrs()self:queue_blit()self:ondock()end
function rtk.Window:queue_reflow(mode,widget)if mode~=rtk.Widget.REFLOW_FULL and widget and widget.box then
if self._reflow_widgets then
self._reflow_widgets[widget]=true
elseif not self._reflow_queued then
self._reflow_widgets={[widget]=true}end
else
self._reflow_widgets=nil
end
self._reflow_queued=true
end
function rtk.Window:queue_draw()self._draw_queued=true
end
function rtk.Window:queue_blit()self._blits_queued=self._blits_queued+2
end
function rtk.Window:_get_content_size(boxw,boxh,fillw,fillh,clampw,clamph,scale)local tp,rp,bp,lp=self:_get_padding_and_border()local calc=self.calc
return self.w and(calc.w-lp-rp)or nil,self.h and(calc.h-tp-bp)or nil,tp,rp,bp,lp
end
function rtk.Window:queue_mouse_refresh()self._mouse_refresh_queued=true
end
function rtk.Window:_reflow(boxx,boxy,boxw,boxh,fillw,filly,clampw,clamph,uiscale,viewport,window)rtk.Container._reflow(self,boxx,boxy,boxw,boxh,fillw,filly,clampw,clamph,uiscale,viewport,window)self.calc.x=0
self.calc.y=0
end
function rtk.Window:reflow(mode,shrinkwrapw,shrinkwraph)local calc=self.calc
local widgets=self._reflow_widgets
local full=false
self._reflow_queued=false
self._reflow_widgets=nil
local t0=reaper.time_precise()if mode~=rtk.Widget.REFLOW_FULL and widgets and self.realized and #widgets<20 then
for widget,_ in pairs(widgets)do
widget:reflow()widget:_realize_geometry()end
else
local saved_size
local boxw,boxh=calc.w,calc.h
if shrinkwrapw or shrinkwraph then
saved_size={self.w,self.h}local _,_,sw,sh=self:_get_display_resolution(true)boxw=shrinkwrapw and(calc.maxw or sw*rtk.scale.framebuffer)or calc.w
boxh=shrinkwraph and(calc.maxh or sh*rtk.scale.framebuffer)or calc.h
self.w=not shrinkwrapw and self.w or nil
self.h=not shrinkwraph and self.h or nil
end
local _,_,w,h=rtk.Container.reflow(self,0,0,boxw,boxh,nil,nil,true,true,rtk.scale.value,nil,self
)self:_realize_geometry()full=true
if saved_size then
self.w,self.h=table.unpack(saved_size)end
end
local reflow_time=reaper.time_precise()-t0
if reflow_time>0.02 then
log.warning("rtk: slow reflow: %s", reflow_time)end
self:onreflow(widgets)self._draw_queued=true
return full
end
function rtk.Window:_get_mouse_button_event(bit,type)if not type then
if rtk.mouse.down&bit==0 and gfx.mouse_cap&bit~=0 then
rtk.mouse.down=rtk.mouse.down|bit
type=rtk.Event.MOUSEDOWN
elseif rtk.mouse.down&bit~=0 and gfx.mouse_cap&bit==0 then
rtk.mouse.down=rtk.mouse.down&~bit
type=rtk.Event.MOUSEUP
end
end
if type then
local event=self._event:reset(type)event.x,event.y=gfx.mouse_x,gfx.mouse_y
event:set_modifiers(gfx.mouse_cap,bit)return event
end
end
function rtk.Window:_get_mousemove_event(simulated)local event=self._event:reset(rtk.Event.MOUSEMOVE)event.simulated=simulated
event:set_modifiers(gfx.mouse_cap,rtk.mouse.state.latest or 0)return event
end
local function _get_wheel_distance(v)if rtk.os.mac then
return-v/90
else
return-v/120
end
end
function rtk.Window:_update()local calc=self.calc
local now=reaper.time_precise()local need_draw=false
if gfx.ext_retina~=rtk.scale.system then
rtk.scale.system=gfx.ext_retina
rtk.scale._calc()self:queue_reflow()end
local files=nil
local _,fname=gfx.getdropfile(0)if fname then
files={fname}local idx=1
while true do
_,fname=gfx.getdropfile(idx)if not fname then
break
end
files[#files+1]=fname
idx=idx+1
end
gfx.getdropfile(-1)end
gfx.update()if rtk._soon_funcs then
rtk._run_soon()end
local focus_changed=false
if rtk.has_js_reascript_api then
rtk.focused_hwnd=reaper.JS_Window_GetFocus()local is_focused=self.hwnd==rtk.focused_hwnd
if is_focused~=self.is_focused then
self.is_focused=is_focused
need_draw=true
focus_changed=true
end
end
if self:onupdate()==false then
return
end
need_draw=rtk._do_animations(now)or need_draw
if self._sync_window_attrs_on_update then
if self:_sync_window_attrs()~=0 then
self:reflow(rtk.Widget.REFLOW_FULL)need_draw=true
end
self._sync_window_attrs_on_update=false
end
local dockstate,x,y=gfx.dock(-1,true,true)local dock_changed=dockstate~=self._dockstate
if dock_changed then
self:_handle_dock_change(dockstate)end
if x~=self.x or y~=self.y then
local lastx,lasty=self.x,self.y
self:sync('x', x, 0)self:sync('y', y, 0)self:onmove(lastx,lasty)end
local resized=gfx.w~=calc.w or gfx.h~=calc.h
if resized and self.visible then
local last_w,last_h=self.w,self.h
self:sync('w', gfx.w / rtk.scale.framebuffer, gfx.w)self:sync('h', gfx.h / rtk.scale.framebuffer, gfx.h)self:_clear_gdi(calc.w,calc.h)self:onresize(last_w,last_h)self:reflow(rtk.Widget.REFLOW_FULL)need_draw=true
elseif self._reflow_queued then
self:reflow()need_draw=true
end
local event=nil
local last_cursor=calc.cursor
calc.cursor=rtk.mouse.cursors.UNDEFINED
if gfx.mouse_wheel~=0 or gfx.mouse_hwheel~=0 then
event=self._event:reset(rtk.Event.MOUSEWHEEL)event:set_modifiers(gfx.mouse_cap,0)event.wheel=_get_wheel_distance(gfx.mouse_wheel)event.hwheel=_get_wheel_distance(gfx.mouse_hwheel)self:onmousewheel(event)gfx.mouse_wheel=0
gfx.mouse_hwheel=0
self:_handle_window_event(event,now)end
local char=gfx.getchar()if char>0 then
event=self._event:reset(rtk.Event.KEY)event:set_modifiers(gfx.mouse_cap,0)event.char=nil
event.keycode=char
if char<=26 and event.ctrl then
event.char=string.char(char+96)elseif char>=32 and char~=127 then
if char<=255 then
event.char=string.char(char)elseif char<=282 then
event.char=string.char(char-160)elseif char<=346 then
event.char=string.char(char-224)end
end
self:onkeypresspre(event)self:_handle_window_event(event,now)elseif char<0 then
self:close()end
if files then
event=self:_get_mousemove_event(false)event.type=rtk.Event.DROPFILE
event.files=files
self:_handle_window_event(event,now)end
rtk._touch_activate_event=rtk.touchscroll and rtk.Event.MOUSEUP or rtk.Event.MOUSEDOWN
need_draw=need_draw or self._draw_queued
local mouse_button_changed=(rtk.mouse.down~=gfx.mouse_cap&rtk.mouse.BUTTON_MASK)local buttons_down=(gfx.mouse_cap&rtk.mouse.BUTTON_MASK~=0)local mouse_moved=(rtk.mouse.x~=gfx.mouse_x or rtk.mouse.y~=gfx.mouse_y)local last_in_window=self.in_window
self.in_window=gfx.mouse_x>=0 and gfx.mouse_y>=0 and gfx.mouse_x<=gfx.w and gfx.mouse_y<=gfx.h
local in_window_changed=self.in_window~=last_in_window
if self._last_mousemove_time and rtk._mouseover_widget and
rtk._mouseover_widget~=self._tooltip_widget and
now-self._last_mousemove_time>rtk.tooltip_delay then
self._tooltip_widget=rtk._mouseover_widget
need_draw=true
end
if mouse_button_changed and rtk.touchscroll and self._jsx then
self._restore_mouse_pos={self._jsx,self._jsy}end
if mouse_moved then
if self.in_window then
self._jsx=nil
elseif not buttons_down then
self._jsx,self._jsy=reaper.GetMousePosition()end
if self._mouse_refresh_queued then
self._mouse_refresh_queued=false
local tmp=self:_get_mousemove_event(true)tmp.buttons=0
tmp.button=0
self:_handle_window_event(tmp,now)need_draw=true
end
end
if not event or mouse_moved then
local suppress=false
if self.in_window and rtk.has_js_reascript_api and self.hwnd then
local x,y=reaper.GetMousePosition()local hwnd=reaper.JS_Window_FromPoint(x,y)if hwnd~=self.hwnd then
self.in_window=false
in_window_changed=last_in_window~=false
end
end
if need_draw or(mouse_moved and self.in_window)or in_window_changed or
(rtk.dnd.dragging and buttons_down)then
event=self:_get_mousemove_event(not mouse_moved)if buttons_down and rtk.touchscroll and not rtk.dnd.dragging then
suppress=not event:get_button_state('mousedown-handled')end
elseif rtk.mouse.down~=0 and not mouse_button_changed then
local buttonstate=rtk.mouse.state[rtk.mouse.state.latest]
local wait=math.max(rtk.long_press_delay,rtk.touch_activate_delay)if now-buttonstate.time<=wait+(2/rtk.fps)then
event=self:_get_mouse_button_event(rtk.mouse.state.latest,rtk.Event.MOUSEDOWN)event.simulated=true
end
end
if event and(not event.simulated or self._touch_scrolling.count==0 or buttons_down)then
need_draw=need_draw or self._tooltip_widget~=nil
self:_handle_window_event(event,now,suppress)end
end
rtk.mouse.x=gfx.mouse_x
rtk.mouse.y=gfx.mouse_y
if mouse_button_changed then
event=self:_get_mouse_button_event(rtk.mouse.BUTTON_LEFT)if not event then
event=self:_get_mouse_button_event(rtk.mouse.BUTTON_RIGHT)if not event then
event=self:_get_mouse_button_event(rtk.mouse.BUTTON_MIDDLE)end
end
if event then
if event.type==rtk.Event.MOUSEDOWN then
local buttonstate=rtk.mouse.state[event.button]
if not buttonstate then
buttonstate={}rtk.mouse.state[event.button]=buttonstate
end
buttonstate.time=now
rtk.mouse.state.order[#rtk.mouse.state.order+1]=event.button
rtk.mouse.state.latest=event.button
elseif event.type==rtk.Event.MOUSEUP then
for i=1,#rtk.mouse.state.order do
if rtk.mouse.state.order[i]==event.button then
table.remove(rtk.mouse.state.order,i)break
end
end
if #rtk.mouse.state.order>0 then
rtk.mouse.state.latest=rtk.mouse.state.order[#rtk.mouse.state.order]
else
rtk.mouse.state.latest=0
end
if rtk.touchscroll and event.buttons==0 and self._restore_mouse_pos then
local x,y=table.unpack(self._restore_mouse_pos)rtk.callafter(0.2,reaper.JS_Mouse_SetPosition,x,y)self._restore_mouse_pos=nil
end
end
self:_handle_window_event(event,now)else
log.warning('rtk: no event for mousecap=%s which indicates an internal rtk bug', gfx.mouse_cap)end
end
if rtk._soon_funcs then
rtk._run_soon()end
local blitted=false
if event and calc.visible then
if self._reflow_queued and not self._sync_window_attrs_on_update then
if self:reflow()then
calc.cursor=rtk.mouse.cursors.UNDEFINED
self:_handle_window_event(self:_get_mousemove_event(true),now)end
end
if need_draw or self._draw_queued then
self._backingstore:resize(calc.w,calc.h,false)self._backingstore:pushdest()self:clear()self._draw_queued=false
self:_draw(0,0,calc.alpha,event,calc.w,calc.h,0,0,0,0)if event.debug then
event.debug:_draw_debug_info(event)end
if self._tooltip_widget and not rtk.dnd.dragging then
self._tooltip_widget:_draw_tooltip(rtk.mouse.x,rtk.mouse.y,calc.w,calc.h)end
self._backingstore:popdest()self:_blit()blitted=true
end
if focus_changed then
if self.is_focused then
if self._focused_saved then
self._focused_saved:focus(event)self._focused_saved=nil
end
self:onfocus(event)else
if rtk.focused then
self._focused_saved=rtk.focused
rtk.focused:blur(event,nil)end
self:onblur(event)end
end
if not event.handled and rtk.is_modal()and
((focus_changed and not self.is_focused)or event.type==rtk._touch_activate_event)then
for _,widget in pairs(rtk._modal)do
widget:_release_modal(event)end
end
if not event.handled and rtk.focused and event.type==rtk._touch_activate_event then
rtk.focused:blur(event,nil)end
if event.type==rtk.Event.KEY then
self:onkeypresspost(event)if event.handled then
return
end
if event.keycode==rtk.keycodes.F12 and log.level<=log.DEBUG then
rtk.debug=not rtk.debug
self:queue_draw()elseif event.keycode==rtk.keycodes.ESCAPE and not self.docked then
self:close()end
end
if calc.cursor==rtk.mouse.cursors.UNDEFINED then
calc.cursor=self.cursor
end
if self.in_window then
if type(calc.cursor)=='userdata' then
reaper.JS_Mouse_SetCursor(calc.cursor)reaper.JS_WindowMessage_Intercept(self.hwnd, "WM_SETCURSOR", false)else
gfx.setcursor(calc.cursor,0)end
elseif in_window_changed and self.hwnd and rtk.has_js_reascript_api then
reaper.JS_WindowMessage_Release(self.hwnd, "WM_SETCURSOR")end
end
if mouse_moved then
self._last_mousemove_time=now
end
if self._blits_queued>0 then
if not blitted then
self:_blit()end
self._blits_queued=self._blits_queued-1
end
local duration=reaper.time_precise()-now
if duration>0.04 then
log.debug("rtk: very slow update: %s  event=%s", duration, event)end
end
function rtk.Window:_blit()self._backingstore:blit{mode=rtk.Image.FAST_BLIT}end
function rtk.Window:_handle_window_event(event,now,suppress)if not self.calc.visible then
return
end
if not event.simulated then
rtk._mouseover_widget=nil
self._tooltip_widget=nil
self._last_mousemove_time=nil
end
event.time=now
if not suppress then
rtk.Container._handle_event(self,0,0,event,false,rtk._modal==nil)end
assert(event.type~=rtk.Event.MOUSEDOWN or event.button~=0)if event.type==rtk.Event.MOUSEUP then
rtk.mouse.state[event.button]=nil
if event.buttons==0 then
rtk._pressed_widgets=nil
end
self._last_mouseup_time=event.time
rtk._drag_candidates=nil
if rtk.dnd.dropping then
rtk.dnd.dropping:_handle_dropblur(event,rtk.dnd.dragging,rtk.dnd.arg)rtk.dnd.dropping=nil
end
if rtk.dnd.dragging and event.buttons&rtk.dnd.buttons==0 then
rtk.dnd.dragging:_handle_dragend(event,rtk.dnd.arg)rtk.dnd.dragging=nil
rtk.dnd.arg=nil
local tmp=event:clone{type=rtk.Event.MOUSEMOVE,simulated=true}rtk.Container._handle_event(self,0,0,tmp,false,rtk._modal==nil)end
elseif rtk._drag_candidates and event.type==rtk.Event.MOUSEMOVE and
not event.simulated and event.buttons~=0 and not rtk.dnd.arg then
event.handled=nil
rtk.dnd.droppable=true
local missed=false
local dthresh=math.ceil(rtk.scale.value ^ 1.7)if rtk.touchscroll and event.time-self._last_mouseup_time<0.2 then
dthresh=rtk.scale.value*10
end
for n,state in ipairs(rtk._drag_candidates)do
local widget,offered=table.unpack(state)if not offered then
local ex,ey,when=table.unpack(rtk._pressed_widgets[widget.id])local dx=math.abs(ex-event.x)local dy=math.abs(ey-event.y)local tthresh=widget:_get_touch_activate_delay(event)if event.time-when>=tthresh and(dx>dthresh or dy>dthresh)then
local arg,droppable=widget:_handle_dragstart(event,ex,ey,when)if arg then
widget:_deferred_mousedown(event,ex,ey)rtk.dnd.dragging=widget
rtk.dnd.arg=arg
rtk.dnd.droppable=droppable~=false and true or false
rtk.dnd.buttons=event.buttons
widget:_handle_dragmousemove(event,arg)break
elseif event.handled then
break
end
state[2]=true
else
missed=true
end
end
end
if not missed or event.handled then
rtk._drag_candidates=nil
end
end
end
function rtk.Window:request_mouse_cursor(cursor,force)if cursor and(self.calc.cursor==rtk.mouse.cursors.UNDEFINED or force)then
self.calc.cursor=cursor
return true
else
return false
end
end
function rtk.Window:clear()self._backingstore:clear(self.calc.bg or rtk.theme.bg)end
function rtk.Window:get_normalized_y()if not rtk.os.mac then
return self.y
else
local _,_,_,sh=self:_get_display_resolution()local offset=gfx.h+self._os_window_frame_height
return sh-self.y-offset/rtk.scale.framebuffer
end
end
function rtk.Window:_set_touch_scrolling(viewport,state)local ts=self._touch_scrolling
local exists=ts[viewport.id]~=nil
if state and not exists then
ts[viewport.id]=viewport
ts.count=ts.count+1
elseif not state and exists then
ts[viewport.id]=nil
ts.count=ts.count-1
end
end
function rtk.Window:_is_touch_scrolling(viewport)if viewport then
return self._touch_scrolling[viewport.id]~=nil
else
return self._touch_scrolling.count>0
end
end
function rtk.Window:onupdate()end
function rtk.Window:onreflow(widgets)end
function rtk.Window:onmove(lastx,lasty)end
function rtk.Window:onresize(lastw,lasth)end
function rtk.Window:ondock()end
function rtk.Window:onclose()end
function rtk.Window:onkeypresspre(event)end
function rtk.Window:onkeypresspost(event)end
end)()

__mod_rtk_box=(function()
local rtk=__mod_rtk_core
local log=__mod_rtk_log
rtk.Box=rtk.class('rtk.Box', rtk.Container)rtk.Box.static.HORIZONTAL=1
rtk.Box.static.VERTICAL=2
rtk.Box.static.FLEXSPACE={}rtk.Box.static.STRETCH_NONE=0
rtk.Box.static.STRETCH_FULL=1
rtk.Box.static.STRETCH_TO_SIBLINGS=2
rtk.Box.register{expand=rtk.Attribute{type='number'},fillw=false,fillh=false,stretch=rtk.Attribute{calculate={none=rtk.Box.STRETCH_NONE,full=rtk.Box.STRETCH_FULL,siblings=rtk.Box.STRETCH_TO_SIBLINGS,['true']=rtk.Box.STRETCH_FULL,['false']=rtk.Box.STRETCH_NONE,[true]=rtk.Box.STRETCH_FULL,[false]=rtk.Box.STRETCH_NONE,[rtk.Attribute.NIL]=rtk.Box.STRETCH_NONE,}},bg=nil,orientation=nil,spacing=rtk.Attribute{default=0,reflow=rtk.Widget.REFLOW_FULL,},}function rtk.Box:initialize(attrs,...)rtk.Container.initialize(self,attrs,self.class.attributes.defaults,...)assert(self.orientation, 'rtk.Box cannot be instantiated directly, use rtk.HBox or rtk.VBox instead')end
function rtk.Box:_validate_child(child)if child~=rtk.Box.FLEXSPACE then
rtk.Container._validate_child(self,child)end
end
function rtk.Box:_reflow(boxx,boxy,boxw,boxh,fillw,fillh,clampw,clamph,uiscale,viewport,window)local calc=self.calc
calc.x,calc.y=self:_get_box_pos(boxx,boxy)local w,h,tp,rp,bp,lp=self:_get_content_size(boxw,boxh,fillw,fillh,clampw,clamph)local inner_maxw=w or(boxw-lp-rp)local inner_maxh=h or(boxh-tp-bp)clampw=clampw or w~=nil or fillw
clamph=clamph or h~=nil or fillh
self._reflowed_children={}self._child_index_by_id={}local innerw,innerh,expand_unit_size,expw,exph=self:_reflow_step1(inner_maxw,inner_maxh,clampw,clamph,uiscale,viewport,window
)if self.orientation==rtk.Box.HORIZONTAL then
expw=(expand_unit_size>0)or expw
elseif self.orientation==rtk.Box.VERTICAL then
exph=(expand_unit_size>0)or exph
end
innerw,innerh=self:_reflow_step2(inner_maxw,inner_maxh,innerw,innerh,clampw,clamph,expand_unit_size,uiscale,viewport,window,tp,rp,bp,lp
)fillw=fillw or(self.w and tonumber(self.w)<1.0)fillh=fillh or(self.h and tonumber(self.h)<1.0)innerw=w or math.max(innerw,fillw and inner_maxw or 0)innerh=h or math.max(innerh,fillh and inner_maxh or 0)calc.w=innerw+lp+rp
calc.h=innerh+tp+bp
return expw,exph
end
function rtk.Box:_reflow_step1(w,h,clampw,clamph,uiscale,viewport,window)local calc=self.calc
local orientation=calc.orientation
local remaining_size=orientation==rtk.Box.HORIZONTAL and w or h
local expand_units=0
local maxw,maxh=0,0
local spacing=0
local expw,exph=false,false
for n,widgetattrs in ipairs(self.children)do
local widget,attrs=table.unpack(widgetattrs)local wcalc=widget.calc
attrs._cellbox=nil
if widget.id then
self._child_index_by_id[widget.id]=n
end
if widget==rtk.Box.FLEXSPACE then
expand_units=expand_units+(attrs.expand or 1)spacing=0
elseif widget.visible==true then
attrs._halign=attrs.halign or calc.halign
attrs._valign=attrs.valign or calc.valign
local implicit_expand
if orientation==rtk.Box.HORIZONTAL then
implicit_expand=attrs.fillw
else
implicit_expand=attrs.fillh
end
attrs._calculated_expand=attrs.expand or(implicit_expand and 1)or 0
if attrs._calculated_expand==0 and implicit_expand then
log.error('rtk.Box: %s: fill=true overrides explicit expand=0: %s will be expanded', self, widget)end
if attrs._calculated_expand==0 then
local ww,wh=0,0
local wexpw,wexph
local ctp,crp,cbp,clp=self:_get_cell_padding(widget,attrs)if orientation==rtk.Box.HORIZONTAL then
local child_maxw=rtk.clamprel(remaining_size-clp-crp-spacing,attrs.minw or wcalc.minw,attrs.maxw or wcalc.maxw
)local child_maxh=rtk.clamprel(h-ctp-cbp,attrs.minh or wcalc.minh,attrs.maxh or wcalc.maxh
)_,_,ww,wh,wexpw,wexph=widget:reflow(0,0,child_maxw,child_maxh,attrs.fillw,attrs.fillh and attrs.stretch~=rtk.Box.STRETCH_TO_SIBLINGS,clampw,clamph,uiscale,viewport,window
)expw=wexpw or expw
exph=wexph or exph
ww=math.max(ww,attrs.minw or widget.minw or 0)wh=math.max(wh,attrs.minh or widget.minh or 0)if wexpw and clampw and ww>=child_maxw and n<#self.children then
attrs._calculated_expand=1
end
else
local child_maxw=rtk.clamprel(w-clp-crp,attrs.minw or wcalc.minw,attrs.maxw or wcalc.maxw
)local child_maxh=rtk.clamprel(remaining_size-ctp-cbp-spacing,attrs.minh or wcalc.minh,attrs.maxh or wcalc.maxh
)_,_,ww,wh,wexpw,wexph=widget:reflow(0,0,child_maxw,child_maxh,attrs.fillw and attrs.stretch~=rtk.Box.STRETCH_TO_SIBLINGS,attrs.fillh,clampw,clamph,uiscale,viewport,window
)expw=wexpw or expw
exph=wexph or exph
wh=math.max(wh,attrs.minh or widget.minh or 0)ww=math.max(ww,attrs.minw or widget.minw or 0)if wexph and clamph and wh>=child_maxh and n<#self.children then
attrs._calculated_expand=1
end
end
expw=expw or attrs.fillw
exph=exph or attrs.fillh
if attrs._calculated_expand==0 and wcalc.position&rtk.Widget.POSITION_INFLOW~=0 then
maxw=math.max(maxw,ww+clp+crp)maxh=math.max(maxh,wh+ctp+cbp)if orientation==rtk.Box.HORIZONTAL then
remaining_size=remaining_size-(clampw and(ww+clp+crp+spacing)or 0)else
remaining_size=remaining_size-(clamph and(wh+ctp+cbp+spacing)or 0)end
else
expand_units=expand_units+attrs._calculated_expand
end
else
expand_units=expand_units+attrs._calculated_expand
end
if orientation==rtk.Box.VERTICAL and attrs.stretch==rtk.Box.STRETCH_FULL then
maxw=w
elseif orientation==rtk.Box.HORIZONTAL and attrs.stretch==rtk.Box.STRETCH_FULL then
maxh=h
end
spacing=(attrs.spacing or self.spacing)*rtk.scale.value
self:_add_reflowed_child(widgetattrs,attrs.z or wcalc.z or 0)else
widget.realized=false
end
end
self:_determine_zorders()local expand_unit_size=expand_units>0 and(remaining_size/expand_units)or 0
return maxw,maxh,expand_unit_size,expw,exph
end
end)()

__mod_rtk_vbox=(function()
local rtk=__mod_rtk_core
rtk.VBox=rtk.class('rtk.VBox', rtk.Box)rtk.VBox.register{orientation=rtk.Box.VERTICAL
}function rtk.VBox:initialize(attrs,...)rtk.Box.initialize(self,attrs,self.class.attributes.defaults,...)end
function rtk.VBox:_reflow_step2(w,h,maxw,maxh,clampw,clamph,expand_unit_size,uiscale,viewport,window,tp,rp,bp,lp)local offset=0
local spacing=0
local second_pass={}for n,widgetattrs in ipairs(self.children)do
local widget,attrs=table.unpack(widgetattrs)local wcalc=widget.calc
if widget==rtk.Box.FLEXSPACE then
local previous=offset
offset=offset+expand_unit_size*(attrs.expand or 1)spacing=0
maxh=math.max(maxh,offset)self:_set_cell_box(attrs,lp,tp+previous,maxw,offset-previous)elseif widget.visible==true then
local wx,wy,ww,wh
local ctp,crp,cbp,clp=self:_get_cell_padding(widget,attrs)local need_second_pass=(attrs.stretch==rtk.Box.STRETCH_TO_SIBLINGS or
(attrs._halign and attrs._halign~=rtk.Widget.LEFT and
not attrs.fillw and
attrs.stretch~=rtk.Box.STRETCH_FULL))local offx=lp+clp
local offy=offset+tp+ctp+spacing
local expand=attrs._calculated_expand
if expand and expand>0 then
local child_maxw=rtk.clamprel(w-clp-crp,attrs.minw or wcalc.minw,attrs.maxw or wcalc.maxw
)local child_maxh=rtk.clamprel((expand_unit_size*expand)-ctp-cbp-spacing,attrs.minh or wcalc.minh,attrs.maxh or wcalc.maxh
)wx,wy,ww,wh=widget:reflow(0,0,child_maxw,child_maxh,attrs.fillw,attrs.fillh,clampw,clamph,uiscale,viewport,window
)if attrs.stretch==rtk.Box.STRETCH_FULL then
ww=maxw
end
if need_second_pass then
second_pass[#second_pass+1]={widget,attrs,offx,offy,ww,child_maxh,ctp,crp,cbp,clp,offset,spacing
}else
self:_align_child(widget,attrs,offx,offy,ww,child_maxh,crp,cbp)self:_set_cell_box(attrs,lp,tp+offset+spacing,ww+clp+crp,child_maxh+ctp+cbp)end
wh=math.max(child_maxh,wh)else
ww=attrs.stretch==rtk.Box.STRETCH_FULL and maxw or wcalc.w
wh=math.max(wcalc.h,attrs.minh or wcalc.minh or 0)if need_second_pass then
second_pass[#second_pass+1]={widget,attrs,offx,offy,ww,wh,ctp,crp,cbp,clp,offset,spacing
}else
self:_align_child(widget,attrs,offx,offy,ww,wh,crp,cbp)self:_set_cell_box(attrs,lp,tp+offset+spacing,ww+clp+crp,wh+ctp+cbp)end
end
if wcalc.position&rtk.Widget.POSITION_INFLOW~=0 then
offset=offset+spacing+ctp+wh+cbp
end
maxw=math.max(maxw,ww+clp+crp)maxh=math.max(maxh,offset)spacing=(attrs.spacing or self.spacing)*rtk.scale.value
if not need_second_pass then
widget:_realize_geometry()end
end
end
if #second_pass>0 then
for n,widgetinfo in ipairs(second_pass)do
local widget,attrs,offx,offy,ww,child_maxh,ctp,crp,cbp,clp,offset,spacing=table.unpack(widgetinfo)if attrs.stretch==rtk.Box.STRETCH_TO_SIBLINGS then
wx,wy,ww,wh=widget:reflow(0,0,maxw,child_maxh,attrs.fillw,attrs.fillh,clampw,clamph,uiscale,viewport,window
)end
self:_align_child(widget,attrs,offx,offy,maxw,child_maxh,crp,cbp)self:_set_cell_box(attrs,lp,tp+offset+spacing,maxw+clp+crp,child_maxh+ctp+cbp)widget:_realize_geometry()end
end
return maxw,maxh
end
function rtk.VBox:_align_child(widget,attrs,offx,offy,cellw,cellh,crp,cbp)local x,y=offx,offy
local wcalc=widget.calc
if cellh>wcalc.h then
if attrs._valign==rtk.Widget.BOTTOM then
y=(offy-cbp)+cellh-wcalc.h-cbp
elseif attrs._valign==rtk.Widget.CENTER then
y=offy+(cellh-wcalc.h)/2
end
end
if attrs._halign==rtk.Widget.CENTER then
x=(offx-crp)+(cellw-wcalc.w)/2
elseif attrs._halign==rtk.Widget.RIGHT then
x=offx+cellw-wcalc.w-crp
end
wcalc.x=wcalc.x+x
widget.box[1]=x
wcalc.y=wcalc.y+y
widget.box[2]=y
end
end)()

__mod_rtk_hbox=(function()
local rtk=__mod_rtk_core
rtk.HBox=rtk.class('rtk.HBox', rtk.Box)rtk.HBox.register{orientation=rtk.Box.HORIZONTAL
}function rtk.HBox:initialize(attrs,...)rtk.Box.initialize(self,attrs,self.class.attributes.defaults,...)end
function rtk.HBox:_reflow_step2(w,h,maxw,maxh,clampw,clamph,expand_unit_size,uiscale,viewport,window,tp,rp,bp,lp)local offset=0
local spacing=0
local second_pass={}for n,widgetattrs in ipairs(self.children)do
local widget,attrs=table.unpack(widgetattrs)local wcalc=widget.calc
if widget==rtk.Box.FLEXSPACE then
local previous=offset
offset=offset+expand_unit_size*(attrs.expand or 1)spacing=0
maxw=math.max(maxw,offset)self:_set_cell_box(attrs,lp+previous,tp,offset-previous,maxh)elseif widget.visible==true then
local wx,wy,ww,wh
local ctp,crp,cbp,clp=self:_get_cell_padding(widget,attrs)local need_second_pass=(attrs.stretch==rtk.Box.STRETCH_TO_SIBLINGS or
(attrs._valign and attrs._valign~=rtk.Widget.TOP and
not attrs.fillh and
attrs.stretch~=rtk.Box.STRETCH_FULL))local offx=offset+lp+clp+spacing
local offy=tp+ctp
local expand=attrs._calculated_expand
if expand and expand>0 then
local child_maxw=rtk.clamprel((expand_unit_size*expand)-clp-crp-spacing,attrs.minw or wcalc.minw,attrs.maxw or wcalc.maxw
)local child_maxh=rtk.clamprel(h-ctp-cbp,attrs.minh or wcalc.minh,attrs.maxh or wcalc.maxh
)wx,wy,ww,wh=widget:reflow(0,0,child_maxw,child_maxh,attrs.fillw,attrs.fillh,clampw,clamph,uiscale,viewport,window
)if attrs.stretch==rtk.Box.STRETCH_FULL then
wh=maxh
end
if need_second_pass then
second_pass[#second_pass+1]={widget,attrs,offx,offy,child_maxw,wh,ctp,crp,cbp,clp,offset,spacing
}else
self:_align_child(widget,attrs,offx,offy,child_maxw,wh,crp,cbp)self:_set_cell_box(attrs,lp+offset+spacing,tp,child_maxw+clp+crp,wh+ctp+cbp)end
ww=math.max(child_maxw,ww)else
ww=math.max(wcalc.w,attrs.minw or wcalc.minw or 0)wh=attrs.stretch==rtk.Box.STRETCH_FULL and maxh or wcalc.h
if need_second_pass then
second_pass[#second_pass+1]={widget,attrs,offx,offy,ww,wh,ctp,crp,cbp,clp,offset,spacing
}else
self:_align_child(widget,attrs,offx,offy,ww,wh,crp,cbp)self:_set_cell_box(attrs,lp+offset+spacing,tp,ww+clp+crp,wh+ctp+cbp)end
end
if wcalc.position&rtk.Widget.POSITION_INFLOW~=0 then
offset=offset+spacing+clp+ww+crp
end
maxw=math.max(maxw,offset)maxh=math.max(maxh,wh+ctp+cbp)spacing=(attrs.spacing or self.spacing)*rtk.scale.value
if not need_second_pass then
widget:_realize_geometry()end
end
end
if #second_pass>0 then
for n,widgetinfo in ipairs(second_pass)do
local widget,attrs,offx,offy,child_maxw,wh,ctp,crp,cbp,clp,offset,spacing=table.unpack(widgetinfo)if attrs.stretch==rtk.Box.STRETCH_TO_SIBLINGS then
wx,wy,ww,wh=widget:reflow(0,0,child_maxw,maxh,attrs.fillw,attrs.fillh,clampw,clamph,uiscale,viewport,window
)end
self:_align_child(widget,attrs,offx,offy,child_maxw,maxh,crp,cbp)self:_set_cell_box(attrs,lp+offset+spacing,tp,child_maxw+clp+crp,maxh+ctp+cbp)widget:_realize_geometry()end
end
return maxw,maxh
end
function rtk.HBox:_align_child(widget,attrs,offx,offy,cellw,cellh,crp,cbp)local x,y=offx,offy
local wcalc=widget.calc
if cellw>wcalc.w then
if attrs._halign==rtk.Widget.RIGHT then
x=(offx-crp)+cellw-wcalc.w-crp
elseif attrs._halign==rtk.Widget.CENTER then
x=offx+(cellw-wcalc.w)/2
end
end
if attrs._valign==rtk.Widget.CENTER then
y=(offy-cbp)+(cellh-wcalc.h)/2
elseif attrs._valign==rtk.Widget.BOTTOM then
y=offy+cellh-wcalc.h-cbp
end
wcalc.x=wcalc.x+x
widget.box[1]=x
wcalc.y=wcalc.y+y
widget.box[2]=y
end
end)()

__mod_rtk_flowbox=(function()
local rtk=__mod_rtk_core
rtk.FlowBox=rtk.class('rtk.FlowBox', rtk.Container)rtk.FlowBox.register{vspacing=rtk.Attribute{default=0,reflow=rtk.Widget.REFLOW_FULL,},hspacing=rtk.Attribute{default=0,reflow=rtk.Widget.REFLOW_FULL,},}function rtk.FlowBox:initialize(attrs,...)rtk.Container.initialize(self,attrs,self.class.attributes.defaults,...)end
function rtk.FlowBox:_reflow(boxx,boxy,boxw,boxh,fillw,fillh,clampw,clamph,uiscale,viewport,window)local calc=self.calc
local x,y=self:_get_box_pos(boxx,boxy)local w,h,tp,rp,bp,lp=self:_get_content_size(boxw,boxh,fillw,fillh,clampw,clamph)local inner_maxw=w or(boxw-lp-rp)local inner_maxh=h or(boxh-tp-bp)clampw=clampw or w~=nil or fillw
clamph=clamph or h~=nil or fillh
local child_geometry={}local hspacing=(calc.hspacing or 0)*rtk.scale.value
local vspacing=(calc.vspacing or 0)*rtk.scale.value
self._reflowed_children={}self._child_index_by_id={}local child_maxw=0
local child_totalh=0
for _,widgetattrs in ipairs(self.children)do
local widget,attrs=table.unpack(widgetattrs)local wcalc=widget.calc
if wcalc.visible==true and wcalc.position&rtk.Widget.POSITION_INFLOW~=0 then
local ctp,crp,cbp,clp=self:_get_cell_padding(widget,attrs)local wx,wy,ww,wh=widget:reflow(0,0,inner_maxw,inner_maxh,nil,nil,clampw,clamph,uiscale,viewport,window
)ww=ww+clp+crp
wh=wh+ctp+cbp
local minw=(attrs.minw or wcalc.minw or 0)+clp+crp
child_maxw=math.min(math.max(child_maxw,ww,minw),inner_maxw)child_totalh=child_totalh+wh
child_geometry[#child_geometry+1]={x=wx,y=wy,w=ww,h=wh}end
end
child_totalh=child_totalh+(#self.children-1)*vspacing
local col_width=child_maxw
local num_columns=math.floor((inner_maxw+hspacing)/(col_width+hspacing))local col_height=h
if not col_height and #child_geometry>0 then
col_height=child_geometry[1].h
for i=2,#child_geometry do
local need_columns=1
local cur_colh=0
for j=1,#child_geometry do
local wh=child_geometry[j].h
if cur_colh+wh>col_height then
need_columns=need_columns+1
cur_colh=0
end
cur_colh=cur_colh+wh+(j>1 and vspacing or 0)end
if need_columns<=num_columns then
num_columns=need_columns
break
end
col_height=col_height+vspacing+child_geometry[i].h
end
end
local col_width_max=math.floor((inner_maxw-((num_columns-1)*hspacing))/num_columns)local col={w=0,h=0,n=1}local offset={x=0,y=0}local inner={w=0,h=0}local chspacing=(col.n<num_columns)and hspacing or 0
for _,widgetattrs in ipairs(self.children)do
local widget,attrs=table.unpack(widgetattrs)local wcalc=widget.calc
attrs._cellbox=nil
if widget==rtk.Box.FLEXSPACE then
col.w=inner_maxw
elseif wcalc.visible==true then
local ctp,crp,cbp,clp=self:_get_cell_padding(widget,attrs)child_maxw=(attrs.fillw and attrs.fillw~=0)and col_width_max or col_width
local wx,wy,ww,wh=widget:reflow(clp,ctp,child_maxw-clp-crp,inner_maxh,attrs.fillw and attrs.fillw~=0,attrs.fillh and attrs.fillh~=0,clampw,clamph,uiscale,viewport,window
)wh=math.max(wh,attrs.minh or 0)if col.h+wh>col_height then
inner.w=inner.w+col.w
offset.x=offset.x+col.w
offset.y=0
col.w,col.h=0,0
col.n=col.n+1
chspacing=(col.n<num_columns)and hspacing or 0
end
wcalc.x=wx+offset.x+lp
wcalc.y=wy+offset.y+tp
widget.box[1]=widget.box[1]+offset.x+lp
widget.box[2]=widget.box[2]+offset.y+tp
self:_set_cell_box(attrs,lp+offset.x,tp+offset.y,child_maxw,wh+ctp+cbp)if wcalc.position&rtk.Widget.POSITION_INFLOW~=0 then
local cvspacing=(col.h+wh<col_height)and vspacing or 0
offset.y=offset.y+wy+wh+cvspacing
col.w=math.max(col.w,child_maxw+chspacing)col.h=col.h+wh+cvspacing+ctp+cbp
inner.h=math.max(inner.h,col.h)end
widget:_realize_geometry()self:_add_reflowed_child(widgetattrs,attrs.z or widget.z or 0)else
widget.realized=false
end
end
self:_determine_zorders()inner.w=inner.w+col.w
calc.x,calc.y=x,y
calc.w=(w or inner.w)+lp+rp
calc.h=(h or inner.h)+tp+bp
end
end)()

__mod_rtk_spacer=(function()
local rtk=__mod_rtk_core
rtk.Spacer=rtk.class('rtk.Spacer', rtk.Widget)function rtk.Spacer:initialize(attrs,...)rtk.Widget.initialize(self,attrs,rtk.Spacer.attributes.defaults,...)end
function rtk.Spacer:_draw(offx,offy,alpha,event,clipw,cliph,cltargetx,cltargety,parentx,parenty)rtk.Widget._draw(self,offx,offy,alpha,event,clipw,cliph,cltargetx,cltargety,parentx,parenty)local calc=self.calc
local y=calc.y+offy
if y+calc.h<0 or y>cliph or self.calc.ghost then
return false
end
self:_handle_drawpre(offx,offy,alpha,event)self:_draw_bg(offx,offy,alpha,event)self:_draw_borders(offx,offy,alpha)self:_handle_draw(offx,offy,alpha,event)end
end)()

__mod_rtk_button=(function()
local rtk=__mod_rtk_core
rtk.Button=rtk.class('rtk.Button', rtk.Widget)rtk.Button.static.RAISED=false
rtk.Button.static.FLAT=true
rtk.Button.static.LABEL=2
rtk.Button.register{[1]=rtk.Attribute{alias='label'},label=rtk.Attribute{reflow=rtk.Widget.REFLOW_FULL},icon=rtk.Attribute{priority=true,reflow=rtk.Widget.REFLOW_FULL,calculate=function(self,attr,value,target)if type(value)=='string' then
local color=self.color
if self.calc.flat==rtk.Button.FLAT then
color=rtk.theme.bg
end
local style=rtk.color.get_icon_style(color,rtk.theme.bg)if self.icon and self.icon.style==style then
return self.icon
end
local img=rtk.Image.icon(value,style)if not img then
img=rtk.Image.make_placeholder_icon(24,24,style)end
return img
else
return value
end
end,},wrap=rtk.Attribute{default=false,reflow=rtk.Widget.REFLOW_FULL,},color=rtk.Attribute{default=function(self,attr)return rtk.theme.button
end,calculate=function(self,attr,value,target)local color=rtk.Widget.attributes.bg.calculate(self,attr,value,target)local luma=rtk.color.luma(color,rtk.theme.bg)local dark=luma<rtk.light_luma_threshold
local theme=rtk.theme
if dark~=theme.dark then
theme=dark and rtk.themes.dark or rtk.themes.light
end
self._theme=theme
if not self.textcolor then
target.textcolor={rtk.color.rgba(theme.button_label)}end
return color
end,},textcolor=rtk.Attribute{default=nil,calculate=rtk.Reference('bg'),},textcolor2=rtk.Attribute{default=function(self,attr)return rtk.theme.text
end,calculate=rtk.Reference('bg'),},iconpos=rtk.Attribute{default=rtk.Widget.LEFT,calculate=rtk.Reference('halign'),},tagged=false,flat=rtk.Attribute{default=rtk.Button.RAISED,calculate={raised=rtk.Button.RAISED,flat=rtk.Button.FLAT,label=rtk.Button.LABEL,[rtk.Attribute.NIL]=rtk.Button.RAISED,},},tagalpha=nil,surface=true,spacing=rtk.Attribute{default=10,reflow=rtk.Widget.REFLOW_FULL,},gradient=1,circular=rtk.Attribute{default=false,reflow=rtk.Widget.REFLOW_FULL,},elevation=rtk.Attribute{default=3,calculate=function(self,attr,value,target)return rtk.clamp(value,0,15)end
},hover=false,font=rtk.Attribute{default=function(self,attr)return self._theme_font[1]
end,reflow=rtk.Widget.REFLOW_FULL,},fontsize=rtk.Attribute{default=function(self,attr)return self._theme_font[2]
end,reflow=rtk.Widget.REFLOW_FULL,},fontscale=rtk.Attribute{default=1.0,reflow=rtk.Widget.REFLOW_FULL
},fontflags=rtk.Attribute{default=function(self,attr)return self._theme_font[3]
end
},valign=rtk.Widget.CENTER,tpadding=6,bpadding=6,lpadding=10,rpadding=10,autofocus=true,}function rtk.Button:initialize(attrs,...)self._theme=rtk.theme
self._theme_font=self._theme_font or rtk.theme.button_font or rtk.theme.default_font
rtk.Widget.initialize(self,attrs,self.class.attributes.defaults,...)self._font=rtk.Font()end
function rtk.Button:__tostring_info()return self.label or(self.icon and self.icon.path)end
function rtk.Button:_handle_attr(attr,value,oldval,trigger,reflow,sync)local ret=rtk.Widget._handle_attr(self,attr,value,oldval,trigger,reflow,sync)if ret==false then
return ret
end
if self._segments and (attr == 'wrap' or attr == 'label') then
self._segments.dirty=true
end
if type(self.icon) == 'string' and (attr == 'color' or attr == 'label') then
self:attr('icon', self.icon, true)elseif attr=='icon' and value then
self._last_reflow_scale=nil
end
return ret
end
function rtk.Button:_reflow_get_max_label_size(boxw,boxh)local calc=self.calc
local seg=self._segments
if seg and seg.boxw==boxw and seg.wrap==calc.wrap and seg:isvalid()then
return self._segments,self.lw,self.lh
else
return self._font:layout(calc.label,boxw,boxh,calc.wrap)end
end
function rtk.Button:_reflow(boxx,boxy,boxw,boxh,fillw,fillh,clampw,clamph,uiscale,viewport,window)local calc=self.calc
calc.x,calc.y=self:_get_box_pos(boxx,boxy)local w,h,tp,rp,bp,lp=self:_get_content_size(boxw,boxh,fillw,fillh,clampw,clamph)local icon=calc.icon
if icon and uiscale~=self._last_reflow_scale then
icon:refresh_scale()self._last_reflow_scale=uiscale
end
local scale=rtk.scale.value
local iscale=scale/(icon and icon.density or 1.0)local iw,ih
if calc.icon then
iw=math.round(icon.w*iscale)ih=math.round(icon.h*iscale)else
iw,ih=0,0
end
if calc.circular then
local size=math.max(iw,ih)if w and not h then
calc.w=w+lp+rp
elseif h and not w then
calc.w=h+tp+bp
else
calc.w=math.max(w or size,h or size)+lp+rp
end
calc.h=calc.w
self._radius=(calc.w-1)/2
if not self._shadow then
self._shadow=rtk.Shadow()end
self._shadow:set_circle(self._radius,calc.elevation)return
end
local spacing=0
local hpadding=lp+rp
local vpadding=tp+bp
if calc.label then
local lwmax=w or((clampw or fillw)and(boxw-hpadding)or math.inf)local lhmax=h or((clamph or fillh)and(boxh-vpadding)or math.inf)if icon then
spacing=calc.spacing*scale
if calc.tagged then
spacing=spacing+(calc.iconpos==rtk.Widget.LEFT and lp or rp)end
lwmax=lwmax-(iw+spacing)end
self._font:set(calc.font,calc.fontsize,calc.fontscale,calc.fontflags)self._segments,self.lw,self.lh=self:_reflow_get_max_label_size(lwmax,lhmax)self.lw=math.min(self.lw,lwmax)if icon then
calc.w=w or(iw+spacing+self.lw)calc.h=h or math.max(ih,self.lh)else
calc.w=w or self.lw
calc.h=h or self.lh
end
elseif icon then
calc.w=w or iw
calc.h=h or ih
else
calc.w=0
calc.h=0
end
calc.w=math.round(rtk.clamp(calc.w+hpadding,calc.minw,calc.maxw))calc.h=math.round(rtk.clamp(calc.h+vpadding,calc.minh,calc.maxh))end
function rtk.Button:_realize_geometry()if self.circular then
return
end
local calc=self.calc
local tp,rp,bp,lp=self:_get_padding_and_border()local surx,sury=0,0
local surw,surh=calc.surface and calc.w or 0,calc.h
local label=calc.label
local icon=calc.icon
local scale=rtk.scale.value
local iscale=scale/(icon and icon.density or 1.0)local spacing=calc.spacing*scale
local tagx,tagw=0,0
local lx=lp
local ix=lx
local lw,lh
if label then
lw,lh=self._font:measure(label)end
if icon and label then
local iconwidth=icon.w*iscale
if calc.iconpos==rtk.Widget.LEFT then
if calc.tagged then
tagw=lp+iconwidth+lp
if calc.halign==rtk.Widget.LEFT then
lx=tagw+spacing
elseif calc.halign==rtk.Widget.CENTER then
lx=tagw+math.max(0,(calc.w-tagw-lw)/2)else
lx=math.max(tagw+spacing,calc.w-rp-lw)end
else
local sz=lw+spacing+iconwidth
if calc.halign==rtk.Widget.LEFT then
lx=lx+iconwidth+spacing
elseif calc.halign==rtk.Widget.CENTER then
local offset=math.max(0,(calc.w-sz)/2)ix=offset
lx=ix+iconwidth+spacing
else
lx=calc.w-rp-lw
ix=lx-spacing-iconwidth
if ix<0 then
lx=lp+iconwidth+spacing
ix=lp
end
end
end
else
if calc.tagged then
ix=calc.w-iconwidth-rp
tagx=ix-rp
tagw=rp+iconwidth+rp
if calc.halign==rtk.Widget.CENTER then
lx=math.max(0,(calc.w-tagw-lw)/2)elseif calc.halign==rtk.Widget.RIGHT then
lx=math.max(lp,calc.w-lw-tagw-spacing)end
else
local sz=lw+spacing+iconwidth
if calc.halign==rtk.Widget.LEFT then
ix=lx+lw+spacing
elseif calc.halign==rtk.Widget.CENTER then
local offset=math.max(0,(calc.w-sz)/2)lx=offset
ix=lx+spacing+lw
else
ix=calc.w-rp-iconwidth
lx=math.max(lx,ix-spacing-lw)end
end
end
else
local sz=icon and(icon.w*iscale)or lw
if calc.halign==rtk.Widget.CENTER then
local offset=(calc.w-sz)/2
lx=offset
elseif calc.halign==rtk.Widget.RIGHT then
lx=calc.w-rp-sz
end
ix=lx
end
local iy
if icon then
if calc.valign==rtk.Widget.TOP then
iy=sury+tp
elseif calc.valign==rtk.Widget.CENTER then
iy=sury+tp+math.max(0,calc.h-icon.h*iscale-tp-bp)/2
else
iy=sury+math.max(0,calc.h-icon.h*iscale-bp)end
end
local ly,clipw,cliph
if label then
if calc.valign==rtk.Widget.TOP then
ly=sury+tp
elseif calc.valign==rtk.Widget.CENTER then
ly=sury+tp+math.max(0,calc.h-lh-tp-bp)/2
else
ly=sury+math.max(0,calc.h-lh-bp)end
clipw=calc.w-lx
if calc.iconpos==rtk.Widget.RIGHT then
clipw=clipw-(tagw>0 and tagw or(calc.w-ix+calc.spacing))end
cliph=calc.h-ly
end
self._pre={tp=tp,rp=rp,bp=bp,lp=lp,ix=ix,iy=iy,lx=lx,ly=ly,lw=lw,lh=lh,tagx=tagx,tagw=tagw,surx=surx,sury=sury,surw=surw or 0,surh=surh or 0,clipw=clipw,cliph=cliph,iw=icon and(icon.w*iscale),ih=icon and(icon.h*iscale),}end
function rtk.Button:_draw(offx,offy,alpha,event,clipw,cliph,cltargetx,cltargety,parentx,parenty)local calc=self.calc
if calc.disabled then
alpha=alpha*0.5
end
rtk.Widget._draw(self,offx,offy,alpha,event,clipw,cliph,cltargetx,cltargety,parentx,parenty)local x=calc.x+offx
local y=calc.y+offy
if y+calc.h<0 or y>cliph or calc.ghost then
return false
end
local hover=(self.hovering or calc.hover)and not calc.disabled
local clicked=hover and event.buttons~=0 and self:focused()and self.window.is_focused
local theme=self._theme
local gradient,brightness,cmul,bmul
if clicked then
gradient=theme.button_clicked_gradient*theme.button_gradient_mul
brightness=theme.button_clicked_brightness
cmul=theme.button_clicked_mul
bmul=theme.button_clicked_border_mul
elseif hover then
gradient=theme.button_hover_gradient*theme.button_gradient_mul
brightness=theme.button_hover_brightness
cmul=theme.button_hover_mul
bmul=theme.button_hover_border_mul
else
gradient=theme.button_normal_gradient*theme.button_gradient_mul
bmul=theme.button_normal_border_mul
brightness=1.0
cmul=1.0
end
self:_handle_drawpre(offx,offy,alpha,event)if self.circular then
self:_draw_circular_button(x,y,hover,clicked,gradient,brightness,cmul,bmul,alpha)else
self:_draw_rectangular_button(x,y,hover,clicked,gradient,brightness,cmul,bmul,alpha)self:_draw_borders(offx,offy,alpha)end
self:_handle_draw(offx,offy,alpha,event)end
function rtk.Button:_is_mouse_over(clparentx,clparenty,event)local calc=self.calc
if calc.circular then
local x=calc.x+clparentx+self._radius
local y=calc.y+clparenty+self._radius
return self.window and self.window.in_window and
rtk.point_in_circle(event.x,event.y,x,y,self._radius)else
return rtk.Widget._is_mouse_over(self,clparentx,clparenty,event)end
end
function rtk.Button:_draw_circular_button(x,y,hover,clicked,gradient,brightness,cmul,bmul,alpha)local calc=self.calc
local radius=math.ceil(self._radius)local cirx=math.floor(x)+radius
local ciry=math.floor(y)+radius
local icon=calc.icon
if calc.surface and(not calc.flat or hover or clicked)then
if calc.elevation>0 then
self._shadow:draw(x+1,y+1)end
local r,g,b,a=rtk.color.mod(calc.color,1.0,1.0,brightness)self:setcolor({r*cmul,g*cmul,b*cmul,a},alpha)gfx.circle(cirx,ciry,radius,1,1)end
if icon then
local ix=(calc.w-(icon.w*rtk.scale.value))/2
local iy=(calc.h-(icon.h*rtk.scale.value))/2
self:_draw_icon(x+ix,y+iy,hover,alpha)end
if calc.border then
local color,thickness=table.unpack(calc.border)self:setcolor(color)for i=1,thickness do
gfx.circle(cirx,ciry,radius-(i-1),0,1)end
end
end
function rtk.Button:_draw_rectangular_button(x,y,hover,clicked,gradient,brightness,cmul,bmul,alpha)local calc=self.calc
local pre=self._pre
local amul=calc.alpha*alpha
local label_over_surface=calc.surface and(calc.flat==rtk.Button.RAISED or hover)local textcolor=label_over_surface and calc.textcolor or calc.textcolor2
local draw_surface=label_over_surface or(calc.label and calc.tagged and calc.surface)local tagx=x+pre.tagx
local surx=x+pre.surx
local sury=y+pre.sury
local surw=pre.surw
local surh=pre.surh
if calc.tagged and calc.flat==rtk.Button.LABEL and calc.surface and not hover then
surx=tagx
surw=pre.tagw
end
if surw>0 and surh>0 and draw_surface then
local d=(gradient*calc.gradient)/calc.h
local lmul=1-calc.h*d/2
local r,g,b,a=rtk.color.rgba(calc.color)local sr,sg,sb,sa=rtk.color.mod({r,g,b,a},1.0,1.0,brightness*lmul,amul)gfx.gradrect(surx,sury,surw,surh,sr*cmul,sg*cmul,sb*cmul,sa*amul,0,0,0,0,r*d,g*d,b*d,0)gfx.set(r*bmul,g*bmul,b*bmul,amul)gfx.rect(surx,sury,surw,surh,0)if pre.tagw>0 and(hover or calc.flat~=rtk.Button.LABEL)then
local ta=1-(calc.tagalpha or self._theme.button_tag_alpha)self:setcolor({0,0,0,1})gfx.muladdrect(tagx,sury,pre.tagw,surh,ta,ta,ta,1.0)end
elseif calc.bg then
self:setcolor(calc.bg)gfx.rect(x,y,calc.w,calc.h,1)end
if calc.icon then
self:_draw_icon(x+pre.ix,y+pre.iy,hover,alpha)end
if calc.label then
self:setcolor(textcolor,alpha)self._font:draw(self._segments,x+pre.lx,y+pre.ly,pre.clipw,pre.cliph)end
end
function rtk.Button:_draw_icon(x,y,hovering,alpha)self.calc.icon:draw(x,y,self.calc.alpha*alpha,rtk.scale.value)end
end)()

__mod_rtk_entry=(function()
local rtk=__mod_rtk_core
local log=__mod_rtk_log
rtk.Entry=rtk.class('rtk.Entry', rtk.Widget)rtk.Entry.static.contextmenu={{'Undo', id='undo'},rtk.NativeMenu.SEPARATOR,{'Cut', id='cut'},{'Copy', id='copy'},{'Paste', id='paste'},{'Delete', id='delete'},rtk.NativeMenu.SEPARATOR,{'Select All', id='select_all'},}rtk.Entry.register{[1]=rtk.Attribute{alias='value'},value=rtk.Attribute{default='',reflow=rtk.Widget.REFLOW_NONE,calculate=function(self,attr,value,target)return value and tostring(value) or ''end,},textwidth=rtk.Attribute{reflow=rtk.Widget.REFLOW_FULL},icon=rtk.Attribute{reflow=rtk.Widget.REFLOW_FULL,calculate=function(self,attr,value,target)if type(value)=='string' then
local icon=self.calc.icon
local style=rtk.color.get_icon_style(self.calc.bg or rtk.theme.bg,rtk.theme.bg)if icon and icon.style==style then
return icon
end
local img=rtk.Image.icon(value,style)if not img then
img=rtk.Image.make_placeholder_icon(24,24,style)end
return img
else
return value
end
end
},icon_alpha=0.6,spacing=rtk.Attribute{default=5,reflow=rtk.Widget.REFLOW_FULL
},placeholder=rtk.Attribute{default=nil,reflow=rtk.Widget.REFLOW_FULL,},textcolor=rtk.Attribute{default=function(self,attr)return rtk.theme.text
end,calculate=rtk.Reference('bg')},border_hover=rtk.Attribute{default=function(self,attr)return {rtk.theme.entry_border_hover,1}end,reflow=rtk.Widget.REFLOW_FULL,calculate=function(self,attr,value,target)return rtk.Widget.static._calc_border(self,value)end,},border_focused=rtk.Attribute{default=function(self,attr)return {rtk.theme.entry_border_focused,1}end,reflow=rtk.Widget.REFLOW_FULL,calculate=rtk.Reference('border_hover'),},blink=true,caret=rtk.Attribute{type='number',default=1,priority=true,reflow=rtk.Widget.REFLOW_NONE,calculate=function(self,attr,value,target)return rtk.clamp(value, 1, #(target.value or '') + 1)end,},font=rtk.Attribute{reflow=rtk.Widget.REFLOW_FULL,default=function(self,attr)return self._theme_font[1]
end
},fontsize=rtk.Attribute{reflow=rtk.Widget.REFLOW_FULL,default=function(self,attr)return self._theme_font[2]
end
},fontscale=rtk.Attribute{default=1.0,reflow=rtk.Widget.REFLOW_FULL
},fontflags=rtk.Attribute{default=function(self,attr)return self._theme_font[3]
end
},bg=rtk.Attribute{default=function(self,attr)return rtk.theme.entry_bg
end
},tpadding=4,rpadding=10,bpadding=4,lpadding=10,cursor=rtk.mouse.cursors.BEAM,autofocus=true,}function rtk.Entry:initialize(attrs,...)self._theme_font=rtk.theme.entry_font or rtk.theme.default_font
rtk.Widget.initialize(self,attrs,self.class.attributes.defaults,...)self._positions={0}self._backingstore=nil
self._font=rtk.Font()self._caretctr=0
self._selstart=nil
self._selend=nil
self._loffset=0
self._blinking=false
self._dirty_text=false
self._dirty_positions=nil
self._dirty_view=false
self._history=nil
self._last_doubleclick_time=0
self._num_doubleclicks=0
end
function rtk.Entry:_handle_attr(attr,value,oldval,trigger,reflow,sync)local calc=self.calc
local ok=rtk.Widget._handle_attr(self,attr,value,oldval,trigger,reflow,sync)if ok==false then
return ok
end
if attr=='value' then
self._dirty_text=true
if not self._dirty_positions then
local diff=math.min(#value,#oldval)for i=1,diff do
if value:sub(i,i)~=oldval:sub(i,i)then
diff=i
break
end
end
self._dirty_positions=diff
end
self._selstart=nil
local caret=rtk.clamp(calc.caret,1,#value+1)if caret~=calc.caret then
self:sync('caret', caret)end
if trigger then
self:_handle_change()end
elseif attr=='caret' then
self._dirty_view=true
elseif attr == 'bg' and type(self.icon) == 'string' then
self:attr('icon', self.icon, true)elseif attr=='icon' and value then
self._last_reflow_scale=nil
end
return true
end
function rtk.Entry:_reflow(boxx,boxy,boxw,boxh,fillw,fillh,clampw,clamph,uiscale,viewport,window)local calc=self.calc
local maxw,maxh=nil,nil
if self._font:set(calc.font,calc.fontsize,calc.fontscale,calc.fontflags)then
self._dirty_positions=1
end
if calc.icon and uiscale~=self._last_reflow_scale then
calc.icon:refresh_scale()self._last_reflow_scale=uiscale
end
if calc.textwidth and not self.w then
local charwidth, _=gfx.measurestr('W')maxw,maxh=charwidth*calc.textwidth,self._font.texth
else
maxw, maxh=gfx.measurestr(calc.placeholder or "Dummy string!")end
calc.x,calc.y=self:_get_box_pos(boxx,boxy)local w,h,tp,rp,bp,lp=self:_get_content_size(boxw,boxh,fillw,fillh,clampw,clamph)calc.w=(w or maxw)+lp+rp
calc.h=(h or maxh)+tp+bp
self._ctp,self._crp,self._cbp,self._clp=tp,rp,bp,lp
if not self._backingstore then
self._backingstore=rtk.Image()end
self._backingstore:resize(calc.w,calc.h,false)self._dirty_text=true
end
function rtk.Entry:_unrealize()rtk.Widget._unrealize(self)self._backingstore=nil
end
function rtk.Entry:_calcpositions(startfrom)startfrom=startfrom or 1
local value=self.calc.value
self._font:set()for i=startfrom,#value+1 do
local w,_=gfx.measurestr(value:sub(1,i))self._positions[i+1]=w
end
self._dirty_positions=nil
end
function rtk.Entry:_calcview()local calc=self.calc
local curx=self._positions[calc.caret]
local curoffset=curx-self._loffset
local innerw=calc.w-(self._clp+self._crp)if calc.icon then
innerw=innerw-(calc.icon.w*rtk.scale.value/calc.icon.density)-calc.spacing
end
local loffset=self._loffset
if curoffset<0 then
loffset=curx
elseif curoffset>innerw then
loffset=curx-innerw
end
local last=self._positions[#calc.value+1]
if last>innerw then
local gap=innerw-(last-loffset)if gap>0 then
loffset=loffset-gap
end
else
loffset=0
end
if loffset~=self._loffset then
self._dirty_text=true
self._loffset=loffset
end
self._dirty_view=false
end
function rtk.Entry:_handle_focus(event,context)local ok=rtk.Widget._handle_focus(self,event,context)self._dirty_text=self._dirty_text or(ok and self._selstart)return ok
end
function rtk.Entry:_handle_blur(event,other)local ok=rtk.Widget._handle_blur(self,event,other)self._dirty_text=self._dirty_text or(ok and self._selstart)return ok
end
function rtk.Entry:_blink()if self.calc.blink and self:focused()then
self._blinking=true
local ctr=self._caretctr%16
self._caretctr=self._caretctr+1
if ctr==0 then
self:queue_draw()end
rtk.defer(self._blink,self)end
end
function rtk.Entry:_caret_from_mouse_event(event)local calc=self.calc
local iconw=calc.icon and(calc.icon.w*rtk.scale.value/calc.icon.density+calc.spacing)or 0
local relx=self._loffset+event.x-self.clientx-iconw-self._clp
for i=2,calc.value:len()+1 do
local pos=self._positions[i]
local width=pos-self._positions[i-1]
if relx<=self._positions[i]-width/2 then
return i-1
end
end
return calc.value:len()+1
end
local function is_word_break_character(value,pos)local c=value:sub(pos,pos)return c ~='_' and c:match('[%c%p%s]')end
function rtk.Entry:_get_word_left(spaces)local value=self.calc.value
local caret=self.calc.caret
if spaces then
while caret>1 and is_word_break_character(value,caret-1)do
caret=caret-1
end
end
while caret>1 and not is_word_break_character(value,caret-1)do
caret=caret-1
end
return caret
end
function rtk.Entry:_get_word_right(spaces)local value=self.calc.value
local caret=self.calc.caret
local len=value:len()while caret<=len and not is_word_break_character(value,caret)do
caret=caret+1
end
if spaces then
while caret<=len and is_word_break_character(value,caret)do
caret=caret+1
end
end
return caret
end
function rtk.Entry:select_all()self._selstart=1
self._selend=self.calc.value:len()+1
self._dirty_text=true
self:queue_draw()end
function rtk.Entry:select_range(a,b)local len=#self.calc.value
if len==0 or not a then
self._selstart=nil
else
b=b or a
self._selstart=math.max(1,a)self._selend=b>0 and math.min(len+1,b+1)or math.max(self._selstart,len+b+2)end
self._dirty_text=true
self:queue_draw()end
function rtk.Entry:get_selection_range()if self._selstart then
return math.min(self._selstart,self._selend),math.max(self._selstart,self._selend)end
end
function rtk.Entry:_edit(insert,delete_selection,dela,delb,caret)local calc=self.calc
local value=calc.value
if delete_selection then
dela,delb=self:get_selection_range()if dela and delb then
local ndeleted=delb-dela
caret=rtk.clamp(dela,1,#value)end
end
caret=caret or calc.caret
if dela and delb then
dela=rtk.clamp(dela,1,#value)delb=rtk.clamp(delb,1,#value+1)value=value:sub(1,dela-1)..value:sub(delb)self._dirty_positions=math.min(dela-1,self._dirty_positions or math.inf)end
if insert then
self._dirty_positions=math.min(caret-1,self._dirty_positions or math.inf)value=value:sub(0,caret-1)..insert..value:sub(caret)caret=caret+insert:len()end
if value~=calc.value then
caret=rtk.clamp(caret,1,#value+1)self:sync('value', value)if caret~=calc.caret then
self:sync('caret', caret)end
self._dirty_view=true
end
end
function rtk.Entry:delete_range(a,b)self:push_undo()self:_edit(nil,nil,a,b)end
function rtk.Entry:delete()if self._selstart then
self:push_undo()end
self:_edit(nil,true)end
function rtk.Entry:clear()if self.calc.value ~='' then
self:push_undo()self:sync('value', '')end
end
function rtk.Entry:copy()if self._selstart then
local a,b=self:get_selection_range()local text=self.calc.value:sub(a,b-1)if rtk.clipboard.set(text)then
return text
end
end
end
function rtk.Entry:cut()local copied=self:copy()if copied then
self:delete()end
return copied
end
function rtk.Entry:paste()local str=rtk.clipboard.get()if str and str ~='' then
self:push_undo()self:_edit(str,true)return str
end
end
function rtk.Entry:insert(text)self:push_undo()self:_edit(text)end
function rtk.Entry:undo()local calc=self.calc
if self._history and #self._history>0 then
local state=table.remove(self._history,#self._history)local value,caret
value,caret,self._selstart,self._selend=table.unpack(state)self:sync('value', value)self:sync('caret', caret)return true
else
return false
end
end
function rtk.Entry:push_undo()if not self._history then
self._history={}end
local calc=self.calc
self._history[#self._history+1]={calc.value,calc.caret,self._selstart,self._selend}end
function rtk.Entry:_handle_mousedown(event)local ok=rtk.Widget._handle_mousedown(self,event)if ok==false then
return ok
end
if event.button==rtk.mouse.BUTTON_LEFT then
local caret=self:_caret_from_mouse_event(event)self._selstart=nil
self._dirty_text=true
self:sync('caret', caret)self:queue_draw()elseif event.button==rtk.mouse.BUTTON_RIGHT then
if not self._popup then
self._popup=rtk.NativeMenu(rtk.Entry.contextmenu)end
local clipboard=rtk.clipboard.get()self._popup:item('undo').disabled = not self._history or #self._history == 0
self._popup:item('cut').disabled = not self._selstart
self._popup:item('copy').disabled = not self._selstart
self._popup:item('delete').disabled = not self._selstart
self._popup:item('paste').disabled = not clipboard or clipboard == ''self._popup:item('select_all').disabled = #self.calc.value == 0
self._popup:open_at_mouse():done(function(item)if item then
self[item.id](self)end
end)end
return true
end
function rtk.Entry:_handle_keypress(event)local ok=rtk.Widget._handle_keypress(self,event)if ok==false then
return ok
end
local calc=self.calc
local newcaret=nil
local len=calc.value:len()local orig_caret=calc.caret
local selecting=event.shift
if event.keycode==rtk.keycodes.LEFT then
if not selecting and self._selstart then
newcaret=self._selstart
elseif event.ctrl then
newcaret=self:_get_word_left(true)else
newcaret=math.max(1,calc.caret-1)end
elseif event.keycode==rtk.keycodes.RIGHT then
if not selecting and self._selstart then
newcaret=self._selend
elseif event.ctrl then
newcaret=self:_get_word_right(true)else
newcaret=math.min(calc.caret+1,len+1)end
elseif event.keycode==rtk.keycodes.HOME then
newcaret=1
elseif event.keycode==rtk.keycodes.END then
newcaret=calc.value:len()+1
elseif event.keycode==rtk.keycodes.DELETE then
if self._selstart then
self:delete()else
if event.ctrl then
self:push_undo()self:_edit(nil,false,calc.caret,self:_get_word_right(true)-1)elseif calc.caret<=len then
self:_edit(nil,false,calc.caret,calc.caret+1)end
end
elseif event.keycode==rtk.keycodes.BACKSPACE then
if calc.caret>=1 then
if self._selstart then
self:delete()else
if event.ctrl then
self:push_undo()local caret=self:_get_word_left(true)self:_edit(nil,false,caret,calc.caret,caret)elseif calc.caret>1 then
local caret=calc.caret-1
self:_edit(nil,false,caret,caret+1,caret)end
end
end
elseif event.char and not event.ctrl then
if self._selstart then
self:push_undo()end
self:_edit(event.char,true)selecting=false
elseif event.ctrl and event.char and not event.shift then
if event.char=='a' and len > 0 then
self:select_all()selecting=nil
elseif event.char=='c' then
self:copy()return true
elseif event.char=='x' then
self:cut()elseif event.char=='v' then
self:paste()elseif event.char=='z' then
self:undo()selecting=nil
end
else
return ok
end
if newcaret then
self:sync('caret', newcaret)end
if selecting then
if not self._selstart then
self._selstart=orig_caret
end
self._selend=calc.caret
self._dirty_text=true
elseif selecting==false and self._selstart then
self._selstart=nil
self._dirty_text=true
end
self._caretctr=0
log.debug2('keycode=%s char=%s caret=%s ctrl=%s shift=%s meta=%s alt=%s sel=%s-%s',event.keycode,event.char,calc.caret,event.ctrl,event.shift,event.meta,event.alt,self._selstart,self._selend
)return true
end
function rtk.Entry:_get_touch_activate_delay(event)if self:focused()then
return 0
else
return rtk.Widget._get_touch_activate_delay(self,event)end
end
function rtk.Entry:_handle_dragstart(event)if not self:focused()or event.button~=rtk.mouse.BUTTON_LEFT then
return
end
local draggable,droppable=self:ondragstart(self,event)if draggable==nil then
self._selstart=self.calc.caret
self._selend=self.calc.caret
return true,false
end
return draggable,droppable
end
function rtk.Entry:_handle_dragmousemove(event)local ok=rtk.Widget._handle_dragmousemove(self,event)if ok==false then
return ok
end
local selend=self:_caret_from_mouse_event(event)if selend==self._selend then
return ok
end
self._selend=selend
self:sync('caret', selend)self._dirty_text=true
return ok
end
function rtk.Entry:_handle_click(event)local ok=rtk.Widget._handle_click(self,event)if ok==false or event.button~=rtk.mouse.BUTTON_LEFT then
return ok
end
if event.time-self._last_doubleclick_time<0.7 then
self:select_all()self._last_doubleclick_time=0
elseif rtk.dnd.dragging~=self then
self:select_range(nil)rtk.Widget.focus(self)end
return ok
end
function rtk.Entry:_handle_doubleclick(event)local ok=rtk.Widget._handle_doubleclick(self,event)if ok==false or event.button~=rtk.mouse.BUTTON_LEFT then
return ok
end
self._last_doubleclick_time=event.time
local left=self:_get_word_left(false)local right=self:_get_word_right(true)self:sync('caret', right)self:select_range(left,right-1)return true
end
function rtk.Entry:_rendertext(x,y)self._font:set()self._backingstore:blit{src=gfx.dest,sx=x+self._clp,sy=y+self._ctp,mode=rtk.Image.FAST_BLIT
}self._backingstore:pushdest()if self._selstart and self:focused()then
local a,b=self:get_selection_range()self:setcolor(rtk.theme.entry_selection_bg)gfx.rect(self._positions[a]-self._loffset,0,self._positions[b]-self._positions[a],self._backingstore.h,1
)end
self:setcolor(self.calc.textcolor)self._font:draw(self.calc.value,-self._loffset,rtk.os.mac and 1 or 0)self._backingstore:popdest()self._dirty_text=false
end
function rtk.Entry:_draw(offx,offy,alpha,event,clipw,cliph,cltargetx,cltargety,parentx,parenty)local calc=self.calc
if offy~=self.offy or offx~=self.offx then
self._dirty_text=true
end
rtk.Widget._draw(self,offx,offy,alpha,event,clipw,cliph,cltargetx,cltargety,parentx,parenty)local x,y=calc.x+offx,calc.y+offy
local focused=self:focused()if(y+calc.h<0 or y>cliph or calc.ghost)and not focused then
return false
end
if self.disabled then
alpha=alpha*0.5
end
local scale=rtk.scale.value
local tp,rp,bp,lp=self._ctp,self._crp,self._cbp,self._clp
self:_handle_drawpre(offx,offy,alpha,event)self:_draw_bg(offx,offy,alpha,event)if self._dirty_positions then
self:_calcpositions(self._dirty_positions)end
if self._dirty_view or self._dirty_text then
self:_calcview()end
if self._dirty_text then
self:_rendertext(x,y)end
local amul=calc.alpha*alpha
local icon=calc.icon
if icon then
local a=math.min(1,calc.icon_alpha*alpha+(focused and 0.2 or 0))icon:draw(x+lp,y+((calc.h+tp-bp)-icon.h*scale/icon.density)/2,a*amul,scale
)lp=lp+icon.w*scale/icon.density+calc.spacing
end
self._backingstore:blit{sx=0,sy=0,sw=calc.w-lp-rp,sh=calc.h-tp-bp,dx=x+lp,dy=y+tp,alpha=amul,mode=rtk.Image.FAST_BLIT
}if calc.placeholder and #calc.value==0 then
self._font:set()self:setcolor(rtk.theme.entry_placeholder,alpha)self._font:draw(calc.placeholder,x+lp,y+tp+(rtk.os.mac and 1 or 0),calc.w-lp,calc.h-tp
)end
if focused then
local showcursor=not self._selstart or(self._selend-self._selstart)==0
if not self._blinking and showcursor then
self:_blink()end
self:_draw_borders(offx,offy,alpha,calc.border_focused)if self._caretctr%32<16 and showcursor then
local curx=x+self._positions[calc.caret]+lp-self._loffset
self:setcolor(calc.textcolor,alpha)gfx.line(curx,y+tp,curx,y+calc.h-bp,0)end
else
self._blinking=false
if self.hovering then
self:_draw_borders(offx,offy,alpha,calc.border_hover)else
self:_draw_borders(offx,offy,alpha)end
end
self:_handle_draw(offx,offy,alpha,event)end
function rtk.Entry:onchange(event)end
function rtk.Entry:_handle_change(event)return self:onchange(event)end
end)()

__mod_rtk_text=(function()
local rtk=__mod_rtk_core
rtk.Text=rtk.class('rtk.Text', rtk.Widget)rtk.Text.static.WRAP_NONE=false
rtk.Text.static.WRAP_NORMAL=true
rtk.Text.static.WRAP_BREAK_WORD=2
rtk.Text.register{[1]=rtk.Attribute{alias='text'},text=rtk.Attribute{default='Text',reflow=rtk.Widget.REFLOW_FULL,},color=rtk.Attribute{default=function(self,attr)return rtk.theme.text
end,calculate=rtk.Reference('bg'),},wrap=rtk.Attribute{default=rtk.Text.WRAP_NONE,reflow=rtk.Widget.REFLOW_FULL,calculate={['none']=rtk.Text.WRAP_NONE,['normal']=rtk.Text.WRAP_NORMAL,['break-word']=rtk.Text.WRAP_BREAK_WORD
},},textalign=rtk.Attribute{default=nil,calculate=rtk.Reference('halign'),},overflow=false,spacing=rtk.Attribute{default=0,reflow=rtk.Widget.REFLOW_FULL,},font=rtk.Attribute{default=function(self,attr)return self._theme_font[1]
end,reflow=rtk.Widget.REFLOW_FULL,},fontsize=rtk.Attribute{default=function(self,attr)return self._theme_font[2]
end,reflow=rtk.Widget.REFLOW_FULL,},fontscale=rtk.Attribute{default=1.0,reflow=rtk.Widget.REFLOW_FULL,},fontflags=rtk.Attribute{default=function(self,attr)return self._theme_font[3]
end
},}function rtk.Text:initialize(attrs,...)self._theme_font=self._theme_font or rtk.theme.text_font or rtk.theme.default_font
rtk.Widget.initialize(self,attrs,rtk.Text.attributes.defaults,...)self._font=rtk.Font()end
function rtk.Text:__tostring_info()return self.text
end
function rtk.Text:_handle_attr(attr,value,oldval,trigger,reflow,sync)if attr == 'text' and reflow == rtk.Widget.REFLOW_DEFAULT and self.w and not self.calc.wrap then
if not value:find('\n') and not oldval:find('\n') then
reflow=rtk.Widget.REFLOW_PARTIAL
end
end
local ok=rtk.Widget._handle_attr(self,attr,value,oldval,trigger,reflow,sync)if ok==false then
return ok
end
if self._segments and (attr == 'text' or attr == 'wrap' or attr == 'textalign' or attr == 'spacing') then
self._segments.dirty=true
end
return ok
end
function rtk.Text:_reflow(boxx,boxy,boxw,boxh,fillw,fillh,clampw,clamph,uiscale,viewport,window)local calc=self.calc
calc.x,calc.y=self:_get_box_pos(boxx,boxy)self._font:set(calc.font,calc.fontsize,calc.fontscale,calc.fontflags)local w,h,tp,rp,bp,lp=self:_get_content_size(boxw,boxh,fillw,fillh,clampw,clamph)local hpadding=lp+rp
local vpadding=tp+bp
local lmaxw=(clampw or fillw)and(boxw-hpadding)or w or math.inf
local lmaxh=(clamph or fillh)and(boxh-vpadding)or h or math.inf
local seg=self._segments
if not seg or seg.boxw~=lmaxw or not seg.isvalid()then
self._segments,self.lw,self.lh=self._font:layout(calc.text,lmaxw,lmaxh,calc.wrap~=rtk.Text.WRAP_NONE,self.textalign and calc.textalign or calc.halign,true,calc.spacing,calc.wrap==rtk.Text.WRAP_BREAK_WORD
)end
calc.w=(w and w+hpadding)or(fillw and boxw)or math.min(clampw and boxw or math.inf,self.lw+hpadding)calc.h=(h and h+vpadding)or(fillh and boxh)or math.min(clamph and boxh or math.inf,self.lh+vpadding)calc.w=math.round(rtk.clamp(calc.w,calc.minw,calc.maxw))calc.h=math.round(rtk.clamp(calc.h,calc.minh,calc.maxh))end
function rtk.Text:_realize_geometry()local calc=self.calc
local tp,rp,bp,lp=self:_get_padding_and_border()local lx,ly
if calc.halign==rtk.Widget.LEFT then
lx=lp
elseif calc.halign==rtk.Widget.CENTER then
lx=lp+math.max(0,calc.w-self.lw-lp-rp)/2
elseif calc.halign==rtk.Widget.RIGHT then
lx=math.max(0,calc.w-self.lw-rp)end
if calc.valign==rtk.Widget.TOP then
ly=tp
elseif calc.valign==rtk.Widget.CENTER then
ly=tp+math.max(0,calc.h-self.lh-tp-bp)/2
elseif calc.valign==rtk.Widget.BOTTOM then
ly=math.max(0,calc.h-self.lh-bp)end
self._pre={tp=tp,rp=rp,bp=bp,lp=lp,lx=lx,ly=ly,}end
function rtk.Text:_draw(offx,offy,alpha,event,clipw,cliph,cltargetx,cltargety,parentx,parenty)rtk.Widget._draw(self,offx,offy,alpha,event,clipw,cliph,cltargetx,cltargety,parentx,parenty)local calc=self.calc
local x,y=calc.x+offx,calc.y+offy
if y+calc.h<0 or y>cliph or calc.ghost then
return
end
local pre=self._pre
self:_handle_drawpre(offx,offy,alpha,event)self:_draw_bg(offx,offy,alpha,event)self:setcolor(calc.color,alpha)assert(self._segments)self._font:draw(self._segments,x+pre.lx,y+pre.ly,not calc.overflow and math.min(clipw-x,calc.w)-pre.lx-pre.rp or nil,not calc.overflow and math.min(cliph-y,calc.h)-pre.ly-pre.bp or nil
)self:_draw_borders(offx,offy,alpha)self:_handle_draw(offx,offy,alpha,event)end
end)()

__mod_rtk_heading=(function()
local rtk=__mod_rtk_core
rtk.Heading=rtk.class('rtk.Heading', rtk.Text)rtk.Heading.register{color=rtk.Attribute{default=function(self,attr)return rtk.theme.heading or rtk.theme.text
end
},}function rtk.Heading:initialize(attrs,...)self._theme_font=self._theme_font or rtk.theme.heading_font or rtk.theme.default_font
rtk.Text.initialize(self,attrs,self.class.attributes.defaults,...)end
end)()

__mod_rtk_imagebox=(function()
local rtk=__mod_rtk_core
local log=__mod_rtk_log
rtk.ImageBox=rtk.class('rtk.ImageBox', rtk.Widget)rtk.ImageBox.register{[1]=rtk.Attribute{alias='image'},image=rtk.Attribute{calculate=rtk.Entry.attributes.icon.calculate,reflow=rtk.Widget.REFLOW_FULL,},scale=rtk.Attribute{reflow=rtk.Widget.REFLOW_FULL,},aspect=rtk.Attribute{reflow=rtk.Widget.REFLOW_FULL,},}function rtk.ImageBox:initialize(attrs,...)rtk.Widget.initialize(self,attrs,self.class.attributes.defaults,...)end
function rtk.ImageBox:_handle_attr(attr,value,oldval,trigger,reflow,sync)local ret=rtk.Widget._handle_attr(self,attr,value,oldval,trigger,reflow,sync)if ret==false then
return ret
end
if attr=='image' and value then
self._last_reflow_scale=nil
end
return ret
end
function rtk.ImageBox:_reflow(boxx,boxy,boxw,boxh,fillw,fillh,clampw,clamph,uiscale,viewport,window)local calc=self.calc
calc.x,calc.y=self:_get_box_pos(boxx,boxy)local w,h,tp,rp,bp,lp=self:_get_content_size(boxw,boxh,fillw,fillh,clampw,clamph,self.scale or 1
)local dstw,dsth=0,0
local hpadding=lp+rp
local vpadding=tp+bp
local image=calc.image
if image then
if uiscale~=self._last_reflow_scale then
image:refresh_scale()self._last_reflow_scale=uiscale
end
local scale=(self.scale or 1)*rtk.scale.value/image.density
local native_aspect=image.w/image.h
local aspect=calc.aspect or native_aspect
dstw=w or(fillw and(boxw-hpadding))dsth=h or(fillh and(boxh-vpadding))local constrain=self.scale==nil and not w and not h
if dstw and not dsth then
dsth=math.min(clamph and boxw or math.inf,dstw)/aspect
elseif not dstw and dsth then
dstw=math.min(clampw and boxh or math.inf,dsth)*aspect
elseif not dstw and not dsth then
dstw=image.w*scale/(native_aspect/aspect)dsth=image.h*scale
end
if constrain then
if dstw+hpadding>boxw then
dstw=boxw-hpadding
dsth=dstw/aspect
end
if dsth+vpadding>boxh then
dsth=boxh-vpadding
dstw=dsth*aspect
end
end
self.iscale=dstw/image.w
calc.aspect=aspect
calc.scale=self.iscale
else
self.iscale=1.0
end
self.iw=math.round(math.max(0,dstw))self.ih=math.round(math.max(0,dsth))calc.w=(fillw and boxw)or math.min(clampw and boxw or math.inf,self.iw+hpadding)calc.h=(fillh and boxh)or math.min(clamph and boxh or math.inf,self.ih+vpadding)calc.w=math.round(rtk.clamp(calc.w,self.minw,self.maxw))calc.h=math.round(rtk.clamp(calc.h,self.minh,self.maxh))end
function rtk.ImageBox:_realize_geometry()local calc=self.calc
local tp,rp,bp,lp=self:_get_padding_and_border()local ix,iy
if calc.halign==rtk.Widget.LEFT then
ix=lp
elseif calc.halign==rtk.Widget.CENTER then
ix=lp+math.max(0,calc.w-self.iw-lp-rp)/2
elseif calc.halign==rtk.Widget.RIGHT then
ix=math.max(0,calc.w-self.iw-rp)end
if calc.valign==rtk.Widget.TOP then
iy=tp
elseif calc.valign==rtk.Widget.CENTER then
iy=tp+math.max(0,calc.h-self.ih-tp-bp)/2
elseif calc.valign==rtk.Widget.BOTTOM then
iy=math.max(0,calc.h-self.ih-bp)end
self._pre={ix=ix,iy=iy}end
function rtk.ImageBox:_draw(offx,offy,alpha,event,clipw,cliph,cltargetx,cltargety,parentx,parenty)rtk.Widget._draw(self,offx,offy,alpha,event,clipw,cliph,cltargetx,cltargety,parentx,parenty)local calc=self.calc
local x,y=calc.x+offx,calc.y+offy
if not self.image or y+calc.h<0 or y>cliph or calc.ghost then
return
end
local pre=self._pre
self:_handle_drawpre(offx,offy,alpha,event)self:_draw_bg(offx,offy,alpha,event)calc.image:blit{dx=x+pre.ix,dy=y+pre.iy,dw=self.iw,dh=self.ih,alpha=calc.alpha*alpha,clipw=calc.w,cliph=calc.h,}self:_draw_borders(offx,offy,alpha)self:_handle_draw(offx,offy,alpha,event)end
end)()

__mod_rtk_optionmenu=(function()
local rtk=__mod_rtk_core
rtk.OptionMenu=rtk.class('rtk.OptionMenu', rtk.Button)rtk.OptionMenu.static._icon=nil
rtk.OptionMenu.register{[1]=rtk.Attribute{alias='menu'},menu=nil,icononly=rtk.Attribute{default=false,reflow=rtk.Widget.REFLOW_FULL,},selected=nil,selected_index=nil,selected_id=nil,selected_item=nil,icon=rtk.Attribute{default=function(self)return rtk.OptionMenu.static._icon
end,},iconpos=rtk.Widget.RIGHT,tagged=true,lpadding=10,rpadding=rtk.Attribute{default=function(self)return(self.icononly or self.circular)and self.lpadding or 7
end
},tagalpha=0.15,}function rtk.OptionMenu:initialize(attrs,...)if not rtk.OptionMenu._icon then
local icon=rtk.Image(13,17)icon:pushdest(icon.id)rtk.color.set(rtk.theme.text)gfx.triangle(2,6,10,6,6,10)icon:popdest()rtk.OptionMenu.static._icon=icon
end
rtk.Button.initialize(self,attrs,self.class.attributes.defaults,...)self._menu=rtk.NativeMenu()self:_handle_attr('menu', self.calc.menu)self:_handle_attr('icononly', self.calc.icononly)end
function rtk.OptionMenu:_reflow_get_max_label_size(boxw,boxh)local segments,lw,lh=rtk.Button._reflow_get_max_label_size(self,boxw,boxh)local w,h=0,0
for item in self._menu:items()do
local item_w,item_h=gfx.measurestr(item.altlabel or item.label)w=math.max(w,item_w)h=math.max(h,item_h)end
return segments,rtk.clamp(w,lw,boxw),rtk.clamp(h,lh,boxh)end
function rtk.OptionMenu:select(value,trigger)return self:attr('selected', value, trigger)end
function rtk.OptionMenu:_handle_attr(attr,value,oldval,trigger,reflow,sync)local ok=rtk.Button._handle_attr(self,attr,value,oldval,trigger,reflow,sync)if ok==false then
return ok
end
if attr=='menu' then
self._menu:set(value)if not self.calc.icononly and not self.selected then
self:sync('label', '')elseif self.selected then
self:_handle_attr('selected', self.selected, self.selected, true)end
elseif attr=='selected' then
local item=self._menu:item(value)self.selected_item=item
if item then
if not self.calc.icononly  then
self:sync('label', item.altlabel or item.label)end
self.selected_index=item.index
self.selected_id=item.id
rtk.Button.onattr(self,attr,value,oldval,trigger)else
self.selected_index=nil
self.selected_id=nil
if not self.calc.icononly then
self:sync('label', '')end
end
local last=self._menu:item(oldval)if value~=oldval and trigger~=false then
self:onchange(item,last)self:onselect(item,last)elseif trigger then
self:onselect(item,last)end
end
return true
end
function rtk.OptionMenu:open()assert(self.menu, 'menu attribute was not set on OptionMenu')self._menu:open_at_widget(self):done(function(item)if item then
self:sync('selected', item.id or item.index, nil, true)end
end)end
function rtk.OptionMenu:_handle_mousedown(event)local ok=rtk.Button._handle_mousedown(self,event)if ok==false then
return ok
end
self:open()return true
end
function rtk.OptionMenu:onchange(item,lastitem)end
function rtk.OptionMenu:onselect(item,lastitem)end
end)()

__mod_rtk_checkbox=(function()
local rtk=__mod_rtk_core
rtk.CheckBox=rtk.class('rtk.CheckBox', rtk.Button)rtk.CheckBox.static._icon_unchecked=nil
rtk.CheckBox.static.DUALSTATE=0
rtk.CheckBox.static.TRISTATE=1
rtk.CheckBox.static.UNCHECKED=false
rtk.CheckBox.static.CHECKED=true
rtk.CheckBox.static.INDETERMINATE=2
function rtk.CheckBox.static._make_icons()local w,h=18,18
local wp,hp=2,2
local colors
if rtk.theme.dark then
colors={border={1,1,1,0.90},fill={1,1,1,1},check={0,0,0,1},checkaa={0.4,0.4,0.4,1},iborder={1,1,1,0.92},}else
colors={border={0,0,0,0.90},fill={0,0,0,1},check={1,1,1,1},checkaa={0.6,0.6,0.6,1},iborder={0,0,0,0.92},}end
local icon=rtk.Image(w,h)icon:pushdest()rtk.color.set(colors.border)rtk.gfx.roundrect(wp,hp,w-wp*2,h-hp*2,2,1)gfx.rect(wp+1,hp+1,w-wp*2-2,h-hp*2-2,0)icon:popdest()rtk.CheckBox.static._icon_unchecked=icon
icon=rtk.Image(w,h)icon:pushdest()rtk.color.set(colors.fill)rtk.gfx.roundrect(wp,hp,w-wp*2,h-hp*2,2,1)rtk.color.set(colors.fill)gfx.rect(wp+1,hp+1,w-wp*2-2,h-hp*2-2,1)rtk.color.set(colors.checkaa)gfx.x=wp+3
gfx.y=hp+6
gfx.lineto(wp+5,hp+9)gfx.lineto(wp+10,hp+3)rtk.color.set(colors.check)gfx.x=wp+2
gfx.y=hp+6
gfx.lineto(wp+5,hp+10)gfx.lineto(wp+11,hp+3)icon:popdest()rtk.CheckBox.static._icon_checked=icon
icon=rtk.CheckBox.static._icon_unchecked:clone()icon:pushdest()rtk.color.set(colors.iborder)gfx.rect(wp+3,hp+3,w-wp*2-6,h-hp*2-6)rtk.color.set(colors.fill)gfx.rect(wp+4,hp+4,w-wp*2-8,h-hp*2-8,1)icon:popdest()rtk.CheckBox.static._icon_intermediate=icon
rtk.CheckBox.static._icon_hover=rtk.CheckBox.static._icon_unchecked:clone():recolor(rtk.theme.accent)end
rtk.CheckBox.register{type=rtk.Attribute{default=rtk.CheckBox.DUALSTATE,calculate={dualstate=rtk.CheckBox.DUALSTATE,tristate=rtk.CheckBox.TRISTATE
},},label=nil,value=rtk.Attribute{default=rtk.CheckBox.UNCHECKED,calculate={[rtk.Attribute.NIL]=rtk.CheckBox.UNCHECKED,checked=rtk.CheckBox.static.CHECKED,unchecked=rtk.CheckBox.static.UNCHECKED,indeterminate=rtk.CheckBox.static.INDETERMINATE,}},icon=rtk.Attribute{default=function(self,attr)return self._value_map[rtk.CheckBox.UNCHECKED]
end,},surface=false,valign=rtk.Widget.TOP,wrap=true,tpadding=0,rpadding=0,lpadding=0,bpadding=0,}function rtk.CheckBox:initialize(attrs,...)if rtk.CheckBox.static._icon_unchecked==nil then
rtk.CheckBox._make_icons()end
self._value_map={[rtk.CheckBox.UNCHECKED]=rtk.CheckBox._icon_unchecked,[rtk.CheckBox.CHECKED]=rtk.CheckBox._icon_checked,[rtk.CheckBox.INDETERMINATE]=rtk.CheckBox._icon_intermediate
}rtk.Button.initialize(self,attrs,self.class.attributes.defaults,...)self:_handle_attr('value', self.calc.value)end
function rtk.CheckBox:_handle_click(event)local ret=rtk.Button._handle_click(self,event)if ret==false then
return ret
end
self:toggle()return ret
end
function rtk.CheckBox:_handle_attr(attr,value,oldval,trigger,reflow,sync)local ret=rtk.Button._handle_attr(self,attr,value,oldval,trigger,reflow,sync)if ret~=false then
if attr=='value' then
self.calc.icon=self._value_map[value] or self._value_map[rtk.CheckBox.UNCHECKED]
if trigger then
self:onchange()end
end
end
return ret
end
function rtk.CheckBox:_draw_icon(x,y,hovering,alpha)rtk.Button._draw_icon(self,x,y,hovering,alpha)if hovering then
rtk.CheckBox._icon_hover:draw(x,y,alpha,rtk.scale.value)end
end
function rtk.CheckBox:toggle()local value=self.calc.value
if self.calc.type==rtk.CheckBox.DUALSTATE then
if value==rtk.CheckBox.CHECKED then
value=rtk.CheckBox.UNCHECKED
else
value=rtk.CheckBox.CHECKED
end
else
if value==rtk.CheckBox.CHECKED then
value=rtk.CheckBox.INDETERMINATE
elseif value==rtk.CheckBox.INDETERMINATE then
value=rtk.CheckBox.UNCHECKED
else
value=rtk.CheckBox.CHECKED
end
end
self:sync('value', value)return self
end
function rtk.CheckBox:onchange()end
end)()

__mod_rtk_application=(function()
local rtk=__mod_rtk_core
rtk.Application=rtk.class('rtk.Application', rtk.VBox)rtk.Application.register{status=rtk.Attribute{reflow=rtk.Widget.REFLOW_NONE
},statusbar=nil,toolbar=nil,screens=nil,}function rtk.Application:initialize(attrs,...)self.screens={stack={},}self.toolbar=rtk.HBox{bg=rtk.theme.bg,spacing=0,z=110,}self.toolbar:add(rtk.HBox.FLEXSPACE)self.statusbar=rtk.HBox{bg=rtk.theme.bg,lpadding=10,tpadding=5,bpadding=5,rpadding=10,z=110,}self.statusbar.text = self.statusbar:add(rtk.Text{color=rtk.theme.text_faded, text=""}, {expand=1})rtk.VBox.initialize(self,attrs,self.class.attributes.defaults,...)self:add(self.toolbar,{minw=150,bpadding=2})self:add(rtk.VBox.FLEXSPACE)self._content_position=#self.children
self:add(self.statusbar,{fillw=true})self:_handle_attr('status', self.calc.status)end
function rtk.Application:_handle_attr(attr,value,oldval,trigger,reflow,sync)local ok=rtk.VBox._handle_attr(self,attr,value,oldval,trigger,reflow,sync)if ok==false then
return ok
end
if attr=='status' then
self.statusbar.text:attr('text', value or ' ', nil, rtk.Widget.REFLOW_PARTIAL)end
return ok
end
function rtk.Application:add_screen(screen,name)assert(type(screen)=='table' and screen.init, 'screen must be a table containing an init() function')name=name or screen.name
assert(name, 'screen is missing name')assert(not self.screens[name], string.format('screen "%s" was already added', name))local widget=screen.init(self,screen)if widget then
assert(rtk.isa(widget, rtk.Widget), 'the return value from screen.init() must be type rtk.Widget (or nil)')screen.widget=widget
else
assert(rtk.isa(screen.widget, rtk.Widget), 'screen must contain a "widget" field of type rtk.Widget')end
screen.name=name
self.screens[name]=screen
if not screen.toolbar then
screen.toolbar=rtk.Spacer{h=0}end
self.toolbar:insert(1,screen.toolbar,{minw=50})screen.toolbar:hide()screen.widget:hide()if #self.screens.stack==0 then
self:replace_screen(screen)end
end
function rtk.Application:_show_screen(screen)screen=type(screen)=='table' and screen or self.screens[screen]
for _,s in ipairs(self.screens.stack)do
s.widget:hide()if s.toolbar then
s.toolbar:hide()end
end
assert(screen, 'screen not found, was add_screen() called?')if screen then
if screen.update then
screen.update(self,screen)end
if screen.widget.scrollto then
screen.widget:scrollto(0,0)end
screen.widget:show()self:replace(self._content_position,screen.widget,{expand=1,fillw=true,fillh=true,minw=screen.minw
})screen.toolbar:show()end
self:attr('status', nil)end
function rtk.Application:push_screen(screen)screen=type(screen)=='table' and screen or self.screens[screen]
assert(screen, 'screen not found, was add_screen() called?')if screen and #self.screens.stack>0 and self:current_screen()~=screen then
self:_show_screen(screen)self.screens.stack[#self.screens.stack+1]=screen
end
end
function rtk.Application:pop_screen()if #self.screens.stack>1 then
self:_show_screen(self.screens.stack[#self.screens.stack-1])table.remove(self.screens.stack)return true
else
return false
end
end
function rtk.Application:replace_screen(screen,idx)screen=type(screen)=='table' and screen or self.screens[screen]
assert(screen, 'screen not found, was add_screen() called?')local last=#self.screens.stack
idx=idx or last
if idx==0 then
idx=1
end
if idx>=last then
self:_show_screen(screen)elseif screen.update then
screen.update(self,screen)end
self.screens.stack[idx]=screen
end
function rtk.Application:current_screen()local n=#self.screens.stack
if n>0 then
return self.screens.stack[#self.screens.stack]
end
end
end)()

__mod_rtk_slider=(function()
local rtk=__mod_rtk_core
local log=__mod_rtk_log
rtk.Slider=rtk.class('rtk.Slider', rtk.Widget)rtk.Slider.static.TICKS_NEVER=0
rtk.Slider.static.TICKS_ALWAYS=1
rtk.Slider.static.TICKS_WHEN_ACTIVE=2
rtk.Slider.register{[1]=rtk.Attribute{alias='value'},value=rtk.Attribute{default=0,priority=true,reflow=rtk.Widget.REFLOW_NONE,calculate=function(self,attr,value,target)return type(value)=='table' and value or {value}end,set=function(self,attr,value,calculated,target)self._use_scalar_value=type(value) ~='table'for i=1,#calculated do
calculated[i]=rtk.clamp(tonumber(calculated[i]),target.min,target.max)if not self._thumbs[i] then
self._thumbs[i]={idx=i,radius=0,radius_target=0}end
end
for i=#calculated+1,#self._thumbs do
self._thumbs[i]=nil
end
target.value=calculated
end
},color=rtk.Attribute{type='color',default=function(self,attr)return rtk.theme.slider
end,calculate=rtk.Reference('bg'),},trackcolor=rtk.Attribute{type='color',default=function(self,attr)return rtk.theme.slider_track
end,calculate=rtk.Reference('bg'),},thumbsize=rtk.Attribute{default=6,reflow=rtk.Widget.REFLOW_FULL,},thumbcolor=rtk.Attribute{type='color',},ticklabels=rtk.Attribute{reflow=rtk.Widget.REFLOW_FULL,},ticklabelcolor=rtk.Attribute {type='color',default=function(self,attr)return rtk.theme.slider_tick_label or rtk.theme.text
end,},spacing=rtk.Attribute{default=2,reflow=rtk.Widget.REFLOW_FULL,},ticks=rtk.Attribute{default=rtk.Slider.TICKS_NEVER,calculate={never=rtk.Slider.TICKS_NEVER,always=rtk.Slider.TICKS_ALWAYS,['when-active']=rtk.Slider.TICKS_WHEN_ACTIVE,['false']=rtk.Slider.TICKS_NEVER,[false]=rtk.Slider.TICKS_NEVER,['true']=rtk.Slider.TICKS_ALWAYS,[true]=rtk.Slider.TICKS_ALWAYS,},set=function(self,attr,value,calculated,target)self._tick_alpha=calculated==rtk.Slider.TICKS_ALWAYS and 1 or 0
target.ticks=calculated
end,},ticksize=rtk.Attribute{default=4,reflow=rtk.Widget.REFLOW_FULL,},tracksize=rtk.Attribute{default=2,reflow=rtk.Widget.REFLOW_FULL,},min=0,max=100,step=rtk.Attribute{type='number',calculate=function(self,attr,value,target)return value and value>0 and value
end,},font=rtk.Attribute{default=function(self,attr)return self._theme_font[1]
end,reflow=rtk.Widget.REFLOW_FULL,},fontsize=rtk.Attribute{default=function(self,attr)return self._theme_font[2]
end,reflow=rtk.Widget.REFLOW_FULL,},fontscale=rtk.Attribute{default=1.0,reflow=rtk.Widget.REFLOW_FULL
},fontflags=rtk.Attribute{default=function(self,attr)return self._theme_font[3]
end
},focused_thumb_index=1,autofocus=true,scroll_on_drag=false,}function rtk.Slider:initialize(attrs,...)self._thumbs={}self._tick_alpha=0
self._hovering_thumb=nil
self._font=rtk.Font()self._theme_font=rtk.theme.slider_font or rtk.theme.default_font
rtk.Widget.initialize(self,attrs,rtk.Slider.attributes.defaults,...)end
function rtk.Slider:_handle_attr(attr,value,oldval,trigger,reflow,sync)local ok=rtk.Widget._handle_attr(self,attr,value,oldval,trigger,reflow,sync)if ok==false then
return ok
end
if attr=='value' then
self:onchange()elseif self._label_segments and attr=='ticklabels' then
self._label_segments=nil
end
end
function rtk.Slider:_reflow(boxx,boxy,boxw,boxh,fillw,fillh,clampw,clamph,uiscale,viewport,window)local calc=self.calc
calc.x,calc.y=self:_get_box_pos(boxx,boxy)local w,h,tp,rp,bp,lp=self:_get_content_size(boxw,boxh,fillw,fillh,clampw,clamph)local hpadding=lp+rp
local vpadding=tp+bp
local lh=0
local segments=self._label_segments
self._font:set(calc.font,calc.fontsize,calc.fontscale,calc.fontflags)if calc.step and calc.ticklabels and(not segments or not segments[1].isvalid())then
local lmaxw=(clampw or fillw)and(boxw-hpadding)or w or math.inf
local lmaxh=(clamph or fillh)and(boxh-vpadding)or h or math.inf
segments={}for n=1,#calc.ticklabels do
local label=calc.ticklabels[n] or ''local s,w,h=self._font:layout(label,lmaxw,lmaxh,false,rtk.Widget.CENTER,true,0,false
)s.w=w
s.h=h
segments[#segments+1]=s
lh=math.max(h,lh)end
lh=lh+calc.spacing
self._label_segments=segments
end
self.lh=lh
local minw=math.max(calc.minw or 0,#calc.value*calc.thumbsize*2)*rtk.scale.value
local minh=math.max(calc.minh or 0,calc.thumbsize*2,calc.tracksize)*rtk.scale.value
local size=math.max(calc.thumbsize*2,calc.ticksize,calc.tracksize)*rtk.scale.value
calc.w=w and(w+hpadding)or boxw
calc.h=h and(h+vpadding)or(size+self.lh+vpadding)calc.w=math.round(rtk.clamp(calc.w,minw,calc.maxw))calc.h=math.round(rtk.clamp(calc.h,minh,calc.maxh))return not w,false
end
function rtk.Slider:_realize_geometry()local calc=self.calc
local tp,rp,bp,lp=self:_get_padding_and_border()local scale=rtk.scale.value
local track={x=calc.x+lp+calc.thumbsize*scale,y=calc.y+tp+((calc.h-tp-bp-self.lh)-calc.tracksize*scale)/2,w=calc.w-lp-rp-calc.thumbsize*2*scale,h=calc.tracksize*scale,}local ticks
if calc.step then
ticks={distance=track.w/((calc.max-calc.min)/calc.step),size=calc.ticksize*scale,}ticks.offset=(ticks.size-track.h)/2
for x=track.x,track.x+track.w+1,ticks.distance do
ticks[#ticks+1]={x-ticks.offset,track.y-ticks.offset}end
if calc.ticklabels then
local ly=track.y+calc.tracksize+(calc.spacing+calc.thumbsize)*scale
for n,segments in ipairs(self._label_segments)do
local tick=ticks[n]
if not tick then
break
end
segments.x=tick[1]
local offset=segments.w-ticks.size
if n==#ticks then
segments.x=segments.x-offset
elseif n>1 then
segments.x=segments.x-offset/2
end
segments.y=ly
end
end
end
self._pre={tp=tp,rp=rp,bp=bp,lp=lp,track=track,ticks=ticks,}for idx=1,#self._thumbs do
self._thumbs[idx].value=nil
end
end
function rtk.Slider:_get_thumb(idx)assert(self._pre, '_get_thumb() called before reflow')local thumb=self._thumbs[idx]
local track=self._pre.track
local calc=self.calc
local value=calc.value[idx]
if thumb.value~=value then
thumb.pos=track.w*(value-calc.min)/(calc.max-calc.min)thumb.value=value
end
local c=self:calc('value')if c~=value then
thumb.pos_final=track.w*(c[idx]-calc.min)/(calc.max-calc.min)else
thumb.pos_final=thumb.pos
end
return thumb
end
function rtk.Slider:_get_nearest_thumb(clientx,clienty)local trackx=self.clientx+self._pre.lp
local tracky=self.clienty+self._pre.tp
local candidate=nil
local candidate_distance=nil
for i=1,#self._thumbs do
local thumb=self:_get_thumb(i)local delta=clientx-trackx-thumb.pos
local distance=math.abs(delta)if not candidate or(distance<candidate_distance)or(distance==candidate_distance and delta>0)then
candidate=thumb
candidate_distance=distance
end
end
return candidate
end
function rtk.Slider:_clamp_value_to_step(v)local calc=self.calc
local step=calc.step
return rtk.clamp(step and(math.round(v/step)*step)or v,calc.min,calc.max)end
function rtk.Slider:_set_thumb_value(thumbidx,value,animate,fast)value=self:_clamp_value_to_step(value)local current=self:calc('value')if current[thumbidx]==value then
return false
end
local newval=self._use_scalar_value and value or table.shallow_copy(current,{[thumbidx]=value})if animate==false then
self:cancel_animation('value')self:sync('value', newval)else
self:sync('value', newval, current)local duration=fast and 0.25 or 0.4
self:animate{'value', dst=newval, doneval=newval, duration=duration, easing='out-expo'}end
return true
end
function rtk.Slider:_set_thumb_value_with_crossover(idx,value,animate,event)local newidx
local calc=self.calc
if idx>1 and value<calc.value[idx-1] then
newidx=idx-1
elseif idx<#self._thumbs and value>calc.value[idx+1] then
newidx=idx+1
end
if newidx then
self:_set_thumb_value(idx,calc.value[newidx],false)self.focused_thumb_index=newidx
self._hovering_thumb=newidx
self:_animate_thumb_overlays(event,nil,true)end
local changed=self:_set_thumb_value(self.focused_thumb_index,value,animate,event.type~=rtk.Event.KEY)return changed,self.focused_thumb_index
end
function rtk.Slider:_is_mouse_over(clparentx,clparenty,event)if not self.window or not self.window.in_window then
self._hovering_thumb=nil
return false
end
local calc=self.calc
local pre=self._pre
local y=calc.y+clparenty+pre.tp
local track=pre.track
local trackx=track.x+clparentx
local tracky=track.y+clparenty
local radius=20*rtk.scale.value
if not event:is_widget_pressed(self)then
self._hovering_thumb=nil
if rtk.point_in_box(event.x,event.y,trackx-radius,y-radius,calc.w+radius*2,calc.h+radius*2)then
for i=1,#self._thumbs do
local thumb=self:_get_thumb(i)if rtk.point_in_circle(event.x,event.y,trackx+thumb.pos,tracky,radius)then
self._hovering_thumb=i
break
end
end
else
return false
end
end
return self._hovering_thumb or
rtk.point_in_box(event.x,event.y,trackx,y-calc.thumbsize,calc.w,calc.h+calc.thumbsize*2)end
function rtk.Slider:_handle_mouseleave(event)local ok=rtk.Widget._handle_mouseleave(self,event)if ok==false then
return ok
end
self:_animate_thumb_overlays(event)return ok
end
function rtk.Slider:_handle_mousedown(event)local ok=rtk.Widget._handle_mousedown(self,event)if ok==false then
return ok
end
local thumb=self:_get_nearest_thumb(event.x,event.y)self.focused_thumb_index=thumb.idx
if not self._hovering_thumb then
local value=self:_get_value_from_offset(event.x-self.clientx-self.calc.thumbsize)self:_set_thumb_value(thumb.idx,value,true,true)else
self._hovering_thumb=thumb.idx
end
self:_animate_thumb_overlays(event)self:_animate_ticks(true)return true
end
function rtk.Slider:_handle_mouseup(event)local ok=rtk.Widget._handle_mouseup(self,event)self:_animate_thumb_overlays(event,nil,true)self:_animate_ticks(false)return ok
end
function rtk.Slider:_handle_dragstart(event,x,y,t)local draggable,droppable=self:ondragstart(self,event,x,y,t)if draggable~=nil then
return draggable,droppable
end
local thumb=self:_get_nearest_thumb(x,y)self.focused_thumb_index=thumb.idx
self:_animate_thumb_overlays(event,nil,true)return {startx=x,starty=y,thumbidx=thumb.idx},false
end
function rtk.Slider:_handle_dragmousemove(event,arg)local ok=rtk.Widget._handle_dragmousemove(self,event)if ok==false or event.simulated then
return ok
end
if not arg.startpos then
local thumb=self:_get_thumb(arg.thumbidx)arg.startpos=thumb.pos_final
end
local offx=(event.x-arg.startx)if arg.fine then
offx=math.ceil(offx*0.2)end
local v=self:_get_value_from_offset(offx+arg.startpos)local value_changed
value_changed,arg.thumbidx=self:_set_thumb_value_with_crossover(arg.thumbidx,v,self.calc.step~=nil,event)if(event.shift and value_changed)or(event.shift~=arg.fine)then
arg.startx=event.x
arg.starty=event.y
arg.startpos=nil
end
arg.fine=event.shift
event:set_handled(self)return true
end
function rtk.Slider:_handle_dragend(event,dragarg)self:_animate_ticks(false)end
function rtk.Slider:_handle_mousemove(event)self:_animate_thumb_overlays(event)end
function rtk.Slider:_handle_focus(event,context)self:_animate_thumb_overlays(event,true)return rtk.Widget._handle_focus(self,event,context)end
function rtk.Slider:_handle_blur(event,other)self._hovering_thumb=nil
self:_animate_thumb_overlays(event,false)return rtk.Widget._handle_blur(self,event,other)end
function rtk.Slider:_handle_keypress(event)local ok=rtk.Widget._handle_keypress(self,event)if ok==false or not self.focused_thumb_index then
return ok
end
local calc=self.calc
local value=calc.value[self.focused_thumb_index]
local step=calc.step or(calc.max-calc.min)/10
if event.shift then
step=step*3
elseif event.ctrl then
step=step*2
end
local newvalue
if event.keycode==rtk.keycodes.LEFT or event.keycode==rtk.keycodes.DOWN then
newvalue=value-step
elseif event.keycode==rtk.keycodes.RIGHT or event.keycode==rtk.keycodes.UP then
newvalue=value+step
end
if newvalue then
self:_set_thumb_value_with_crossover(self.focused_thumb_index,newvalue,true,event)end
return ok
end
function rtk.Slider:_animate_thumb_overlays(event,focused,force)if rtk.dnd.dragging and not force then
return
end
if focused==nil then
focused=self.window.is_focused and self:focused()end
for i=1,#self._thumbs do
local dst=nil
local thumb=self:_get_thumb(i)if focused and thumb.idx==self.focused_thumb_index then
if event and event.buttons~=0 then
dst=32
else
dst=20
end
elseif thumb.idx==self._hovering_thumb then
dst=20
elseif thumb.radius_target>0 then
dst=0
end
if dst~=nil and dst~=thumb.radius_target then
thumb.radius_target=dst
rtk.queue_animation{key=string.format('%s.thumb.%d.hover', self.id, thumb.idx),src=thumb.radius,dst=dst,duration=0.2,easing='out-sine',update=function(val)thumb.radius=val
self:queue_draw()end,}end
end
end
function rtk.Slider:_animate_ticks(on)local calc=self.calc
if calc.step and calc.ticks==rtk.Slider.TICKS_WHEN_ACTIVE then
local dst=on and 1 or 0
rtk.queue_animation{key=string.format('%s.ticks', self.id),src=self._tick_alpha,dst=dst,duration=0.2,easing='out-sine',update=function(val)self._tick_alpha=val
self:queue_draw()end,}else
self._ticks_alpha=(calc.ticks==rtk.Slider.TICKS_ALWAYS)and 1 or 0
end
end
function rtk.Slider:_get_value_from_offset(offx)local calc=self.calc
local v=(offx*(calc.max-calc.min)/self._pre.track.w)+calc.min
return self:_clamp_value_to_step(v)end
function rtk.Slider:_draw(offx,offy,alpha,event,clipw,cliph,cltargetx,cltargety,parentx,parenty)rtk.Widget._draw(self,offx,offy,alpha,event,clipw,cliph,cltargetx,cltargety,parentx,parenty)local calc=self.calc
local y=calc.y+offy
if y+calc.h<0 or y>cliph or self.calc.ghost then
return false
end
local scale=rtk.scale.value
local pre=self._pre
local track=pre.track
local ticks=pre.ticks
local trackx=track.x+offx
local tracky=track.y+offy
local thumby=tracky+(track.h/2)local tickalpha=0.6*self._tick_alpha*alpha*calc.alpha
local drawticks=ticks and tickalpha>0 and not calc.disabled
self:_handle_drawpre(offx,offy,alpha,event)self:_draw_bg(offx,offy,alpha,event)self:setcolor(calc.trackcolor,alpha)gfx.rect(trackx,tracky,track.w,track.h,1)local first_thumb_x,last_thumb_x
if drawticks then
first_thumb_x=trackx+self:_get_thumb(1).pos
last_thumb_x=trackx+self:_get_thumb(#self._thumbs).pos
self:setcolor('black', tickalpha)for i=1,#ticks do
local x,y=table.unpack(ticks[i])if x<first_thumb_x or x>last_thumb_x then
gfx.rect(offx+x,offy+y,ticks.size,ticks.size,1)end
end
end
local thumbs={}local lastpos=0
for i=1,#self._thumbs do
local thumb=self:_get_thumb(i)local thumbx=trackx+thumb.pos
if not calc.disabled then
if #self._thumbs==1 or i>1 then
local segmentw=thumb.pos-lastpos
self:setcolor(calc.color,alpha)gfx.rect(trackx+lastpos,tracky,segmentw,track.h,1)if drawticks then
self:setcolor('white', tickalpha)for j=math.floor(lastpos/ticks.distance)+(i>1 and 2 or 1),#ticks do
local x,y=table.unpack(ticks[j])if x>=track.x+thumb.pos then
break
end
gfx.rect(offx+x,offy+y,ticks.size,ticks.size,1)end
end
end
if thumb.radius>0 then
self:setcolor(calc.thumbcolor or calc.color,0.25*alpha)gfx.circle(thumbx,thumby,thumb.radius*scale,1,1)end
end
thumbs[#thumbs+1]={thumbx,thumby}lastpos=thumb.pos
end
if not calc.disabled then
self:setcolor(calc.thumbcolor or calc.color,alpha)end
for i=1,#thumbs do
local pos=thumbs[i]
gfx.circle(pos[1],pos[2],calc.thumbsize*scale,1,1)end
if self._label_segments then
if not calc.disabled then
self:setcolor(calc.ticklabelcolor,alpha)end
for n,segments in ipairs(self._label_segments)do
if not segments.x then
break
end
self._font:draw(segments,offx+segments.x,offy+segments.y)end
end
self:_draw_borders(offx,offy,alpha)self:_handle_draw(offx,offy,alpha,event)end
function rtk.Slider:onchange()end
end)()

rtk.log=__mod_rtk_log
local function init()rtk.script_path=({reaper.get_action_context()})[2]:match('^.+[\\//]')rtk.reaper_hwnd=reaper.GetMainHwnd()local ver=reaper.GetAppVersion():lower()if ver:find('x64') or ver:find('arm64') or ver:find('_64') or ver:find('aarch64') then
rtk.os.bits=64
end
local parts=ver:gsub('/.*', ''):split('.')rtk._reaper_version_major=tonumber(parts[1])local minor=parts[2] or ''local sepidx=minor:find('%D')if sepidx then
rtk._reaper_version_prerelease=minor:sub(sepidx):gsub('^%+', '')minor=minor:sub(1,sepidx-1)end
minor=tonumber(minor)or 0
rtk._reaper_version_minor=minor<100 and minor or minor/10
rtk.version.parse()rtk.scale._discover()if rtk.os.mac then
rtk.font.multiplier=0.75
elseif rtk.os.linux then
rtk.font.multiplier=0.7
end
rtk.set_theme_by_bgcolor(rtk.color.get_reaper_theme_bg() or '#262626')rtk.theme.default=true
end
init()return rtk
end)()
return rtk
