JUST ?= just

.PHONY: check-just lint test build package security ci

check-just:
	@command -v $(JUST) >/dev/null 2>&1 || { \
		echo "'just' is required. Install from https://github.com/casey/just"; \
		exit 1; \
	}

lint: check-just
	@$(JUST) lint

test: check-just
	@$(JUST) test

build: check-just
	@$(JUST) build

package: check-just
	@$(JUST) package

security: check-just
	@$(JUST) security

ci: check-just
	@$(JUST) ci
