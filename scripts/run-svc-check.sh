#!/usr/bin/env bash

oc apply -f manifests/network/ds-debug-run.yaml

# The default port range is 30000-32767
# https://docs.openshift.com/container-platform/4.15/networking/configuring-node-port-service-range.html
for PORT in {30000..32767}
do
    echo "\nTESTING PORT: ${PORT}\n"
    cat manifests/network/pod-service.yaml | sed "s|30007|${PORT}|g" \
        | oc apply -f -
    echo "\nwaiting 3 seconds\n"
    sleep 3

    for TRY in echo {0..100}
    do
        echo "TRY: ${TRY}"
        echo "Putting a debug pod on the opposite - powerworker"
        sleep 1

        # fail in logs is ok.
        oc rsh daemonset/debug-runner curl http://power-net-workload-svc.openshift-net-workload.svc.cluster.local:8080/status -k -v
        [ $? -eq 1 ] && echo "Failed to curl"
    done
done