cask "reverse-scroll-cli" do
  version "0.3.0"
  sha256 "7dd58c1e199b70bccdb2e7b57bf5a919488d7ede13a05c325b5cb750b4ff157a"

  url "https://github.com/dongzhenye/reverse-scroll-cli/releases/download/v#{version}/ReverseScrollCLI.app.zip"
  name "ReverseScrollCLI"
  desc "Lightweight CLI daemon to reverse mouse scroll direction on macOS"
  homepage "https://github.com/dongzhenye/reverse-scroll-cli"

  depends_on macos: ">= :ventura"

  app "ReverseScrollCLI.app"
  binary "#{appdir}/ReverseScrollCLI.app/Contents/MacOS/reverse-scroll-cli"

  postflight do
    plist = "#{ENV["HOME"]}/Library/LaunchAgents/com.dongzhenye.reverse-scroll-cli.plist"
    system_command "cp",
      args: ["#{staged_path}/LaunchAgent/com.dongzhenye.reverse-scroll-cli.plist", plist],
      sudo: false
    # bootout is a no-op if the label is not currently loaded.
    system_command "/bin/launchctl",
      args: ["bootout", "gui/#{Process.uid}/com.dongzhenye.reverse-scroll-cli"],
      sudo: false,
      must_succeed: false
    system_command "/bin/launchctl",
      args: ["bootstrap", "gui/#{Process.uid}", plist],
      sudo: false
  end

  uninstall_postflight do
    plist = "#{ENV["HOME"]}/Library/LaunchAgents/com.dongzhenye.reverse-scroll-cli.plist"
    system_command "/bin/launchctl",
      args: ["bootout", "gui/#{Process.uid}/com.dongzhenye.reverse-scroll-cli"],
      sudo: false,
      must_succeed: false
    system_command "rm",
      args: ["-f", plist],
      sudo: false
  end
end
