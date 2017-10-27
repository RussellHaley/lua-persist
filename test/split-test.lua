---split-test
-- \author	Russell Haley
--
package.path = package.path..";/home/russellh/Git/lua-csv/lua/?.lua;/home/russellh/Git/lua-persist/?.lua"

persist = require('persist')
local csv = require("csv")
local name = arg[1]
name = string.gsub(name,"%.","_")
name = name or "split-test"

db = persist.open_or_new(name) -- persist.open_db('random-data')
t1 = db:new_database("all") -- db:open_table("t1")

p= req
local f = csv.open(arg[1])
local t = {}
	for fields in f:lines() do
	items = {}
	local temp = ""
		for i, v in ipairs(fields) do 
			if i == 1 then temp = v end
			if i == 2 then items[temp] = v end
	end
t1:add_items(items)
end


out = t1:get_all()

for i,v in pairs(out) do
print(i,v)
end