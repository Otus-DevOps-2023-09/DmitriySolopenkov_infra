import os

import testinfra.utils.ansible_runner

testinfra_hosts = testinfra.utils.ansible_runner.AnsibleRunner(
    os.environ["MOLECULE_INVENTORY_FILE"]
).get_hosts("all")


# check if MongoDB is enabled and running
def test_mongo_running_and_enabled(host):
    mongo = host.service("mongod")
    assert mongo.is_running
    assert mongo.is_enabled


# check if configuration file contains the required line
def test_config_file(host):
    config_file = host.file("/etc/mongod.conf")
    assert config_file.contains("bindIp: 0.0.0.0")
    assert config_file.is_file


# check if MongoDB port is reachable
def test_mongo_port(host):
    localhost = host.addr("127.0.0.1")
    assert localhost.port(27017).is_reachable
