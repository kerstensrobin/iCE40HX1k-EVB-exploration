PROJ    = blink
TOP     = top
DEVICE  = hx1k
PACKAGE = tq144
PCF     = ice40hx1k-evb.pcf
SOURCES = top.vhd

RPI_HOST ?= pi@raspberrypi.local

.PHONY: all clean flash

all: $(PROJ).bin

$(PROJ).json: $(SOURCES)
	yosys -m ghdl -p "ghdl --std=08 $(SOURCES) -e $(TOP); synth_ice40 -top $(TOP) -json $@"

$(PROJ).asc: $(PROJ).json $(PCF)
	nextpnr-ice40 --$(DEVICE) --package $(PACKAGE) --freq 100 --json $< --pcf $(PCF) --asc $@

$(PROJ).bin: $(PROJ).asc
	icepack $< $@

flash: $(PROJ).bin
	scp $(PROJ).bin $(RPI_HOST):~/$(PROJ).bin
	ssh $(RPI_HOST) '\
		tr "\000" "\377" < /dev/zero | dd bs=2M count=1 of=flash_image.bin 2>/dev/null; \
		dd if=$(PROJ).bin conv=notrunc of=flash_image.bin 2>/dev/null; \
		flashrom -p linux_spi:dev=/dev/spidev0.0,spispeed=20000 -w flash_image.bin; \
		echo in > /sys/class/gpio/gpio24/direction'

clean:
	rm -f $(PROJ).json $(PROJ).asc $(PROJ).bin flash_image.bin
