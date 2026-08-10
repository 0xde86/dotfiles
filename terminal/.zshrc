# Interactive shells only: prompt, completion, aliases, keybindings.
#
# Environment and PATH belong in ~/.config/shell/env (loaded via ~/.zshenv).
# Anything exported here is invisible to scripts and to programs launched
# from Hyprland.

# fpath must be extended before compinit, or these completions never load.
fpath=(~/.zsh/zsh-completions/src $fpath)
autoload -Uz compinit
compinit

HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000000
SAVEHIST=10000000

eval "$(starship init zsh)"
eval "$(fnm env --use-on-cd)"
eval "$(fnm completions --shell zsh)"

# bun completions
[ -s "/home/vir/.bun/_bun" ] && source "/home/vir/.bun/_bun"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

alias ls="eza"
alias ll="eza -la"
alias vi="nvim"
alias vim="nvim"
alias cat="bat"
alias code="codium"
alias z="zoxide"
alias zed="zeditor"
alias frbc="flutter_rust_bridge_codegen"
alias rpiimager='sudo QT_QPA_PLATFORM=wayland WAYLAND_DISPLAY="$WAYLAND_DISPLAY" XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" rpi-imager'
alias tinycode='tinygo-edit --editor codium --target pico2'

bindkey '^H' backward-kill-word
bindkey '5~' kill-word
bindkey '^[[1;5D' backward-word
bindkey '^[[1;5C' forward-word
bindkey '^U'      kill-region

go_audit() {
  go mod verify
  go vet ./...
  go run honnef.co/go/tools/cmd/staticcheck@latest -checks=all,-ST1000,-U1000 ./...
  go run golang.org/x/vuln/cmd/govulncheck@latest -show verbose ./...
  go test -race -buildvcs -vet=off ./...
}

function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}

function clmy() {
	export CLAUDE_CONFIG_DIR="$HOME/.claude"
}

function clmax() {
	export CLAUDE_CONFIG_DIR="$HOME/.claude-max"
	rm ~/.claude-max/settings.json
	cp ~/.claude/settings.json ~/.claude-max/
}

function ahx() {
	alr exec -- hx "$@"
}

fastfetch
