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

5. Find the created test files

```
> ls
gzfht_test
gunz_test

```

### Setup the NX-GZip test deployment

1. Install Kustomization tool for the deployment 

```
curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"  | bash
sudo mv kustomize /usr/local/bin
kustomize -h
```

2. Clone the ocp4-power-workload-tools repository 

```
git clone https://github.com/IBM/ocp4-power-workload-tools
cd ocp4-power-workload-tools
```

3. Configure the worker nodes to use `/dev/crypto/nx-gzip` as an `allowed_device`.

```
oc apply -f ocp4-power-workload-tools/manifests/nx-gzip/99-worker-crio-nx-gzip.yaml
```

4. Export `kubeconfig` using `export KUBECONFIG=~/.kube/config`

5. Setup the nx-gzip test Pod as below 

```
cd manifests/nx-gzip
kustomize build . | oc apply -f - 
```

6. Resulting running pod as below 

```
# oc get pod -n nx-gzip
NAME                                    READY   STATUS    RESTARTS   AGE
pod/ocp4-nx-gzip-power-workload-82hqb   1/1     Running   0          51s
```

To test with Privileged mode, you can use `nx-gzip-privileged`.

### Copy the Test artifact into the running Pod and Run the Test Artifact

1. Copy the above created executable files to the running pod 

```
# oc cp gzfht_test ocp4-nx-gzip-power-workload-b97jx:/tmp/
```

2. Access the pod shell 

```
# oc rsh ocp4-nx-gzip-power-workload-b97jx
sh-5.1#
```

3. Create a test file for testing 

```
sh-5.1# cd /tmp/
sh-5.1#
sh-5.1# dd if=/dev/random of=test bs=1M count=1
1+0 records in
1+0 records out
1048576 bytes (1.0 MB, 1.0 MiB) copied, 0.00431494 s, 243 MB/s
sh-5.1#

```

4. Run the tests in pod 

```
sh-5.1#  ./gzfht_test test
file test read, 1048576 bytes
compressed 1048576 to 1105823 bytes total, crc32 checksum = 9b75f9f7
```

If it shows as compressed and as above then its considered as PASS.
