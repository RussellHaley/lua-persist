package.path = package.path .. ';../src/?.lua;'
persist = require("persist")
Rtvg = require("random-tables")

x=Rtvg()
t=x:getVals(10000)

rand_data, err, errno = persist.open_or_new("random-data")
if not rand_data then print("oops".. err,errno) os.exit(1) end

rd_t1 = rand_data:open_or_new_db("t1")

ok, err, errno = rd_t1:add_items(t)

if not ok then 
	print(err, errno)

end

for i,v in pairs(rd_t1:stats()) do
print(i,v)
end

--~ rd_t1:close()
--~ rd_t1 = nil

count = rand_data:open_database("t1"):count()

print("Curren count is "..count.."records to the database")
