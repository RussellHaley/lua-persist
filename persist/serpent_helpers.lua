local serpent = require("serpent")

local function check_table(item)
  local is_table = item:find('--%[%[table: 0x%x+%]%]$')
    if is_table then
      return serpent.load(item)
    else
      return nil
    end
end

local function check_function(item)
  local is_func = item:find('--%[%[function: 0x%x+%]%]$')
    if is_func then
      print('found a function. functions don\'t work.')
      return serpent.load(item)
    else
      return nil
    end
end


local function check_userdata(u)
  assert("not supported")
end


--- *KEYS CAN TOTALLY BE TABLES. THIS NEEDS FIXING

local function _encode(item)
  if type(item) == 'userdata' then assert('userdata is un supported.') end
  if type(item) == 'table' or type(item) == 'function' then
    item = serpent.block(item)
  elseif type(item) == 'boolean' then
    if item then item = 'true' else item = 'false' end
  end
  return item
end

-- @param key The item key that is checked and serialized if necessary
-- @param value The table item value to check and serialize if necessary
-- @param throw_on_key Throws an error if the key is a table. ?
-- @return key cleaned key
-- @return value cleaned value
local function encode(key,value)
    return _encode(key),_encode(value)
end

local function _decode(item)
  item = tonumber(item) or item
  if type(item) == 'number' then return item end
  
  if type(item) == 'string' then
  --how do I determin an error?
    local ok, res = check_table(item)
    if ok then
      return res
    else
      ok, res = check_function(item)
      if ok then 
        return res
      else
        ok, res = check_userdata(item)
        if ok then 
          assert('userdata is unsupported')
        else
          --I guess this is just a string?
          return item
        end
      end
    end
  else
    assert('This should not have happened. There should only be numbers and strings?')
    --return item
  end
end

local function decode(key, value)
  return _decode(key), _decode(value)
end


return {
encode = encode,
decode = decode
} 
