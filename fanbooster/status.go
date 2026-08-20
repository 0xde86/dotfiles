package main

import "fmt"

// printStatus reports what the hardware is doing right now: the measured
// temperature and fan speed, the boost currently programmed into the EC, and
// the boost this configuration's curve would ask for at that temperature.
//
// It only reads, so it works as an unprivileged user and can be pointed at a
// machine where the daemon is already running.
func printStatus(dir string, channels []*channel) error {
	fmt.Printf("fanctl: %s at %s\n", driverName, dir)
	for _, ch := range channels {
		tempC, err := ch.temperature()
		if err != nil {
			return fmt.Errorf("%s sensor: %w", ch.label, err)
		}
		boost, err := readInt(ch.boostPath)
		if err != nil {
			return fmt.Errorf("%s boost: %w", ch.label, err)
		}
		fmt.Printf("  %s %5.1fC  %4d rpm   boost %3d/%d   curve wants %3d\n",
			ch.label, tempC, ch.rpm(), boost, maxBoost, ch.curve.boostAt(tempC))
	}
	return nil
}
