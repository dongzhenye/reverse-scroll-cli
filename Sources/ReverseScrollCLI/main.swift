import Foundation

let args = CommandLine.arguments.dropFirst()

if args.isEmpty {
    printStatus()
    exit(0)
}

switch args.first {
case "--version", "-v":
    print("reverse-scroll-cli v\(version)")
case "--daemon":
    runDaemon(foreground: false)
case "--foreground":
    runDaemon(foreground: true)
case "--help", "-h":
    print("""
    reverse-scroll-cli v\(version)

    Usage:
      reverse-scroll-cli              Show status
      reverse-scroll-cli --foreground Run in foreground (testing)
      reverse-scroll-cli --version    Show version

    Install: brew install --cask reverse-scroll-cli
    """)
default:
    die([
        "Unknown option: \(args.first!)",
        "Run with --help for usage.",
    ])
}
