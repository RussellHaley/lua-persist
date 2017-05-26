--- lua-persist. This is the core library for the Gilead project. 
-- It provides a wraper around LMDB and provides the following general modules:
-- environment - the lmdb environment
-- database - a wraper around database functionality
-- tracker - a table designed to track changes for persistence
-- cursor - not implemented
-- index - not implemented

local lmdb_env
local readOnly
local tracker
local debug_flag = true



---Prototype for LMDB Environment
local persist = {}
local env = {
  --- a table of all the dbs opened for this env.
  databases={}
  }
local db = {}
local cursor = {}

--- LMDB Wrapper
local lightningmdb_lib = require("lightningmdb")
--- Filesystem
local lfs = require("lfs")
local serpent = require("serpent")

--Set up lmdb and a table of constants
local lightningmdb = _VERSION >= "Lua 5.2" and lightningmdb_lib or lightningmdb
local MDB = setmetatable({}, {
  __index = function(_, k)
    return lightningmdb["MDB_" .. k]
  end
})



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

--- Opens an lmdb transaction.
-- Makes some assumptions about what we need (i.e. MDB.CREATE)
-- @remarks: shouldn't we know at this point that the database
-- actually exists? We don't need MDB.create
db.open_tx = function(self,name,readonly)
  local t,dh
  local opts

  if readonly then opts = MDB.RDONLY else opts = 0 end
  t = assert(self.env.lmdb_env:txn_begin(nil, opts))
  dh = assert(t:dbi_open(name, MDB.CREATE))
  return t, dh
end


--- Checks the entry for valid values and serialises tables.
local function clean_items(key,value,throw_on_key)
  if type(key) == 'table' then
    if throw_on_key then error('Key cannot be of type table.') end
    key = serpent.block(key)
  end
  if type(value) == 'table' then
    value = serpent.block(value)
  elseif type(value) == 'boolean' then
    if value then value = 1 else value = 0 end
  end
  return key,value
end

--- Debug function to print the raw entries 
db.print_entries = function (self)
  local t,d = self.open_tx(self.name, true)
  local cursor, error, errorno = t:cursor_open(d)
  local k
  local ok
  for k, v in cursor_pairs(cursor) do
    if type(v) == 'table' then ok,v = serpent.block(v) end
    print(k,v)
  end

  cursor:close()
  t:abort()
end

--- This funciton is a raw get of all entries in the database
-- It could use parameters for fetch size and offset? I don't
-- know how that would be implemented yet
db.get_keys = function (self)
  local retval = {}
  local t,d = self:open_tx(self.name, true)
  local cursor, error, errorno = t:cursor_open(d)
  local k = 0

  for k in cursor_pairs(cursor) do
    retval[k] = true
  end
  cursor:close()
  t:abort()
  return tracker(self, retval)
end

--- This funciton is a raw get of all entries in the database
-- It could use parameters for fetch size and offset? I don't
-- know how that would be implemented yet
db.get_all = function (self)
  local retval = {}
  local t,d = self:open_tx(self.name, true)
  local cursor, error, errorno = t:cursor_open(d)
  local k = 0

  for k, v in cursor_pairs(cursor) do
    local ok, ret = true, true
    if type(v) == 'table' then
      ok, ret = serpent.load(v)
    else
      k = tonumber(k) or k
      ret = v
    end
    if ok then retval[k] = ret end
  end
  cursor:close()
  t:abort()
  return tracker(self, retval)
end

--- Commits values to the database from a table.
-- if a change tracker was used, only the changes
-- (updates/new, delete) are applied to the database.
-- otherwise we just puts everything in there (not implemented yet). 
db.commit =  function (self,tbl)
  local has_tracker = false
  local tx,db = self:open_tx(self.name)
  local ok, err, errno
  local cursor
  cursor, err, errno= tx:cursor_open(db)
  if not cursor then
    tx:abort()
    return nil, err, errno
  end

  local meta = getmetatable(tbl)
  if meta and meta.changes then
    has_tracker = true
    local count = 0
    for k,action in pairs(meta.changes) do
      local v
      k,v = clean_items(k,tbl[k],true)
      if action == "add" or action == "update" then
        ok, err, errno = cursor:put(k,v,0)
      elseif action == "delete" then
        ok, err, errno = cursor:del(k,v,0)
      end
      count = count + 1
      if not ok then
        cursor:close()
        tx:abort()
        return nil, err, errno
      end
    end

  else
    --non-tracked. update all???
  end

  cursor:close()
  tx:commit()
  if debug then
    print("Has tracker: "..tostring(has_tracker))
    print("Changes Committed: ".. count)
  end
