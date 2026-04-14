import ApplicationServices
import Foundation

func isAccessibilityGranted() -> Bool {
    AXIsProcessTrusted()
}

func isNaturalScrollingEnabled() -> Bool {
    let key = "com.apple.swipescrolldirection" as CFString
    guard let value = CFPreferencesCopyValue(
        key,
        kCFPreferencesAnyApplication,
        kCFPreferencesCurrentUser,
        kCFPreferencesAnyHost
    ) else {
        return true
    }
    return (value as? Bool) ?? true
}

func requireMinimumMacOS() {
    let v = ProcessInfo.processInfo.operatingSystemVersion
    if v.majorVersion < 13 {
        die("reverse-scroll-cli requires macOS 13.0 or later (current: \(v.majorVersion).\(v.minorVersion))")
    }
}
