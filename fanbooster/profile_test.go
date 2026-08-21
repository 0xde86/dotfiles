package main

import (
	"os"
	"path/filepath"
	"testing"
	"time"
)

// fakeProfile redirects the guard at a scratch directory, so the state machine
// can be driven through trip and release without a hot machine or root.
func fakeProfile(t *testing.T, initial, choices string) string {
	t.Helper()
	dir := t.TempDir()
	path := filepath.Join(dir, "platform_profile")
	if err := os.WriteFile(path, []byte(initial+"\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	choicesPath := filepath.Join(dir, "platform_profile_choices")
	if err := os.WriteFile(choicesPath, []byte(choices+"\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func(old, oldChoices string) func() {
		return func() { profilePath, profileChoicesPath = old, oldChoices }
	}(profilePath, profileChoicesPath))
	profilePath, profileChoicesPath = path, choicesPath
	return path
}

func readProfile(t *testing.T) string {
	t.Helper()
	got, err := readProfileFile(profilePath)
	if err != nil {
		t.Fatal(err)
	}
	return got
}

// clock drives the guard's sustained-heat wait without making tests sleep.
type clock struct{ t time.Time }

func (c *clock) advance(d time.Duration) { c.t = c.t.Add(d) }

// newTestGuard builds a guard that trips on the first hot sample, so tests of
// the profile state machine stay separable from tests of the delay.
func newTestGuard(t *testing.T, tripC float64) *profileGuard {
	t.Helper()
	g, _ := newDelayedGuard(t, tripC, 0)
	return g
}

func newDelayedGuard(t *testing.T, tripC float64, delay time.Duration) (*profileGuard, *clock) {
	t.Helper()
	g, err := newProfileGuard(tripC, delay, false)
	if err != nil {
		t.Fatal(err)
	}
	c := &clock{t: time.Date(2026, 8, 20, 21, 0, 0, 0, time.UTC)}
	g.now = func() time.Time { return c.t }
	return g, c
}

func TestGuardTripsAndReleases(t *testing.T) {
	fakeProfile(t, "balanced", "quiet balanced performance")
	g := newTestGuard(t, 70)

	if err := g.update(69.9); err != nil {
		t.Fatal(err)
	}
	if got := readProfile(t); got != "balanced" {
		t.Fatalf("below the trip point the profile should be untouched, got %q", got)
	}

	if err := g.update(70); err != nil {
		t.Fatal(err)
	}
	if got := readProfile(t); got != performanceProfile {
		t.Fatalf("at the trip point want %q, got %q", performanceProfile, got)
	}

	// Inside the hysteresis band the guard must keep holding performance.
	if err := g.update(66); err != nil {
		t.Fatal(err)
	}
	if got := readProfile(t); got != performanceProfile {
		t.Fatalf("inside the hysteresis band want %q, got %q", performanceProfile, got)
	}

	if err := g.update(65); err != nil {
		t.Fatal(err)
	}
	if got := readProfile(t); got != "balanced" {
		t.Fatalf("under the release point want %q, got %q", "balanced", got)
	}
	if g.forced {
		t.Fatal("guard still claims to hold the profile after releasing it")
	}
}

func TestGuardRestoresWhatItDisplaced(t *testing.T) {
	fakeProfile(t, "balanced", "quiet balanced performance")
	g := newTestGuard(t, 70)

	// A profile chosen after startup is the one that should come back, not
	// whatever happened to be set when fanctl launched.
	if err := os.WriteFile(profilePath, []byte("quiet\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	if err := g.update(80); err != nil {
		t.Fatal(err)
	}
	if err := g.update(50); err != nil {
		t.Fatal(err)
	}
	if got := readProfile(t); got != "quiet" {
		t.Fatalf("want the displaced profile %q back, got %q", "quiet", got)
	}
}

func TestGuardReassertsWhileHot(t *testing.T) {
	fakeProfile(t, "balanced", "quiet balanced performance")
	g := newTestGuard(t, 70)

	if err := g.update(80); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(profilePath, []byte("quiet\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	if err := g.update(80); err != nil {
		t.Fatal(err)
	}
	if got := readProfile(t); got != performanceProfile {
		t.Fatalf("still hot, want %q held, got %q", performanceProfile, got)
	}
}

func TestGuardLeavesAnExplicitChoiceOnTheWayDown(t *testing.T) {
	fakeProfile(t, "balanced", "quiet balanced performance")
	g := newTestGuard(t, 70)

	if err := g.update(80); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(profilePath, []byte("quiet\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	if err := g.update(50); err != nil {
		t.Fatal(err)
	}
	if got := readProfile(t); got != "quiet" {
		t.Fatalf("a profile picked while cooling should stand, got %q", got)
	}
}

func TestGuardRestoreOnExit(t *testing.T) {
	fakeProfile(t, "balanced", "quiet balanced performance")
	g := newTestGuard(t, 70)

	if err := g.update(80); err != nil {
		t.Fatal(err)
	}
	if err := g.restore(); err != nil {
		t.Fatal(err)
	}
	if got := readProfile(t); got != "balanced" {
		t.Fatalf("exiting should hand the profile back, got %q", got)
	}

	// Restoring without ever having tripped must not touch anything.
	if err := os.WriteFile(profilePath, []byte("quiet\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	if err := g.restore(); err != nil {
		t.Fatal(err)
	}
	if got := readProfile(t); got != "quiet" {
		t.Fatalf("an untripped guard should not write, got %q", got)
	}
}

func TestGuardDryRunDoesNotWrite(t *testing.T) {
	fakeProfile(t, "balanced", "quiet balanced performance")
	g, err := newProfileGuard(70, 0, true)
	if err != nil {
		t.Fatal(err)
	}

	for _, tempC := range []float64{80, 80, 80} {
		if err := g.update(tempC); err != nil {
			t.Fatal(err)
		}
	}
	if got := readProfile(t); got != "balanced" {
		t.Fatalf("a dry run must not write, got %q", got)
	}
	// Repeated hot samples must not read back as somebody else fighting us.
	if g.reasserted {
		t.Fatal("dry run mistook its own declined write for an external change")
	}
}

func TestGuardDisabledAndUnsupported(t *testing.T) {
	fakeProfile(t, "balanced", "quiet balanced performance")

	g, err := newProfileGuard(0, 30*time.Second, false)
	if err != nil {
		t.Fatal(err)
	}
	if g != nil {
		t.Fatal("a zero trip point should disable the guard")
	}
	// Every method has to tolerate the disabled case.
	if err := g.update(90); err != nil {
		t.Fatal(err)
	}
	if err := g.restore(); err != nil {
		t.Fatal(err)
	}
	if got := g.describe(); got != "disabled" {
		t.Fatalf("describe() = %q, want %q", got, "disabled")
	}

	fakeProfile(t, "balanced", "quiet balanced")
	if _, err := newProfileGuard(70, 30*time.Second, false); err == nil {
		t.Fatal("firmware without a performance profile should be reported")
	}
}

func TestGuardWaitsForSustainedHeat(t *testing.T) {
	fakeProfile(t, "balanced", "quiet balanced performance")
	g, c := newDelayedGuard(t, 70, 30*time.Second)

	// Hot, but not yet for long enough.
	for _, step := range []time.Duration{0, 10 * time.Second, 19 * time.Second} {
		c.advance(step)
		if err := g.update(80); err != nil {
			t.Fatal(err)
		}
		if got := readProfile(t); got != "balanced" {
			t.Fatalf("after %s hot the profile should still be untouched, got %q", step, got)
		}
	}

	c.advance(time.Second) // 30s total
	if err := g.update(80); err != nil {
		t.Fatal(err)
	}
	if got := readProfile(t); got != performanceProfile {
		t.Fatalf("after the full wait want %q, got %q", performanceProfile, got)
	}
}

func TestGuardSpikeRestartsTheWait(t *testing.T) {
	fakeProfile(t, "balanced", "quiet balanced performance")
	g, c := newDelayedGuard(t, 70, 30*time.Second)

	if err := g.update(80); err != nil {
		t.Fatal(err)
	}
	c.advance(29 * time.Second)

	// A single sample back under the trip point discards the accumulated time.
	if err := g.update(69); err != nil {
		t.Fatal(err)
	}
	c.advance(29 * time.Second)
	if err := g.update(80); err != nil {
		t.Fatal(err)
	}
	if got := readProfile(t); got != "balanced" {
		t.Fatalf("a dip under the trip point should restart the wait, got %q", got)
	}

	// The fresh run still trips once it has run its own full length.
	c.advance(30 * time.Second)
	if err := g.update(80); err != nil {
		t.Fatal(err)
	}
	if got := readProfile(t); got != performanceProfile {
		t.Fatalf("the restarted wait should still trip, got %q", got)
	}
}

func TestGuardRearmsTheWaitAfterReleasing(t *testing.T) {
	fakeProfile(t, "balanced", "quiet balanced performance")
	g, c := newDelayedGuard(t, 70, 30*time.Second)

	if err := g.update(80); err != nil {
		t.Fatal(err)
	}
	c.advance(30 * time.Second)
	if err := g.update(80); err != nil {
		t.Fatal(err)
	}
	if got := readProfile(t); got != performanceProfile {
		t.Fatalf("want %q, got %q", performanceProfile, got)
	}

	// Cool off and release.
	if err := g.update(60); err != nil {
		t.Fatal(err)
	}
	if got := readProfile(t); got != "balanced" {
		t.Fatalf("want %q after release, got %q", "balanced", got)
	}

	// The next heat-up must serve the whole wait again, not inherit credit
	// from the previous episode.
	if err := g.update(80); err != nil {
		t.Fatal(err)
	}
	if got := readProfile(t); got != "balanced" {
		t.Fatalf("the second episode should start its wait over, got %q", got)
	}
	c.advance(30 * time.Second)
	if err := g.update(80); err != nil {
		t.Fatal(err)
	}
	if got := readProfile(t); got != performanceProfile {
		t.Fatalf("want %q, got %q", performanceProfile, got)
	}
}
