# Automatic Server Cleaning System

A fully automated cleaning and maintenance system for Linux servers.\
Designed to keep your server fast, stable, and clean by removing
unwanted files, Docker leftovers, old backups, logs, cache, and
temporary data.

This tool is ideal for servers running FastAPI apps, Nginx, databases,
Pi Node, and multi-app environments.

## 🚀 Features

-   Automatic cleanup of APT cache, logs, Docker elements, temporary
    folders, user cache, and old backups.
-   Logs all actions to `/var/log/clean-server.log`
-   Shows disk usage before and after cleaning
-   Can run manually or via cron

## 📦 Installation

1.  Create the script:

    ``` bash
    sudo nano /usr/local/bin/clean-server
    ```

2.  Paste the script (not included here).

3.  Make it executable:

    ``` bash
    sudo chmod +x /usr/local/bin/clean-server
    ```

## 🧪 Manual Usage

``` bash
sudo clean-server
```

Logs:

``` bash
sudo less /var/log/clean-server.log
```

## 🔄 Automatic Weekly Cleaning

Add to root crontab:

``` cron
30 3 * * 0 /usr/local/bin/clean-server >> /var/log/clean-server-cron.log 2>&1
```

## 🛡️ Safety Notes

-   Does not touch system files
-   Removes only unused Docker data
-   Deletes only backups older than 14 days

## 🧑‍💻 Author

Created by **TamerOnLine**.
