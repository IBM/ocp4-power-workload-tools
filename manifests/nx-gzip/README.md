This document demonstrate using the NX-GZip feature in a non-privileged container. You must have deployed a cluster with workers with a processor compatibility of IBM Power 10 or higher. The *Active Memory Expansion* feature must be licensed.

### Build the power-gzip selftest binary

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
# ls g*test -al
-rwxr-xr-x. 1 root root 74992 Jun  9 08:24 gunz_test
-rwxr-xr-x. 1 root root 74888 Jun  9 08:24 gzfht_test
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
# oc get pod -n nx-gzip-demo
NAME               READY   STATUS    RESTARTS   AGE
nx-gzip-ds-2mlmh   1/1     Running   0          3s
```

To test with Privileged mode, you can use `nx-gzip-privileged`.

### Copy the Test artifact into the running Pod and Run the Test Artifact

1. Copy the above created executable files to the running pod 

```
# oc cp gzfht_test nx-gzip-ds-2mlmh:/nx-test/
```

2. Access the pod shell and confirm the Model name is Power10 or higher.

```
# oc rsh nx-gzip-ds-2mlmh
sh-5.1# lscpu | grep Model
Model name:                           POWER10 (architected), altivec supported
Model:                                2.0 (pvr 0080 0200)
```

3. Create a test file for testing 

```
sh-5.1# dd if=/dev/random of=/nx-test/test bs=1M count=1
1+0 records in
1+0 records out
1048576 bytes (1.0 MB, 1.0 MiB) copied, 0.00431494 s, 243 MB/s
sh-5.1#

```

4. Run the tests in pod 

```
sh-5.1# /nx-test/gzfht_test /nx-test/test
file /nx-test/test read, 1048576 bytes
compressed 1048576 to 1105994 bytes total, crc32 checksum = a094fbab
sh-5.1# echo $?
0
```

If it shows as `compressed` and the return code is `0` and as above then its considered as PASS.

Thank you for your time and good luck.