# Examples

Each example is self-contained with its own `Makefile`. From any example directory:

```bash
make                        # synthesise → <name>.bin
make flash RPI_HOST=pi@...  # flash via RPi
```

## Available examples

| Example | Description |
|---------|-------------|
| [blink](blink/) | Two-mode LED demo: button mirror and 1 Hz blink |