end

--- Runs a function over each value from the database and
-- if it returns true, adds it to the return set.
db.search_entries = function (self,func,...)
  local tx,db = self:open_tx(self.name, true)
  local cursor, error, errorno = tx:cursor_open(db)
  local k
  local retval= {}
  for k, v in cursor_pairs(cursor) do
    local ok,val = func(k,v,...)
    if ok then
      retval[ok] = val
    end
  end
  cursor:close()
  tx:abort()
  return tracker(self,retval)
end

--- Gets a single item from the database
db.get_item = function (self,key)
  local t,d = self:open_tx(self.name, true)
  local ok,res,errno = t:get(d,key, _, 0)
  t:commit()
  return ok,res,errno
end


--- Searches the database for all the keys in tbl and returns a table of records.
-- @param tbl table Table containing the keys for searching. The value is ignored.
db.get_items = function (self,tbl)
  local retval = {}
  local tx,db = self:open_tx(self.name, true)
  local cursor, error, errorno = tx:cursor_open(db)
  local k = 0
  for i,v in tbl do
    local key,val = cursor:get(i, MDB.FIRST)
    while key do
      retval[key] = val
      local key,val = cursor:get(i, MDB.NEXT)
    end
  end
  cursor:close()
  tx:abort()
end

--- Adds all entries ina table to the database
db.add_items= function (self,table)
  local tx,db = self:open_tx(self.name)
  local ok, err, errno
  local cursor
  cursor, err, errno= tx:cursor_open(db)
  if not cursor then
    tx:abort()
    return nil, err, errno
  end
  local tmp = 0
  for k,v in pairs(table) do
    k,v = clean_items(k,v,true)
    ok, err, errno = cursor:put(k,v,0)
    if not ok then
      cursor:close()
      tx:abort()
      return err, errno
    end
  end
  cursor:close()
  tx:commit()
end

--- Checks if the database exists. This doesn't work!
db.item_exists = function (self,key)
  local t,d = self:open_tx(self.name)
  clean_items(key, nil, true)
  local ok, err, errno = t:get(d, key)
  if not ok then
    t:abort()
    return nil, err, errno
  end
  t:commit()
  return key
end


--- Use this function to only insert the data if the key is already present and
-- duplicates are not allowed.
db.add_item = function (self,key,value)
  local t,d = self:open_tx(self.name)
  --Need to wrap in pcall to catch errors.
  --should return key if success or 
  --nil, error, errorno
  key, value = clean_items(key,value, true)
  local ok, err, errno = t:put(d, key, value, MDB.NOOVERWRITE)
  if not ok then
    t:abort()
    return nil, err, errno
  end
  t:commit()
  return key
end

--- Inserts or updates an item in the database
db.upsert_item = function (self,key,value)
  local t,d = self:open_tx(self.name)
  key, value = clean_items(key,value, true)
  local ok, err, errno = t:put(d, key, value, 0)
  if not ok then
    t:abort()
    return nil, err, errno
  end
  t:commit()
  return key
end

--- Opens the named k,v database.
-- @param name The name of the database to open. If the named database does not exist and the `create` parameter does
-- not equate to true, the system asserts.
-- @param create boolean Specify true if the system should create the database if it does not exist.
env.open_database = function(self,name,create)
  if self.lmdb_env then
    if self.databases[name] then
      return self.databases[name]
    end

    local t = self.lmdb_env:txn_begin(nil, 0)
    if name == "" then name = nil end
    local opts
    if create then
      opts = MDB.CREATE
    else
      opts = 0
    end
    local dh = assert(t:dbi_open(name, opts))

    local cursor = t:cursor_open(dh)
    cursor:close()
    t:abort()

    local mt = {__index = db }
    local new_db = {}
    setmetatable(new_db,mt)
    new_db.name = name
    new_db.env = self

    if name ~= nil then self.databases[name] = new_db end
    return new_db
  else
    return nil, "NO_ENV_AVAIL", 100
  end
end

env.list_dbs = function(self)
  local ldb = self:open_database("")
  local t = ldb:get_keys()
  local count = 0
  for i in pairs(t) do
    count = count + 1
    print(i)
  end
  return t, count
end

--- Returns the lmdb statistics as a table
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
  new_env.lmdb_env:set_maxdbs(4)
  new_env.lmdb_env:open(datadir, 0, 420)

  return new_env

end

--- Returns a new lmdb environment. This is the base environment/file 
-- for all databases in your project.
-- @param datadir A base directory to find the lmdb files. 
-- @remarks Needs to be implemeneted like this:
-- local function new(datadir,create_dir) and assert if not create dir and the dir doesn't exist
-- Need to add an open to complement new only assert if it doesn't exist.
persist.new = function(datadir, warn)
  local cd = lfs.currentdir()
  local exists = lfs.chdir(datadir)
  lfs.chdir(cd)

  if warn and exists then
    error('Data directory alread exists and warn flag set to true. Directory:'..datadir)
  end
  if not exists then
    assert(lfs.mkdir(datadir))
  end

  return persist.open(datadir)
end

--- Adds the changes table and the database to the base table specified in t. 
-- @param db Will assert if null. Should have check for actual database object. 
-- @param t Base table for tracking. If t is null a blank table is used.
tracker = function (db,t)

  assert(db,"Database is null");

  if not t then t = {} end

  local proxy ={} -- proxy for table t

  --create metatable for the proxy
  local mt = {
    changes = {},
    database = db,
    --table key/value access
    __index = function (_,k,v)
      local meta = getmetatable(_)
      if k == "commit" then return end
      --print("*access to element" .. tostring(k))
      return t[k]
    end,
    --table value assignment
    __newindex = function (_,k,v)
      local meta = getmetatable(_)
      local changes = meta.changes
      assert(changes,"NO CHANGES TABLE in META TABLE")
      if k == "commit" then print('cannot change the "commit" key') return end
      local action

      if rawget(t,k) == nil then
        --run the "insert" item function
        action = "add"
        if debug_flag then print('add') end
      elseif v == nil then
        --run the delete item function
        action = "delete"
        if debug_flag then print('nil/delete') end
      else
        --run the update item function
        action = "update"
        if debug_flag then print('udpate') end
      end
      --update the change tracking table. 
      -- We need to keep the action taken and the key reference?      
      --print("*update of element " .. tostring(k) ..
      -- " to " .. tostring(v))

      if changes[k] ~= nil then
        if changes[k] == "new" then
          if action == "delete" then
            changes[k] = nil
          elseif action == "update" then
            --no change. still need to insert regardless of 
            -- the table contents so don't change state
          end
        elseif change[k] == "update" then
          if action == "delete" then
            changes[k] = "delete"
          end
        elseif change[k] == "delete" then
          if action == "new" then
            changes[k] = "update"
          end
        end
      else
        changes[k] = action
      end
      t[k] = v --update original table
    end,

    --returns iterator
    __pairs = function()
      return function (_,k) --iteration function
        local nextkey, nextvalue = next(t,k)
        if nextkey ~=nil  then --avoid last value
          --print("*taversing element " .. tostring(nextkey))
        end
        return nextkey, nextvalue
      end
    end,
    --RH - update this to be smarter?
    __len = function () return #t end,

    __commit = function()
      local meta = getmetatable(proxy)
      if meta.database then
        meta.database:commit(proxy)
      end
    end
  }

  proxy.commit = mt.__commit

  setmetatable(proxy, mt)

  return proxy

end

--- Creates a read only table. 
readOnly = function (t)
  local proxy = {}

  local mt = {
    __index = t,
    __newindex = function(t,k,v)
      print("No access to readonly tables")
    end
  }
  setmetatable(proxy,mt)
  return proxy
end

return persist