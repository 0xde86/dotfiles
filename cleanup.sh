#!/usr/bin/env bash
#
# cleanup.sh — remove unused pacman packages and reclaim disk space.
#
# Dry-run by default. Nothing is removed until you pass --apply.
# Every group is opt-in except orphans and cache trimming.
#
# Findings this script is based on (audited 2026-08-16 on cachy-os):
#   - no printer is configured (lpstat: no destinations), yet the full
#     CUPS + foomatic + HPLIP stack is installed and cups.service runs
#   - libvirt has zero domains defined and docker has zero images
#   - root is a plain btrfs partition: no LVM, no MD RAID, no XFS/F2FS/JFS/NILFS
#   - wpa_supplicant is the active supplicant, so iwd is dead weight;
#     NetworkManager is in charge, so netctl is too
#   - hyprlock/hyprpaper are in use, so swaylock/swaybg are duplicates
#   - the only wireless/GPU/NIC silicon present is Intel (AX200, UHD 630, igc)
#     and NVIDIA, so the AMD/Atheros/Broadcom/MediaTek firmware blobs are dead
#
# Two removals here are booby-trapped and are handled explicitly below:
#   - the linux-firmware meta depends on all ten vendor sub-packages, so
#     dropping one forces the meta out too, and -Rs then cascades into
#     linux-firmware-intel and -nvidia (goodbye WiFi and GPU on next boot)
#   - netctl owns systemd-resolvconf
# In both cases the survivors are re-marked explicit *before* the removal runs.
#
set -euo pipefail

APPLY=0
SELECTED=()
LOG_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/cleanup-sh"
CACHE_KEEP=2

# Packages that must never be removed, whatever a group asks for. Removal of a
# group is aborted entirely if its cascade touches one of these.
PROTECTED=(
  # NB: the linux-firmware *meta* is deliberately absent here. It ships no
  # files, and the firmware group cannot drop a single vendor blob without
  # taking it too. The vendor packages that matter are protected instead.
  base linux-cachyos linux-cachyos-lts mkinitcpio systemd
  nvidia-utils nvidia-open-dkms linux-cachyos-nvidia-open linux-cachyos-lts-nvidia-open
  hyprland pipewire wireplumber networkmanager wpa_supplicant
  systemd-resolvconf pacman glibc grub btrfs-progs snapper sudo zsh
  # Firmware for silicon that IS present. linux-firmware-intel covers both the
  # AX200 (iwlwifi + btusb) and the UHD 630 (i915); sof-firmware is live because
  # snd_sof_pci_intel_cnl is loaded on this Comet Lake-H board.
  linux-firmware-intel linux-firmware-nvidia intel-ucode sof-firmware
)

# Vendor firmware kept because the matching hardware exists (or because the
# package is a licence/grab-bag blob that is not worth the risk).
FW_KEEP=(
  linux-firmware-intel linux-firmware-nvidia linux-firmware-other
  linux-firmware-realtek linux-firmware-whence
)

say()  { printf '\n ────────── %s ────────── \n\n' "$1"; }
info() { printf '  %s\n' "$1"; }
warn() { printf '  !! %s\n' "$1" >&2; }

# du exits non-zero when it hits an unreadable subdirectory, which under
# `set -eo pipefail` would abort the script mid-report. Swallow that.
dirsize() { du -sh "$1" 2>/dev/null | cut -f1 || true; }

