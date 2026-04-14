import Foundation

func isDaemonRunning() -> Bool {
    let selfPID = ProcessInfo.processInfo.processIdentifier
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/usr/bin/pgrep")
    task.arguments = ["-f", "reverse-scroll-cli --(daemon|foreground)"]
    let pipe = Pipe()
    task.standardOutput = pipe
    task.standardError = FileHandle.nullDevice
    try? task.run()
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    task.waitUntilExit()
    let output = String(data: data, encoding: .utf8) ?? ""
    return output.split(separator: "\n")
        .compactMap { Int32($0) }
        .contains { $0 != selfPID }
}
