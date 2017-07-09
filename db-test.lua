#!/usr/local/bin/lua
--- @file db-test.lua

local persist = require("persist")
local m = require("moses")
local env1, err, errno = persist.open_or_new("data")

if not env1 then print(err,errno) os.exit(1) end

local env2 = persist.open_or_new("data2")
local serpent = require("serpent")


local t, count = env1:list_dbs()

print("count init "..count)
[[
WHAT IS TRANSACTION RESET AND RENEW???
]]
local mydb1 = env1:open_database("mydb1", true)
print("one")
mydb1:add_item(1,"one")
print("two")
local t, count = env1:list_dbs()

print("count one"..count)

local mydb2 = env1:open_database("mydb2",true)

mydb2:add_item(2,"one")

local t, count = env1:list_dbs()

print("count two "..count)

local e2db1 = env2:open_database("testy",true)
e2db1:add_item("A1","No good deed will go unpunished")
local t2,c2 = env2:list_dbs()

print("data2 count "..c2)

print(serpent.block(t2))
env1:close()
env2:close()



