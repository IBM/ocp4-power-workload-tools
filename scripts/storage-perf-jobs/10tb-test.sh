#!/bin/bash

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
    bs=1024k
    direct=0
    ioengine=libaio
    iodepth=16
    numjobs=4
    directory=/pv
    filename_format=$jobname-$filenum
    group_reporting=1
    runtime=3600
    size=10TB
EOF