#!/bin/bash

oc label node/worker-0 cpu-coprocessor.nx_gzip=true
oc create imagestream nx-gzip

if [ -n "${NON_PROD}" ]
then
echo "Setting non-prod status for imageregistry"
oc patch configs.imageregistry.operator.openshift.io cluster --type merge --patch '{"spec":{"storage":{"emptyDir":{}}}}'
fi