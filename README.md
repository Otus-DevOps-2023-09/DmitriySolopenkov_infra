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

---

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

---

## Packer homework

### Используем packer для создания образа для compute instance

- ставим packer, создаем service account key file, по шагам в дз.
- создаем *.json с параметрами и provisioner-инструкциями для packer.
- исталляция ruby, mongo - представлена 2мя provisioner скриптами
- запускаем сборку образа: `packer build ./ubuntu16.json`

---

### Диагностика ошибки

>> `Build 'yandex' errored: Failed to find instance ip address: instance has no one IPv4 external address.`

- фиксируется добавлением в секции "builders":

```json
            "use_ipv4_nat": true
```

>> отказ создавать еще одну подсеть (дефолтное поведение CLI-команды создания инстанса)

- фиксим использованием существующей, указываем в секции "builders":

```json
            "subnet_id": "{{user `subnet_id`}}",
```

### Выносим часть параметров в файл variables.json

- заносим variables.json в .gitignore; переносим значения privacy-sensitive части параметров в variables.json.
- создаем variables.json.example с фейковыми значениями параметров из variables.json, для re-use git-кода
- в новом проекте необходимо
   -- `cp variables.json.example variables.json`
   -- поставить правильные значения в variables.json
- команда создания образа: `packer build -var-file=./variables.json ./ubuntu16.json`
- созданный образ используем при создании compute instance, логинимся по ssh.
- вручную инсталлируем & запускаем web-приложение `https://github.com/express42/reddit.git` вручную.
- проверяем работу в браузере: http://<внешний IP машины>:9292
