I inspected the repo structure and contents. It includes three main parts: **Ansible node preparation**, **KubeKey cluster installation**, and a **Helm chart for ClickHouse + ClickHouse Keeper**. The repo also contains large binary artifacts: `kubekey/kk` is **94.7 MB**, and `kubekey/etcd-v3.6.5-linux-amd64.tar.gz` is **23.2 MB**, which GitHub does not render inline. ([GitHub][1])

The draft README is below.

# k8s-with-kk

A practical Kubernetes lab repository for preparing Linux nodes, installing a Kubernetes cluster with **KubeKey**, and deploying a local **ClickHouse cluster with ClickHouse Keeper** using Helm.

The repository is organized around three workflows:

1. Prepare Kubernetes nodes with Ansible.
2. Create a Kubernetes cluster using KubeKey.
3. Deploy a 3-replica ClickHouse cluster with ClickHouse Keeper.

## Repository Structure

```text
.
├── README.md
├── .gitignore
├── k8s-prep-ansible/
│   ├── inventory.ini
│   ├── prepare-k8s-nodes.yml
│   ├── runme.sh
│   └── group_vars/
│       └── all.yml
├── kubekey/
│   ├── config.yaml
│   ├── inventory.yaml
│   ├── runme.sh
│   ├── kk
│   └── etcd-v3.6.5-linux-amd64.tar.gz
└── clickhouse-chart/
    ├── Chart.yaml
    ├── values.yaml
    ├── clickhouse-values-3replicas.yaml
    └── templates/
        ├── _helpers.tpl
        ├── clickhouse-configmap.yaml
        ├── clickhouse-service.yaml
        ├── clickhouse-statefulset.yaml
        ├── keeper-configmap.yaml
        ├── keeper-service.yaml
        └── keeper-statefulset.yaml
```

## What This Project Does

### 1. Prepares Kubernetes Nodes

The `k8s-prep-ansible` directory contains an Ansible playbook that prepares master and worker nodes for Kubernetes installation.

The playbook handles:

* Hostname configuration
* `/etc/hosts` cluster entries
* Timezone setup
* Common package installation
* Swap disablement
* Kernel module loading
* Kubernetes sysctl configuration
* Chrony enablement
* Firewall disablement
* SELinux disablement on RedHat-based systems
* SSH daemon configuration
* Basic validation commands

Default nodes are defined as:

| Role   | Hostname  | IP                |
| ------ | --------- | ----------------- |
| Master | `master1` | `192.168.100.101` |
| Worker | `worker1` | `192.168.100.111` |
| Worker | `worker2` | `192.168.100.112` |
| Worker | `worker3` | `192.168.100.113` |

### 2. Installs Kubernetes with KubeKey

The `kubekey` directory contains KubeKey configuration and inventory files for creating a Kubernetes cluster.

The current configuration uses:

* Kubernetes: `v1.34.0`
* Container runtime: `containerd`
* CNI: `calico`
* Calico version: `v3.31.3`
* etcd version: `v3.6.5`
* Helm version: `v3.18.5`
* Local PV provisioner enabled
* NodeLocal DNS enabled
* Alibaba Cloud image registry mirror

The KubeKey inventory defines one control-plane node and three worker nodes.

### 3. Deploys ClickHouse with ClickHouse Keeper

The `clickhouse-chart` directory contains a Helm chart named `clickhouse-local`.

The chart deploys:

* A ClickHouse `StatefulSet`
* A ClickHouse Keeper `StatefulSet`
* Headless services for stable pod DNS
* ClickHouse and Keeper config maps
* Persistent volume claims for ClickHouse and Keeper data

Default ClickHouse settings:

| Setting             | Value                                                    |
| ------------------- | -------------------------------------------------------- |
| ClickHouse image    | `docker.arvancloud.ir/clickhouse/clickhouse-server:26.3` |
| ClickHouse replicas | `3`                                                      |
| ClickHouse storage  | `10Gi` per replica                                       |
| Keeper replicas     | `3`                                                      |
| Keeper storage      | `5Gi` per replica                                        |
| HTTP port           | `8123`                                                   |
| Native TCP port     | `9000`                                                   |
| Interserver port    | `9009`                                                   |
| Keeper client port  | `9181`                                                   |
| Keeper Raft port    | `9234`                                                   |

## Prerequisites

Install the following tools on your local/admin machine:

* `git`
* `ssh`
* `sshpass`
* `ansible-core`
* `kubectl`
* `helm`

On Debian/Ubuntu:

```bash
sudo apt update
sudo apt install -y git sshpass ansible-core
```

Install the required Ansible collection:

```bash
ansible-galaxy collection install community.general
```

## Step 1: Clone the Repository

```bash
git clone https://github.com/So-Ebrahimi/k8s-with-kk.git
cd k8s-with-kk
```

## Step 2: Configure the Ansible Inventory

Edit:

```bash
k8s-prep-ansible/inventory.ini
```

Update the IP addresses, hostnames, and SSH user for your environment:

```ini
[masters]
master1 ansible_host=192.168.100.101 hostname=master1

[workers]
worker1 ansible_host=192.168.100.111 hostname=worker1
worker2 ansible_host=192.168.100.112 hostname=worker2
worker3 ansible_host=192.168.100.113 hostname=worker3

[k8s_nodes:vars]
ansible_user=user
ansible_become=true
ansible_become_method=sudo
```

## Step 3: Configure Cluster Variables

Edit:

```bash
k8s-prep-ansible/group_vars/all.yml
```

Update the timezone, host IPs, hostnames, and package list if needed.

Example:

