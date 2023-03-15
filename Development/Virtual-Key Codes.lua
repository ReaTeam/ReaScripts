-- NoIndex: true
-- @description Virtual-Key Codes
-- @author amagalma
-- @version 1.00
-- @link https://docs.microsoft.com/en-us/windows/win32/inputdev/virtual-key-codes
-- @about
-- # For use with JS_ReaScript_API with APIs like: reaper.JS_VKeys_Intercept, reaper.JS_VKeys_GetState, etc
--[[
-- code to import:
VK_path = (reaper.GetResourcePath().. "\\Scripts\\ReaTeam Scripts\\Development\\Virtual-Key Codes.lua")
VK_path = VK_path:gsub( "\\", function (a) return (not reaper.GetOS():match("Win")) and "/" or a end )
loadfile(VK_path)()
-- example code:
if reaper.JS_VKeys_GetState(start):byte(VK[9]) ~= 0 then -- check if key 9 is pressed
  -- number 0 to 9: use VK[number]
  -- for all other use VK.name : ex VK.LEFT, VK.F, VK.F8 etc
end--]]

VK = 
{
LMB = 0x01, -- Left mouse button
RMB = 0x02, -- Right mouse button
MMB = 0x04, -- Middle mouse button (three-button mouse)
X1 = 0x05, -- X1 mouse button
X2 = 0x06, -- X2 mouse button
BACKSPACE = 0x08, -- BACKSPACE key
TAB = 0x09, -- TAB key
CLEAR = 0x0C, -- CLEAR key
ENTER = 0x0D, -- ENTER key
SHIFT = 0x10, -- SHIFT key
CTRL = 0x11, -- CTRL key
ALT = 0x12, -- ALT key
PAUSE = 0x13, -- PAUSE key
CAPS = 0x14, -- CAPS LOCK key
ESC = 0x1B, -- ESC key
SPACEBAR = 0x20, -- SPACEBAR
PAGE_UP = 0x21, -- PAGE UP key
PAGE_DOWN = 0x22, -- PAGE DOWN key
END = 0x23, -- END key
HOME = 0x24, -- HOME key
LEFT = 0x25, -- LEFT ARROW key
UP = 0x26, -- UP ARROW key
RIGHT = 0x27, -- RIGHT ARROW key
DOWN = 0x28, -- DOWN ARROW key
SELECT = 0x29, -- SELECT key
PRINT = 0x2A, -- PRINT key
EXECUTE = 0x2B, -- EXECUTE key
PRINT_SCREEN = 0x2C, -- PRINT SCREEN key
INS = 0x2D, -- INS key
DEL = 0x2E, -- DEL key
HELP = 0x2F, -- HELP key
[0] = 0x30, -- 0 key
[1] = 0x31, -- 1 key
[2] = 0x32, -- 2 key
[3] = 0x33, -- 3 key
[4] = 0x34, -- 4 key
[5] = 0x35, -- 5 key
[6] = 0x36, -- 6 key
[7] = 0x37, -- 7 key
[8] = 0x38, -- 8 key
[9] = 0x39, -- 9 key
A = 0x41, -- A key
B = 0x42, -- B key
C = 0x43, -- C key
D = 0x44, -- D key
E = 0x45, -- E key
F = 0x46, -- F key
G = 0x47, -- G key
H = 0x48, -- H key
I = 0x49, -- I key
J = 0x4A, -- J key
K = 0x4B, -- K key
L = 0x4C, -- L key
M = 0x4D, -- M key
N = 0x4E, -- N key
O = 0x4F, -- O key
P = 0x50, -- P key
Q = 0x51, -- Q key
R = 0x52, -- R key
S = 0x53, -- S key
T = 0x54, -- T key
U = 0x55, -- U key
V = 0x56, -- V key
W = 0x57, -- W key
X = 0x58, -- X key
Y = 0x59, -- Y key
Z = 0x5A, -- Z key
LWIN = 0x5B, -- Left Windows key (Natural keyboard)
RWIN = 0x5C, -- Right Windows key (Natural keyboard)
APP = 0x5D, -- Applications key (Natural keyboard)
SLEEP = 0x5F, -- Computer Sleep key
NUM0 = 0x60, -- Numeric keypad 0 key
NUM1 = 0x61, -- Numeric keypad 1 key
NUM2 = 0x62, -- Numeric keypad 2 key
NUM3 = 0x63, -- Numeric keypad 3 key
NUM4 = 0x64, -- Numeric keypad 4 key
NUM5 = 0x65, -- Numeric keypad 5 key
NUM6 = 0x66, -- Numeric keypad 6 key
NUM7 = 0x67, -- Numeric keypad 7 key
NUM8 = 0x68, -- Numeric keypad 8 key
NUM9 = 0x69, -- Numeric keypad 9 key
MULTIPLY = 0x6A, -- Multiply key
ADD = 0x6B, -- Add key
SEPARATOR = 0x6C, -- Separator key
SUBTRACT = 0x6D, -- Subtract key
DECIMAL = 0x6E, -- Decimal key
DIVIDE = 0x6F, -- Divide key
F1 = 0x70, -- F1 key
F2 = 0x71, -- F2 key
F3 = 0x72, -- F3 key
F4 = 0x73, -- F4 key
F5 = 0x74, -- F5 key
F6 = 0x75, -- F6 key
F7 = 0x76, -- F7 key
F8 = 0x77, -- F8 key
F9 = 0x78, -- F9 key
F10 = 0x79, -- F10 key
F11 = 0x7A, -- F11 key
F12 = 0x7B, -- F12 key
F13 = 0x7C, -- F13 key
F14 = 0x7D, -- F14 key
F15 = 0x7E, -- F15 key
F16 = 0x7F, -- F16 key
F17 = 0x80, -- F17 key
F18 = 0x81, -- F18 key
F19 = 0x82, -- F19 key
F20 = 0x83, -- F20 key
F21 = 0x84, -- F21 key
F22 = 0x85, -- F22 key
F23 = 0x86, -- F23 key
F24 = 0x87, -- F24 key
NUM_LOCK = 0x90, -- NUM LOCK key
SCROLL_LOCK = 0x91, -- SCROLL LOCK key
LEFT_SHIFT = 0xA0, -- Left SHIFT key
RIGHT_SHIFT = 0xA1, -- Right SHIFT key
LEFT_CONTROL = 0xA2, -- Left CONTROL key
RIGHT_CONTROL = 0xA3, -- Right CONTROL key
LEFT_MENU = 0xA4, -- Left MENU key
RIGHT_MENU = 0xA5, -- Right MENU key
BR_Back = 0xA6, -- Browser Back key
BR_FORWARD = 0xA7, -- Browser Forward key
BR_REFRESH = 0xA8, -- Browser Refresh key
BR_STOP = 0xA9, -- Browser Stop key
BR_SEARCH = 0xAA, -- Browser Search key
BR_FAVORITES = 0xAB, -- Browser Favorites key
HOME = 0xAC, -- Browser Start and Home key
VOL_MUTE = 0xAD, -- Volume Mute key
VOL_DOWN = 0xAE, -- Volume Down key
VOL_UP = 0xAF, -- Volume Up key
NEXT_TRACK = 0xB0, -- Next Track key
PREV_TRACK = 0xB1, -- Previous Track key
STOP = 0xB2, -- Stop Media key
PLAY_PAUSE = 0xB3, -- Play/Pause Media key
START_MAIL = 0xB4, -- Start Mail key
SELECT_MEDIA = 0xB5, -- Select Media key
START_APP1 = 0xB6, -- Start Application 1 key
START_APP2 = 0xB7, -- Start Application 2 key
PLUS = 0xBB, -- For any country/region, the '+' key
COMMA = 0xBC, -- For any country/region, the ',' key
MINUS = 0xBD, -- For any country/region, the '-' key
DOT = 0xBE, -- For any country/region, the '.' key
}
