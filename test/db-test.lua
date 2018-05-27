package.path = '../?/init.lua;../?.lua;' .. package.path
--#!/usr/local/bin/lua
--- @file db-test.lua
--[[Script purpose
This script opens two databases
data-numbers - table idx use numbers
table - cities, people, addresses
data-words - table idx uses non-numbers (guids, other)
--]]
--require("mobdebug").start()

local persist = require("persist")
--local m = require("moses")
-- serpent is just for convenience in this script.
local serpent = require("serpent")

--open a new or existing database. 
local words, err, errno = persist.open_or_new("data-words")

local t, count = words:list_dbs()
print("Words db init table count "..count)
local boys = words:open_or_new_db("boysnames")
boys:add_item("Russell",true)
boys:add_item("Adam",true)
boys:add_item("Christopher",true)
boys:add_item("Stephen",true)
boys:add_item("Richard",true)
boys:add_item("William",true)
boys:add_item("Joeseph",true)

local count = boys:count()
print ("boys names: " .. count)
local recs = boys:get_all()

for i,v in pairs(recs) do
  print(type(i), type(v))
end
print(serpent.block(recs))

--Open a second 'database' in the same files. 
local cities = words:open_or_new_db("cities")

cities:add_item("Victoria","{description='some random data in here'}")
cities:add_item("Belingham","{description='some random data in here'}")
cities:add_item("Kelowna","{description='some random data in here'}")

local t, count = words:list_dbs()

print(serpent.block(t))
print("How many databases in the words environment? "..count)

--open a second database just for shits and giggles. The databases do not interact, 
--they're separate files
local numbers, err, errno = persist.open_or_new("data-numbers")
if not numbers then print("uh,ho") print(err,errno) os.exit(1) end

local policies = numbers:open_or_new_db("life-policies")
policies:add_item(1,"Don't forget to eat your meat.")
policies:add_item(2,"No good deed will go unpunished")
policies:add_item(3,"How can you have any pudding if you don't eat your meat?")
policies:add_item(4,"Oh, my. Oh my my. Chitty Chitty Bang Bang! Horray!")

local t2,c2 = numbers:list_dbs()

print('Databases: \n'..serpent.block(t2))

print("Numbers Database Count "..c2)

words:close()
numbers:close()

