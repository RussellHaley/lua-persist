#!/usr/local/bin/lua

local data = require("lmdb_env")
local m = require("moses")
local env = data.new("/tmp/data")
local serpent = require("serpent")
db_check = env.open_database("")
--db_players = env.open_database("players")
--db_year_player = env.open_database("year_players")
--teams_db = env.open_database("team")

local function getPlayerYears(k,v,p)
--  if type(k) ~= 'number' then
--    return nil
--  end
--print(k)
  if(string.sub(k,1,4) == tostring(p)) then
    return string.sub(k,5),{k,v,p}
  end
end


local function getPlayersByCity(k,v,...) 
  local p = table.pack(...)
  local ok,res
  if type(v) == 'string' then
    ok, res = assert(serpent.load(v))
  elseif type(v) == 'table' then
    ok, res = true, v
  else
    return nil
  end
  
  if ok then
    for _,v in pairs(p) do
      if res.Team.City == v then 
        return k,res
      end
    end
  end
  return nil
end



local function searchPlayerYear(year)
local playersIn2015 = db_year_player:search(getPlayerYears,2015)

if playersIn2015 then
  local count = 0
  for i,v in pairs(playersIn2015) do
    count = count + 1
    local res, player = serpent.load(db_players:get_item(i))
    print(player.FirstName, player.LastName)
  end
  print("players in ".."2015"..":"..count)
end
end
--if retvals then 
--  for i,v in pairs(retvals) do
--    print(v.FirstName, v.LastName)
--  end
--else
--  print('not found')
--end

--local retvals = db_players:search(getPlayersByCity,"Vancouver")

--local players = db_players:get_all()

--local c = {Team={City="Vancouver"}}

--print(serpent.block(c))

----searchPlayerYear()
----local van = m.chain(players):select(getPlayersByCity,"Vancouver","Detroit"):countBy(function(i,v) return v.Team.City end):value()
--local teams = m.chain(players):countBy(function(i,v) return v.Team.City end):value()
  
--if teams then 
--  for i,v in pairs(teams) do
--    print(i,v)
--  end
--else
--  print('no vals')
--end

--m.chain(players)
--:select(function(i,v) return v.Team.City=="Vancouver" end)
--:forEach(function(i,v) v.Team.Name="Nuckleheads" end)


----db_players:commit(players)

--players:commit()

local t = db_check:get_all()
local count = 0
for i,v in pairs(t) do
  count = count + 1
  print(i)
end
print("count "..count)
print(serpent.block(env:stats()))
env:close_env()




