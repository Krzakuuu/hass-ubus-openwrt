# hass-ubus-openwrt

Easy Lua Script For Home Assistant Integration With Ubus OpenWRT

### <img src="https://github.com/Krzakuuu/hass-ubus-openwrt/blob/main/Hassio.png?raw=true"> 

# Installation

```
opkg install luasocket

mkdir /root/lua
cd /root/lua
wget https://raw.githubusercontent.com/craigmj/json4lua/master/json/json.lua
wget https://raw.githubusercontent.com/Krzakuuu/hass-ubus-openwrt/main/main.lua
(edit this file)
```

Run on Startup

```
nano /etc/init.d/hass-ubus-openwrt 
chmod +x /etc/init.d/hass-ubus-openwrt
```

Paste init file
```
#!/bin/sh /etc/rc.common

START=99
USE_PROCD=1

start_service() {
    procd_open_instance
    procd_set_param command /usr/bin/lua /root/lua/main.lua
    procd_set_param stdout 1
    procd_set_param stderr 1
    procd_set_param respawn
    procd_close_instance
}

stop_service() {
    procd_close_instance
}
```

Enable and Start Script

```
/etc/init.d/hass-ubus-openwrt enable
/etc/init.d/hass-ubus-openwrt start
```




# Helpfull Informations

* Commands:
  * logread  
  * ubus -v list 
  * ubus call 
  * ubus list 

* Links
  * https://openwrt.org/docs/techref/ubus
  * https://eko.one.pl/?p=easyconfig
