# SubProxifier
SubProxifier is a Sub Rosa server proxy tool written in Luvit. The purpose of this tool is to allow masquerading of a gameserver's real IP address, typically for DDOS mitigation purposes, and to allow direct control over the master server (and, by association, authentication/server listing).
# How to Install/Use
This project depends on Luvit. Install it over at https://luvit.io/install.html before continuing. Make sure you have git installed as well.
Run the following commands:
```sh
git clone https://github.com/checkraisefold/SubProxifier.git
cd SubProxifier
```
Edit config.json to suit your needs. Then, run the following command to start SubProxifier:
```sh
luvit main.lua
```