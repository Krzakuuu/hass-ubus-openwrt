
-- Configuration
local token = "" -- Hassio long lived access token (at the end of your profile page) 
local refresh_interval = 30 --(seconds)
local url = "http://192.168.0.34:8123/api/states/" -- Home Assistant url
local device_name = "Openwrt_Router" -- device name for hassio (e.g. openwrt_router_5Ghz_temp)

-- Required libraries
package.path = "/root/lua/?.lua;" .. package.path -- path to libraries /root/lua/lib.lua
local json = require("json")
local ubuss = require("ubus")
local http = require("socket.http")
local socket = require("socket")
local ltn12 = require("ltn12")

local rx = 0
local tx = 0

-- HTTP request headers
local headers = {
    ["Content-Type"] = "application/json",  
    ["Transfer-Encoding"] = "chunked",
    ["Authorization"] = "Bearer ".. token
}

function round(number, precision)
    local fmtStr = string.format('%%0.%sf',precision)
    number = string.format(fmtStr,number)
    return number
end

-- Connect to ubus
function conUbus () 
    conn = ubus.connect()
    if not conn then
        print("Couldn't connect to ubus")
        return false
    end
    return true
end

function post_req (domain, sensor_name, data) 
    local response_body, response_code, response_headers = http.request {
        url = url.. domain.. ".".. device_name.. "_".. sensor_name,
        method = "POST",
        headers = headers,       
        source = ltn12.source.string(json.encode(data))  
    }

    if response_code == 201 then
        print("Created new sensor: ")
        print(device_name.. "_".. sensor_name)
    elseif response_code == 200 then
        --print("successfully updated sensor state")
    else
        print("Request Error. Response code: " .. response_code)
        --print(response_body)
    end
end

function easyconfig ()
    local status = conn:call("easyconfig", "status", {})

    if status then 

        --Temp 2.4GHz
        local data = {
            state = status["sensors"][1]["Temperatura Wi-Fi 2.4 GHz"]:gsub("&deg;C", ""),
            attributes = {
                state_class = "measurement",
                device_class = "temperature",
                unit_of_measurement = "°C",
                friendly_name = "Radio 2.4GHz"
            }
        }
        post_req("sensor", "2_4Ghz_temp", data)

        --Temp 5GHz
        local data = {
            state = status["sensors"][2]["Temperatura Wi-Fi 5 GHz"]:gsub("&deg;C", ""),
            attributes = {
                state_class = "measurement",
                device_class = "temperature",
                unit_of_measurement = "°C",
                friendly_name = "Radio 5GHz"
            }
        }
        post_req("sensor", "5Ghz_temp", data)
        
        --WLAN clients
        local data = {
            state = status["wlan_clients"],
            attributes = {
                icon = "mdi:wifi",
                state_class = "measurement",
                friendly_name = "Klienci WiFi"
            }
        }
        post_req("sensor", "wlan_clients", data)

        --LAN clients
        local data = {
            state = status["lan_clients"],
            attributes = {
                icon = "mdi:lan",
                state_class = "measurement",
                friendly_name = "Klienci LAN"
            }
        }
        post_req("sensor", "lan_clients", data)

        --WAN status 
        icon = "mdi:web-off"
        if status["wan_uptime"] == "" then state = "off" else state = "on" icon = "mdi:web" end 
        local data = {
            state = state,
            attributes = {
                icon = icon,
                device_class = "connectivity",
                friendly_name = "Status WAN"
            }
        }
        post_req("binary_sensor", "wan_status", data)

        currentTime = socket.gettime()
        elapsedTime = currentTime - lastExecutionTime
        lastExecutionTime = currentTime 
    
        --Download Speed
        local rxSpeed = 0
        if status["wan_rx"] > rx then 
            rxSpeed = status["wan_rx"] - rx
            rx = status["wan_rx"]
        elseif rx > status["wan_rx"] then
            rx = status["wan_rx"]
        end

        rxSpeed = rxSpeed / elapsedTime

        local data = {
            state = round((rxSpeed / 131072), 2),
            attributes = {
                icon = "mdi:download",
                unit_of_measurement = "Mb/s",
                state_class = "measurement",
                friendly_name = "Download"
            }
        }
        post_req("sensor", "download_speed", data)

        --Upload Speed
        local txSpeed = 0
        if status["wan_tx"] > tx then 
            txSpeed = status["wan_tx"] - tx
            tx = status["wan_tx"]
        elseif tx > status["wan_tx"] then
            tx = status["wan_tx"]
        end

        txSpeed = txSpeed / elapsedTime

        local data = {
            state = round((txSpeed / 131072), 2),
            attributes = {
                icon = "mdi:upload",
                unit_of_measurement = "Mb/s",
                state_class = "measurement",
                friendly_name = "Upload"
            }
        }
        post_req("sensor", "upload_speed", data)

        --Upload Data (GB)
        local data = {
            state = round(((tx - init_tx) / 1073741824), 2),
            attributes = {
                icon = "mdi:upload-outline",
                unit_of_measurement = "GB",
                state_class = "measurement",
                friendly_name = "Upload Data"
            }
        }
        post_req("sensor", "upload_data", data)

        --Download Data (GB)
        local data = {
            state = round(((rx - init_rx) / 1073741824), 2),
            attributes = {
                icon = "mdi:download-outline",
                unit_of_measurement = "GB",
                state_class = "measurement",
                friendly_name = "Download Data"
            }
        }
        post_req("sensor", "download_data", data)

    end

end 

function execute_command(command)
    local handle = io.popen(command)
    local result = handle:read("*a")
    handle:close()
    return result
end

function ping ()

    local ping_command = "ping 1.1.1.1 -q -c 4"
    local ping_result = execute_command(ping_command)

    local avg = string.match(ping_result, "round%-trip min/avg/max = %d+%.%d+/(%d+%.%d+)/%d+%.%d+ ms")

    if avg then
        local data = {
            state = round(avg, 0),
            attributes = {
                unit_of_measurement = "ms",
                state_class = "measurement",
                friendly_name = "Ping"
            }
        }
        post_req("sensor", "ping", data)
        --print("avg:", avg)
    else
        local data = {
            state = "unavailable",
            attributes = {
                unit_of_measurement = "ms",
                state_class = "measurement",
                friendly_name = "Ping"
            }
        }
        post_req("sensor", "ping", data)
        --print("Cant find avgerage ping value.")
    end

end

conUbus()
local status = conn:call("easyconfig", "status", {})
lastExecutionTime = socket.gettime()

-- Initial rx/tx values
init_rx = status["wan_rx"]
init_tx = status["wan_tx"]

-- Value updated every interval
rx = status["wan_rx"]
tx = status["wan_tx"]

while true do
    easyconfig()
    ping()
    socket.sleep(refresh_interval)
end
