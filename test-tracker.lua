local track = require('table-tracker')

local t = {}

t["one"] = 1
t[2] = "two"

t = track.new()

t[2] = "three"

print(t[2])

print("tracking test")
local u = track.new()

u["one"] = 1
u["one"] = 2
u[2] = "three"
print(u["one"], u[2])
u[2] = nil
u[3] = "three"

--meta = getmetatable(u)
--local count = 0
--for i,_ in pairs(meta.changes) do
--  count = count + 1
--end
--print("committing changes "..count)

u.commit = "somethings"

u:commit()
print("testing")

