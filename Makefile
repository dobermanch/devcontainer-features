# REGISTRY and NAMESPACE come from a local .env (see .env.example) or the
# environment; command-line values (make publish REGISTRY=...) override both.
-include .env
REGISTRY  ?= ghcr.io
NAMESPACE ?= dobermanch/devcontainer-features
BASE_IMAGE ?= mcr.microsoft.com/devcontainers/base:jammy
DEVCONTAINER := scripts/devcontainer

.PHONY: test test-% publish

# All features, with their scenarios
test:
	$(DEVCONTAINER) features test --project-folder . --base-image $(BASE_IMAGE)

# One feature: make test-idle-shutdown
test-%:
	$(DEVCONTAINER) features test --project-folder . --base-image $(BASE_IMAGE) -f $*

# Pushes every feature whose version is not in the registry yet, tagged
# 1, 1.0, 1.0.0 and latest. Needs `docker login $(REGISTRY)` first.
publish:
	@test -n "$(REGISTRY)" -a -n "$(NAMESPACE)" || { echo "Set REGISTRY and NAMESPACE (in .env or: make publish REGISTRY=... NAMESPACE=...)"; exit 1; }
	$(DEVCONTAINER) features publish --registry $(REGISTRY) --namespace $(NAMESPACE) ./src
