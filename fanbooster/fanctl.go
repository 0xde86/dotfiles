// Command fanctl drives the Alienware WMI fan-boost knobs from live CPU and
// GPU temperatures.
//
// The Alienware EC ignores writes to the dell_smm pwm* attributes, so the only
// controllable knob on this hardware is fanN_boost (0-255) exposed by the
// alienware_wmi hwmon driver. That boost is a static offset on top of whatever
// curve the active platform_profile selects, so this program supplies the
// temperature dependence the firmware will not: it samples tempN_input and
// rewrites fanN_boost to match a user-defined curve.
//
// Because that boost is only an offset, a quiet or cool profile caps how much
// airflow any boost can buy. As a safety net fanctl also forces the
// performance platform profile once a sensor has stayed past -profile-temp for
// -profile-delay, and hands the profile back when the machine cools.
//
// Requires root to apply (writes to /sys); -dry-run works as an ordinary user.
//
//	go build -o fanctl fanctl.go
//	sudo ./fanctl                     # follow the default curves
//	./fanctl -dry-run -once           # show what it would do
//	sudo ./fanctl -cpu 70:0,85:120,95:255
package main

import (
	"context"
	"errors"
	"flag"
	"fmt"
	"math"
	"os"
	"os/signal"
	"path/filepath"
	"strconv"
	"strings"
	"syscall"
	"time"
)

const (
	hwmonRoot  = "/sys/class/hwmon"
	driverName = "alienware_wmi"
	maxBoost   = 255
)

// Defaults tuned for an Alienware m15 R4 (i7-10870H / RTX 3070 Mobile)
const (
	defaultCPUCurve = "40:0,65:50,75:70,85:150,92:210,97:255"
	defaultGPUCurve = "40:0,55:50,68:70,78:150,85:210,90:255"
)

// findHwmon locates the hwmon directory belonging to the named driver. The
// hwmonN numbering is not stable across boots, so it must be resolved by name.
func findHwmon(name string) (string, error) {
	dirs, err := filepath.Glob(filepath.Join(hwmonRoot, "hwmon*"))
	if err != nil {
		return "", err
	}
	for _, dir := range dirs {
		got, err := os.ReadFile(filepath.Join(dir, "name"))
		if err != nil {
			continue
		}
		if strings.TrimSpace(string(got)) == name {
			return dir, nil
		}
	}
	return "", fmt.Errorf("no hwmon device named %q under %s", name, hwmonRoot)
}

// readInt reads a single integer out of a sysfs attribute.
func readInt(path string) (int, error) {
	b, err := os.ReadFile(path)
	if err != nil {
		return 0, err
	}
	v, err := strconv.Atoi(strings.TrimSpace(string(b)))
	if err != nil {
		return 0, fmt.Errorf("%s: %v", path, err)
	}
	return v, nil
}

func main() {
	if err := run(); err != nil {
		fmt.Fprintln(os.Stderr, "fanctl:", err)
		os.Exit(1)
	}
}

