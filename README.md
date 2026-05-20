# Ansible Homelab

Homelab configuration management. Terraform creates infrastructure; Ansible configures the operating system and services inside VMs.

## Run From Bastion

`bastion01` has SSH access to new Ubuntu VMs and is the preferred control host for internal-only services.

Bootstrap Ansible on bastion:

```bash
ssh ubuntu@10.0.0.99
sudo apt update
sudo apt install -y ansible git
git clone https://github.com/larsj96/Ansible.git ansible-homelab
cd ansible-homelab
```

Known DHCP mapping:

```text
docker1: 10.0.0.35
mkdocs: 10.0.0.37
```

Install and publish MkDocs:

```bash
ansible-playbook playbooks/mkdocs.yml
```

Then test:

```bash
curl -I http://10.0.0.37/
```
