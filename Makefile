.PHONY: check fmt lint test vendor-check release-check demo
NVIM ?= nvim
check: fmt lint test vendor-check
fmt:
	stylua --check lua tests plugin
lint:
	selene lua tests plugin
test:
	$(NVIM) --headless -u NONE -l tests/run.lua
vendor-check:
	PYTHONDONTWRITEBYTECODE=1 python3 ../tools/kit/vendor.py check .
release-check:
	PYTHONDONTWRITEBYTECODE=1 python3 ../tools/bibliothek/gate.py --repo . --seit-tag
demo:
	vhs docs/demo/demo.tape
	ffmpeg -v error -y -i docs/demo/.build/demo.mp4 -vf "fps=20,split[a][b];[a]palettegen=stats_mode=diff[p];[b][p]paletteuse=dither=bayer:bayer_scale=5" docs/images/demo.gif
	ffmpeg -v error -y -i docs/demo/.build/demo.mp4 -vf fps=20 -c:v libx264 -pix_fmt yuv420p -movflags +faststart docs/images/demo.mp4
