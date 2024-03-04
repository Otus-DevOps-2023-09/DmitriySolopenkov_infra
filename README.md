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

"terraform-1. Практика IaC с использованием Terraform"

> проверяем пре-реквизиты

- список образов должен содержать reddit-base-XXXXXXXXXX

```
yc compute image list
+----------------------+------------------------+-------------+----------------------+--------+
|          ID          |          NAME          |   FAMILY    |     PRODUCT IDS      | STATUS |
+----------------------+------------------------+-------------+----------------------+--------+
| xxxxxxxxxxxxxxxxxxxx | reddit-full-XXXXXXXXXX | reddit-full | xxxxxxxxxxxxxxxxxxxx | READY  |
| xxxxxxxxxxxxxxxxxxxx | reddit-base-XXXXXXXXXX | reddit-base | xxxxxxxxxxxxxxxxxxxx | READY  |
| xxxxxxxxxxxxxxxxxxxx | reddit-base-XXXXXXXXXX | reddit-base | xxxxxxxxxxxxxxxxxxxx | READY  |
| xxxxxxxxxxxxxxxxxxxx | reddit-full-XXXXXXXXXX | reddit-full | xxxxxxxxxxxxxxxxxxxx | READY  |
+----------------------+------------------------+-------------+----------------------+--------+
```

- в нашем случае, 2 образа подойдут; packer выберет более новый из них.
- при желании 'освежить' образ (или отсутствии reddit-base-XXXXXXXXXX), собираем новый образ:
  - `packer/variables.json` создаем и редактируем, используя `cp packer/variables.json.example packer/variables.json` (подробней в ветке `packer-base`)
  - то же, с парой `packer/key.json.example packer/key.json` (подробней в ветке `packer-base`)
  - `cd packer/ && packer build -var-file=./variables.json ./ubuntu16.json`
- устанавливаем terraform, версия ~> 0.12.0.

```
terraform -v
Terraform v0.12.30
```

- mkdir terraform && cd terraform
- секцию provider yandex заполняем сначала hardcoded значениями:

```
provider "yandex" {
  token     = "<OAuth или статический ключ сервисного аккаунта>"
  cloud_id  = "<идентификатор облака>"
  folder_id = "<идентификатор каталога>"
  zone      = "ru-central1-a"
}
```

- узнаем нужные id для подстановки:
- `yc config list`

```
token: XXXXXXX_XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
cloud-id: xxxxxxxxxxxxxxxxxxxx
folder-id: xxxxxxxxxxxxxxxxxxxx
```

- `terraform init`
- убеждаемся в выводе init'а, что версия провайдера yandex соответствует затребованной в дз:

```
...
provider.yandex: version = "~> 0.35"
Terraform has been successfully initialized!
```

> создаем `resource "yandex_compute_instance"`

- image_id, subnet_id - согласно инструкции, пока hardcoded.
  - image_id: выбираем нужный из колонки ID вывода `yc compute image list`
  - subnet_id: значение колонки ID нужной строки вывода `yc vpc subnet list` (в моем примере - нужная строка с ZONE="ru-central1-a")
- `terraform apply`
- подключаемся к vm
  - `terraform show | grep nat_ip_address`
  - `ssh -i ~/.ssh/ubuntu ubuntu@<найденный_ip_address>`
    > > коннект неуспешен, фиксим передачей ssh public key в инстанс
  - добавляем в `main.tf`, внутри секции `resource "yandex_compute_instance" "app"`:

```
  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/ubuntu.pub")}"
  }
```

- `terraform destroy`
- `terraform apply`
- подключаемся к vm: коннект успешен

- в `outputs.tf` добавляем `output "external_ip_address_app"`
- `terraform refresh`

```
Outputs:
external_ip_address_app = NN.NN.NN.NN
```

- в `main.tf` добавляем провиженеры: "file" для puma.service и "remote-exec" для запуска скрипта установки и настройки приложения.
  - подключение провижинеров: секция

```
connection {
  type = "ssh"
  host = yandex_compute_instance.app.network_interface.0.nat_ip_address
  user = "ubuntu"
  agent = false
  private_key = file("~/.ssh/ubuntu")
}
```

- `terraform taint yandex_compute_instance.app`
- `terraform apply`

```
...
Outputs:
external_ip_address_app = NN.NN.NN.NN
```

- проверяем работу приложения в браузере `http://<external_ip_address_app>:9292`
- параметризуем переменные: переносим hardcoded vars из `main.tf` в `variables.tf`
  - `cloud_id, folder_id, zone, public_key_path`
  - создаем пару `terraform.tfvars` & `terraform.tfvars.example`; готовим \*.example для коммита в git - удаляем psi, не портя неконфиденциальную инфу

```
token            = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
cloud_id         = "xxxxxxxxxxxxxxxxxxxx"
folder_id        = "xxxxxxxxxxxxxxxxxxxx"
zone             = "ru-central1-a"
...
```

