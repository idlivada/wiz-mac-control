# Wiz Control

macOS menu bar app for controlling two Wiz smart bulbs over the local network (UDP port 38899).

## Features

- Menu bar popover with color wheel, temperature slider (2200–6500 K), and brightness slider
- Power toggle
- Control both bulbs together (default) or each independently
- 5 preset slots — click to load, right-click to save/rename/clear; presets store per-bulb state
- Syncs with the bulbs' real state each time the popover opens (`getPilot`)
- Launch-at-login toggle
- Bulb IPs editable in the popover (gear icon), persisted across launches

## Build

Requires only Swift command-line tools (no Xcode):

```sh
./build.sh
open build/WizControl.app          # or: cp -R build/WizControl.app /Applications/
```

## First run

macOS will ask for **Local Network** permission the first time the app talks to the bulbs — approve it, or every bulb will show as "not responding". If you denied it, re-enable in System Settings → Privacy & Security → Local Network.

## Bulbs

| Bulb   | Default IP    |
|--------|---------------|
| Bulb 1 | 192.168.0.29  |
| Bulb 2 | 192.168.0.28  |

Debug from a terminal:

```sh
echo -n '{"id":1,"method":"getPilot","params":{}}' | nc -u -w 1 192.168.0.29 38899
```
