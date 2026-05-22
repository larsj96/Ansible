# VM Benchmark Role

Runs repeatable CPU, memory, and disk benchmarks on temporary Proxmox VMs.

The role writes results under `/var/tmp/homelab-benchmark/<run_id>/` on each VM and fetches them back to `benchmark-results/<run_id>/` on the Ansible control host.

Default tests:

- `sysbench cpu` for 180 seconds using all visible vCPUs.
- `sysbench memory` for 120 seconds using all visible vCPUs.
- `fio` sequential read/write and 4k random read/write/mixed profiles for 180 seconds each.
- `iperf3` against the selected benchmark iperf server.

Use smaller variables for a quick smoke test:

```bash
ansible-playbook -i inventory/benchmarks.ini playbooks/benchmarks.yml \
  -e benchmark_cpu_seconds=20 \
  -e benchmark_memory_seconds=20 \
  -e benchmark_fio_runtime=30 \
  -e benchmark_fio_size=2G
```

To test VM throughput toward the Frankfurt VPS instead of another benchmark VM,
use the persistent VPS iperf3 server:

```bash
ansible-playbook -i inventory/benchmarks.ini playbooks/benchmarks.yml \
  -e benchmark_iperf_host=72.61.95.150 \
  -e benchmark_iperf_manage_server=false
```
