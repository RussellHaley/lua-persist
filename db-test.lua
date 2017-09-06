#!/usr/local/bin/lua
--- @file db-test.lua

require("mobdebug").start()

local persist = require("persist")
local m = require("moses")
local serpent = require("serpent")

--open a new or existing database
local words, err, errno = persist.open_or_new("data-words")
-- Test if the databse is valid
if not words then print("oops".. err,errno) os.exit(1) end

--Try to open something that doesn't exist... 
--local data2, err = pcall(persist.open("data2"))

--Try to re-create something that exists...
--local words, err, errno = pcall(persist.new("data-words"))

local numbers, err, errno = persist.new("data-numbers")
if not numbers then print("uh,ho") print(err,errno) os.exit(1) end

local t, count = words:list_dbs()

print("count init "..count)

local boys = words:open_or_new_db("boysnames")

boys:add_item("Russell",true)
boys:add_item("Adam",true)

local t, count = words:list_dbs()

local cities = words:open_or_new_db("cities")

cities:add_item("Victoria","{description='some random data in here'}")
cities:add_item("Belingham","{description='some random data in here'}")
cities:add_item("Kelowna","{description='some random data in here'}")

local t, count = words:list_dbs()

print("count two "..count)

local policies = numbers:open_or_new_db("insurance-policies")
policies:add_item(1,"No good deed will go unpunished")
policies:add_item(2,"No good deed will go unpunished")
policies:add_item(3,"No good deed will go unpunished")
policies:add_item(4,"No good deed will go unpunished")

local t2,c2 = numbers:list_dbs()

print("data2 count "..c2)

print(serpent.block(t2))

words:close()
numbers:close()



