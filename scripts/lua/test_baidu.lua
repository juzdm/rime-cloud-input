-- local simplehttp = require("simplehttp")
local simplehttp = require("simplehttp")
local json = require("json")


local function make_url(input, bg, ed)
    return 'http://olime.baidu.com/py?input=' .. input ..
       '&inputtype=py&bg='.. bg .. '&ed='.. ed ..
       '&result=hanzi&resultcoding=utf-8&ch_en=0&clientinfo=web&version=1'
 end


local url = make_url("nh", 0, 5)

-- GET 请求
local body, status, headers = simplehttp.request(url)
local _, j = pcall(json.decode, body)


print("GET Request - URL:", url)
print("Status Code:", status)
print("Response Headers:", headers)
print("Response Body:", body)
print("j:", j)

if j.status == "T" and j.result and j.result[1] then
    for i, v in ipairs(j.result[1]) do
        print("i=", i)
        print("v=", v)
    end
end  
