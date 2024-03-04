provider "yandex" {
  version                  = "~> 0.35.0"
  service_account_key_file = var.yandex_service_account_key_file
  cloud_id                 = var.yandex_cloud_id
  folder_id                = var.yandex_folder_id
  zone                     = "ru-central1-a"
}

# terraform {
#   required_providers {
#     yandex = {
#       source  = "yandex-cloud/yandex"
#       version = "0.109.0"
#     }
#   }
# }

# provider "yandex" {
#   service_account_key_file = var.yandex_service_account_key_file
#   cloud_id                 = var.yandex_cloud_id
#   folder_id                = var.yandex_folder_id
#   zone                     = "ru-central1-a"
# }

module "app" {
  source          = "../modules/app"
  public_key_path = var.public_key_path
  app_disk_image  = var.app_disk_image
  subnet_id       = yandex_vpc_subnet.app-subnet.id
}

module "db" {
  source          = "../modules/db"
  public_key_path = var.public_key_path
  db_disk_image   = var.db_disk_image
  subnet_id       = yandex_vpc_subnet.app-subnet.id
}
