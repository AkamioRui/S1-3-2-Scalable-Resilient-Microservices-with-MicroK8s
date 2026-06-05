# wsl troubleshoot
## building image
- systemd --user not started, just dont use systemd --user, use these instead
``` ~/.config/containers/containers.conf
[containers]
systemd = "false"

[engine]
cgroup_manager = "cgroupfs"
```

``` sh
podman system migrate
```

## start systemd --user 
```sh
sudo systemctl start user@1000
```


