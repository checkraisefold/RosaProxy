# SubProxifier
SubProxifier is a Sub Rosa server proxy tool written in Luvit. The purpose of this tool is to allow masquerading of a gameserver's real IP address, typically for DDOS mitigation purposes, and to allow direct control over the master server (and, by association, authentication/server listing).
# How to Run
First, edit the configuration in config.json to match your needs. Have Luvit already installed/accessible. Then, simply run the below command while in the directory:
`luvit main`