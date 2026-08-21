BIN     := fanctl
PREFIX  := /usr/local
UNIT    := fanctl.service
UNITDIR := /etc/systemd/system

.PHONY: build test install uninstall enable disable start stop restart status logs clean

build:
	go build -o $(BIN) ./...

test:
	go test ./...

# Root: writes to $(PREFIX)/bin and $(UNITDIR).
install:
	install -Dm755 $(BIN) $(DESTDIR)$(PREFIX)/bin/$(BIN)
	install -Dm755 fan $(DESTDIR)$(PREFIX)/bin/fan
	install -Dm644 $(UNIT) $(DESTDIR)$(UNITDIR)/$(UNIT)
	systemctl daemon-reload

# Install, start now, and start on every boot.
enable: install
	systemctl enable --now $(UNIT)

disable:
	-systemctl disable --now $(UNIT)

uninstall: disable
	rm -f $(DESTDIR)$(UNITDIR)/$(UNIT) $(DESTDIR)$(PREFIX)/bin/$(BIN) $(DESTDIR)$(PREFIX)/bin/fan
	systemctl daemon-reload

start:
	systemctl start $(UNIT)

stop:
	systemctl stop $(UNIT)

restart:
	systemctl restart $(UNIT)

# Service state plus what the hardware is actually doing.
status:
	-systemctl status $(UNIT) --no-pager
	@echo
	@$(PREFIX)/bin/$(BIN) -status

logs:
	journalctl -u $(UNIT) -f

clean:
	rm -f $(BIN)
