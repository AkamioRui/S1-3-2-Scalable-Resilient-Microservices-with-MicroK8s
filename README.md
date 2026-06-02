# This branch will aggregate all the other branch

## setting up
- clone.sh = this will clone all the other branch
- microk8s_setup.sh = installs microk8s and **will reboot**
- microk8s_setup_2.sh = enable ingress and registry


# documentation
## architecture (pods)
```mermaid
graph LR
    WC[web-scrapper]
    AN[analyzer]
    DB[database]
    WA[web-API]
    WS[web-server]

    WC --> DB --> WS
    DB --> AN --> DB
    
    



```
AN --> DB --> AN