#!/bin/sh

# Keep absolute black and white for maximum contrast on the login screen.
# The remaining ANSI colors come from Kitty's Catppuccin Frappe theme.
if [ "${TERM:-}" = "linux" ]; then
	printf '\033]P0000000' # black/background
	printf '\033]P1E78284' # red
	printf '\033]P2A6D189' # green
	printf '\033]P3E5C890' # yellow
	printf '\033]P48CAAEE' # blue
	printf '\033]P5F4B8E4' # magenta
	printf '\033]P681C8BE' # cyan
	printf '\033]P7FFFFFF' # white
	printf '\033]P8626880' # bright black
	printf '\033]P9E78284' # bright red
	printf '\033]PaA6D189' # bright green
	printf '\033]PbE5C890' # bright yellow
	printf '\033]Pc8CAAEE' # bright blue
	printf '\033]PdF4B8E4' # bright magenta
	printf '\033]Pe81C8BE' # bright cyan
	printf '\033]PfFFFFFF' # bright white

	clear
fi
