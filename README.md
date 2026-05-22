# Ansible Homelab

Homelab configuration management. Terraform creates infrastructure; Ansible configures the operating system and services inside VMs.

## Run From Bastion

`bastion01` has SSH access to new Ubuntu VMs and is the preferred control host for internal-only services.

Bootstrap Ansible on bastion:

```bash
ssh ubuntu@10.0.0.102
sudo apt update
sudo apt install -y ansible git
git clone https://github.com/larsj96/Ansible.git ansible-homelab
cd ansible-homelab
```

Known mapping:

```text
bastion01: 10.0.0.102
mkdocs: 10.0.0.35
docker1: 10.0.0.37
monitoring1: 10.0.0.38
media1: 10.0.0.39
mgmt1: 10.0.0.100
runner1: 10.0.0.101
```

MkDocs variables are set directly in `playbooks/mkdocs.yml` for the first deployment, with the same values also present in `roles/mkdocs/defaults/main.yml` for later reuse.

Install and publish MkDocs:

```bash
ansible-playbook playbooks/mkdocs.yml
```

Then test:

```bash
curl -I http://10.0.0.35/
```

## Vault

`docker1` runs the internal HashiCorp Vault service for automation secrets. It is not exposed through Cloudflare.

Live endpoint:

```text
http://10.0.0.37:8200
```

Deploy or reconcile from bastion:

```bash
ansible-playbook playbooks/vault.yml
```

The playbook creates `/opt/vault`, starts Vault with Docker Compose, initializes it once, unseals it, enables the `homelab` KV v2 mount, and installs the `homelab-automation` policy.

The first initialization material is stored only on `docker1`:

```text
/opt/vault/init/vault-init.json
```

That file contains the unseal keys and initial root token. Copy the unseal keys to Bitwarden/Vaultwarden for break-glass recovery. Do not commit it and do not paste it into chat.

## Monitoring

`monitoring1` is the central Docker host for metrics and logs:

- InfluxDB for Telegraf metrics.
- Central Telegraf for ping and x509 checks.
- Chronograf and Kapacitor for the TICK-style workflow.
- Grafana as the primary dashboard UI.
- OpenSearch, OpenSearch Dashboards, and Logstash for syslog/audit/application logs.
- Filebeat shipping from Linux hosts into Logstash for centralized log/audit data.

Create secrets before the first deploy:

```bash
cp group_vars/monitoring_secrets.yml.example group_vars/monitoring_secrets.yml
ansible-vault encrypt group_vars/monitoring_secrets.yml
```

Generated monitoring passwords/tokens should remain in Vault and can be mirrored into Vaultwarden for break-glass recovery.

Deploy from bastion:

```bash
ansible-playbook playbooks/monitoring.yml --ask-vault-pass
```

When Terraform creates a new Ubuntu VM, add it to `[telegraf_agents]` in `inventory/homelab.ini`, then rerun the monitoring playbook.

HP iLO SNMP polling is enabled for `ilo-hp2` (`10.0.124.165`) and `ilo-hp3` (`10.0.124.163`) through `monitoring_snmp_targets`. `ilo-hp1` (`10.0.124.164`) is documented as pending because it currently times out on UDP/161.

Palo Alto SNMP polling is enabled against `10.1.1.3`. SNMP was explicitly enabled on the Palo management-plane service on `2026-05-22`; credentials belong in the vaulted monitoring secrets file.

Proxmox metrics are collected centrally with Telegraf's Proxmox API input for `hp1`, `hp2`, `hp3`, and `dell1`. The Grafana dashboard is provisioned from `roles/monitoring_stack/templates/grafana-dashboard-proxmox-ve.json.j2`.

Cloudflare metrics can be enabled in the same stack by setting:

- `monitoring_cloudflare_enabled: true` in `group_vars/monitoring.yml`
- `cloudflare_api_token` in `group_vars/monitoring_secrets.yml` (Vault-backed)

When enabled, Ansible starts a Cloudflare exporter container (`ghcr.io/lablabs/cloudflare_exporter`) and scrapes Prometheus metrics from it into InfluxDB through Telegraf.

- The exporter auth uses Cloudflare API token with:
  - `Zone > Analytics:Read` (required)
  - `Account > Account Analytics:Read` (if account metrics are collected)
  - Optional: zone/firewall/load-balancer/etc. reads per the integration if those dashboards are used
- Optional filters are provided in vars as `monitoring_cloudflare_accounts` and `monitoring_cloudflare_zones` (zone/account ID lists).

A dedicated dashboard is provisioned as `roles/monitoring_stack/templates/grafana-dashboard-cloudflare.json.j2` when the feature is enabled.

Alternative options:

- Use the Cloudflare Prometheus integration (Cloudflare Prometheus Exporter, GraphQL + REST API backed) and keep your own dashboards.
- Use the Grafana Cloudflare data source plugin (public preview, not part of Grafana OSS by default).

References:

- https://developers.cloudflare.com/analytics/analytics-integrations/prometheus/
- https://github.com/lablabs/cloudflare-exporter
- https://developers.cloudflare.com/fundamentals/api/reference/permissions/

## Management Workbench

`mgmt1` is the inside Linux desktop/workbench for browser-based admin access. It runs Docker, Terraform, VS Code, code-server, and a web desktop with Firefox and Remmina/FreeRDP for reaching Windows RDP machines from inside the homelab.

Terraform creates `mgmt1` at `10.0.0.100` and `runner1` at `10.0.0.101`. Both belong in `[telegraf_agents]` so the monitoring playbook installs host metrics automatically.

After the Cloudflare tunnel stack has created `homelab-mgmt`, deploy the workbench from bastion:

```bash
ansible-playbook playbooks/mgmt.yml \
  -e "cloudflared_token=$(terraform -chdir=/path/to/docs-tunnel output -raw mgmt_cloudflared_tunnel_token)"
```

The generated local web credentials are stored on bastion under `~/.ansible/secrets/` and written on `mgmt1` to:

```text
/opt/mgmt-workbench/credentials.txt
```

Deploy the runner host:

```bash
ansible-playbook playbooks/runners.yml
```

## Media

`media1` is the first Docker Compose host for Plex and media automation:

- Plex
- Sonarr
- Radarr
- Prowlarr
- qBittorrent
- Overseerr

The first scaffold uses local `/mnt/media` directories so the containers can be brought up before HP2 SAS storage is exported. When the HP2 SAS media filesystem is ready, set:

```yaml
media_create_local_library_dirs: false
media_nfs_enabled: true
media_nfs_src: "hp2.example:/export/media"
```

Optional Plex claim tokens belong in the ignored `group_vars/media_secrets.yml` file:

```bash
cp group_vars/media_secrets.yml.example group_vars/media_secrets.yml
ansible-vault encrypt group_vars/media_secrets.yml
```

Deploy from bastion:

```bash
ansible-playbook playbooks/media.yml --ask-vault-pass
```

After deployment, run monitoring again so `media1` gets Telegraf:

```bash
ansible-playbook playbooks/monitoring.yml --ask-vault-pass
```
