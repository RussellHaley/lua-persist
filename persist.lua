--- lua-persist. This is the core library for the Gilead project. 
-- It provides a wraper around LMDB and provides the following general modules:
-- environment - the lmdb environment
-- database - a wraper around database functionality
-- tracker - a table designed to track changes for persistence
-- cursor - not implemented
-- index - not implemented

local lmdb_env
local readOnly

local debug_flag = true

local errors = require('errors')

local pdb = require("database")

---The libraries main module
local persist = {}

--lmdb environment table
local env = {
  --- a table of all the dbs opened for this env.
  databases={}
}

local cursor = {}

--- LMDB Wrapper
local lightningmdb_lib = require("lightningmdb")
--- Filesystem
local lfs = require("lfs")


--Set up lmdb and a table of constants
local LMDB_FLAGS = require("lmdb-flags")

--local lightningmdb = _VERSION >= "Lua 5.2" and lightningmdb_lib --or lightningmdb
--Create a copy of the library and set the meta table? This is a pattern I inherited from
--the lightningMDB example code. Code this be reduced to the following?
--  local lightningmdb = require("lightningmdb")
local lightningmdb = _VERSION >= "Lua 5.2" and lightningmdb_lib
local MDB = setmetatable({}, {
  __index = function(_, k)
    return lightningmdb["MDB_" .. k]
  end
})


--- cursor_pairs. Use a coroutine to iterate through the open lmdb data set
-- @param cursor_ cursor used for retrieving item
-- @param key_ The key to retrieve
--@param op_ the operation to perform default is MDB.NEXT
function cursor_pairs(cursor_, key_, op_)
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


--- Opens the named k,v database.
-- @param self The database environment
-- @param name The name of the database to open. If the named database does not exist and the `create` parameter does
-- not equate to true, the system asserts.
-- @param options table containing lmdb options. NOT IMPLEMENTED YET.
-- @param create boolean Specify true if the system should create the database if it does not exist.
env.open_database = function(self, name, create)

  assert(type(self) == "table","open_database must be called using the colon ':' notation. example: env:open_database('name',true)")

  if name == "" then name = nil end
  if create and not name then return nil, "Cannot create database with a name of blank ('') or nil." end

  if self.lmdb_env then
    if self.databases[name] then

      return self.databases[name]
    end

    local tx = self.lmdb_env:txn_begin(nil, 0)
    local _db = pdb:new_db(name)
    if name ~= nil then self.databases[name] = new_db end
    local opts
    if create then

      opts = MDB.CREATE
      self.index:add_item(name,_db,tx)

    else
      opts = 0
    end
    local dh = assert(tx:dbi_open(name, opts))

    --This code may be unnecessary
    local cursor = tx:cursor_open(dh)
    cursor:close()
    tx:commit()

    return _db
  else
    return nil, errors.NO_ENV_AVAIL.err, errors.NO_ENV_AVAIL.errno
  end
end

---List the databases contained in the lmdb environment
env.list_dbs = function(self)

  local tx = self.lmdb_env:txn_begin(nil, 0)
  local dh = assert(tx:dbi_open("", MDB.RDONLY))
  local cursor = assert(tx:cursor_open(dh))
  local retval = {}
  local count = 0
  for k in cursor_pairs(cursor) do
    retval[k] = true
    count = count + 1
  end

  cursor:close()
  tx:commit()

  return retval, count
end

--- Returns the lmdb environment statistics as a table
env.stats = function(self)
  return self.lmdb_env:stat()
end

--- Closes the environment/files
env.close = function(self)
  self.lmdb_env:close()
end


--- Open an existing database. Asserts if the data directory does not exist
-- @param datadir Base directory that contains the database files
persist.open = function(datadir)
  local cd = lfs.currentdir()
  assert(lfs.chdir(datadir))
  lfs.chdir(cd)

  local mt = {__index = env }
  local new_env = {}
  setmetatable(new_env,mt)

  new_env.datadir = datadir
  new_env.lmdb_env = lightningmdb.env_create()
  new_env.lmdb_env:set_mapsize(10485760)
  new_env.lmdb_env:set_maxdbs(10000)
  new_env.lmdb_env:open(datadir, 0, 420)
  new_env.index = new_env:open_database("__databases")
  return new_env

end

--- Opens a database or creates a new one if it does not exist
persist.open_or_new = function(datadir)
  local cd = lfs.currentdir()
  local exists = lfs.chdir(datadir)
  lfs.chdir(cd)

  if exists then
    return persist.open(datadir)
  else
    return persist.new(datadir)
  end
end

--- Returns a new lmdb environment. Throws an error if it already exists.
-- @param datadir A base directory to find the lmdb files.
persist.new = function(datadir)
  local cd = lfs.currentdir()
  local exists = lfs.chdir(datadir)
  lfs.chdir(cd)

  if exists then
    error('Data directory alread exists.  Directory:'..datadir..' \n Use open_or_new if you expect to be trying this again.')
  end
  if not exists then
    assert(lfs.mkdir(datadir))
  end

--[[need to create the __databases and __indexes tables
__database = {key="", value={duplicates="", indexes={}, relationships={}}}
__indexes = {key="",value={__func="function(k,v,...) return v end", dirty=false,  }}
__relationships = {}
--]]
  -- Insert a new __databases kvs into the new environment. We can't use the persist API because it requires access
  -- to the __databases kvs so we use the base lightningmdb API.
  local lmdbenv = lightningmdb.env_create()
  lmdbenv:set_mapsize(10485760)
  lmdbenv:set_maxdbs(10000)
  lmdbenv:open(datadir, 0, 420)
  local tx = lmdbenv:txn_begin(nil, 0)
  local opts = MDB.CREATE

  local dh = assert(tx:dbi_open("__databases", opts))
  local ok, err, errno = tx:put(dh, "_", serpent.block(new_db("__databases")),  MDB.NOOVERWRITE)
  if not ok then
    tx:abort()
    lmdbenv:close()
    error(err, errno)
  end
  tx:commit()
  lmdbenv:close()
  return persist.open(datadir)

end

persist.delete = function(datadir)
  return nil, errors.NOT_IMPLEMENTED.err, errors.NOT_IMPLEMENETED.errno
end

return persist
