--
-- Created by IntelliJ IDEA.
-- User: russellh
-- Date: 5/11/17
-- Time: 11:31 PM
-- To change this template use File | Settings | File Templates.
--
local data = require("lmdb_env")
local serpent = require("serpent")
local env = data.new("data")
local db_check = env.open_database("")

local iterations = 10000

local function count_please(t)
  local count = 0
  for i, v in pairs(t) do
    count = count + 1
  end
  print(count)
end



--local start_time = os.time()

local newRussells = env.open_database("russells", true)
local first = "Russell"
local last = "Haley"

local tmp = { first_name = first, last_name = last, column_a = "COLUMN_A", column_b = "COLUMN_B", number_1 = 1, number_2 = 2 }

for i = 1, iterations, 1 do
  newRussells:add(i,tmp)
end

local end_time = os.time()

local elapsed_time = os.difftime(end_time,start_time)

print(iterations.." Russells inserted in " .. elapsed_time)

local start_time = os.time()
local first = "Jim"
local last = "Fergison"

local tmp = { first_name = first, last_name = last, column_a = "COLUMN_A", column_b = "COLUMN_B", number_1 = 1, number_2 = 2 }
local newJims = env.open_database("jims", true)
local jims = {}

for i = 1, iterations, 1 do
  jims[i] = tmp
end
newJims:add_table(jims)

local end_time = os.time()

local elapsed_time = os.difftime(end_time, start_time)

print(iterations.."jims inserted in ".. elapsed_time)

local t = db_check:get_all()

jims = nil

local more_jims = newJims:get_all()

count_please(more_jims)

local more_russells = newRussells:get_all()

count_please(more_russells)

count_please(db_check:get_all())

print(serpent.block(env:stats()))

env:close_env()






