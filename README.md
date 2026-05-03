# My Linux setup :rocket:

Installation script is expected to be executed on CachyOS with Cosmic DE installed. Probably works on other flavors of Arch.

note: during installation of cachyos uncheck insallation of fish shell

## Install

```bash
git clone git@github.com:x-dvr/dotfiles.git
cd dotfiles
bash ./install.sh
```

## Generate SSH Keys

Generate Key:
```bash
ssh-keygen -t ed25519 -C "denis.rodin@proton.me"
```
Start SSH Agent & add key:
```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/github
```

## Generate GPG key & Setup GIT to sign commits

```bash
gpg --full-generate-key
gpg --list-secret-keys --keyid-format=long
gpg --armor --export <KEY_ID>

git config --global commit.gpgsign true
git config --global user.signingkey <KEY_ID>
```

## Download androi SDK

Download from: https://developer.android.com/studio#command-line-tools-only
```bash
mkdir -p ~/Android/Sdk/cmdline-tools
yes | sdkmanager --licenses
sdkmanager "platform-tools" "platforms;android-35" "build-tools;35.0.0"
```