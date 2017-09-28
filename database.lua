--- Wraps an lmdb database in a lua friendly API.
-- This is the base object returned from a persistence environment when a user requests a new database
-- @author Russell Haley
-- @copyright (c) 2016 Russell Haley
-- @license FreeBSD License. See License.txt

---table serializer
local serpent = require("serpent")

local lightningmdb = _VERSION >= "Lua 5.2" and require("lightningmdb")

local MDB = setmetatable({}, {
  __index = function(_, k)
    return lightningmdb["MDB_" .. k]
  end
})

local database = {}

local tracker

---prototype for a database
local proto = {duplicates=false, indexes={}, relationships={} }

--- Opens an lmdb transaction.
-- Makes some assumptions and applies DUPSORT, which is not always desired
-- @param name The name of the database to open
-- @param readonly Optional flag to open a readonly transaction
proto.open_tx = function(self,name,readonly)
  local tx,dh
  local opts

  if readonly then
    opts = MDB.RDONLY + MDB.DUPSORT
  else
    opts = 0
  end

  tx = assert(self.lmdb_env:txn_begin(nil, opts))
  dh = assert(tx:dbi_open(name, MDB.DUPSORT))
  return tx, dh
end

---Checks the transaction to see if tx is not null and if the transaction flags
-- allow for a write to the environment
-- NOTE: Does not check the transaction yet.
-- @param tx The transaction to check
-- @return tx Cleaned transaction or nil
-- @return dh database handle or error message
-- @return commit_flag or error number
proto.check_tx = function(self,tx)
  local dh, err, errno
  if tx then
    --local state = tx:mt_flags
    dh, err, errno = tx:dbi_open(self.name, MDB.DUPSORT)
    if dh then
      return tx, dh
    else
      return dh, err, errno
    end
  else
    tx, dh, errno = self:open_tx(self.name)
    -- true indicates the commit_flag return value
    return tx, dh, errno or true
  end
end

--- Checks the entry for valid values and serialises tables.
-- @param key The item key that is checked and serialized if necessary
-- @param value The table item value to check and serialize if necessary
-- @param throw_on_key Throws an error if the key is a table. ?
-- @return key cleaned key
-- @return value cleaned value
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
proto.print_entries = function (self)
  local tx,dh = self.open_tx(self.name, true)
  local cursor, error, errorno = tx:cursor_open(dh)
  local k
  local ok
  for k, v in cursor_pairs(cursor) do
    if type(v) == 'table' then ok,v = serpent.block(v) end
    print(k,v)
  end

  cursor:close()
  tx:abort()
end

--- This funciton is a raw get of all KEYS in the database
-- It could use parameters for fetch size and offset? I don't
-- know how that would be implemented yet
proto.get_keys = function (self)
  local retval = {}
  local tx,dh = self:open_tx(self.name, true)
  local cursor, error, errorno = tx:cursor_open(dh)
  local k = 0

  for k in cursor_pairs(cursor) do
    retval[k] = true
  end
  cursor:close()
  tx:abort()
  return tracker(self, retval)
end

--- This funciton is a raw get of all ENTRIES in the database
-- It could use parameters for fetch size and offset? I don't
-- know how that would be implemented yet
proto.get_all = function (self)
  local retval = {}
  local tx, dh = self:open_tx(self.name, true)
  local cursor, error, errorno = tx:cursor_open(dh)
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
  tx:abort()
  return tracker(self, retval)
end

--- Commits values to the database from a tracker table.
-- only the changes(updates/new, delete) are applied to the database.
-- returns nil and an error if a regular table is used. NOTE: This api is not
-- currently thread safe if an optional transaction is specified
-- @param tt Tracker Table containing recordset and meta about the changes made to the data.
-- @param tx Optional transaction. NOTE: If a transaction is specified, the tracker table is committed as a CHILD
-- TRANSACTION that must be completed with no errors. NO OTHER actions on this transaction can occur at the same time.
proto.commit =  function (self,tt, tx)
  local meta = getmetatable(tt)
  if meta and meta.changes then
    local tx, dh = self:open_tx(self.name)
    local ok, err, errno
    local cursor
    cursor, err, errno= tx:cursor_open(dh)
    if not cursor then
      tx:abort()
      return nil, err, errno
    end
    local count = 0
    for k,action in pairs(meta.changes) do
      local v
      k,v = clean_items(k,tt[k],true)
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
    cursor:close()
    tx:commit()
    if debug then
      print("Has tracker: "..tostring(has_tracker))
      print("Changes Committed: ".. count)
    end
  else
    -- non-tracked. update all
    return nil, errors.COMMIT_NOT_A_TRACKER_TABLE.err, errors.COMMIT_NOT_A_TRACKER_TABLE.errno
  end