```yaml
timezone: Asia/Tehran

cluster_hosts:
  - ip: 192.168.100.101
    name: master1
  - ip: 192.168.100.111
    name: worker1
  - ip: 192.168.100.112
    name: worker2
  - ip: 192.168.100.113
    name: worker3
```

## Step 4: Prepare the Nodes

Run the Ansible workflow:

```bash
cd k8s-prep-ansible
export ANSIBLE_HOST_KEY_CHECKING=False

ansible all -i inventory.ini -m ping -k -K
ansible-playbook -i inventory.ini prepare-k8s-nodes.yml -k -K
```

Verify the nodes:

```bash
ansible k8s_nodes -i inventory.ini -m shell -a "hostname && free -h && lsmod | egrep 'overlay|br_netfilter|ip_vs' && sysctl net.ipv4.ip_forward"
```

## Step 5: Configure KubeKey Inventory

Edit:

```bash
kubekey/inventory.yaml
```

Update each host entry with your real SSH details:

```yaml
master1:
  connector:
    type: ssh
    host: 192.168.100.101
    port: 22
    user: user
    password: REPLACE_ME
    internal_ipv4: 192.168.100.101
```

Do the same for all worker nodes.

> Do not commit real passwords, private keys, or production credentials to the repository.

## Step 6: Review the KubeKey Cluster Config

Edit:

```bash
kubekey/config.yaml
```

The current config is prepared for Kubernetes `v1.34.0` with `containerd`, `calico`, local storage, and registry mirrors.

Important settings:

```yaml
kube_version: v1.34.0
container_manager: containerd
type: calico
calico_version: v3.31.3
local:
  enabled: true
  default: true
```

## Step 7: Create the Kubernetes Cluster

Run:

```bash
cd kubekey
chmod +x kk
sudo ./kk create cluster -i inventory.yaml -c config.yaml
```

The `runme.sh` file also includes commands for pulling and retagging Kubernetes control-plane images from the configured mirror.

## Step 8: Verify the Kubernetes Cluster

After installation, verify the cluster:

```bash
kubectl get nodes -o wide
kubectl get pods -A
kubectl get storageclass
```

You should see one control-plane node and three worker nodes.

## Step 9: Deploy ClickHouse

From the repository root:

```bash
helm install clickhouse ./clickhouse-chart
```

Or install into a dedicated namespace:

```bash
kubectl create namespace clickhouse
helm install clickhouse ./clickhouse-chart -n clickhouse
```

Check the deployed resources:

```bash
kubectl get pods -n clickhouse
kubectl get svc -n clickhouse
kubectl get pvc -n clickhouse
```

## Step 10: Customize ClickHouse Values

Edit:

```bash
clickhouse-chart/values.yaml
```

Common options:

```yaml
clickhouse:
  replicas: 3
  storage:
    size: 10Gi
    storageClassName: ""

keeper:
  replicas: 3
  storage:
    size: 5Gi
    storageClassName: ""

service:
  httpPort: 8123
  tcpPort: 9000
  keeperPort: 9181
  keeperRaftPort: 9234
  interserverPort: 9009
```

To use a specific storage class:

```yaml
clickhouse:
  storage:
    storageClassName: local

keeper:
  storage:
    storageClassName: local
```

Upgrade the release after changes:

```bash
helm upgrade clickhouse ./clickhouse-chart -n clickhouse
```

## Connecting to ClickHouse

Port-forward the ClickHouse HTTP port:

```bash
kubectl port-forward svc/clickhouse-clickhouse 8123:8123 -n clickhouse
```

Test with curl:

```bash
curl "http://localhost:8123/?query=SELECT%201"
```

Port-forward the native TCP port:

```bash
kubectl port-forward svc/clickhouse-clickhouse 9000:9000 -n clickhouse
```

Then connect using `clickhouse-client`:

```bash
clickhouse-client --host 127.0.0.1 --port 9000
```

## Cleanup

Uninstall the ClickHouse Helm release:

```bash
helm uninstall clickhouse -n clickhouse
```

Delete the namespace if used:

```bash
kubectl delete namespace clickhouse
```

Delete persistent volume claims if you want to remove stored data:

```bash
kubectl delete pvc -n clickhouse --all
```

## Security Notes

This repository is suitable for lab, learning, and internal testing environments.

Before using it in production:

* Replace all example passwords.
* Use SSH keys instead of plaintext passwords.
* Do not commit real secrets.
* Review firewall and SELinux changes before applying them.
* Review registry mirror settings for your region and compliance requirements.
* Validate Kubernetes and component versions against your production support policy.
* Consider removing large binary artifacts from Git and storing them in releases or artifact storage.

## Notes

* The KubeKey binary and etcd tarball are included in the repository.
* The ClickHouse chart uses StatefulSets and PVCs, so deleting pods does not automatically delete data.
* StatefulSet volume size changes may require manual PVC expansion depending on your storage class.
* The current topology is one Kubernetes control-plane node with three workers.
* The ClickHouse topology is three ClickHouse replicas with three ClickHouse Keeper replicas.

## License

No license file is currently included. Add a license before publishing or distributing this project.

One important note: `clickhouse-values-3replicas.yaml` appears in the GitHub directory listing, but GitHub returned a 404 when I tried to open that specific file. The README above still documents the 3-replica setup because `values.yaml` clearly sets `clickhouse.replicas: 3` and `keeper.replicas: 3`. ([GitHub][2])

[1]: https://github.com/So-Ebrahimi/k8s-with-kk "GitHub - So-Ebrahimi/k8s-with-kk · GitHub"
[2]: https://github.com/So-Ebrahimi/k8s-with-kk/tree/main/clickhouse-chart "k8s-with-kk/clickhouse-chart at main · So-Ebrahimi/k8s-with-kk · GitHub"
