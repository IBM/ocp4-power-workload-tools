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
	+@podman build --platform linux/${ARCH} -t ${REGISTRY}/sock-shop-user:${ARCH} -f automation/Dockerfile-user
	+@echo "Done Image - 'user'"
.PHONY: cross-build-user

# pushes the individual images
push-user: verify-environment
	+@podman push ${REGISTRY}/sock-shop-user:${ARCH}
.PHONY: push-user

pull-deps:
	+@podman pull --platform linux/amd64 ${REGISTRY}/sock-shop-${APP}:amd64
	+@podman pull --platform linux/s390x ${REGISTRY}/sock-shop-${APP}:s390x
	+@podman pull --platform linux/arm64 ${ARM_REGISTRY}/sock-shop-${APP}:arm64
	+@podman pull --platform linux/ppc64le ${REGISTRY}/sock-shop-${APP}:ppc64le
.PHONY: pull-deps

# Applies to all (except catalogue-db) - generate-and-push-manifest-list.
push-ml: verify-environment pull-deps
	+@echo "Remove existing manifest listed - ${APP}"
	+@podman manifest rm ${REGISTRY}/sock-shop-${APP} || true
	+@echo "Create new ML - ${APP}"
	+@podman manifest create ${REGISTRY}/sock-shop-${APP} \
		${REGISTRY}/sock-shop-${APP}:amd64 \
		${REGISTRY}/sock-shop-${APP}:s390x \
		${ARM_REGISTRY}/sock-shop-${APP}:arm64 \
		${REGISTRY}/sock-shop-${APP}:ppc64le
	+@echo "Pushing image - ${APP}"
	+@podman manifest push ${REGISTRY}/sock-shop-${APP} ${REGISTRY}/sock-shop-${APP}
.PHONY: push-ml