usage() {
  cat <<'EOF'
Usage: ./cleanup.sh [--apply] [group...]

Without --apply this only prints what would happen.

Always run (safe):
  orphans           remove orphaned dependencies, repeatedly until none remain
  cache             trim /var/cache/pacman/pkg (currently ~16G) and paru's cache
  journal           vacuum systemd journal down to 200M

Opt-in groups (pass by name, or use --all for every group marked SAFE):
  printing   SAFE   CUPS, foomatic, HPLIP, gutenprint, ghostscript   ~360 MiB
  legacy-fs  SAFE   dmraid, xfsprogs, f2fs-tools, nilfs-utils,
                    jfsutils, lvm2 — none of these filesystems exist   ~40 MiB
  net        SAFE   iwd, netctl, xl2tpd, modemmanager                  ~30 MiB
  sway       SAFE   swaylock, swaybg — superseded by hyprlock/hyprpaper
  docker     SAFE   docker, containerd, runc — no images present      ~180 MiB
  firmware   SAFE   vendor blobs for silicon you do not have:         ~134 MiB
                    amdgpu, radeon, atheros, mediatek, broadcom,
                    cirrus, alsa-firmware. KEEPS intel (AX200 +
                    UHD 630), nvidia, sof (snd_sof_pci_intel_cnl is
                    loaded), realtek, other, whence, intel-ucode.
                    Note: this also drops the linux-firmware meta,
                    and costs you plug-and-play support for external
                    USB WiFi/BT dongles from those vendors.
  flatpak    SAFE   uninstall unused flatpak runtimes                 ~1.3 GiB
  virt              qemu-full, libvirt, virt-manager (~150 pkgs)      ~1.0 GiB
                    no VMs are defined, but this is a big one-way door
  cachyos           cachyos-hello, -packageinstaller, -wallpapers,
                    -kernel-manager (drags in scx-scheds)             ~340 MiB
  cross             riscv64/aarch64/arm-none-eabi toolchains          ~1.0 GiB
                    CAUTION: you have ~/.rpiboot and ~/Android — check first
  redundant         micro (+cachyos-micro-settings), mission-center,
                    minicom, s-nail, nfs-utils                         ~20 MiB

Examples:
  ./cleanup.sh                      # audit only, change nothing
  ./cleanup.sh --apply printing net legacy-fs sway docker
  ./cleanup.sh --apply --all        # every SAFE group
EOF
}

# ---------------------------------------------------------------- group tables

group_pkgs() {
  case "$1" in
    printing)
      echo "cups cups-filters cups-pdf hplip gutenprint system-config-printer
            foomatic-db foomatic-db-engine foomatic-db-ppds foomatic-db-nonfree
            foomatic-db-nonfree-ppds foomatic-db-gutenprint-ppds" ;;
    legacy-fs) echo "dmraid xfsprogs f2fs-tools nilfs-utils jfsutils lvm2" ;;
    net)       echo "iwd netctl xl2tpd modemmanager" ;;
    sway)      echo "swaylock swaybg" ;;
    docker)    echo "docker" ;;
    virt)
      echo "qemu-full qemu-user-static qemu-user-static-binfmt libvirt
            virt-manager virt-viewer swtpm edk2-ovmf" ;;
    cachyos)
      echo "cachyos-hello cachyos-packageinstaller cachyos-wallpapers
            cachyos-kernel-manager" ;;
    cross)
      echo "riscv64-linux-gnu-gcc aarch64-linux-gnu-gcc arm-none-eabi-binutils
            arm-none-eabi-gdb" ;;
    redundant)
      echo "micro cachyos-micro-settings mission-center minicom s-nail nfs-utils" ;;
    firmware)
      # The meta must go with them; it hard-depends on every vendor package.
      echo "linux-firmware linux-firmware-amdgpu linux-firmware-radeon
            linux-firmware-atheros linux-firmware-mediatek
            linux-firmware-broadcom linux-firmware-cirrus alsa-firmware" ;;
    *) return 1 ;;
  esac
}

# Packages to re-mark as explicitly installed *before* a group is removed, so
# that neither the -Rs cascade nor the later orphan sweep can take them.
group_keep() {
  case "$1" in
    firmware) printf '%s\n' "${FW_KEEP[@]}" ;;
    net)      echo "systemd-resolvconf" ;;   # netctl is its only dependent
    *)        echo "" ;;
  esac
}

# Services to stop and disable before a group's packages go away.
group_units() {
  case "$1" in
    printing) echo "cups.service cups.socket cups.path cups-browsed.service" ;;
    docker)   echo "docker.service docker.socket containerd.service" ;;
    virt)     echo "libvirtd.service libvirtd.socket libvirtd-ro.socket
                    libvirtd-admin.socket virtlogd.socket virtlockd.socket" ;;
    net)      echo "iwd.service ModemManager.service" ;;
    *)        echo "" ;;
  esac
}

SAFE_GROUPS=(printing legacy-fs net sway docker firmware flatpak)

# ------------------------------------------------------------------- arg parse

