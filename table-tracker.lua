t = {}

t.new = function () 
  return t.track({})  
end

t.track = function (t,db)
  local proxy ={} -- proxy for table t

  --create metatable for the proxy
  local mt = {
    changes = {},
    database = db,
    --table key/value access
    __index = function (_,k,v)
      if k == "commit" then __commit() end
      print("*access to element" .. tostring(k))
      return t[k]
    end,
    --table value assignment
    __newindex = function (_,k,v)
      local meta = getmetatable(_)
      local changes = meta.changes
      assert(changes,"NO CHANGES TABLE in META TABLE")
      if k == "commit" then print('cannot change the "commit" key') return end
      local action = nil
      if rawget(t,k) == nil then 
        --run the "insert" item function
        action = "new"
        print('new') 
      elseif v == nil then 
        --run the delete item function
        action = "delete"
        print('nil/delete')        
      else 
        --run the update item function
        action = "update"
        print('udpate')
      end  
      --update the change tracking table. 
      -- We need to keep the action taken and the key reference?      
      print("*update of element " .. tostring(k) ..
        " to " .. tostring(v))
      
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
          print("*taversing element " .. tostring(nextkey))
        end
        return nextkey, nextvalue
      end
    end,
    --RH - update this to be smarter?
    __len = function () return #t end,
    
    __commit = function(self)
      local meta = getmetatable(self)
      if meta.db then
        db:commit(t,meta.changes)
      end      
    end
  }

  
  setmetatable(proxy, mt)

  return proxy

end

t.readOnly = function (t)
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

return t