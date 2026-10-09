.PHONY: check fmt lint test vendor-check release-check
check: fmt lint test vendor-check
fmt:
	stylua --check lua tests
lint:
	selene lua tests
test:
	nvim --headless -u NONE -l tests/run.lua
vendor-check:
	PYTHONDONTWRITEBYTECODE=1 python3 ../tools/kit/vendor.py check .
release-check:
	PYTHONDONTWRITEBYTECODE=1 python3 ../tools/bibliothek/gate.py --repo . --seit-tag
