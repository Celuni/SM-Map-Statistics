![DNH Logo](https://camo.githubusercontent.com/742c455547018630cf337754b6e93a16e880dbd2/68747470733a2f2f63646e2e646973636f72646170702e636f6d2f6174746163686d656e74732f3433353630313839363836323930383433372f3533383532363832363139323936313533362f6e626664666864666864686468642e706e67)


## About
Wanting to know more about you're community? This might be the script you are looking for, it stores individual and total map statistics into a database and comes with a website script to view them.

## Setup

### Game Server
- Move mapstas.smx into addons/sourcemod/plugins
- Edit addons/sourcemod/configs/databases.cfg
```
"mapstats"
 {
    "driver"            "mysql"
    "host"                "ip"
    "database"            "db"
    "user"                "user"
    "pass"                "pass"
    //"timeout"            "0"
    "port"            "3306"
}
```

### Web Server
- Upload files inside of the web server folder into your web server.
- Edit config.php, enter your database details and maps.

## Preview 
![preview](https://i.imgur.com/Ebl7sRN.png)
![preview](https://i.imgur.com/hHWZlsx.png)
