package main

import (
	"errors"
	"fmt"
	"sort"
	"strconv"
	"strings"
)

// A point maps a temperature to the boost that should be applied at or above
// it. A curve is a set of such points sorted by temperature; values between
// points are interpolated linearly.
type point struct {
	tempC float64
	boost int
}

type curve []point

// parseCurve reads a curve written as "temp:boost,temp:boost,...".
func parseCurve(s string) (curve, error) {
	fields := strings.Split(s, ",")
	c := make(curve, 0, len(fields))
	for _, f := range fields {
		t, b, ok := strings.Cut(strings.TrimSpace(f), ":")
		if !ok {
			return nil, fmt.Errorf("bad point %q, want temp:boost", f)
		}
		tempC, err := strconv.ParseFloat(strings.TrimSpace(t), 64)
		if err != nil {
			return nil, fmt.Errorf("bad temperature in %q: %v", f, err)
		}
		boost, err := strconv.Atoi(strings.TrimSpace(b))
		if err != nil {
			return nil, fmt.Errorf("bad boost in %q: %v", f, err)
		}
		if boost < 0 || boost > maxBoost {
			return nil, fmt.Errorf("boost %d out of range 0-%d", boost, maxBoost)
		}
		c = append(c, point{tempC: tempC, boost: boost})
	}
	if len(c) == 0 {
		return nil, errors.New("empty curve")
	}
	sort.Slice(c, func(i, j int) bool { return c[i].tempC < c[j].tempC })
	return c, nil
}

// boostAt returns the boost the curve calls for at tempC, clamping below the
// first point and above the last.
func (c curve) boostAt(tempC float64) int {
	if tempC <= c[0].tempC {
		return c[0].boost
	}
	last := c[len(c)-1]
	if tempC >= last.tempC {
		return last.boost
	}
	for i := 1; i < len(c); i++ {
		hi := c[i]
		if tempC > hi.tempC {
			continue
		}
		lo := c[i-1]
		span := hi.tempC - lo.tempC
		if span <= 0 {
			return hi.boost
		}
		frac := (tempC - lo.tempC) / span
		return lo.boost + int(frac*float64(hi.boost-lo.boost)+0.5)
	}
	return last.boost
}

func (c curve) String() string {
	parts := make([]string, len(c))
	for i, p := range c {
		parts[i] = fmt.Sprintf("%g:%d", p.tempC, p.boost)
	}
	return strings.Join(parts, ",")
}
