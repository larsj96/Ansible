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
monitoring1: planned 10.0.0.38
```

MkDocs variables are set directly in `playbooks/mkdocs.yml` for the first deployment, with the same values also present in `roles/mkdocs/defaults/main.yml` for later reuse.

Install and publish MkDocs:

```bash
ansible-playbook playbooks/mkdocs.yml
```

Then test:

```bash
curl -I http://10.0.0.37/
```

## Monitoring

`monitoring1` is the central Docker host for metrics and logs:

- InfluxDB for Telegraf metrics.
- Central Telegraf for ping and x509 checks.
- Chronograf and Kapacitor for the TICK-style workflow.
- Grafana as the primary dashboard UI.
- OpenSearch, OpenSearch Dashboards, and Logstash for syslog/audit/application logs.

Create secrets before the first deploy:

```bash
cp group_vars/monitoring_secrets.yml.example group_vars/monitoring_secrets.yml
ansible-vault encrypt group_vars/monitoring_secrets.yml
```

Deploy from bastion:

```bash
ansible-playbook playbooks/monitoring.yml --ask-vault-pass
```

When Terraform creates a new Ubuntu VM, add it to `[telegraf_agents]` in `inventory/homelab.ini`, then rerun the monitoring playbook.
