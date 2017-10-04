local persist = require("persist.persist")

local s = require('serpent')
local Rtvg=require'tobias-data'
x=Rtvg()
t=x:getVals(30000)


--print(s.block(t))

local rand_data, err, errno = persist.open_or_new("random-data")
if not rand_data then print("oops".. err,errno) os.exit(1) end

local rd_t1 = rand_data:open_or_new_db("t1")

rd_t1:add_items(t)

print (rd_t1:stats())

rd_t1:close()
rd_t1 = nil

local t1 = rand_data:open_database("t1"):get_all()

print(t1:count())



