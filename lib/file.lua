--- Basic file functions for Lua. Familiar patterns for an old C# developer.
-- @author gummesson [GitHub](https://github.com/gummesson/file.lua)
-- @license MIT. See License.txt for details


local io, os, error = io, os, error

--- The function container
local file = {}

--- Check if the path exists
function file.exists(path)
    local file = io.open(path, 'rb')
    if file then
        file:close()
    end
    return file ~= nil
end

--- returns a string of the files content
-- @param path the path to read
function file.read(path)
    local file, err = io.open(path, 'rb')
    if err then
        error(err)
    end
    local content = file:read(mode)
    file:close()
    return content
end

--- Write the content string to the path specified.
-- See mode for write/append details
-- @param path The path of the file to commit the content
-- @param content String content
-- @param mode w - write the file. overwrites current contient. a - append the data to current content.
-- nil defaults to overwrite.
function file.write(path, content, mode)
    mode = mode or 'w'
    local file, err = io.open(path, mode)
    if err then
        error(err)
    end
    file:write(content)
    file:close()
end

--- Copy the file by reading the `src` and writing it to the `dest`.
-- @param src source path
-- @param dest dentination path
function file.copy(src, dest)
    local content = file.read(src)
    file.write(dest, content)
end

--- Move the file form source to destination
-- @param src source path
-- @param dest detination path
function file.move(src, dest)
    os.rename(src, dest)
end

--- Remove the file i.e. delete
-- @param path the path of the file to delete
function file.remove(path)
    os.remove(path)
end

function file.getfilepath(path)
    print("not implemented")
end

--- extract the filename from a path
-- @param path the path with filename
function file.getfilename(path)
    local i = path:find("/")
    if i == nil then
        return path:match("^.+\\(.+)$")
    else
        return path:match("^.+/(.+)$")
    end
end

--- gets the extension of the file specified
-- @param path a full path or just a file
-- @return the extension if a '.' is found, otherwise nil
function file.getfileextension(path)
    local ext = path:match "[^.]+$"
    if #ext == #url then
        return nil
    else
        return ext
    end
end

--- Returns the date of the time the file was modified
-- @param path the path to the file to be inspected
-- @return The datetime the file was last modified.
function file.getlastmodified(path)
    local f = io.popen("stat -c %Y " .. path)
    local last_modified = f:read()
    f:close()
    return last_modified
end

--[[

function file.getmd5Hex(path)
    local content = file.read(path)
    local md5 = require 'md5'
    return md5.sumhexa(content)
end

function file.getcrc32(path)
    local CRC = require 'digest.crc32lua'
    local content = open(path)
    return CRC.crc32(content)
end

function file.createhashfile(path, hashFileName)
    print("path from file", path)
    content = file.read(path)
    local md5 = require 'md5'
    local md5_as_hex = md5.sumhexa(content)
    hashFile = io.open(hashFileName, 'w')
    hashFile:write(md5_as_hex)
    hashFile:close()
end

]]
-- ## Exports
--
-- Export `file` as a Lua module.
--
return file
