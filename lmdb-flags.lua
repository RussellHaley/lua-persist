--- Constant representation of the LMDB flags. I would like to separate these out the same way as the
-- lmdb documentation does.
local LMDB_FLAGS = {
--- LMDB database defines as a constant table. This data is exported from the lightningmdb module.
  DB_FLAGS ={
    --- use reverse string keys
    REVERSEKEY = 0x2,
    --- use sorted duplicates. Adds duplicate key support for a database
    DUPSORT = 0x4,
    --- numeric keys in native byte order: either unsigned int or size_t. The keys must all be of the same size.
    INTEGERKEY = 0x08,
    --- with MDB_DUPSORT, sorted dup items have fixed size NOTE: Not applicable to lua-persist
    DUPFIXED = 0x10,
    --- with MDB_DUPSORT, dups are MDB_INTEGERKEY-style integers
    INTEGERDUP = 0x20,
    --- with MDB_DUPSORT, use reverse string dups
    REVERSEDUP = 0x40,
    --- create DB if not already existing
    CREATE =  0x40000
  },

  --- LMDB return code defines as a constant table. This data is exported from the lightningmdb module.
  RETURN_CODES = {
    SUCCESS = 0,
    DBS_FULL = -30791,
    TXN_FULL = -30788,
    CORRUPTED = -30796,
    VERSION_MISMATCH = -30794,
    NOTFOUND = -30798,
    MAP_RESIZED = -30785,
    KEYEXIST = -30799,
    PANIC = -30795,
    TLS_FULL = -30789,
    MAP_FULL = -30792,
    INVALID = -30793,
    PAGE_NOTFOUND = -30797,
    CURSOR_FULL = -30787,
    PAGE_FULL = -30786,
    INCOMPATIBLE = -30784,
    READERS_FULL = -30790,
  },

  --- ALL LMDB defines as a constant table. This data is exported from the lightningmdb module. Inclusive of RETURN_CODES
  -- AND DB_FLAGS
  MDB = {
      APPEND = 131072.0,
      APPENDDUP = 262144.0,
      CORRUPTED = -30796.0,
      CREATE = 262144.0,
      CURRENT = 64.0,
      CURSOR_FULL = -30787.0,
      DBS_FULL = -30791.0,
      DUPFIXED = 16.0,
    --- Adds duplicate key support for a database
      DUPSORT = 4.0,
      FIRST = 0.0,
      FIRST_DUP = 1.0,
      FIXEDMAP = 1.0,
      GET_BOTH = 2.0,
      GET_BOTH_RANGE = 3.0,
      GET_CURRENT = 4.0,
      GET_MULTIPLE = 5.0,
      INCOMPATIBLE = -30784.0,
      INTEGERDUP = 32.0,
      INTEGERKEY = 8.0,
      INVALID = -30793.0,
      KEYEXIST = -30799.0,
      LAST = 6.0,
      LAST_DUP = 7.0,
      MAPASYNC = 1048576.0,
      MAP_FULL = -30792.0,
      MAP_RESIZED = -30785.0,
      MULTIPLE = 524288.0,
      NEXT = 8.0,
      NEXT_DUP = 9.0,
      NEXT_MULTIPLE = 10.0,
      NEXT_NODUP = 11.0,
      NODUPDATA = 32.0,
      NOLOCK = 4194304.0,
      NOMEMINIT = 16777216.0,
      NOMETASYNC = 262144.0,
      NOOVERWRITE = 16.0,
      NORDAHEAD = 8388608.0,
      NOSUBDIR = 16384.0,
      NOSYNC = 65536.0,
      NOTFOUND = -30798.0,
      NOTLS = 2097152.0,
      PAGE_FULL = -30786.0,
      PAGE_NOTFOUND = -30797.0,
      PANIC = -30795.0,
      PREV = 12.0,
      PREV_DUP = 13.0,
      PREV_NODUP = 14.0,
      RDONLY = 131072.0,
      READERS_FULL = -30790.0,
      RESERVE = 65536.0,
      REVERSEDUP = 64.0,
      REVERSEKEY = 2.0,
      SET = 15.0,
      SET_KEY = 16.0,
      SET_RANGE = 17.0,
      SUCCESS = 0.0,
      TLS_FULL = -30789.0,
      TXN_FULL = -30788.0,
      VERSION_MISMATCH = -30794.0,
      WRITEMAP = 524288.0
    },

  --- Transaction return codes. This list is notpart of the MDB items
  TXN={
    TXN_BEGIN=0,
    TXN_RDONLY=0x20000,
    TXN_WRITEMAP=0x80000,
    TXN_FINISHED=0x01,
    TXN_ERROR=0x02,
    TXN_DIRTY=0x04,
    TXN_SPILLS=0x08,
    TXN_HAS_CHILD=0x10,
    TXN_BLOCKED= function() return 0x01 + 0x2 + 0x10 end
  }
}

return LMDB_FLAGS

--[[

local mdb2={
SET_RANGE = 0x11,
CORRUPTED = -30796,
APPENDDUP = 0x40000,
SUCCESS = 0x00,
MULTIPLE = 0x80000,
SET_KEY = 0x10,
SET = 0x0f,
PREV_NODUP = 0x0e,
MAP_RESIZED = -30785,
PREV_DUP = 0x0d,
PREV = 0x0c,
INTEGERKEY = 0x08,
MAPASYNC = 0x100000,
LAST_DUP = 0x07,
TLS_FULL = -30789,
CURSOR_FULL = -30787,
DUPSORT = 0x04,
CURRENT = 0x40,
NOMEMINIT = 0x1000000,
PAGE_FULL = -30786,
NEXT = 0x08,
NOMETASYNC = 0x40000,
DBS_FULL = -30791,
LAST = 0x06,
GET_MULTIPLE = 0x05,
RESERVE = 0x10000,
DUPFIXED = 0x10,
RDONLY = 0x20000,
NOSYNC = 0x10000,
PANIC = -30795,
GET_BOTH = 0x02,
FIRST_DUP = 0x01,
FIRST = 0x00,
TXN_FULL = -30788,
NEXT_DUP = 0x09,
NORDAHEAD = 0x800000,
NOLOCK = 0x400000,
NOTFOUND = -30798,
NOTLS = 0x200000,
NEXT_MULTIPLE = 0x0a,
APPEND = 0x20000,
VERSION_MISMATCH = -30794,
GET_BOTH_RANGE = 0x03,
WRITEMAP = 0x80000,
KEYEXIST = -30799,
GET_CURRENT = 0x04,
NOOVERWRITE = 0x10,
NOSUBDIR = 0x4000,
FIXEDMAP = 0x01,
CREATE = 0x40000,
REVERSEDUP = 0x40,
INTEGERDUP = 0x20,
NEXT_NODUP = 0x0b,
INCOMPATIBLE = -30784,
REVERSEKEY = 0x02,
INVALID = -30793,
NODUPDATA = 0x20,
MAP_FULL = -30792,
READERS_FULL = -30790,
PAGE_NOTFOUND = -30797,
}
]]