end

--- Runs a function over each value from the database and
-- if it returns true, adds it to the return set.
-- @param func A function for searching a table entry. The function signature should support
-- parameters for key, value and any optional items you want to specify
-- @return Returns a tracker table of all values found in the database that matched the search.
proto.search_entries = function (self,func,...)
  local tx, dh = self:open_tx(self.name, true)
  local cursor, error, errorno = tx:cursor_open(dh)
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
-- @param key The item key for the database to retrieve
proto.get_item = function (self,key)
  local tx, dh = self:open_tx(self.name, true)
  local ok,res,errno = tx:get(dh,key, _)
  tx:commit()
  return ok,res,errno
end


--- Searches the database for all the keys in tbl and returns a table of records.
-- @param self The lp database object
-- @param tbl Table containing the keys for searching. The value is ignored.
proto.get_items = function (self,tbl)
  local retval = {}
  local tx, dh = self:open_tx(self.name, true)
  local cursor, error, errorno = tx:cursor_open(dh)
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
-- @param items A table containing the items to be committed
-- @return On success returns true. On error returns nil, err, errno
proto.add_items= function (self,items)
  local tx, dh = self:open_tx(self.name)
  local ok, err, errno
  local cursor
  cursor, err, errno= tx:cursor_open(dh)
  if not cursor then
    tx:abort()
    return nil, err, errno
  end
  local tmp = 0
  for k,v in pairs(items) do
    k,v = clean_items(k,v,true)
    ok, err, errno = cursor:put(k,v,0)
    if not ok then
      cursor:close()
      tx:abort()

      return nil, err, errno
    end
  end
  cursor:close()
  tx:commit()
  return true
end

--- Checks if the database exists. This doesn't work!
-- @param key The key to find
-- @return On success returns true. On Error returns nil, err, errno
proto.item_exists = function (self,key)
  local tx, dh = self:open_tx(self.name)
  clean_items(key, nil, true)
  local ok, err, errno = tx:get(dh, key)
  if not ok then
    tx:abort()
    return nil, err, errno
  end
  tx:commit()
  return key
end



--- Use this function to only insert the data if the key is already present and duplicates are not allowed.
proto.add_item = function (self,key,value,tx)
  local dh, cf
  tx, dh, cf = self:check_tx(tx)

  -- If the transaction fails, dh and cf will specify the error message and error number
  if not tx then return dh,cf end

  key, value = clean_items(key,value, true)
  local ok, err, errno = tx:put(dh, key, value, MDB.NOOVERWRITE)
  if cf then
    if not ok then
      tx:abort()
      return nil, err, errno
    end
    tx:commit()
  end
  return key
end

--- Inserts or updates an item in the database
-- @param key The key item to add to the database
-- @param value The value item to add to the databse at key
proto.upsert_item = function (self,key,value)
  local tx, dh = self:open_tx(self.name)
  key, value = clean_items(key,value, true)
  local ok, err, errno = tx:put(dh, key, value, 0)
  if not ok then
    tx:abort()
    return nil, err, errno
  end
  tx:commit()
  return key
end

--- Returns database statistics including the number of entries
proto.stats = function(self)
  local tx, dh = self:open_tx(self.name,true)
  local stats,err,errno = tx:stat(dh)
  tx:commit()
  return stats, err, errno
end

--- Returns a count of entries for a database
proto.count = function(self)
  local stats = self:stats()
  return stats.ms_entries
end

proto.close = function(self)
  --De-allocate self from env.databases?
  --update any indexes?
  --any cleanup?
end


--- Turns a regular table into a "Tracker Table".
-- The function adds the database and a change tracking meta table to the base table specified in t.
-- @param db Will assert if null. Should have check for actual database object.
-- @param t Base table for tracking. If t is null a blank table is used.
-- @return A proxy table for the original data that tracks all changes to the data.
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
local readOnly = function (t)
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


database.new = function(self, lmdb_env, name)
  local mt = {__index = proto }
  local new_db = {}
  setmetatable(new_db,mt)
  new_db.name = name
  new_db.lmdb_env = lmdb_env

  return new_db
end


database.tracker = tracker

return database
