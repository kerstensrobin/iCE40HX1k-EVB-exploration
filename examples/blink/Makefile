PROJ    = blink
TOP     = top
DEVICE  = hx1k
PACKAGE = vq100
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
		dd if=/dev/zero of=flash_image.bin bs=2097152 count=1 2>/dev/null; \
		dd if=$(PROJ).bin of=flash_image.bin conv=notrunc 2>/dev/null; \
		sudo pinctrl set 24 op dl; \
		sudo /usr/local/sbin/flashrom -p linux_spi:dev=/dev/spidev0.0,spispeed=20000 -w flash_image.bin; \
		sudo pinctrl set 24 ip'

clean:
	rm -f $(PROJ).json $(PROJ).asc $(PROJ).bin flash_image.bin
