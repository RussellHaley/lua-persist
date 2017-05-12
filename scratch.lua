
local mt = {
  
  changes={},
  
  add = function(self)
    self.changes["new"] = 1
  end,
  
  check = function(self) 
    self:add()
    print(self.changes.new)
  end
  
}

mt:add()

mt:check()

