# OpenCode for Termux — targets for the bundle line (2.2.7+).
#
# CI does not call make: it runs scripts/ci/*.sh directly. These targets are the
# same steps for a local run, reading the version from supply-chain-lock.json.

SHELL := /bin/bash

VERSION := $(shell python3 tools/ocver.py current)
REVISION := $(shell python3 tools/ocver.py revision)
TAG := $(shell python3 tools/ocver.py tag)
DEB := $(shell python3 tools/ocver.py debversion)

.PHONY: help bundle deb status selfcheck test clean clean-artifacts

help:
	@echo "OpenCode $(VERSION) — package $(DEB), tag $(TAG)"
	@echo "  make bundle          build artifacts/bundle/$(VERSION) (NDK + llvm-strip)"
	@echo "  make deb             package that bundle into artifacts/release/"
	@echo "  make status          pinned version, tag and release files"
	@echo "  make selfcheck       plugin and hook self-check"
	@echo "  make test            shell unit tests (tests/run.sh)"
	@echo "  make clean           remove work/ and artifacts/staged"
	@echo "  make clean-artifacts remove artifacts/ (generated)"

bundle:
	bash scripts/ci/build-opencode-bundle.sh

deb:
	bash scripts/ci/package-release-bundle.sh \
		"artifacts/bundle/$(VERSION)" "$(VERSION)" artifacts/release "$(REVISION)"

status:
	@echo "version  $(VERSION)"
	@echo "revision $(REVISION)"
	@echo "tag      $(TAG)"
	@echo "deb      opencode_$(DEB)_aarch64.deb"
	@ls -l artifacts/release 2>/dev/null || echo "release  <not built>"

selfcheck:
	./tools/plugin-selfcheck.sh

test:
	./tests/run.sh

clean:
	rm -rf work artifacts/staged

clean-artifacts:
	rm -rf artifacts
