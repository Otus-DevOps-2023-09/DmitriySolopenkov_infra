# DmitriySolopenkov_infra
DmitriySolopenkov Infra repository

## Bastion homework

```bash
ssh-add ~/.ssh/appuser
ssh -J appuser@51.250.94.43 appuser@10.128.0.8
```

```bash
vim ~/.ssh/config
```

```bash
Host bastion
    HostName 51.250.94.43
    User appuser
    IdentityFile ~/.ssh/appuser

Host someinternalhost
    ProxyJump appuser@51.250.94.43
    HostName 10.128.0.8
    User appuser
    IdentityFile ~/.ssh/appuser
```

```bash
vim ~/.bashrc
```

```bash
alias someinternalhost='ssh someinternalhost'
```

```bash
bastion_IP = 158.160.106.57
someinternalhost_IP = 10.128.0.8
```
