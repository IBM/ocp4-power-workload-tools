#!/usr/bin/env bash

# The default port range is 30000-32767
# https://docs.openshift.com/container-platform/4.15/networking/configuring-node-port-service-range.html
for PORT in echo {30000..32767}
do
    echo "\nTESTING PORT: ${PORT}"
    cat pod-service.yaml | sed 's|30007|'${PORT}'|g' | oc apply -f -
    echo "waiting 10 seconds"
    sleep 10

    for TRY in echo {0..5}
    do
        echo "TRY: ${TRY}"
        echo "Putting a debug pod on the opposite - powerworker"
        oc apply -f pod-debug-run.yaml
        sleep 1

        oc rsh pod/runner curl http://power-net-workload-svc.openshift-net-workload.svc.cluster.local:8080/status -k
        [ $? -eq 1 ] && echo "Failed to curl"
    done
done