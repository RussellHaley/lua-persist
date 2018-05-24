package = "lua-persist"
version = "dev-1"
source = {
   url = "git+https://github.com/russellhaley/lua-persist"
}
description = {
   summary = "Lua-persist is a persistence and indexing library for lua tables.",
   detailed = [[
<<<<<<< HEAD
Lua-persist is a persistence and indexing library for lua tables. It allows you to perform lighting fast searches on keys and in future releases, create indexes using regular lua functions.
=======
Lua-persist is a persistence and indexing library for lua tables. It allows you to perform lighting fast searches on keys and create indexes using regular lua functions.
>>>>>>> dba8a84c5fa0789b373b53844ccc19d718b46861
Lua-persist tracks changes to data returned from the environment allowing you to insert, update and delete data and simply commit() the data.]],
   homepage = "https://github.com/russellhaley/lua-persist",
   license = "FreeBSD"
}
dependencies = {
<<<<<<< HEAD
   "lua >= 5.3",
=======
   "lua >= 5.3, < 5.4",
>>>>>>> dba8a84c5fa0789b373b53844ccc19d718b46861
   "serpent >= 0.28",
   "lightningmdb >= 0.9.19",
   "luafilesystem >= 1.7.0"
}

build = {
   type = "builtin",
   modules = {
<<<<<<< HEAD
      ["persist/database"] = "src/database.lua",
      ["persist/errors"] = "src/errors.lua",
      ["persist/lmdb-flags"] = "src/lmdb-flags.lua",
      ["persist/init"] = "src/persist.lua",
=======
      database = "database.lua",
      errors = "errors.lua",
      ["lmdb-flags"] = "lmdb-flags.lua",
      persist = "persist.lua",
>>>>>>> dba8a84c5fa0789b373b53844ccc19d718b46861
   },
   copy_directories = {
      "doc"
   }
}
