# lua-persist

Lua-persist is a persistence and indexing library for lua tables. It allows you to perform lighting fast searches on keys and create indexes using regular lua functions.
Lua-persist tracks changes to data returned from the environment allowing you to insert, update and delete data and simply commit() the data.

## Requirements:

**build/test:**

 * ldoc - luarocks - documentation

**runtime:**

 * lfs - luarocks - filesystem access
 * lmdb - https://github.com/LMDB/lmdb - base persistence engine
 * lightningmdb - luarocks - lua wrapper for lmdb
 * serpent - luarocks - table serialization

All lua packages are available through luarocks:
sudo ldoc luarocks install lfs lightningmdb serpent

**Building LMDB**

lmdb can be pulled from here:
https://github.com/LMDB/lmdb

Just type make && sudo make install

## Using the Library

I don't have any installer yet, so you will need to use LUA_PATH to include it in your library:
cd ~/git/lua-persist #or where ever you have it
#bash
LUA_PATH=`pwd`/\?.lua";;"
export LUA_PATH

#csh
setenv LUA_PATH `pwd`/\?.lua";;"

Basic Usage:



