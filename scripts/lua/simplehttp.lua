local socket = require("socket")
local ssl = require("ssl")

local simplehttp = {}

simplehttp.TIMEOUT = 5 -- 将超时时间延长到 5 秒

local function create_ssl_connection(sock, host)
    local params = {
        mode = "client",
        protocol = "tlsv1_2",
        verify = "none", -- 如果需要验证服务器证书，请设置为 "peer"
        options = "all",
    }
    sock = ssl.wrap(sock, params)
    sock:sni(host)
    sock:dohandshake()
    return sock
end

local function parse_url(url_str)
    local scheme, rest = url_str:match("^(.-)://(.+)$")
    if not scheme then
        scheme = "http" -- 默认为 http
        rest = url_str
    end

    local host, port, path = rest:match("^(.-):(%d+)(/.+)$")
    if not host then
        host, path = rest:match("^(.-)(/.+)$")
        if not host then
            host = rest
            path = "/"
        end
    else
        path = path or "/"
    end

    local query = path:match("?(.*)")
    if query then
        path = path:match("^(.-)%?")
    end

    return {
        scheme = scheme,
        host = host,
        port = tonumber(port) or (scheme == "https" and 443 or 80),
        path = path,
        query = query
    }
end

local function create_request(method, host, path, headers, body)
    local request = method .. " " .. path .. " HTTP/1.1\r\n"
    request = request .. "Host: " .. host .. "\r\n"
    
    if not headers["User-Agent"] then
        request = request .. "User-Agent: SimpleHTTP/1.0\r\n"
    end

    if not headers["Accept"] then
        request = request .. "Accept: */*\r\n"
    end

    for k, v in pairs(headers) do
        request = request .. k .. ": " .. v .. "\r\n"
    end

    if body then
        request = request .. "Content-Length: " .. #body .. "\r\n"
        request = request .. "\r\n" .. body
    else
        request = request .. "\r\n"
    end

    return request
end

local function receive_response(sock)
    local response_headers = {}
    local response_body = {}

    -- 读取响应头
    local response_header_string = ""
    while true do
        local line, err = sock:receive("*l")
        if err then
            return nil, "Error receiving header line: " .. err
        end
        if line == "" then -- 空行标志头部结束
            break
        end
        response_header_string = response_header_string .. line .. "\r\n"
    end

    -- 打印响应头部以便调试
    print("Response Headers:\n" .. response_header_string)

    -- 解析响应头
    for line in response_header_string:gmatch("[^\r\n]+") do
        local key, value = line:match("^(.-):%s*(.*)")
        if key and value then
            response_headers[key] = value
        elseif line:match("^HTTP/%d+%.%d+%s+(%d+)%s+(.*)") then
            local status_code = line:match("^HTTP/%d+%.%d+%s+(%d+)%s+(.*)")
            response_headers.status = tonumber(status_code)
        end
    end

    -- 读取响应体
    if response_headers["Transfer-Encoding"] == "chunked" then
        while true do
            local size_line, err = sock:receive("*l")
            if err then
                return nil, "Error receiving chunk size: " .. err
            end
            local chunk_size = tonumber(size_line:gsub("%s+", ""), 16)
            if not chunk_size then
                return nil, "Invalid chunk size: " .. (size_line or "nil")
            end
            if chunk_size == 0 then break end
            local chunk, err = sock:receive(chunk_size)
            if err then
                return nil, "Error receiving chunk data: " .. err
            end
            table.insert(response_body, chunk)
            sock:receive(2) -- 跳过 \r\n
        end
    else
        local content_length = response_headers["Content-Length"]
        if content_length then
            local content_length_num = tonumber(content_length:match("%d+"))
            if content_length_num then
                local remaining = content_length_num
                while remaining > 0 do
                    local chunk = sock:receive(math.min(remaining, 8192))
                    if not chunk then
                        return nil, "Failed to read body"
                    end
                    table.insert(response_body, chunk)
                    remaining = remaining - #chunk
                end
            else
                print("Content-Length is not a valid number:", content_length)
                while true do
                    local chunk, err = sock:receive("*a")
                    if not chunk then
                        return nil, "Error receiving body: " .. err
                    end
                    if chunk == "" then break end
                    table.insert(response_body, chunk)
                end
            end
        else
            while true do
                local chunk, err = sock:receive("*a")
                if not chunk then
                    return nil, "Error receiving body: " .. err
                end
                if chunk == "" then break end
                table.insert(response_body, chunk)
            end
        end
    end

    local body = table.concat(response_body)

    return body, response_headers.status, response_headers
end

local function request(url_str, method, headers, body)
    local parsed_url, err = parse_url(url_str)
    if not parsed_url then
        return nil, err
    end

    local host = parsed_url.host
    local port = parsed_url.port
    local path = parsed_url.path or "/"
    if parsed_url.query then
        path = path .. "?" .. parsed_url.query
    end

    -- 打印请求 URL 进行调试
    print("Request URL: " .. path)

    method = method or "GET"
    headers = headers or {}

    -- 创建 socket 连接
    local sock, err = socket.tcp()
    if not sock then
        return nil, "Error creating socket: " .. err
    end

    sock:settimeout(simplehttp.TIMEOUT)

    -- 连接到服务器
    local res, err = sock:connect(host, port)
    if not res then
        return nil, "Error connecting to server: " .. err
    end

    -- 如果是 HTTPS，使用 SSL/TLS 连接
    if parsed_url.scheme == "https" then
        sock, err = create_ssl_connection(sock, host)
        if err then
            return nil, "Error creating SSL connection: " .. err
        end
    end

    -- 构建并发送 HTTP 请求
    local req = create_request(method, host, path, headers, body)
    print("Request sent:\n" .. req)  -- 打印请求内容进行调试
    local _, err = sock:send(req)
    if err then
        return nil, "Error sending request: " .. err
    end

    -- 接收 HTTP 响应
    local body, status, response_headers = receive_response(sock)

    -- 关闭连接
    sock:close()

    return body, status, response_headers
end

function simplehttp.request(url_str, options)
    local method = options and options.method or "GET"
    local headers = options and options.headers or {}
    local body = options and options.body

    return request(url_str, method, headers, body)
end

return simplehttp
