.DEFAULT_GOAL := travis
.PHONY: travis clean-all build-all setup setup-all

TEST_REGISTRY ?= localhost:5000
POD_START_TIMEOUT ?= 120s
KUBE_CONTEXT ?= dind
USE_MOCK ?= true
FAKE_CASSANDRA_IMAGE ?= $(TEST_REGISTRY)/fake-cassandra:v$(gitRev)
CASSANDRA_BOOTSTRAPPER_IMAGE ?= $(TEST_REGISTRY)/cassandra-bootstrapper:v$(gitRev)
CASSANDRA_SNAPSHOT_IMAGE ?= $(TEST_REGISTRY)/cassandra-snapshot:v$(gitRev)

gitRev := $(shell git rev-parse --short HEAD)
projectDir := $(realpath $(dir $(firstword $(MAKEFILE_LIST))))

travis: clean-all build-all

setup: setup-all recreate-dind-cluster

release: release-all

build-all:
	@echo "== build-all"
	$(MAKE) -C cassandra-bootstrapper
	$(MAKE) -C fake-cassandra-docker
	KUBE_CONTEXT=$(KUBE_CONTEXT) TEST_REGISTRY=$(TEST_REGISTRY) FAKE_CASSANDRA_IMAGE=$(FAKE_CASSANDRA_IMAGE) USE_MOCK=$(USE_MOCK) $(MAKE) -C cassandra-snapshot
	KUBE_CONTEXT=$(KUBE_CONTEXT) TEST_REGISTRY=$(TEST_REGISTRY) FAKE_CASSANDRA_IMAGE=$(FAKE_CASSANDRA_IMAGE) CASSANDRA_BOOTSTRAPPER_IMAGE=$(CASSANDRA_BOOTSTRAPPER_IMAGE) CASSANDRA_SNAPSHOT_IMAGE=$(CASSANDRA_SNAPSHOT_IMAGE) USE_MOCK=$(USE_MOCK) POD_START_TIMEOUT=$(POD_START_TIMEOUT) $(MAKE) -C cassandra-operator

clean-all:
	@echo "== clean-all"
	$(MAKE) -C fake-cassandra-docker clean
	$(MAKE) -C cassandra-bootstrapper clean
	$(MAKE) -C cassandra-snapshot clean
	$(MAKE) -C cassandra-operator clean

setup-all:
	@echo "== setup-all"
	$(MAKE) -C fake-cassandra-docker setup
	$(MAKE) -C cassandra-bootstrapper setup
	$(MAKE) -C cassandra-snapshot setup
	$(MAKE) -C cassandra-operator setup

recreate-dind-cluster:
	@echo "== recreate dind cluster"
	$(projectDir)/test-kubernetes-cluster/recreate-dind-cluster.sh

release-all:
	@echo "== release-all"
	$(MAKE) -C fake-cassandra-docker release
	$(MAKE) -C cassandra-bootstrapper release
	$(MAKE) -C cassandra-snapshot release
	$(MAKE) -C cassandra-operator release