func run() error {
	var (
		cpuSpec      = flag.String("cpu", defaultCPUCurve, "CPU fan curve as temp:boost,... (boost 0-255)")
		gpuSpec      = flag.String("gpu", defaultGPUCurve, "GPU fan curve as temp:boost,... (boost 0-255)")
		interval     = flag.Duration("interval", 2*time.Second, "sampling interval")
		hysteresis   = flag.Int("hysteresis", 12, "boost must fall this far below the applied value before easing off")
		reassert     = flag.Duration("reassert", 30*time.Second, "re-write the boost this often even when it has not changed (0 disables)")
		profileTemp  = flag.Float64("profile-temp", 70, "force the performance platform profile above this temperature in C (0 disables)")
		profileDelay = flag.Duration("profile-delay", 30*time.Second, "how long the temperature must stay above -profile-temp before the profile is forced")
		once         = flag.Bool("once", false, "sample and apply a single time, then exit")
		status       = flag.Bool("status", false, "print current temperature, fan speed and boost, then exit")
		dryRun       = flag.Bool("dry-run", false, "report each sample and what would be written, without touching the hardware")
		verbose      = flag.Bool("v", false, "log every sample, not just changes")
	)
	flag.Parse()

	cpuCurve, err := parseCurve(*cpuSpec)
	if err != nil {
		return fmt.Errorf("cpu curve: %w", err)
	}
	gpuCurve, err := parseCurve(*gpuSpec)
	if err != nil {
		return fmt.Errorf("gpu curve: %w", err)
	}

	dir, err := findHwmon(driverName)
	if err != nil {
		return err
	}

	// temp1/fan1 is the CPU side and temp2/fan2 the GPU side; the driver
	// confirms the pairing via pwmN_auto_channels_temp.
	// Pointers, not values: tick and the restore path mutate applied/initial,
	// and ranging over a value slice would only ever update a copy.
	channels := []*channel{
		{
			label:     "CPU",
			tempPath:  filepath.Join(dir, "temp1_input"),
			boostPath: filepath.Join(dir, "fan1_boost"),
			rpmPath:   filepath.Join(dir, "fan1_input"),
			curve:     cpuCurve,
		},
		{
			label:     "GPU",
			tempPath:  filepath.Join(dir, "temp2_input"),
			boostPath: filepath.Join(dir, "fan2_boost"),
			rpmPath:   filepath.Join(dir, "fan2_input"),
			curve:     gpuCurve,
		},
	}

	// A machine whose firmware exposes no usable platform profile is still
	// worth driving the boost curve on, so a guard that cannot be built is a
	// warning rather than a failure.
	guard, err := newProfileGuard(*profileTemp, *profileDelay, *dryRun)
	if err != nil {
		fmt.Fprintln(os.Stderr, "fanctl: platform profile guard disabled:", err)
	}

	// Reporting state only reads sysfs, so it needs no privileges and is safe
	// to run against a daemon that is already driving the fans.
	if *status {
		return printStatus(dir, channels, guard)
	}

	if !*dryRun && os.Geteuid() != 0 {
		return errors.New("writing fan boost requires root; re-run with sudo or pass -dry-run")
	}

	for _, ch := range channels {
		if _, err := ch.temperature(); err != nil {
			return fmt.Errorf("%s sensor: %w", ch.label, err)
		}
		boost, err := readInt(ch.boostPath)
		if err != nil {
			return fmt.Errorf("%s boost: %w", ch.label, err)
		}
		ch.initial, ch.applied = boost, boost
	}

	fmt.Printf("fanctl: %s at %s\n", driverName, dir)
	for _, ch := range channels {
		fmt.Printf("  %s curve %s (boost now %d)\n", ch.label, ch.curve, ch.initial)
	}
	fmt.Printf("  guard %s (profile now %s)\n", guard.describe(), guard.current())
	if *dryRun {
		fmt.Println("  dry run: no writes will be made")
	}

	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	// Put the boost back where it was found, so exiting does not leave the
	// fans pinned at whatever the last sample called for.
	if !*dryRun {
		defer func() {
			for _, ch := range channels {
				if ch.applied == ch.initial {
					continue
				}
				if err := ch.writeBoost(ch.initial); err != nil {
					fmt.Fprintf(os.Stderr, "fanctl: restoring %s boost: %v\n", ch.label, err)
				}
			}
			if err := guard.restore(); err != nil {
				fmt.Fprintln(os.Stderr, "fanctl: restoring platform profile:", err)
			}
			fmt.Println("fanctl: restored initial boost")
		}()
	}

	tick := func() error {
		// The platform profile is one global setting, so it answers to the
		// hottest sensor of the sample rather than to either channel alone.
		hottest := math.Inf(-1)
		for _, ch := range channels {
			tempC, err := ch.temperature()
			if err != nil {
				return fmt.Errorf("%s sensor: %w", ch.label, err)
			}

			// The EC does not always keep the boost it is handed: a thermal
			// mode change, a resume, or its own housekeeping can drop it back
			// without telling anyone. Believing our own last write would then
			// leave the fans unboosted for as long as the curve asks for the
			// same value, so let the hardware's reading win over the cached
			// one and report the disagreement -- a run that logs drift every
			// few seconds is the EC refusing to be driven, not a curve
			// problem.
			if !*dryRun {
				live, err := readInt(ch.boostPath)
				if err != nil {
					return fmt.Errorf("%s boost: %w", ch.label, err)
				}
				if live != ch.applied {
					if !ch.drifted {
						fmt.Printf("%s %s boost drifted %d -> %d, re-asserting\n",
							time.Now().Format("15:04:05"), ch.label, ch.applied, live)
						ch.drifted = true
					}
					ch.applied = live
				} else {
					ch.drifted = false
				}
			}

			prev := ch.applied
			want := ch.target(tempC, *hysteresis)
			changed := want != prev
			// Re-assert on a slow cadence even when nothing changed. Drift
			// detection only catches a dropped boost that sysfs admits to; a
			// driver answering reads from its own cache would hide one, and a
			// redundant write costs nothing.
			stale := *reassert > 0 && time.Since(ch.wrote) >= *reassert
			if (changed || stale) && !*dryRun {
				if err := ch.writeBoost(want); err != nil {
					return err
				}
			}
			// A dry run exists to be read, so report every sample even when
			// the curve calls for no change; otherwise an idle machine shows
			// no temperatures at all.
			if changed || *verbose {
				fmt.Printf("%s %s %5.1fC  %4d rpm  boost %3d -> %3d\n",
					time.Now().Format("15:04:05"), ch.label, tempC, ch.rpm(), prev, want)
			}
			if *dryRun {
				ch.applied = want // track intent so hysteresis still behaves
			}
			hottest = math.Max(hottest, tempC)
		}
		return guard.update(hottest)
	}

	if err := tick(); err != nil {
		return err
	}
	if *once {
		return nil
	}

	ticker := time.NewTicker(*interval)
	defer ticker.Stop()
	for {
		select {
		case <-ctx.Done():
			return nil
		case <-ticker.C:
			if err := tick(); err != nil {
				return err
			}
		}
	}
}
