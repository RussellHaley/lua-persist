# lua-persist

Lua-persist is a persistence and indexing library for lua tables. It allows you to perform lighting fast searches on keys and create indexes using regular lua functions.
Lua-persist tracks changes to data returned from the environment allowing you to insert, update and delete data and simply commit() the data.

**Note:** This project is still just in a prototype phase. The current implementation is limited but has some great things to offer lua. 

## Requirements:

**Development/test:**

 * ldoc is required to build the documentation and Luarocks is a requirement to install. You can run out of the local git repository by adding the git repository to the top of your files. 
 
 To install:
 ```sh
~/git/lua-persist$ sudo luarocks make lua-persist-dev-1.rockspec
 ```

Or in your file:
 ``` lua
 package.path = "/home/russellh/git/lua-persist/;"..package.path
 ...
 ```
 
**Runtime**

Not supplied:
* **lmdb** - https://github.com/LMDB/lmdb - The base persistence engine. Most package managers have it available. Otherwise it builds with make (gmake on FreeBSD). I'm working on a Windows build.

Available through Luarcoks:
 * **lfs** - Filesystem access
 * **lightningmdb** - Lua wrapper for lmdb
 * **serpent** - Table serialization

```sh
sudo luarocks install lfs lightningmdb serpent ldoc
```

## Using the Library

At this point the library is still limited to simple functions and does not expose the powerful cursors. The indexing feature hasn't been written yet. 

You can run the test/db-test.lua script or the test/insert-random-data.lua files. I apologise for the poor quality. I'm still working on it. Persist is also very useful in interactive mode. I create a small script that opens a specific database and then run it interactively. 

init-words.lua
```lua
p = require 'persist'
s = require 'serpent'
words, err, errno = persist.open_or_new("data-words")
boys = words:open_or_new_db("boysnames")
```

```sh
lua -i init-words.lua
```

Then run manipulate and update the data from the console:
```lua
boys.upsert_item('Christopher',{id=1,lastname='hibblebibble'})
chris = boys.get_item('Christopher')
print(serpent.block(chris))
words.close()
^C
```
