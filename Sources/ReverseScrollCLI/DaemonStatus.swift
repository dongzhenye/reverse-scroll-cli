import Foundation

private let launchAgentLabel = "com.dongzhenye.reverse-scroll-cli"

/// Return true if the LaunchAgent is loaded AND has a live PID.
/// Uses `launchctl print` under gui/<uid>, which is the documented query path
/// for per-user agents on macOS 10.11+. Falls back to returning false on any
/// parse failure — status output will then suggest `brew reinstall`.
func isDaemonRunning() -> Bool {
    let uid = getuid()
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/bin/launchctl")
    task.arguments = ["print", "gui/\(uid)/\(launchAgentLabel)"]
    let pipe = Pipe()
    task.standardOutput = pipe
    task.standardError = FileHandle.nullDevice
    do {
        try task.run()
    } catch {
        return false
    }
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    task.waitUntilExit()
    guard task.terminationStatus == 0,
          let output = String(data: data, encoding: .utf8) else {
        return false
    }
    // `launchctl print` for an agent with a live child shows `pid = <n>`.
    // Agents that are loaded but not currently running show `state = not running`.
    return output.contains("pid = ")
}