- `terraform destroy`
- `terraform apply`
- проверяем работоспособность приложения
  - без браузера можно проверить только наличие листенера `nc -vzw1 <external_ip_address_app> 9292`
  - более полную проверку: `curl`; выборочно проверяем контент; для примера берем ф-цию `/login`:

```
curl http://<external_ip_address_app>:9292/login 2>/dev/null | grep -i input
<input class='form-control' id='username' name='username' placeholder='Your username'>
<input class='form-control' id='password' name='password' placeholder='Your password'>
<input class='btn btn-primary' type='submit' value='Log in'>
```

> самостоятельные задания

> > Определите input переменную для приватного ключа... подключения для провижинеров (connection)

```
variable private_key_path {
  description = "Path to the private key used for ssh access"
}
```

> > Определите input переменную для задания зоны в ресурсе "yandex_compute_instance" "app". У нее <b>должно</b> быть значение по умолчанию

```
variable zone {
  description = "zone"
  default     = "ru-central1-a"
}

```

> > Отформатируйте все конфигурационные файлы используя команду `terraform fmt`

- `terraform fmt`

> > ... файл `terraform.tfvars.example`

- после `git clone`:
  - `cp <file>.example <file>`
  - редактируем <file> согласно инструкции

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
- создаем \*.json с параметрами и provisioner-инструкциями для packer.
- исталляция ruby, mongo - представлена 2мя provisioner скриптами
- запускаем сборку образа: `packer build ./ubuntu16.json`

---

### Диагностика ошибки

> > `Build 'yandex' errored: Failed to find instance ip address: instance has no one IPv4 external address.`

- фиксируется добавлением в секции "builders":

```json
            "use_ipv4_nat": true
```

> > отказ создавать еще одну подсеть (дефолтное поведение CLI-команды создания инстанса)

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

---

## Terraform-1 homework

### проверяем пре-реквизиты

- список образов должен содержать reddit-base-XXXXXXXXXX

```bash
yc compute image list
+----------------------+------------------------+-------------+----------------------+--------+
|          ID          |          NAME          |   FAMILY    |     PRODUCT IDS      | STATUS |
+----------------------+------------------------+-------------+----------------------+--------+
| xxxxxxxxxxxxxxxxxxxx | reddit-full-XXXXXXXXXX | reddit-full | xxxxxxxxxxxxxxxxxxxx | READY  |
| xxxxxxxxxxxxxxxxxxxx | reddit-base-XXXXXXXXXX | reddit-base | xxxxxxxxxxxxxxxxxxxx | READY  |
| xxxxxxxxxxxxxxxxxxxx | reddit-base-XXXXXXXXXX | reddit-base | xxxxxxxxxxxxxxxxxxxx | READY  |
| xxxxxxxxxxxxxxxxxxxx | reddit-full-XXXXXXXXXX | reddit-full | xxxxxxxxxxxxxxxxxxxx | READY  |
+----------------------+------------------------+-------------+----------------------+--------+
```

- в нашем случае, 2 образа подойдут; packer выберет более новый из них.
- при желании 'освежить' образ (или отсутствии reddit-base-XXXXXXXXXX), собираем новый образ:
- `packer/variables.json` создаем и редактируем, используя `cp packer/variables.json.example packer/variables.json` (подробней в ветке `packer-base`)
- то же, с парой `packer/key.json.example packer/key.json` (подробней в ветке `packer-base`)
- `cd packer/ && packer build -var-file=./variables.json ./ubuntu16.json`
- устанавливаем terraform, версия ~> 0.12.0.

```bash
terraform -v
Terraform v0.12.30
```

- mkdir terraform && cd terraform
- секцию provider yandex заполняем сначала hardcoded значениями:

```terraform
provider "yandex" {
  token     = "<OAuth или статический ключ сервисного аккаунта>"
  cloud_id  = "<идентификатор облака>"
  folder_id = "<идентификатор каталога>"
  zone      = "ru-central1-a"
}
```

- узнаем нужные id для подстановки:
- `yc config list`

```bash
token: XXXXXXX_XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
cloud-id: xxxxxxxxxxxxxxxxxxxx
folder-id: xxxxxxxxxxxxxxxxxxxx
```

- `terraform init`
- убеждаемся в выводе init'а, что версия провайдера yandex соответствует затребованной в дз:

```
...
provider.yandex: version = "= 0.108.1"
Terraform has been successfully initialized!
```

> создаем `resource "yandex_compute_instance"`

- image_id, subnet_id - согласно инструкции, пока hardcoded.
  - image_id: выбираем нужный из колонки ID вывода `yc compute image list`
  - subnet_id: значение колонки ID нужной строки вывода `yc vpc subnet list` (в моем примере - нужная строка с ZONE="ru-central1-a")
- `terraform apply`
- подключаемся к vm
  - `terraform show | grep nat_ip_address`
  - `ssh -i ~/.ssh/ubuntu ubuntu@<найденный_ip_address>`
    > > коннект неуспешен, фиксим передачей ssh public key в инстанс
  - добавляем в `main.tf`, внутри секции `resource "yandex_compute_instance" "app"`:

