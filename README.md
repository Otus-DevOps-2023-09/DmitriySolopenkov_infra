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
bastion_IP = 51.250.94.43
someinternalhost_IP = 10.128.0.8
```

## Cloud-testapp homework

testapp_IP = 158.160.120.62
testapp_port = 9292

```bash
yc compute instance create \
 --name reddit-app \
 --hostname reddit-app \
 --memory=4 \
 --create-boot-disk image-folder-id=standard-images,image-family=ubuntu-1604-lts,size=10GB \
 --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 \
 --metadata serial-port-enable=1 \
 --metadata-from-file user-data=cloud-init.conf

```
