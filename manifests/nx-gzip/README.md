This document demonstrate using the NX-GZip feature in a non-privileged container. You must have deployed a cluster with workers with a processor compatibility of IBM Power 10 or higher. The *Active Memory Expansion* feature must be licensed.

### Build the power-gzip test binary

1. Login to the PowerVM instance running Red Hat Enterprise Linux 9
2. Install required build binaries

```
dnf install make git gcc zlib-devel vim util-linux-2.37.4-11.el9.ppc64le -y
```

3. Setup the Clone repository 

```
git clone https://github.com/libnxz/power-gzip
cd power-gzip/
```

4. Run the tests 

```
./configure 
cd selftests
make
```

### Setup the NX-GZip test deployment

1. Install Kustomization tool for the deployment 

```
curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"  | bash
sudo mv kustomize /usr/local/bin
kustomize -h
```

2. Configure the worker nodes to use `/dev/crypto/nx-gzip` as an `allowed_device`.

```
oc apply -f ocp4-power-workload-tools/manifests/nx-gzip/99-worker-crio-nx-gzip.yaml
```

3. Clone the ocp4-power-workload-tools

```
git clone https://github.com/IBM/ocp4-power-workload-tools
cd ocp4-power-workload-tools
```

4. Export `kubeconfig` using `export KUBECONFIG=~/.kube/config`

5. Setup the nx-gzip test Pod as below 

```
cd manifests/nx-gzip
kustomize build . | oc apply -f - 
```

6. Resulting running pod as below 

```
# oc get pod -n nx-gzip-demo
NAME                                    READY   STATUS    RESTARTS   AGE
pod/ocp4-nx-gzip-power-workload-dk7tc   1/1     Running   0          51s
```

To test with Privileged mode, you can use `nx-gzip-privileged`.

### Copy the Test artifact into the running Pod

explain how to copy over the compiled binary

### Run the Test Artifact

explain how to setup the test file
explain how to run it.