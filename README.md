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

## Install

### From a release (no build tools needed)

1. Download `WizControl-x.y.z.zip` from the [latest release](https://github.com/idlivada/wiz-mac-control/releases/latest)
2. Unzip it and move `WizControl.app` to `/Applications`
3. The app is ad-hoc signed (not notarized), so macOS quarantines downloaded copies. Clear it with:

   ```sh
   xattr -dr com.apple.quarantine /Applications/WizControl.app
   ```

   (or right-click the app → Open → Open)
4. Launch it — the lightbulb icon appears in the menu bar

### From source

Requires only the Swift command-line tools (no Xcode):

```sh
git clone https://github.com/idlivada/wiz-mac-control.git
cd wiz-mac-control
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
