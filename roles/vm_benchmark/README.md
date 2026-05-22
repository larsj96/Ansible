# VM Benchmark Role

Runs repeatable CPU, memory, and disk benchmarks on temporary Proxmox VMs.

The role writes results under `/var/tmp/homelab-benchmark/<run_id>/` on each VM and fetches them back to `benchmark-results/<run_id>/` on the Ansible control host.

Default tests:

- `sysbench cpu` for 180 seconds using all visible vCPUs.
- `sysbench memory` for 120 seconds using all visible vCPUs.
- `fio` sequential read/write and 4k random read/write/mixed profiles for 180 seconds each.

Use smaller variables for a quick smoke test:

```bash
ansible-playbook -i inventory/benchmarks.ini playbooks/benchmarks.yml \
  -e benchmark_cpu_seconds=20 \
  -e benchmark_memory_seconds=20 \
  -e benchmark_fio_runtime=30 \
  -e benchmark_fio_size=2G
```