while (($#)); do
  case "$1" in
    --apply) APPLY=1 ;;
    --all)   SELECTED+=("${SAFE_GROUPS[@]}") ;;
    -h|--help) usage; exit 0 ;;
    -*) warn "unknown flag: $1"; usage; exit 2 ;;
    *)
      if [[ "$1" == flatpak ]] || group_pkgs "$1" >/dev/null 2>&1; then
        SELECTED+=("$1")
      else
        warn "unknown group: $1"; usage; exit 2
      fi ;;
  esac
  shift
done

# de-duplicate while preserving order
if ((${#SELECTED[@]})); then
  mapfile -t SELECTED < <(printf '%s\n' "${SELECTED[@]}" | awk '!seen[$0]++')
fi

mkdir -p "$LOG_DIR"
STAMP=$(date +%Y%m%d-%H%M%S)
RESTORE="$LOG_DIR/removed-$STAMP.txt"

if ((APPLY)); then
  info "APPLY mode — packages will actually be removed."
  info "Reinstall list will be written to $RESTORE"
  sudo -v
else
  info "DRY RUN — nothing will be changed. Re-run with --apply to execute."
fi

# ---------------------------------------------------------------------- helpers

# Keep only the packages that are actually installed.
installed_only() {
  local p keep=()
  for p in "$@"; do
    pacman -Qq -- "$p" &>/dev/null && keep+=("$p")
  done
  printf '%s\n' "${keep[@]:-}"
}

# Abort a group if its removal cascade would take out something protected.
cascade_is_safe() {
  local cascade=$1 p
  for p in "${PROTECTED[@]}"; do
    if grep -qx -- "$p" <<<"$cascade"; then
      warn "cascade would remove protected package '$p' — skipping this group"
      return 1
    fi
  done
  return 0
}

disable_units() {
  local units unit
  units=$(group_units "$1")
  [[ -z "${units// }" ]] && return 0
  for unit in $units; do
    systemctl list-unit-files --no-legend -- "$unit" &>/dev/null || continue
    if ((APPLY)); then
      sudo systemctl disable --now -- "$unit" &>/dev/null || true
      info "disabled $unit"
    else
      info "would disable $unit"
    fi
  done
}

# Pin a group's survivors as explicit. Must happen before pacman -Rs runs,
# because -s only spares dependencies that are marked explicit.
pin_survivors() {
  local group=$1 keep pinned=()
  mapfile -t keep < <(installed_only $(group_keep "$group"))
  [[ ${#keep[@]} -eq 0 || -z "${keep[0]}" ]] && return 0

  local p
  for p in "${keep[@]}"; do
    pacman -Qi -- "$p" 2>/dev/null | grep -q 'Install Reason.*dependency' && pinned+=("$p")
  done
  [[ ${#pinned[@]} -eq 0 ]] && return 0

  if ((APPLY)); then
    sudo pacman -D --asexplicit -- "${pinned[@]}" >/dev/null
    info "pinned as explicit so they survive: ${pinned[*]}"
  else
    info "would pin as explicit first: ${pinned[*]}"
  fi
}

process_group() {
  local group=$1 pkgs cascade count
  mapfile -t pkgs < <(installed_only $(group_pkgs "$group"))
  # installed_only emits an empty line when nothing matched
  [[ ${#pkgs[@]} -eq 0 || -z "${pkgs[0]}" ]] && { info "nothing installed"; return 0; }

  pin_survivors "$group"

  if ! cascade=$(pacman -Rsp --print-format '%n' -- "${pkgs[@]}" 2>/dev/null); then
    warn "pacman refuses this removal (a dependency outside the group needs it)"
    warn "run: pacman -Rsp ${pkgs[*]}"
    return 0
  fi

  # In dry-run the pin above was not actually applied, so pacman still reports
  # the survivors as part of the cascade. Subtract them to model the real
  # outcome -- otherwise the safety check below would abort on its own trap.
  if ((!APPLY)); then
    local keep_list
    keep_list=$(group_keep "$group" | tr -s ' \t' '\n' | grep -v '^$' || true)
    if [[ -n "$keep_list" ]]; then
      cascade=$(grep -vxF -f <(printf '%s\n' "$keep_list") <<<"$cascade" || true)
    fi
  fi

  cascade_is_safe "$cascade" || return 0

  count=$(grep -c . <<<"$cascade")
  info "$count package(s) would be removed:"
  printf '%s\n' "$cascade" | tr '\n' ' ' | fold -s -w 100 | sed 's/^/    /'
  echo

  disable_units "$group"

  if ((APPLY)); then
    printf '%s\n' "$cascade" >>"$RESTORE"
    sudo pacman -Rns --noconfirm -- "${pkgs[@]}"
    info "removed."
  fi
}

# ------------------------------------------------------------------------ audit

say "System"
info "$(uname -sr) — $(source /etc/os-release && echo "$PRETTY_NAME")"
info "packages: $(pacman -Q | wc -l) total, $(pacman -Qe | wc -l) explicit, $(pacman -Qm | wc -l) foreign"
info "pacman cache: $(dirsize /var/cache/pacman/pkg) in $(ls /var/cache/pacman/pkg 2>/dev/null | wc -l) files"
info "root fs: $(df -h --output=used,avail,pcent / | tail -1 | tr -s ' ')"

# ---------------------------------------------------------------------- groups

for group in "${SELECTED[@]:-}"; do
  [[ -z "$group" ]] && continue
  [[ "$group" == flatpak ]] && continue   # handled separately below
  say "Group: $group"
  process_group "$group"
done

# --------------------------------------------------------------------- orphans

say "Orphans"
# netctl owns systemd-resolvconf; if netctl went away, keep resolvconf so the
# orphan sweep below does not take systemd-resolved's compat layer with it.
if pacman -Qq systemd-resolvconf &>/dev/null && ! pacman -Qq netctl &>/dev/null; then
  if ((APPLY)); then
    sudo pacman -D --asexplicit systemd-resolvconf >/dev/null
    info "marked systemd-resolvconf explicit so it survives orphan cleanup"
  else
    info "would mark systemd-resolvconf explicit (protects it from orphan sweep)"
  fi
fi

# Removing orphans can orphan their dependencies in turn, so loop to a fixpoint.
round=0
while :; do
  mapfile -t orphans < <(pacman -Qdtq 2>/dev/null || true)
  [[ ${#orphans[@]} -eq 0 ]] && break
  ((round++))
  info "round $round: ${#orphans[@]} orphan(s): ${orphans[*]}"
  if ((APPLY)); then
    printf '%s\n' "${orphans[@]}" >>"$RESTORE"
    sudo pacman -Rns --noconfirm -- "${orphans[@]}"
  else
    break   # cannot iterate without actually removing
  fi
done
((round == 0)) && info "none"

# --------------------------------------------------------------------- flatpak

if [[ " ${SELECTED[*]:-} " == *" flatpak "* ]] && command -v flatpak &>/dev/null; then
  say "Flatpak"
  flatpak list --columns=application,size 2>/dev/null | sed 's/^/    /'
  if ((APPLY)); then
    flatpak uninstall --unused --assumeyes || true
    info "removed unused runtimes."
  else
    info "would run: flatpak uninstall --unused"
  fi
fi

# ----------------------------------------------------------------------- cache

say "Package cache"
info "current size: $(dirsize /var/cache/pacman/pkg)"
if ((APPLY)); then
  sudo paccache -rk "$CACHE_KEEP"     # keep N most recent of installed packages
  sudo paccache -ruk0                 # drop every version of uninstalled ones
  command -v paru &>/dev/null && paccache -rk1 -c "$HOME/.cache/paru/clone" 2>/dev/null || true
  info "now: $(dirsize /var/cache/pacman/pkg)"
else
  info "would keep $CACHE_KEEP versions per installed package, drop uninstalled entirely:"
  { paccache -dk "$CACHE_KEEP" 2>&1 || true; } | tail -2 | sed 's/^/    /'
  { paccache -duk0 2>&1 || true; } | tail -2 | sed 's/^/    /'
fi

# --------------------------------------------------------------------- journal

say "Journal"
info "current: $(journalctl --disk-usage 2>/dev/null | sed -n 's/.*take up \(.*\) in the file system.*/\1/p' || true)"
if ((APPLY)); then
  sudo journalctl --vacuum-size=200M
else
  info "would run: journalctl --vacuum-size=200M"
fi

# ------------------------------------------------------------------------- done

say "Done"
if ((APPLY)); then
  info "root fs now: $(df -h --output=used,avail,pcent / | tail -1 | tr -s ' ')"
  if [[ -s "$RESTORE" ]]; then
    info "to undo: sudo pacman -S --needed - < $RESTORE"
  fi
else
  info "This was a dry run. Re-run with --apply to make the changes."
fi
