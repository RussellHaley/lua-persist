
package.path = '../?/init.lua;../?.lua;'..package.path 
persist = require("persist")
tim = require ('chronos')
Rtvg = require("random-tables")
x=Rtvg()
local start_get = tim.nanotime()
t=x:getVals(arg[1])
local stop_get = tim.nanotime()

rand_data, err, errno = persist.open_or_new("random-data")
if not rand_data then print("oops".. err,errno) os.exit(1) end

rd_t1 = rand_data:open_or_new_db("t1")
local start_ins = tim.nanotime()
ok, err, errno = rd_t1:add_items(t)
local stop_ins = tim.nanotime()

if not ok then 
	print(err, errno)

end
print(string.format("Create: %s \n Insert %s\n", (stop_get - start_get), (stop_ins - start_ins)))

--~ for i,v in pairs(rd_t1:stats()) do
--~ print(i,v)
--~ end

--~ rd_t1:close()
--~ rd_t1 = nil

count = rand_data:open_database("t1"):count()

print("Curren count is "..count.."records to the database")
