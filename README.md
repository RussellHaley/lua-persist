#lua-persist

lua-persist is a persistence and indexing library for lua tables. It allows you to perform lighting fast searches on keys or create indexes based on persisted table values. The second phase of the project is to integrate it with the Moses library to provide a single point for table manipulation and persistence.


Required tests:
create new env
open existing env
close env

open database
- create if not exists

- Single Key
	add item
	add items
	update item
	update items
	commit(t)
	delete item
	delete items

-Duplicate Support
	add item
	add items
	update item
	update items
	commit(t)
	delete item
	delete items

-read only
	- open
	- attempt to add
	- attempt to delete
	- attempt to update

Indexes
	-create index
	- add item:test index
	- add items:test index
	- update value: test index
	- delete item: test index
	- re-index
	- delete index

currently have two issues:

1) duplicate support and how to pass options to LMDB
2) creating default databases OR having to always check for their existence



