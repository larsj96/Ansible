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

Confirm the `mkdocs` VM IP before running. Earlier DHCP scan showed `mkdocs` and `docker1` as `10.0.0.35` / `10.0.0.37`:

```bash
for host in 10.0.0.35 10.0.0.37; do
  echo "===== $host ====="
  ssh ubuntu@$host hostname
done
```

If needed, edit `inventory/homelab.ini` so `mkdocs ansible_host=` points at the host named `mkdocs`.

Install and publish MkDocs:

```bash
ansible-playbook playbooks/mkdocs.yml
```

Then test:

```bash
curl -I http://10.0.0.35/
```
