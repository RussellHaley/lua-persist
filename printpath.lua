local path = {}
package.path:gsub("[^;]+",function(x) path[#path+1]=x end)

for i,v in pairs(path) do
print(i,v)
end
