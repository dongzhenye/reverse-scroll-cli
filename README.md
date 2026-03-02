# reverse-scroll-cli

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![macOS](https://img.shields.io/badge/macOS-13.0+-blue.svg)](https://www.apple.com/macos/)
[![GitHub stars](https://img.shields.io/github/stars/dongzhenye/reverse-scroll-cli.svg)](https://github.com/dongzhenye/reverse-scroll-cli/stargazers)

**Reverse mouse scroll on macOS. Lightweight CLI, no GUI.**

Reverses mouse scroll direction while keeping trackpad natural.
A zero-config daemon — no menu bar, no preferences window.

## Why CLI?

All existing scroll reversal tools (Scroll Reverser, Mos, LinearMouse) are GUI applications with menu bar icons and preferences windows. If you just want mouse scroll reversed without configuration or visual clutter, this is the simplest option.

| Tool | Type | Config | Size | Differentiator |
|------|------|--------|------|----------------|
| **reverse-scroll-cli** | CLI daemon | Zero | 150KB | Install and forget |
| Scroll Reverser | Menu bar app | Preferences window | ~5MB | Established, feature-rich |
| LinearMouse | Preferences app | Full GUI | ~10MB | Per-device customization |
| Mos | Menu bar app | Per-app settings | ~8MB | Smooth scrolling |

## Install

```bash
brew tap dongzhenye/tap
brew install --cask reverse-scroll-cli
```

macOS will ask for Accessibility permission on first run.
Grant it in **System Settings > Privacy & Security > Accessibility**.

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
- ~200 lines of Swift, zero dependencies
- Universal binary (Apple Silicon + Intel)

## Manual testing

```bash
# Run in foreground without installing
./reverse-scroll-cli --foreground
# Ctrl-C to stop
```

## Troubleshooting

### Permission not granted

If the tool doesn't work after installation:

1. Open **System Settings**
2. Go to **Privacy & Security > Accessibility**
3. Find **Terminal** or **ReverseScrollCLI** in the list
4. Toggle it **on**
5. Restart the tool: `brew reinstall --cask reverse-scroll-cli`

### Conflicting tools detected

If you have Scroll Reverser, Mos, or similar tools running, two reversals cancel out. Check running apps:

```bash
reverse-scroll-cli  # Shows warning if conflicts detected
```

Quit the other tool or uninstall this one.

### Natural scrolling is OFF

The tool works best when **Natural Scrolling is ON** (System Settings > Trackpad/Mouse). If Natural Scrolling is off, the tool will reverse your mouse to "natural" direction (opposite of what you want).

**Recommended setup:**
- System Settings: Natural Scrolling **ON**
- This tool: Reverses mouse only → trackpad stays natural, mouse becomes traditional

## Requirements

- macOS 13.0 (Ventura) or later
- Accessibility permission

## Contributing

Contributions welcome! Please:

1. Fork the repo
2. Create a feature branch (`git checkout -b feat/my-feature`)
3. Commit your changes (`git commit -m 'feat: add my feature'`)
4. Push to the branch (`git push origin feat/my-feature`)
5. Open a Pull Request

Follow [Conventional Commits](https://www.conventionalcommits.org/) for commit messages.

## License

MIT

---

**Built with:** Swift, CoreGraphics, Homebrew Cask  
**Author:** [Zhenye Dong](https://github.com/dongzhenye)
