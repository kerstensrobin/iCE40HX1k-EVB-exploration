# iCE40HX1k-EVB-exploration

Getting started with the [Olimex iCE40HX1K-EVB](https://www.olimex.com/Products/FPGA/iCE40/iCE40HX1K-EVB/) using an open-source toolchain and a Raspberry Pi as programmer.

## Toolchain

All synthesis tools come from the [OSS CAD Suite](https://github.com/YosysHQ/oss-cad-suite-build) — a single pre-built bundle, no manual compilation needed.

| Tool | Purpose |
|------|---------|
| `ghdl` | VHDL analysis and simulation |
| `yosys` + GHDL plugin | VHDL synthesis |
| `nextpnr-ice40` | Place and route |
| `icepack` | Pack bitstream |

Install: download the latest `oss-cad-suite-linux-x64-*.tgz` from the releases page and add the `bin/` directory to your `PATH`.

## Build flow

```
ghdl → yosys (ghdl plugin) → nextpnr-ice40 → icepack → top.bin
```

## Programming via Raspberry Pi

The board has no USB programmer — flashing is done over SPI from a Raspberry Pi (or similar SBC). Synthesis runs on your main machine; you copy the bitstream to the Pi and flash from there.

**RPi one-time setup:**
```bash
echo dtparam=spi=on >> /boot/config.txt  # then reboot
# build flashrom from source (see https://github.com/anse1/olimex-ice40-notes)
echo 24 > /sys/class/gpio/export
echo out > /sys/class/gpio/gpio24/direction
```

**Flash a bitstream:**
```bash
# on your machine
scp top.bin pi@raspberrypi.local:~/

# on the RPi
tr '\0' '\377' < /dev/zero | dd bs=2M count=1 of=image.bin  # pad to flash size
dd if=top.bin conv=notrunc of=image.bin
flashrom -p linux_spi:dev=/dev/spidev0.0,spispeed=20000 -w image.bin
echo in > /sys/class/gpio/gpio24/direction  # release reset
```

The padding step is required because `flashrom` writes the full 2 MB flash chip; the bitstream alone is much smaller.

**RPi → EVB wiring (RPi pin → EVB header):**

| RPi pin | Signal | EVB |
|---------|--------|-----|
| 17 | 3v3 | 3v3 |
| 18 (GPIO24) | CRESET | CRESET |
| 19 (MOSI) | SDO | SDO |
| 20 | GND | GND |
| 21 (MISO) | SDI | SDI |
| 22 (GPIO25) | CDONE | CDONE |
| 23 (CLK) | SCK | SCK |
| 24 (CE0) | CS | #CD/SS_B |
| 25 | GND | GND |

> **Pin-out warning:** The UEXT/SPI header on the EVB can appear to be oriented either way depending on how you approach the board. Two nights were lost to a connector plugged in 180 degrees rotated. Before powering up, physically verify pin 1 (marked on the PCB silkscreen) matches your cable. When in doubt, probe 3v3 and GND before connecting the SPI lines.

## References

- [Getting started tutorial (cocoacrumbs)](https://www.cocoacrumbs.com/blog/2023-01-27-getting-started-with-the-olimex-ice40hx1k-evb/)
- [RPi programming notes (anse1)](https://github.com/anse1/olimex-ice40-notes)
- [SBC programmer interface inspiration (tomek-szczesny)](https://github.com/tomek-szczesny/ice40hx8k-evb-prog-if)
