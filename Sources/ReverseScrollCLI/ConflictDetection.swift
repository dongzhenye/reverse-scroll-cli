import AppKit

struct ConflictingTool {
    let displayName: String
    let bundleIdentifiers: [String]
}

let knownConflictingTools: [ConflictingTool] = [
    ConflictingTool(displayName: "Scroll Reverser",
                    bundleIdentifiers: ["com.pilotmoon.scroll-reverser"]),
    ConflictingTool(displayName: "Mos",
                    bundleIdentifiers: ["cn.caldis.Mos"]),
    ConflictingTool(displayName: "LinearMouse",
                    bundleIdentifiers: ["com.lujjjh.LinearMouse"]),
    ConflictingTool(displayName: "UnnaturalScrollWheels",
                    bundleIdentifiers: ["com.theron.UnnaturalScrollWheels"]),
    ConflictingTool(displayName: "Mac Mouse Fix",
                    bundleIdentifiers: ["com.nuebling.mac-mouse-fix"]),
]

func runningConflictingTools() -> [String] {
    let bundleIDs = Set(NSWorkspace.shared.runningApplications.compactMap { $0.bundleIdentifier })
    return knownConflictingTools.compactMap { tool in
        tool.bundleIdentifiers.contains(where: bundleIDs.contains) ? tool.displayName : nil
    }
}
