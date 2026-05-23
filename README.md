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

## Secure DNS

Update `/etc/dnscrypt-proxy/dnscrypt-proxy.toml`:
```
server_names = ['cloudflare']
```

ensure resolv.conf can be edited without it being overwritten. This can vary depending on your networking software, but for NetworkManager (default in most common Desktop Environments) it is as simple as adding the following to `/etc/NetworkManager/conf.d/dns.conf`:
```
[main]
dns=none
```

Afterwards, edit `/etc/resolv.conf` to include the following:
```
nameserver ::1
nameserver 127.0.0.1
options edns0
```
And after a reboot it should be working perfectly. Test your connection with 1.1.1.1/help (easy to remember) or dnsleaktest.com (thorough)

## Download android SDK

Download from: https://developer.android.com/studio#command-line-tools-only
```bash
mkdir -p ~/Android/Sdk/cmdline-tools
yes | sdkmanager --licenses
sdkmanager "platform-tools" "platforms;android-35" "build-tools;35.0.0"
sdkmanager "platforms;android-36" "build-tools;36.0.0" "build-tools;28.0.3"
sdkmanager --install "system-images;android-33;google_apis;x86_64"
avdmanager create avd -n Pixel_6 -k "system-images;android-33;google_apis;x86_64"
flutter doctor -v
```