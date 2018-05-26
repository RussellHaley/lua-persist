package.path = '../?/init.lua;../?.lua;' .. package.path
p = require 'persist'
s = require 'serpent'
words, err, errno = p.open_or_new("data-words")
boys = words:open_or_new_db("boysnames")
