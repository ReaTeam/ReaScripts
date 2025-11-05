#!/usr/bin/env lua
--@noindex
--@description

package.path = package.path .. ";../emojimgui/ext/?.lua"
local JSON = require "json"
local serpent = require("serpent")
local os = require "os"

local function test(json_path, target_path)
  local t1 = os.clock()
  local file = io.open(json_path, "r")
  local content = file:read("*all")
  file:close()

  local success, result = pcall(function()
    content = JSON.decode(content) or nil
  end)
  print("JSON loading " .. (os.clock() - t1))

  local t1 = os.clock()
  ret = dofile(target_path)
  print("LUA loading " .. (os.clock() - t1))

  print(#ret.groups)
end

local function build_lua_spec_from_json(json_path, target_path)

  local file = io.open(json_path, "r")
  local content = file:read("*all")
  file:close()

  local success, result = pcall(function()
    content = JSON.decode(content) or nil
  end)

  local file = io.open(target_path, "wb")

  file:write("-- @noindex\n\z
-- @author Ben 'Talagan' Babut\n\z
-- @license MIT\n\z
-- @description This file is part of EmojImGui\n\n")

  file:write(serpent.dump(content, {comment = false, compact = true}))
  file:close()

  test(json_path, target_path)
end

print("Building openmoji-spec.lua")
build_lua_spec_from_json("build/openmoji-spec.json", "build/openmoji-spec.lua")
print("")
print("Building twemoji-spec.lua")
build_lua_spec_from_json("build/twemoji-spec.json", "build/twemoji-spec.lua")


