--- table listing for errors

--- An enumeration for errors and error numbers
local errors = {
  NOT_IMPLEMENTED = {errno = -1, err ="This feature is not yet implemented."},
  NO_ENV_AVAIL = {errno=1, err ="The expected lmdb environment does not exist. An error has occured during initialization." },
  NO_DATABASES_DB = {errno=2,err="Did not find the expected __databases database. There is an error in your environment"}
}

return errors