#!/usr/bin/env bash

oc apply -f manifests/network/ds-debug-run.yaml

if [ ! -f manifests/network/pod-service.yaml ]
then
    echo "file doesn't exist: manifests/network/pod-service.yaml"
    echo "check running scripts/run-svc-check.sh"
    exit 1
else
    # The default port range is 30000-32767
    # https://docs.openshift.com/container-platform/4.15/networking/configuring-node-port-service-range.html
    for PORT in {30000..32767}
    do
        echo "TESTING PORT: ${PORT}"
        cat manifests/network/pod-service.yaml | sed "s|30007|${PORT}|g" \
            | oc apply -f -
        echo "waiting 1 seconds"
        sleep 1

        for TRY in {1..10}
        do
            echo ""
            echo "TRY: ${TRY}"
            echo "Putting a debug pod on the opposite - powerworker"

            # fail in logs is ok.
            oc rsh daemonset/debug-runner curl http://power-net-workload-svc.openshift-net-workload.svc.cluster.local:8080/status -k -o /dev/null -w "%{http_code}" -s \
                || echo "Failed to curl" &
        done
        wait $(jobs -p)
        for TRY in {11..20}
        do
            echo ""
            echo "TRY: ${TRY}"
            echo "Putting a debug pod on the opposite - powerworker"

            # fail in logs is ok.
            oc rsh daemonset/debug-runner curl http://power-net-workload-svc.openshift-net-workload.svc.cluster.local:8080/status -k -o /dev/null -w "%{http_code}" -s \
                || echo "Failed to curl" &
        done
        wait $(jobs -p)
        for TRY in {21..30}
        do
            echo ""
            echo "TRY: ${TRY}"
            echo "Putting a debug pod on the opposite - powerworker"

            # fail in logs is ok.
            oc rsh daemonset/debug-runner curl http://power-net-workload-svc.openshift-net-workload.svc.cluster.local:8080/status -k -o /dev/null -w "%{http_code}" -s \
                || echo "Failed to curl" &
        done
        wait $(jobs -p)
    done
fi