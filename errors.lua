--- table listing for errors

-- An enumeration for errors and error numbers
local errors = {
  -- Feature not implemented
  NOT_IMPLEMENTED = {errno = -1, err ="This feature is not yet implemented."},
  -- The Env was not available
  NO_ENV_AVAIL = {errno=1, err ="The expected lmdb environment does not exist. An error has occured during initialization." },
  NO_DATABASES_DB = {errno=2,err="Did not find the expected __databases database. There is an error in your environment"},
  COMMIT_NOT_A_TRACKER_TABLE = {errno=3,err="You did not use a tracker table and called commit. Use db:add_item instead."},
  DB_ALREADY_OPEN = {errno=4,err="The database is already open."},
  MUST_USE_SELF = {errno=5,err="First param must be self (table). Call this using colon notaion. example: env:open_database('name',true)"},
  NO_BLANK_OR_NIL = {errno=6, err="Cannot create database with a name of blank ('') or nil."},
  DIR_ALREADY_EXISTS = {errno=7, err="Data directory alread exists. Use open_or_new if you expect to be trying this again."},
  DIR_DOES_NOT_EXIST = {errno=8, err="Data directory does not exist. Create a new database first."}
}

return errors
