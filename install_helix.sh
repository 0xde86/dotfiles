#!/bin/bash

mkdir -p ~/.local/src

git clone https://github.com/helix-editor/helix \
    ~/.local/src/helix

cd ~/.local/src/helix

cargo install --path helix-term --locked


