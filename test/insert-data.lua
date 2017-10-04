local persist = require("persist")
local Rtvg = require("random-tables")

x=Rtvg()
t=x:getVals(30000)

local rand_data, err, errno = persist.open_or_new("random-data")
if not rand_data then print("oops".. err,errno) os.exit(1) end

local rd_t1 = rand_data:open_or_new_db("t1")

rd_t1:add_items(t)

print (rd_t1:stats())

rd_t1:close()
rd_t1 = nil

local t1 = rand_data:open_database("t1"):get_all()

print("Added "..t1:count().."records to the database")
