autoload -Uz compinit
compinit

fpath=(~/.zsh/zsh-completions/src $fpath)

HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000000
SAVEHIST=10000000

eval "$(starship init zsh)"
eval "$(fnm env --use-on-cd)"
eval "$(fnm completions --shell zsh)"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

alias ls="eza"
alias ll="eza -la"
alias vi="nvim"
alias vim="nvim"
alias cat="bat"
alias code="codium"
alias hx="helix"
alias z="zoxide"
alias zed="zeditor"
alias frbc="flutter_rust_bridge_codegen"

export EDITOR="helix"
export CHROME_EXECUTABLE="brave"
export PATH="$PATH:$HOME/bin"
export PATH=$HOME/.local/bin:$PATH

export PATH="$HOME/flutter/bin:$HOME/Android/Sdk/cmdline-tools/latest/bin:$HOME/Android/Sdk/platform-tools:$PATH"
export ANDROID_HOME="$HOME/Android/Sdk"

source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

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

eval "$(ssh-agent -s)" > /dev/null

fastfetch

# bun completions
[ -s "/home/vir/.bun/_bun" ] && source "/home/vir/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
