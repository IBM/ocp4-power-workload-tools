#Arches can be: amd64 s390x arm64 ppc64le
ARCH ?= ppc64le

# The app to build
APP ?= ocp4-power-workload-tools

# If absent, registry defaults
REGISTRY ?= quay.io/powercloud 
ARM_REGISTRY ?= ${REGISTRY}

verify-environment:
	+@echo "REGISTRY: ${REGISTRY}"
	+@echo "ARCH: ${ARCH}"
	+@echo "ARM_REGISTRY: ${ARM_REGISTRY}"
.PHONY: verify-environment

cross-build-user: verify-environment
	+@echo "Building Image - 'user'"
	+@podman build --platform linux/${ARCH} -t ${REGISTRY}/ocp4-power-workload-tools:${ARCH} -f automation/Dockerfile-user
	+@echo "Done Image - 'user'"
.PHONY: cross-build-user

# pushes the individual images
push-user: verify-environment
	+@podman push ${REGISTRY}/ocp4-power-workload-tools:${ARCH}
.PHONY: push-user

pull-deps:
	+@podman pull --platform linux/amd64 ${REGISTRY}/ocp4-power-workload-tools:amd64
	+@podman pull --platform linux/s390x ${REGISTRY}/ocp4-power-workload-tools:s390x
	+@podman pull --platform linux/arm64 ${ARM_REGISTRY}/ocp4-power-workload-tools:arm64
	+@podman pull --platform linux/ppc64le ${REGISTRY}/ocp4-power-workload-tools:ppc64le
.PHONY: pull-deps

# Applies to all (except catalogue-db) - generate-and-push-manifest-list.
push-ml: verify-environment pull-deps
	+@echo "Remove existing manifest listed - ${APP}"
	+@podman manifest rm ${REGISTRY}/ocp4-power-workload-tools || true
	+@echo "Create new ML - ${APP}"
	+@podman manifest create ${REGISTRY}/ocp4-power-workload-tools \
		${REGISTRY}/ocp4-power-workload-tools:amd64 \
		${REGISTRY}/ocp4-power-workload-tools:s390x \
		${ARM_REGISTRY}/ocp4-power-workload-tools:arm64 \
		${REGISTRY}/ocp4-power-workload-tools:ppc64le
	+@echo "Pushing image - ${APP}"
	+@podman manifest push ${REGISTRY}/ocp4-power-workload-tools ${REGISTRY}/ocp4-power-workload-tools
.PHONY: push-ml
