# VIR NORIN — Plymouth boot splash

A green-CRT boot splash ported from the Vir Norin web page: a perspective
grid background, a gradient "VIR NORIN" handle, a green progress bar, and
POST-style detail lines that stream in as the system boots. Uses Plymouth's
`script` module, so it works on any distro whose Plymouth was built with
script support (Debian/Ubuntu, Fedora, Arch, openSUSE, etc.).

## Contents
```
vir-norin.plymouth     theme descriptor
vir-norin.script       animation logic (handle is drawn as live text here)
background.png         perspective grid + horizon glow
bar_box.png            progress bar outline
bar_fill.png           progress bar fill (scaled at runtime)
scanlines.png          CRT scanline overlay (covers the handle too)
```

The "VIR NORIN" handle is **not** a pre-rendered image — it is drawn from
text inside `vir-norin.script`, with the effects applied programmatically:
the gradient is one coloured sprite per character (sampled along the
chartreuse -> spring -> emerald ramp), and the glow is built by stacking
offset and scaled semi-transparent copies of the word behind the sharp text.
The CRT line effect over the handle comes from the full-screen
`scanlines.png` overlay (Plymouth's script language has no primitive for
drawing lines, so scanlines must be a raster layer).

## Install

1. Copy the theme into Plymouth's themes directory:
   ```bash
   sudo cp -r vir-norin /usr/share/plymouth/themes/
   ```

2. Register it as an alternative (Debian/Ubuntu):
   ```bash
   sudo update-alternatives --install \
     /usr/share/plymouth/themes/default.plymouth default.plymouth \
     /usr/share/plymouth/themes/vir-norin/vir-norin.plymouth 200
   sudo update-alternatives --config default.plymouth   # pick vir-norin
   ```

   On Fedora / RHEL:
   ```bash
   sudo plymouth-set-default-theme -R vir-norin
   ```

   On Arch / generic systemd (skip step 3 — `-R` rebuilds for you on Fedora):
   ```bash
   sudo plymouth-set-default-theme vir-norin
   ```

3. Rebuild the initramfs so the theme is included in early boot:
   - Debian/Ubuntu:  `sudo update-initramfs -u`
   - Fedora/RHEL:    `sudo dracut -f`   (or use the `-R` flag above)
   - Arch:           `sudo mkinitcpio -P`

4. Make sure the splash actually shows. Your kernel cmdline needs `splash`
   (and usually `quiet`). Edit `/etc/default/grub`:
   ```
   GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"
   ```
   then `sudo update-grub` (Debian/Ubuntu) or
   `sudo grub2-mkconfig -o /boot/grub2/grub.cfg` (Fedora).

## Preview without rebooting
```bash
sudo plymouthd ; sudo plymouth --show-splash
# simulate progress:
for i in $(seq 0 100); do sudo plymouth --update=test$i; sleep 0.03; done
sudo plymouth --quit
```
(Exact progress stepping depends on your Plymouth build; the boot itself
drives the real progress.)

## Tuning
Open `vir-norin.script` and adjust:
- `logo_y`, `bar_y`, `post_log_x/y` — element positions (fractions of screen).
- `hfs = Math.Int(sh / 8)` — handle font size (it auto-shrinks if it would
  exceed 90% of screen width).
- `g0*/g1*/g2*` — the three gradient stop colours (rgb 0..1) for the handle.
- `ring_r[]` / `ring_o[]` and the `halo` opacity — glow spread and intensity.
- `post_text[]` / `post_thr[]` — the detail lines and the progress point each
  one appears at. Swap in your real hardware (CPU, modem, OS name) here.
- `scan.SetOpacity(...)` — scanline strength / flicker.

To regenerate the remaining PNGs (background, bar, scanlines) at a different
resolution or palette, re-run the included `generate.py` (requires Pillow).

## Notes
- DejaVu Sans Mono is assumed present (it ships with virtually every distro).
  If your initramfs lacks it, install a monospace font into the initramfs or
  change the font name in the script.
- The background PNG is 1920×1080 and is scaled to your panel at runtime, so
  it adapts to other resolutions; for pixel-perfect HiDPI, regenerate larger.
