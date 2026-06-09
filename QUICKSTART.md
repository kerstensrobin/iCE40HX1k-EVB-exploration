# Quickstart: build and flash an example via Raspberry Pi

## 1. One-time RPi setup

SSH into the Pi and run this block once. It enables SPI, exports the reset GPIO, and builds flashrom.

```bash
# Enable SPI (requires reboot)
echo dtparam=spi=on | sudo tee -a /boot/config.txt
sudo reboot
```

After reboot, back on the Pi:

```bash
# Export CRESET GPIO
echo 24 | sudo tee /sys/class/gpio/export
echo out | sudo tee /sys/class/gpio/gpio24/direction

# Build and install flashrom (no libpci/libusb needed)
sudo apt install -y git build-essential
git clone https://www.flashrom.org/git/flashrom.git
cd flashrom
make CONFIG_ENABLE_LIBPCI_PROGRAMMERS=no \
     CONFIG_ENABLE_LIBUSB0_PROGRAMMERS=no \
     CONFIG_ENABLE_LIBUSB1_PROGRAMMERS=no
sudo make install
```

## 2. One-time host setup

If you opened a new terminal since installing the OSS CAD Suite:

```bash
source ~/.bashrc
```

Verify:

```bash
yosys --version && nextpnr-ice40 --version && ghdl --version
```

## 3. Wiring

> **Double-check pin 1 orientation before connecting.** The UEXT header looks symmetric — plugging it in 180° rotated will waste your evening.

| RPi pin | Signal | EVB header pin |
|---------|--------|----------------|
| 17 | 3v3 | 3v3 |
| 18 (GPIO24) | CRESET | CRESET |
| 19 (MOSI) | SDO | SDO |
| 20 | GND | GND |
| 21 (MISO) | SDI | SDI |
| 22 (GPIO25) | CDONE | CDONE |
| 23 (CLK) | SCK | SCK |
| 24 (CE0) | CS | #CD/SS_B |
| 25 | GND | GND |

## 4. Build an example

```bash
cd examples/blink
make
```

Output: `blink.bin`

## 5. Flash

```bash
make flash RPI_HOST=pi@raspberrypi.local
```

This will:
1. Copy `blink.bin` to the Pi
2. Pad it to the full 2 MB flash size
3. Run `flashrom` over SPI
4. Release CRESET so the FPGA boots the new configuration

If the board doesn't respond after flashing, toggle power — the FPGA loads from flash on power-up.

## Troubleshooting

| Symptom | Likely cause |
|---------|-------------|
| `flashrom` finds no flash chip | SPI not enabled, or wiring wrong — re-check pin 1 orientation |
| `flashrom` finds chip but write fails | Try dropping speed: `spispeed=4000` |
| FPGA does nothing after flash | CRESET not released — re-run `echo in > /sys/class/gpio/gpio24/direction` on Pi |
| `ghdl` not found | Run `source ~/.bashrc` first |
