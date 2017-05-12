--- Instrumentation.
-- Creates a new persistence table for running values and data sets based on an lmdb database
-- The current implementation is somewhat restricted to simple key value pairs.
-- There are two update methodoldies:
-- 1)Persist the entire table at the same time or
-- 2)Persiste a single key value item
-- @copyright (c) 2016 Russell Haley
-- @license FreeBSD License. See License.txt

--[[
1) start a new application database for persistent values
- get basedir from a config file
- open a new directory under basedir - timestamped for execution start

- keys will be strings of constants (how to ensure uniqness?)
	- where do defaults come from? application startup file?
	
	OR
	
- one key per "application", stored a lua table as the value.

]] --

--- The table with instrumentation values
local Instr = {}

--- LMDB Wrapper
local lightningmdb_lib = require("lightningmdb")
--- Filesystem
local lfs = require("lfs")

--- Configuration settings
local configuration = require("configuration")

--Set up lmdb and a table of constants
local lightningmdb = _VERSION >= "Lua 5.2" and lightningmdb_lib or lightningmdb
local MDB = setmetatable({}, {
    __index = function(_, k)
        return lightningmdb["MDB_" .. k]
    end
})


--Tried to protect values but it didn't work.
local function protect(tbl)
    return setmetatable({}, {
        __index = tbl,
        __newindex = function(_, key, value)
            error("attempting to change constant " ..
                    tostring(key) .. " to " .. tostring(value), 2)
        end
    })
end

--- Stat. Get Statistics about the database
Instr.Stat = function()
    local e = lightningmdb.env_create()
    e:open(Instr["data_directory"], 0, 420)
    local stat = e:stat()
    e:close()
    return stat

end

--- DirectoryExists. Internal for check directory for data files
local function DirectoryExists(name)
    if type(name) ~= "string" then return false end
    local cd = lfs.currentdir()
    local is = lfs.chdir(name) and true or false
    lfs.chdir(cd)
    return is
end


--- WriteInstrumentation
-- This function write the entire Instrumentation table
-- to the application database. If the application dies, these values are
-- persisted for diagnostics.
Instr.WriteInstrumentation = function ()
    local e = lightningmdb.env_create()
    e:open(Instr["data_directory"], 0, 420)
    local t = e:txn_begin(nil, 0)
    local d = t:dbi_open(nil, 0)

    local count = 0

    for key, value in pairs(Instr) do
        assert(t:put(d, key, value, MDB.NOOVERWRITE))
    end
    t:commit()
    PrintStat(e)
    e:close()
end


--- cursor_pairs. Use a coroutine to iterate through the
-- open lmdb data set
local function cursor_pairs(cursor_, key_, op_)
    return coroutine.wrap(function()
        local k = key_
        repeat
            local k, v = cursor_:get(k, op_ or MDB.NEXT)
            if k then
                coroutine.yield(k, v)
            end
        until not k
    end)
end

--- Create a UUID for unique keys. This is no longer used here I don't think
local function GetUuid()
    local handle = io.popen("uuidgen")
    local val = handle:read("*a")
    val = val:gsub("^%s*(.-)%s*$", "%1")
    return val
end

--- UpdateInstrumentation
-- Set a key value pair
Instr.UpdateInstrumentation = function (key, value)
    local e = lightningmdb.env_create()
    Instr[key] = value
    e:open(Instr.data_directory, 0, 420)
    local t = e:txn_begin(nil, 0)
    local d = t:dbi_open(nil, 0)

    t:put(d, key, value, 0)

    t:commit()
    e:close()
end

--- ReadInsrumentation
-- read in the entire database
Instr.ReadInstrumentation = function ()
    local e = lightningmdb.env_create()
    e:open(Instr.data_directory, 0, 420)
    local t = e:txn_begin(nil, MDB.RDONLY)
    local d = t:dbi_open(nil, 0)
    local cursor = t:cursor_open(d)

    local data = {}
    data[":data_directory"] = Instr.data_directory
    local k
    for k, v in cursor_pairs(cursor) do
        data[k] = v
    end

    cursor:close()
    t:abort()
    e:close()
    return data
end

local function RemoveFileExtention(url)
    return url:gsub(".[^.]*$", "")
end

--- Cleanup. If configured, removes the data directory
Instr.Cleanup = function()
    if Instr.rm_data_dir then
        os.execute("rm -rf " .. Instr.data_directory)
        print("database removed:".. Instr.data_directory )
    end
end

--- New.
-- Creates a new instance of a database
local function new(confFilePath)
    --Load the configuration file
    local conf = configuration.new(confFilePath)

    --Set up the database and check if we are supposed to remove the database when done.
    Instr["data_directory"] = conf["base_path"] .. "/" .. conf["data_dir_name"] .. "/" .. os.date("%Y-%m-%d_%H%M%S")
    Instr.rm_data_dir = conf.rm_data_dir
    if DirectoryExists(Instr.data_directory) then
        print("Found data directory. Using existing database.")
    else
        local count = 0
        for _ in Instr.data_directory:gmatch("/") do
            count = count + 1
        end

        --local first_slash = Instr.data_directory:gmatch("/")
        if count <= 1 then
            error("The filename is invalid. Check the base_path and data_dir values in the config file. Attempted data dir: " .. Instr.data_directory)
        else
            os.execute("mkdir -p " .. Instr.data_directory)
        end
    end

    return Instr;
end

return {new = new;}

