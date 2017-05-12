--- Loads a configuration files and returns a table of key value pairs
-- Can also write a line item. If it exists, it updates the value
--- Table returned with conf KVPs.
-- @author Russell Haley
-- @copyright (c) 2016 Russell Haley
-- @license FreeBSD License. See License.txt

local conf = {}

---
-- This funciton is not tested.
-- a local fucntion for reading in a configuration file
--and outputing a table.
-- @param fn - path to the file loaded
local function loadConfFile(fn)
    local f = io.open(fn, 'r')
    if f == nil then return {} end
    local str = f:read('*a') .. '\n'
    f:close()
    local res = 'return {'

    for line in str:gmatch("(.-)[\r\n]") do
        line = line:gsub('^%s*(.-)%s*$"', '%1') -- trim line
        -- ignore empty lines and comments
        if line ~= '' and line:sub(1, 1) ~= '#' then
            line = line:gsub("'", "\\'") -- escape all '
            line = line:gsub("=%s*", "='", 1) -- match on +
            res = res .. line .. "',"
        end
    end
    res = res:sub(1, -2)
    res = res .. '}'

    local t = assert(load(res)())
    return t
end


local function trim(s)
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end

--- Read a conf file into a table.
-- Reads a configuration file in key=value notation.
-- Can include a couple of transforms but it really needs to
-- use lpeg to do the transformations.
-- @function ReadConf
-- @param filePath Path of the file to open
-- @param removequotes Removed the quotes around text items (useful in freebsd)
-- @param debug Outputs the table for review
local function ReadConf(filePath, removequotes, debug)
    local fp = io.open(filePath, "r")
    if fp then
        --Add our own path as a control mechanism (:)
        conf[":conf_file_path"] = filePath
        --loop through each line of the file
        for line in fp:lines() do
            --no idea what this does
            line = line:match("%s*(.+)")
            --if the line is valid and doesn't start with # or ; then continue
            if line and line:sub(1, 1) ~= "#" and line:sub(1, 1) ~= ";" then
                --Match on the = and get our option and it's value
                local option, value = line:match('%s*(.-)%s*=%s*(.+)%s*')
                if not option then
                    error("Unexplained match that has a key but no option: " .. line)
                elseif not value then
                    --an option key with no value is false
                    conf[option] = false
                else
                    --Success
                    --Check for comma, If no comma, single value
                    if not value:find(",") then
                        if removequotes == true then
                            table.insert(conf, option)
                            conf[option] = trim(value:gsub("\"", ""))
                        else
                            conf[option] = trim(value)
                        end
                    else
                        --This line has a comma in it. There is more than
                        -- one value item
                        value = value .. ","
                        conf[option] = {}
                        for entry in value:gmatch("%s*(.-),") do
                            conf[option][#conf[option] + 1] = entry
                        end
                    end
                end
            end
        end
        fp:close()
    else
        --No file. die.
        error("File does not exist: " .. filePath)
    end

    if debug == true then
        for i, v in pairs(conf) do
            print(i, v)
        end
    end
    return conf
end

--- Sets a value for the given key if it exists, if not, creates it.
-- @param key The key/option name
-- @param value The new value to set for given key
conf.SetItem = function(key, value)
    --(1) read all the lines into an array
    local f, e = io.open(file)
    -- check that e!
    local lines = {}
    for line in f:lines() do
        table.insert(lines, line)
    end
    f:close()

    --(2) process only non-blank or lines not starting with #
    local values = {}
    local value_lines = {}
    for i, line in ipairs(lines) do
        if not (line:match '^%s*$' or line:match '^#') then
            local var, val = line:match('^([^=]+)=(.+)')
            values[var] = val
            value_lines[var] = i
        end
    end

    --The values table is what you need.  Updating a var is like so
    lines[value_lines[var]] = var .. '=' .. new_value
    --        and then write out
    local f, e = io.open(file, 'w');
    for _, line in ipairs(lines) do
        f:write(line, '\n')
    end
    f:close()
end

--- new. Creates a new configuration table based on the file path given.
local function new(file, removequotes, debug)
    return ReadConf(file, removequotes, debug)
end


return { new = new; }
