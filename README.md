# reverse-scroll-cli

Reverse mouse scroll on macOS. Lightweight CLI, no GUI.

Reverses mouse scroll direction while keeping trackpad natural.
A zero-config daemon — no menu bar, no preferences window.

## Install

```bash
brew install --cask reverse-scroll-cli
```

macOS will ask for Accessibility permission on first run.
Grant it in System Settings > Privacy & Security > Accessibility.

That's it. No configuration needed.

## Uninstall

```bash
brew uninstall --cask reverse-scroll-cli
```

## How it works

macOS ties mouse and trackpad scroll direction to a single setting.
This tool intercepts mouse scroll events and reverses them,
leaving trackpad behavior untouched.

- Uses macOS CGEvent tap (documented public API)
- Runs as an invisible background service
- ~70 lines of Swift, zero dependencies

## Manual testing

```bash
# Run in foreground without installing
./reverse-scroll-cli --foreground
# Ctrl-C to stop
```

## Requirements

- macOS 13.0 (Ventura) or later
- Accessibility permission

## License

MIT
