#!/usr/bin/env bash

# Execute load across workers until we hit a failure.
# Run as ./scripts/run-svc-check-nodes.sh ocp4-net-power-workload-6jmrp ocp4-net-power-workload-xqk67

oc apply -f manifests/network/ds-debug-run.yaml

if [ ! -f manifests/network/pod-service.yaml ]
then
  echo "file doesn't exist: manifests/network/pod-service.yaml"
  echo "check running scripts/run-svc-check-nodes.sh"
  exit
fi

PODNAME_FIRST_NODE="${1}"
PODNAME_SECOND_NODE="${2}"

# Runs the test against the backend
# Thought about adding a random delay using $(echo {1..30} | sed 's| |\n|g' | shuf | head -n 1)
function port_test {
    PORT="${1}"
    echo "TESTING PORT: ${PORT}"
    cat manifests/network/pod-service.yaml | sed "s|30007|${PORT}|g" \
      | oc apply -f -
    echo "waiting 1 seconds"
    sleep 1

    for TRY in {1..10}
    do
      oc exec pod/${PODNAME_FIRST_NODE} -- curl http://power-net-workload-svc.openshift-net-workload.svc.cluster.local:8080/status -k -o /dev/null -w "%{http_code}" -s \
        || echo "Failed to curl ${PORT}" &
    done
    wait $(jobs -p)
    for TRY in {11..20}
    do
      oc exec pod/${PODNAME_SECOND_NODE} -- curl http://power-net-workload-svc.openshift-net-workload.svc.cluster.local:8080/status -k -o /dev/null -w "%{http_code}" -s \
        || echo "Failed to curl ${PORT}" &
    done
    echo ""
}

# The default port range is 30000-32767
# https://docs.openshift.com/container-platform/4.15/networking/configuring-node-port-service-range.html
for PORT in {30000..32767}
do
  port_test ${PORT}
done