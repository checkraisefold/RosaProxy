# RosaProxy
RosaProxy is a Sub Rosa server proxy tool written in Luvit. The purpose of this tool is to allow masquerading of a gameserver's real IP address, typically for DDOS mitigation purposes, and to allow direct control over the master server (and, by association, authentication/server listing).

# How to Install/Use
This project uses a master server replacement for the Sub Rosa dedicated server to function. You can either use your own webserver or use https://m.gart.sh/ to create a page with a valid serverInfo reply for the dedicated server to use. You will need to hex edit the dedicated server binary, replacing `www.crypticsea.com` with `m.gart.sh` and padding with 0x00 afterwards or the domain for your webserver. You will also need to replace `/anewzero/serverinfo.php` with `/givenpPath/serverInfo` as given by MonsotaHost or your webserver. If the dedicated server is returning 'connection failed', you may also need to replace the Host: header's `www.crypticsea.com` with your domain, padding with `\r\n\r\n` and 0x00 afterwards.

This project depends on Luvit. Install it over at https://luvit.io/install.html before continuing. Make sure you have git installed as well.
Run the following commands:
```sh
git clone https://github.com/checkraisefold/RosaProxy.git
cd RosaProxy
```
Edit config.json to suit your needs. Then, run the following command to start RosaProxy:
```sh
luvit main.lua
```