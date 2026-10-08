# frozen_string_literal: true

require "cask/cask_loader"
require "tmpdir"
require "json"

cask = Cask::CaskLoader::FromContentLoader.new(File.read(ARGV.fetch(0))).load(config: nil)
installer = cask.artifacts.find { |a| a.is_a?(Cask::Artifact::Installer) }
abort "FAIL: official installer interface missing" unless installer
abort "FAIL: later artifacts can break transaction rollback" if cask.artifacts.any? { |a| a.is_a?(Cask::Artifact::App) || a.is_a?(Cask::Artifact::Binary) || a.is_a?(Cask::Artifact::PostflightSteps) }
script_name, script_options = cask.artifacts.find { |a| a.is_a?(Cask::Artifact::GeneratedScript) }.to_args
uninstall = cask.artifacts.find { |a| a.is_a?(Cask::Artifact::Uninstall) }
abort "FAIL: uninstall hook missing" unless uninstall.directives.fetch(:script).fetch(:args).first == "uninstall"
abort "FAIL: install mode missing" unless installer.args.fetch(:args).first == "install"

Dir.mktmpdir("reverse-scroll-cask-") do |directory|
  root = Pathname(directory)
  home = root/"user home"
  stage = root/"stage"
  appdir = root/"custom Applications"
  prefix = root/"prefix"
  source = stage/"LaunchAgent/com.dongzhenye.reverse-scroll-cli.plist"
  destination = home/"Library/LaunchAgents/com.dongzhenye.reverse-scroll-cli.plist"
  source.dirname.mkpath
  destination.dirname.mkpath
  source.write(File.read(File.expand_path("../LaunchAgent/com.dongzhenye.reverse-scroll-cli.plist", File.dirname(ARGV.fetch(0)))))
  destination.write("previous install\n")
  source_app = stage/"ReverseScrollCLI.app"
  (source_app/"Contents/MacOS").mkpath
  (source_app/"Contents/MacOS/reverse-scroll-cli").write("fixture binary\n")
  [source, destination, source_app].each do |path|
    system("/usr/bin/xattr", "-w", "com.apple.quarantine", "0081;00000000;test;", path.to_s, exception: true)
  end
  app = appdir/"ReverseScrollCLI.app"
  link = prefix/"bin/reverse-scroll-cli"
  running = root/"bootstrapped"

  # Only launchctl is doubled; the actual installer and file operations run.
  launchctl = root/"launchctl"
  launchctl.write(<<~SH)
    #!/bin/sh
    case "$1" in
      print) test -f "#{running}" ;;
      bootout) rm "#{running}" ;;
      bootstrap)
        test -f "$3" || exit 2
        if /usr/bin/xattr -p com.apple.quarantine "$3" >/dev/null 2>&1; then exit 5; fi
        test -f "#{app}/Contents/MacOS/reverse-scroll-cli" || exit 6
        touch "#{running}"
        test ! -f "#{root}/reject-bootstrap" || exit 5
        ;;
      *) exit 99 ;;
    esac
  SH
  launchctl.chmod(0755)
  script = stage/script_name
  script.write(script_options.fetch(:content).gsub("/bin/launchctl", launchctl.to_s))
  environment = { "HOME" => home.to_s }
  run = ->(action) { system(environment, "/bin/sh", script.to_s, action, appdir.to_s, prefix.to_s) }
  assert_clean = lambda do
    abort "FAIL: failed installation or uninstall left files or service behind" if app.exist? || link.symlink? || destination.exist? || running.exist?
  end

  2.times do
    abort "FAIL: installation failed" unless run.call("install")
    abort "FAIL: service or CLI link missing" unless running.exist? && link.symlink?
    abort "FAIL: installed plist is quarantined" if system("/usr/bin/xattr", "-p", "com.apple.quarantine", destination.to_s, out: File::NULL, err: File::NULL)
    arguments = JSON.parse(IO.popen(["/usr/bin/plutil", "-extract", "ProgramArguments", "json", "-o", "-", destination.to_s], &:read))
    abort "FAIL: daemon arguments changed" unless arguments == [(app/"Contents/MacOS/reverse-scroll-cli").to_s, "--daemon"]
    [source, source_app, app].each do |path|
      abort "FAIL: source or app quarantine was modified" unless system("/usr/bin/xattr", "-p", "com.apple.quarantine", path.to_s, out: File::NULL)
    end
    abort "FAIL: collision was overwritten" if run.call("install")
    abort "FAIL: collision stopped existing service" unless running.exist?
    abort "FAIL: uninstall failed" unless run.call("uninstall")
    assert_clean.call
  end
  (root/"reject-bootstrap").write("")
  abort "FAIL: bootstrap error was hidden" if run.call("install")
  assert_clean.call
  (root/"reject-bootstrap").delete
  File.rename(source_app, stage/"saved.app")
  abort "FAIL: app copy failure was hidden" if run.call("install")
  assert_clean.call
  File.rename(stage/"saved.app", source_app)
  link.dirname.mkpath
  link.write("unrelated executable")
  abort "FAIL: executable collision was overwritten" if run.call("install")
  abort "FAIL: unrelated executable changed" unless link.read == "unrelated executable"
  link.delete
  2.times { abort "FAIL: repeated uninstall failed" unless run.call("uninstall") }
  assert_clean.call
  puts "PASS: quarantine, custom appdir, reinstall, app preservation, collisions, copy/bootstrap rollback, uninstall"
end
