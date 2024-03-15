#!/bin/bash

# Outputs the InternalIP

for NODEIP in $(oc get nodes -l kubernetes.io/arch=ppc64le -ojson | jq -r '.items[].status.addresses[] | select(.type == "InternalIP").address')
do
    echo "NODE_IP: ${NODEIP}"
done
