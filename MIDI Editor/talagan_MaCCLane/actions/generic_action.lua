-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of MaCCLane

PATH            = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]]
package.path    = PATH  .. "talagan_MaCCLane/?.lua" .. ";"  .. package.path

local ACTION    = require "modules/action_interface"
local action    = debug.getinfo(1,"S").source

ACTION.EnqueueAction(action)

