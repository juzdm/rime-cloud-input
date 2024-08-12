-- local simplehttp = require("simplehttp")
local simplehttp = require("simplehttp")

-- GET 请求
local url = "http://www.example.com"
local body, status, headers = simplehttp.request(url)

print(package.path)
print(package.cpath)
print(require("socket")._VERSION)


print("GET Request - URL:", url)
print("Status Code:", status)
print("Response Headers:", headers)
print("Response Body:", body)