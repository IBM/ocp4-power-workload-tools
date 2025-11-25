# kdump-pmem Setup

This deployment configures persistent memory (PMEM) for kdump crash dumps on OpenShift worker nodes. Kdump is a kernel crash dumping mechanism that allows you to save the contents of system memory when a kernel panic occurs. By configuring kdump to use persistent memory (PMEM), crash dumps can be stored in a dedicated memory region that survives system crashes, providing faster and more reliable crash dump capture compared to traditional disk-based storage.

The setup deploys a privileged DaemonSet that runs on all worker nodes with access to the host's `/sys` filesystem, enabling it to configure PMEM devices for kdump operations.

## Prerequisites

- OpenShift cluster with worker nodes that support persistent memory (PMEM)
- Cluster admin privileges
- Kustomize tool installed

## Architecture

The deployment consists of:

1. **Project/Namespace** (`00-project.yaml`): Creates the `kdump-pmem-setup` namespace with privileged security context
2. **ServiceAccount** (`01-sa.yaml`): Creates `ocp4-kdump-pmem-setup-sa` service account
3. **RBAC** (`02-rbac.yaml`): Binds the service account to cluster-admin role for system-level operations
4. **DaemonSet** (`03-daemonset.yaml`): Deploys privileged containers on all nodes to configure PMEM for kdump

## Installation

### 1. Install Kustomize

```bash
curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash
sudo mv kustomize /usr/local/bin
kustomize -h
```

### 2. Clone the Repository

```bash
git clone https://github.com/IBM/ocp4-power-workload-tools
cd ocp4-power-workload-tools
```

### 3. Set Kubeconfig

```bash
export KUBECONFIG=~/.kube/config
```

### 4. Deploy the kdump-pmem Setup

```bash
cd manifests/kdump-pmem
kustomize build . | oc apply -f -
```

### 5. Verify Deployment

Check that the DaemonSet pods are running on all nodes:

```bash
oc get pods -n kdump-pmem-setup
```

Expected output:
```
NAME                      READY   STATUS    RESTARTS   AGE
kdump-pmem-setup-xxxxx    1/1     Running   0          30s
kdump-pmem-setup-yyyyy    1/1     Running   0          30s
```

## Configuration Details

The DaemonSet runs with the following characteristics:

- **Image**: `quay.io/powercloud/ocp4-power-workload-tools:main`
- **Privileged Mode**: Required for system-level PMEM configuration
- **Host Access**: Mounts `/sys` for device management
- **Network Mode**: Uses host network, PID, and IPC namespaces
- **Priority**: Runs as `system-cluster-critical` for high availability
- **Capabilities**: Includes `CAP_SYS_ADMIN`, `CAP_FOWNER`, `NET_ADMIN`, and `SYS_ADMIN`

## Uninstall

To remove the kdump-pmem setup:

```bash
cd manifests/kdump-pmem
kustomize build . | oc delete -f -
```

## Troubleshooting

### Check Pod Logs

```bash
oc logs -n kdump-pmem-setup <pod-name>
```

### Verify PMEM Devices

Exec into a pod to check PMEM configuration:

```bash
oc exec -n kdump-pmem-setup <pod-name> -it -- /bin/bash
ls -la /sys/bus/nd/devices/
```

### Check Security Context

Ensure the namespace has privileged security context:

```bash
oc get namespace kdump-pmem-setup -o yaml | grep security
```

## Notes

- This setup requires nodes with PMEM hardware support
- The DaemonSet runs indefinitely (`sleep infinity`) to maintain the configuration
- Changes to PMEM configuration may require node reboots to take effect
- Ensure adequate PMEM capacity is available for expected crash dump sizes