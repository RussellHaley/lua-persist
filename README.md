lua-persist aka Gilead is a table manipulation and persistence library. It allows you to perform lighting fast key searches and create indexes based on persisted table values. 

do
local p = require('lua-persist')
local env = p.open_env('~/mydir') 

local ts = env.open_tableset('my_new_table')

local t = {}

t[1] = 21
t[2]= 33
t["three"] = {"a"="b","c"="d"}

ts:add_table(t)

local cursor = ts:open_cursor(true,10)

if cursor then
  for i,v in random_generator(100000) do
    if i == 44444 then 
      cursor:insert(3,21)
      cursor:insert(4,21)
      cursor:insert(5,33)
    end
    if i == 20000 or i == 57231 or i = 77777 then 
      local t = {}            
      t["three"..i] = {"a"="b","c"="d"}      
      cursor:insert_table(t)
    else
      cursor:insert(i,v)
    end
    
  end
  cursor:commit():close()  
end

ts:add_item("four",4)

ts:close()

local idx, err, errno = env.create_index('my_index','my_new_table', function(k,v,...) if type(v) = table return v.c end )

if idx then
  idx:index()
  idx:close()
end

ts = env.open_tableset('my_new_table',true) --true indicates it should assert if the table doesn't exist already

ts:fetchedIndexed('my_index_name', "b"):forEach(function(k,v) v["e"] = "f" end):commit()

ts:close()



creating indexes

table_index
table_name, index_name

index
index_name, function









