# hass-ubus-openwrt

Easy Lua Script For Home Assistant Integration With Ubus OpenWRT

# Installation

```
opkg install luasocket

mkdir /root/lua
cd /root/lua
wget https://raw.githubusercontent.com/craigmj/json4lua/master/json/json.lua
wget https://raw.githubusercontent.com/Krzakuuu/hass-ubus-openwrt/main/main.lua

```

# Run on Startup

```
nano /etc/init.d/hass-ubus-openwrt 
chmod +x /etc/init.d/hass-ubus-openwrt

/etc/init.d/hass-ubus-openwrt enable
/etc/init.d/hass-ubus-openwrt start
```

# Helpfull Informations

* Commands  
 * logread  
 * ubus -v list 
 * ubus call 
 * ubus list 

### <img src="https://github.com/Krzakuuu/hass-ubus-openwrt/blob/main/Hassio.png?raw=true"> 