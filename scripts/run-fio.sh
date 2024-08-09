#!/bin/bash

cat << EOF > /tmp/perf.fio
[global]
name=perf-seq-read
time_based
ramp_time=5
runtime=30
readwrite=write
bs=256k
ioengine=libaio
direct=1
numjobs=1
iodepth=32
group_reporting=1[nvme0]
filename=/dev/nvme0n1