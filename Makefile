.PHONY: check fmt lint test vendor-check release-check demo
NVIM ?= nvim
check: fmt lint test vendor-check
fmt:
	stylua --check lua tests plugin
lint:
	selene lua tests plugin
test:
	$(NVIM) --headless -u NONE -l tests/run.lua
# vendor-check and release-check need the nvim-plugins Dach one level up (../tools). A clone of
# this repo alone skips them loudly instead of failing with "can't open file".
DACH := ..
vendor-check:
	@if [ -f $(DACH)/tools/kit/vendor.py ]; then PYTHONDONTWRITEBYTECODE=1 python3 $(DACH)/tools/kit/vendor.py check .; \
	else echo "vendor-check: SKIPPED — no nvim-plugins Dach at $(DACH)/tools (it checks the vendored copies against their sources)"; fi
release-check:
	@if [ -f $(DACH)/tools/bibliothek/gate.py ]; then PYTHONDONTWRITEBYTECODE=1 python3 $(DACH)/tools/bibliothek/gate.py --repo . --seit-tag; \
	else echo "release-check: SKIPPED — no nvim-plugins Dach at $(DACH)/tools (Bibliothek gate)"; fi
demo:
	vhs docs/demo/demo.tape
	ffmpeg -v error -y -i docs/demo/.build/demo.mp4 -vf "fps=20,split[a][b];[a]palettegen=stats_mode=diff[p];[b][p]paletteuse=dither=bayer:bayer_scale=5" docs/images/demo.gif
	ffmpeg -v error -y -i docs/demo/.build/demo.mp4 -vf fps=20 -c:v libx264 -pix_fmt yuv420p -movflags +faststart docs/images/demo.mp4
