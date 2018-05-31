package = "lua-persist"
version = "0.1.1-1"
source = {
   url = "git+https://github.com/russellhaley/lua-persist"
}
description = {
   summary = "Lua-persist is a persistence and indexing library for lua tables.",
   detailed = [[Lua-persist is a persistence and indexing library for lua tables. It allows you to perform lighting fast searches on keys and in future releases, create indexes using regular lua functions. Lua-persist tracks changes to data returned from the environment allowing you to insert, update and delete data and simply commit() the data.]],
   homepage = "https://github.com/russellhaley/lua-persist",
   license = "FreeBSD"
}
dependencies = {
   "lua >= 5.3",
   "serpent >= 0.28",
   "lightningmdb >= 0.9.19",
   "luafilesystem >= 1.7.0",
   "chronos >= 0.2-3"
}

build = {
   type = "builtin",
   modules = {
      ["persist/ptable"] = "persist/ptable.lua",
      ["persist/errors"] = "persist/errors.lua",
      ["persist/defaults"] = "persist/defaults.lua",
      ["persist/serpent_helpers"] = "persist/serpent_helpers.lua",
      ["persist/"] = "persist/init.lua"
   },
   copy_directories = {
      "doc"
   }
}
