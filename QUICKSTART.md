# Quickstart: build and flash an example via Raspberry Pi

Tested with a Raspberry Pi 4. The SPI and GPIO pins referenced here are standard 40-pin header positions, so earlier Pi models should work too.

The RPi runs headless (no monitor or keyboard) — you interact with it entirely over SSH from your main machine.

## 1. One-time RPi setup

### Find the Pi on your network

If your router supports mDNS, the Pi is reachable as `raspberrypi.local`. Otherwise find its IP in your router's device list. Verify connectivity:

```bash
ping raspberrypi.local
```

### SSH in

```bash
ssh pi@raspberrypi.local
```

Default credentials on a fresh Raspberry Pi OS install are `pi` / `raspberry`. You'll be prompted to change the password on first login.

### Set up SSH keys (recommended)

Avoids typing your password on every `make flash`:

```bash
# Run this on your main machine, not the Pi
ssh-copy-id pi@raspberrypi.local
```

### Enable SPI

On the Pi, run:

```bash
echo dtparam=spi=on | sudo tee -a /boot/config.txt
sudo reboot
```

After the reboot, SSH back in. SPI is now available at `/dev/spidev0.0`.

### Install flashrom

```bash
sudo apt install -y git build-essential
git clone https://www.flashrom.org/git/flashrom.git
cd flashrom
make CONFIG_ENABLE_LIBPCI_PROGRAMMERS=no \
     CONFIG_ENABLE_LIBUSB0_PROGRAMMERS=no \
     CONFIG_ENABLE_LIBUSB1_PROGRAMMERS=no
sudo make install
```

Verify: `flashrom --version`

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

> **Double-check pin 1 orientation before connecting.** The UEXT header looks symmetric and pin 1 is not marked on the PCB. Pin 1 is the **right pin of the bottom row, directly above the barrel jack**. Plugging it in 180° rotated will waste your evening.

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

On your main machine:

```bash
cd examples/blink
make
```

Output: `blink.bin`

## 5. Flash

```bash
make flash RPI_HOST=pi@raspberrypi.local
```

This will, entirely from your main machine:
1. Copy `blink.bin` to the Pi over SCP
2. Pad it to the full 2 MB flash size
3. Assert CRESET (puts FPGA in reset, frees the SPI bus)
4. Run `flashrom` over SPI
5. Release CRESET so the FPGA boots the new configuration

If the board doesn't respond after flashing, toggle power — the FPGA loads from flash on every power-up.

## 6. Using the blink example

The blink example has two modes toggled by pressing both buttons simultaneously:

- **Mode 0** (default) — LED1 lights while BUT1 is held, LED2 lights while BUT2 is held
- **Mode 1** — LED1 and LED2 blink alternately at 1 Hz

## Troubleshooting

| Symptom | Likely cause |
|---------|-------------|
| `ping raspberrypi.local` fails | mDNS not supported by router — find IP in router device list instead |
| `flashrom` finds no flash chip | SPI not enabled, or wiring wrong — re-check pin 1 orientation |
| `flashrom` finds chip but write fails | Try dropping speed: edit `spispeed=20000` to `spispeed=4000` in the Makefile |
| FPGA does nothing after flash | Power cycle the board — FPGA reloads bitstream from flash on power-up |
| `ghdl` not found | Run `source ~/.bashrc` first |
