#!/bin/bash

echo "The nodes are: "
oc get nodes -lnode-role.kubernetes.io/worker -oname
echo ""

echo "[ConfigMap] setup fio"
cat << EOF | oc apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: fio
  namespace: openshift-power-workload
data:
  test.fio: |
    [write-and-verify]
    time_based
    readwrite=write
    bs=256k
    direct=0
    ioengine=libaio
    iodepth=16
    numjobs=4
    #verify=crc32c
    directory=/pv
    #filename=testfile
    filename_format=$jobname-$filenum
    group_reporting=1
    runtime=600
    size=1TB
EOF
echo ""

COUNT_WORKER_NODES=$(oc get nodes -lnode-role.kubernetes.io/worker -oname | wc -l)

echo "Creating PVCs for all workers"
IDX=0
for WORKER_NODE in $(oc get nodes -lnode-role.kubernetes.io/worker -oname | sed 's|node/||g')
do
echo "PVC: workloads-pvc-${IDX}"
cat << EOF | oc apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: workloads-pvc-${IDX}
  namespace: openshift-power-workload
spec:
  storageClassName: ibm-spectrum-scale-data-rwo-sc
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 11000Gi
EOF
IDX=$((IDX+1))
done
echo ""

echo "Creating the job"
IDX=0
for WORKER_NODE in $(oc get nodes -lnode-role.kubernetes.io/worker -oname | sed 's|node/||g')
do
echo "WORKER_NODE: ${WORKER_NODE} | INDEX: ${IDX}"
cat << EOF | oc apply -f -
apiVersion: batch/v1
kind: Job
metadata:
  name: job-${IDX}
  namespace: openshift-power-workload
spec:
  template:
    spec:
      containers:
      - name: fio
        affinity:
          nodeAffinity:
            requiredDuringSchedulingIgnoredDuringExecution:
              nodeSelectorTerms:
              - matchExpressions:
                - key: kubernetes.io/hostname
                  operator: In
                  values:
                  - db2u-worker0101.iias.mille.pl
        image: quay.io/powercloud/ocp4-power-workload-tools:main
        imagePullPolicy: IfNotPresent
        command: ["fio","/scripts/test.fio"]
        resources:
          limits:
            cpu: 4000m
            memory: 4Gi
          requests:
            cpu: 100m
            memory: 100Mi
        volumeMounts:
        - name: fio-volume
          mountPath: /scripts
        - name: pv
          mountPath: /pv
      restartPolicy: Never
      volumes:
        - name: pv
          persistentVolumeClaim:
            claimName: workloads-pvc-${IDX}
        - name: fio-volume
          configMap:
            name: fio
  backoffLimit: 0
EOF

IDX=$((IDX+1))
done
echo ""

echo "Finished"