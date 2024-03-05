# Среда для ansible

```bash
python3.10 -m venv .venv
source .venv/bin/activate
python3 -m pip install --upgrade pip
python3 -m pip install -r ansible/requirements.txt
./.venv/bin/ansible --version

cd ansible

../.venv/bin/ansible all -m ping
../.venv/bin/ansible-playbook clone.yml

cd ..
deactivate
```
