# media_stack

Deploys the `media1` Docker Compose stack:

- Plex
- Sonarr
- Radarr
- Prowlarr
- qBittorrent
- Overseerr

The role owns the application directories, optional NFS mount, Compose file, and local `.env` file under `media_stack_dir`. It does not configure app-specific accounts, indexers, tracker credentials, libraries, or request workflows.

## Storage Model

The bootstrap path uses local directories on `media1`:

```text
/mnt/media/movies
/mnt/media/tv
/opt/media/downloads
```

When HP2 SAS storage is ready, keep the same container paths and move only the host backing storage:

```yaml
media_create_local_library_dirs: false
media_nfs_enabled: true
media_nfs_src: "hp2.example:/export/media"
```

Confirm the real HP2 export path, ownership, and permissions before enabling NFS. The mounted export should provide `movies` and `tv` directories writable by `media_puid` and `media_pgid`.

## Secrets

Optional Plex claim tokens belong in the ignored `group_vars/media_secrets.yml` file. Do not commit tokens, application passwords, API keys, or qBittorrent credentials.

## Monitoring

`media1` should also be in the `telegraf_agents` inventory group. After applying this role, run the monitoring playbook so host metrics are present in InfluxDB/Grafana:

```bash
ansible-playbook playbooks/monitoring.yml --ask-vault-pass
```

Expected first checks are host availability, CPU, memory, disk, Docker health, and storage capacity trends for `/opt/media` and `/mnt/media`.
