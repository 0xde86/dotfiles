package main

import (
	"fmt"
	"os"
	"strconv"
)

// A channel pairs one temperature sensor with the fan boost it governs.
type channel struct {
	label     string
	tempPath  string
	boostPath string
	rpmPath   string
	curve     curve

	initial int // boost found at startup, restored on exit
	applied int // boost most recently written
}

// temperature reports the channel's sensor reading. hwmon exposes
// millidegrees Celsius.
func (ch *channel) temperature() (float64, error) {
	milli, err := readInt(ch.tempPath)
	if err != nil {
		return 0, err
	}
	return float64(milli) / 1000, nil
}

// rpm reports the measured fan speed, or -1 if it cannot be read.
func (ch *channel) rpm() int {
	v, err := readInt(ch.rpmPath)
	if err != nil {
		return -1
	}
	return v
}

func (ch *channel) writeBoost(boost int) error {
	if err := os.WriteFile(ch.boostPath, []byte(strconv.Itoa(boost)), 0o644); err != nil {
		return fmt.Errorf("%s: %w", ch.boostPath, err)
	}
	ch.applied = boost
	return nil
}

// target applies hysteresis to the curve's output: the boost rises as soon as
// the curve calls for more cooling, but only falls once it has dropped a full
// hysteresis band below what is currently applied. That keeps the fans from
// oscillating around a curve knee.
func (ch *channel) target(tempC float64, hysteresis int) int {
	want := ch.curve.boostAt(tempC)
	if want > ch.applied {
		return want
	}
	if want <= ch.applied-hysteresis {
		return want
	}
	return ch.applied
}
