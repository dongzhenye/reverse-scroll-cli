import Foundation

/// Print one or more lines to stderr and exit.
func die(_ lines: [String], code: Int32 = 1) -> Never {
    for line in lines { fputs(line + "\n", stderr) }
    exit(code)
}

func die(_ line: String, code: Int32 = 1) -> Never {
    die([line], code: code)
}