```
  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/ubuntu.pub")}"
  }
```

- `terraform destroy`
- `terraform apply`
- подключаемся к vm: коннект успешен

- в `outputs.tf` добавляем `output "external_ip_address_app"`
- `terraform refresh`

```
Outputs:
external_ip_address_app = NN.NN.NN.NN
```

- в `main.tf` добавляем провиженеры: "file" для puma.service и "remote-exec" для запуска скрипта установки и настройки приложения.
  - подключение провижинеров: секция

```
connection {
  type = "ssh"
  host = yandex_compute_instance.app.network_interface.0.nat_ip_address
  user = "ubuntu"
  agent = false
  private_key = file("~/.ssh/ubuntu")
}
```

- `terraform taint yandex_compute_instance.app`
- `terraform apply`

```
...
Outputs:
external_ip_address_app = NN.NN.NN.NN
```

- проверяем работу приложения в браузере `http://<external_ip_address_app>:9292`
- параметризуем переменные: переносим hardcoded vars из `main.tf` в `variables.tf`
  - `cloud_id, folder_id, zone, public_key_path`
  - создаем пару `terraform.tfvars` & `terraform.tfvars.example`; готовим \*.example для коммита в git - удаляем psi, не портя неконфиденциальную инфу

```
token            = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
cloud_id         = "xxxxxxxxxxxxxxxxxxxx"
folder_id        = "xxxxxxxxxxxxxxxxxxxx"
zone             = "ru-central1-a"
...
```

- `terraform destroy`
- `terraform apply`
- проверяем работоспособность приложения
  - без браузера можно проверить только наличие листенера `nc -vzw1 <external_ip_address_app> 9292`
  - более полную проверку: `curl`; выборочно проверяем контент; для примера берем ф-цию `/login`:

```
curl http://<external_ip_address_app>:9292/login 2>/dev/null | grep -i input
<input class='form-control' id='username' name='username' placeholder='Your username'>
<input class='form-control' id='password' name='password' placeholder='Your password'>
<input class='btn btn-primary' type='submit' value='Log in'>
```

> самостоятельные задания

> > Определите input переменную для приватного ключа... подключения для провижинеров (connection)

```
variable private_key_path {
  description = "Path to the private key used for ssh access"
}
```

> > Определите input переменную для задания зоны в ресурсе "yandex_compute_instance" "app". У нее <b>должно</b> быть значение по умолчанию

```
variable zone {
  description = "zone"
  default     = "ru-central1-a"
}

```

> > Отформатируйте все конфигурационные файлы используя команду `terraform fmt`

- `terraform fmt`

> > ... файл `terraform.tfvars.example`

- после `git clone`:
  - `cp <file>.example <file>`
  * редактируем <file> согласно инструкции

## лекция 9: дз "terraform-2. Создание Terraform модулей для управления компонентами инфраструктуры."

> следуем инструкциям ДЗ

- lb.tf переносим в files/; параметр кол-во инстансов для lb ставим = 1
- создаем сетевые ресурсы `yandex_vpc_network, yandex_vpc_subnet`
- выносим redis бэкенд нашего приложения в отдельный VM instance; для этого
  - модифицируем packer и пересобираем образы 2 VM для расщепленных инстансов app, db:
  - `(cd packer/; packer build -var-file=./variables.json ./app.json)`
  - `(cd packer/; packer build -var-file=./variables.json ./db.json)`
- разносим конфиги из `main.tf` в `app.tf, db.tf`; конфигурацию сети в `vpc.tf`
- соотв-е изменения с переменными и параметрами `variables.tf, outputs.tf, terraform.tfvars, terraform.tfvars.example`
- `terraform apply` #проверяем создание ресурсов \* с последующим `terraform destroy`
- разбиваем код на модули `modules/db, modules/app`, переносим соотв. контент из `app.tf, db.tf, vpc.tf`; в `main.tf` определяем модули
- загружаем модули из локального источника в кэш `.terraform`:
  - `terraform get`
- модифицируем переменные на пользование модулями `module.app, module.db` вместо `yandex_compute_instance.app....`
- `terraform apply` #проверяем создание ресурсов - с последующим `terraform destroy`
- создаем инфраструктуру для 2х окружений - `stage, prod`
- дублируем код в `stage/, prod/` для создания идентичных ресурсов для `stage, prod`
- `terraform apply` #проверяем создание ресурсов - с последующим `terraform destroy`

> самостоятельное задание:

- удаляем из `terraform/` файлы `main.tf, outputs.tf, terraform.tfvars, variables.tf` так как они теперь перенесены в `stage/ prod/`
- параметризуем модули переменными `path.module, app_disk_image, subnet_id`
  - при желании, можем параметризовать разные defaults для `core_fraction, cores, memory` для stage VS prod; но по задаче у нас пока идентичные env'ы
- `terraform fmt`
