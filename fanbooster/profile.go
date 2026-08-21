package main

import (
	"fmt"
	"os"
	"slices"
	"strings"
	"time"
)

// Paths are variables rather than constants so tests can point the guard at a
// scratch file instead of the running machine's firmware.
var (
	profilePath        = "/sys/firmware/acpi/platform_profile"
	profileChoicesPath = "/sys/firmware/acpi/platform_profile_choices"
)

const (
	performanceProfile = "performance"

	// Hand the profile back only once the temperature has fallen this far
	// below the trip point. Without a band a sensor sitting on the threshold
	// would flip the platform profile every couple of seconds, and each flip
	// makes the EC re-evaluate its whole thermal policy.
	profileHysteresisC = 5.0
)

// A profileGuard forces the performance platform profile while the machine is
// hot, and gives it back once the machine has cooled.
//
// It exists because fanN_boost alone cannot guarantee cooling: the boost is an
// offset on top of the curve the active platform_profile selects, so a quiet
// or cool profile caps how much airflow any boost can buy. When temperatures
// reach the point where that matters, the profile itself has to move.
type profileGuard struct {
	tripC  float64
	delay  time.Duration
	dryRun bool
	now    func() time.Time // injectable so the delay can be tested without waiting

	hotSince   time.Time // first sample of the current unbroken run above tripC
	forced     bool      // performance is currently held by us
	restoreTo  string    // profile displaced when we stepped in
	pretend    string    // in a dry run, the profile we would have written
	reasserted bool      // something else moved the profile and we put it back
}

// newProfileGuard prepares the guard, or reports why the machine cannot
// support one. A tripC of zero disables the feature and yields a nil guard,
// which every method below accepts.
func newProfileGuard(tripC float64, delay time.Duration, dryRun bool) (*profileGuard, error) {
	if tripC <= 0 {
		return nil, nil
	}
	choices, err := readProfileFile(profileChoicesPath)
	if err != nil {
		return nil, err
	}
	if !slices.Contains(strings.Fields(choices), performanceProfile) {
		return nil, fmt.Errorf("firmware offers no %q profile, only %q", performanceProfile, choices)
	}
	// Fail here rather than at the first trip: a guard that only reveals it
	// cannot read the profile once the machine is already overheating is
	// worse than no guard at all.
	if _, err := readProfileFile(profilePath); err != nil {
		return nil, err
	}
	return &profileGuard{tripC: tripC, delay: delay, dryRun: dryRun, now: time.Now}, nil
}

func readProfileFile(path string) (string, error) {
	b, err := os.ReadFile(path)
	if err != nil {
		return "", err
	}
	return strings.TrimSpace(string(b)), nil
}

// effective reports the profile the guard should reason about: the one sysfs
// holds, or in a dry run the one it would have written. Without the second
// case, declining to write would read back as somebody else having changed the
// profile, and the guard would report a fight it is having with itself.
func (g *profileGuard) effective() (string, error) {
	if g.dryRun && g.pretend != "" {
		return g.pretend, nil
	}
	return readProfileFile(profilePath)
}

func (g *profileGuard) write(profile string) error {
	if g.dryRun {
		g.pretend = profile
		return nil
	}
	if err := os.WriteFile(profilePath, []byte(profile), 0o644); err != nil {
		return fmt.Errorf("%s: %w", profilePath, err)
	}
	return nil
}

// current reports the profile in effect. It is for display only, so a machine
// that cannot answer says so rather than failing.
func (g *profileGuard) current() string {
	profile, err := readProfileFile(profilePath)
	if err != nil {
		return "unknown"
	}
	return profile
}

// update drives the profile from the hottest sensor reading of this sample.
func (g *profileGuard) update(tempC float64) error {
	if g == nil {
		return nil
	}
	live, err := g.effective()
	if err != nil {
		return err
	}

	if !g.forced {
		if tempC < g.tripC {
			// One sample back under the trip point starts the wait over. The
			// guard answers sustained heat, and a turbo burst the cooling
			// system absorbs on its own is not worth a profile change.
			g.hotSince = time.Time{}
			return nil
		}
		now := g.now()
		if g.hotSince.IsZero() {
			g.hotSince = now
		}
		sustained := now.Sub(g.hotSince)
		if sustained < g.delay {
			return nil
		}
		// Remember what was displaced instead of a snapshot taken at startup:
		// the desktop may have changed the profile since, and the thing to put
		// back is whatever was actually in effect when we stepped in.
		g.restoreTo, g.forced, g.reasserted = live, true, false
		g.hotSince = time.Time{}
		if live == performanceProfile {
			return nil
		}
		fmt.Printf("%s %5.1fC at or above %.0fC for %s, forcing %s profile (was %s)\n",
			now.Format("15:04:05"), tempC, g.tripC, sustained.Round(time.Second), performanceProfile, live)
		return g.write(performanceProfile)
	}

	// Still hot. Holding the profile is the whole point of the guard, so put
	// it back if something else moved it, but say so once per episode rather
	// than every sample.
	if tempC > g.tripC-profileHysteresisC {
		if live == performanceProfile {
			g.reasserted = false
			return nil
		}
		if !g.reasserted {
			fmt.Printf("%s profile changed to %s while still %5.1fC, holding %s\n",
				time.Now().Format("15:04:05"), live, tempC, performanceProfile)
			g.reasserted = true
		}
		return g.write(performanceProfile)
	}

	g.forced = false
	if live != performanceProfile {
		// Someone picked a profile of their own on the way down; leave it be.
		return nil
	}
	fmt.Printf("%s %5.1fC back under %.0fC, restoring %s profile\n",
		time.Now().Format("15:04:05"), tempC, g.tripC-profileHysteresisC, g.restoreTo)
	return g.write(g.restoreTo)
}

// restore puts back a profile the guard is still holding, so exiting does not
// leave the machine pinned to performance.
func (g *profileGuard) restore() error {
	if g == nil || !g.forced {
		return nil
	}
	g.forced = false
	live, err := g.effective()
	if err != nil || live != performanceProfile {
		return err
	}
	return g.write(g.restoreTo)
}

// describe reports how the guard is configured, for the startup banner.
func (g *profileGuard) describe() string {
	if g == nil {
		return "disabled"
	}
	return fmt.Sprintf("%s profile above %.0fC for %s, released under %.0fC",
		performanceProfile, g.tripC, g.delay, g.tripC-profileHysteresisC)
}
