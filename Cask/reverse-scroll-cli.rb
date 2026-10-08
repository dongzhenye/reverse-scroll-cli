# frozen_string_literal: true

cask "reverse-scroll-cli" do
  version "0.3.1"
  sha256 "8bc14cc7d78d6c76aef4832ba72639b5ee4ab620a51605bef8c39d7deb670a85"

  url "https://github.com/dongzhenye/reverse-scroll-cli/releases/download/v#{version}/ReverseScrollCLI.app.zip"
  name "ReverseScrollCLI"
  desc "Lightweight CLI daemon to reverse mouse scroll direction"
  homepage "https://github.com/dongzhenye/reverse-scroll-cli"

  depends_on macos: :ventura

  generated_script "launch-agent.sh", content: <<~SH
    #!/bin/sh
    set -eu
    action="$1"
    appdir="$2"
    prefix="$3"
    app="$appdir/ReverseScrollCLI.app"
    binary="$app/Contents/MacOS/reverse-scroll-cli"
    link="$prefix/bin/reverse-scroll-cli"
    plist="$HOME/Library/LaunchAgents/com.dongzhenye.reverse-scroll-cli.plist"
    domain="gui/$(/usr/bin/id -u)"
    service="$domain/com.dongzhenye.reverse-scroll-cli"

    stop_service() {
      if /bin/launchctl print "$service" >/dev/null 2>&1; then
        /bin/launchctl bootout "$service"
      fi
    }

    case "$action" in
      install)
        # Refuse collisions before changing any existing service or files.
        for target in "$app" "$link"; do
          if [ -e "$target" ] || [ -L "$target" ]; then
            echo "Installation target already exists: $target" >&2
            exit 1
          fi
        done
        app_created=0
        link_created=0
        plist_created=0
        service_created=0
        rollback() {
          status=$?
          trap - EXIT
          if [ "$status" -ne 0 ]; then
            set +e
            if [ "$service_created" -eq 1 ]; then stop_service; fi
            if [ "$link_created" -eq 1 ]; then /bin/rm -f "$link"; fi
            if [ "$plist_created" -eq 1 ]; then /bin/rm -f "$plist"; fi
            if [ "$app_created" -eq 1 ]; then /bin/rm -rf "$app"; fi
          fi
          exit "$status"
        }
        trap rollback EXIT
        stop_service
        /bin/mkdir -p "$appdir" "$prefix/bin" "$HOME/Library/LaunchAgents"
        /bin/mkdir "$app"
        app_created=1
        source_app="$(/usr/bin/dirname "$0")/ReverseScrollCLI.app"
        /usr/bin/ditto --rsrc --extattr --acl --qtn "$source_app" "$app"
        # ditto does not copy the root directory's quarantine onto an existing directory.
        if quarantine="$(/usr/bin/xattr -p com.apple.quarantine "$source_app" 2>/dev/null)"; then
          /usr/bin/xattr -w com.apple.quarantine "$quarantine" "$app"
        fi
        /bin/ln -s "$binary" "$link"
        link_created=1
        plist_created=1
        /bin/cp "$(/usr/bin/dirname "$0")/LaunchAgent/com.dongzhenye.reverse-scroll-cli.plist" "$plist"
        /usr/libexec/PlistBuddy -c "Set :ProgramArguments:0 $binary" "$plist"
        # launchd refuses quarantined plists. Preserve quarantine on the app.
        if /usr/bin/xattr -p com.apple.quarantine "$plist" >/dev/null 2>&1; then
          /usr/bin/xattr -d com.apple.quarantine "$plist"
        fi
        service_created=1
        /bin/launchctl bootstrap "$domain" "$plist"
        ;;
      uninstall)
        # Do not remove an unrelated executable that replaced our symlink.
        if [ -L "$link" ] && [ "$(/usr/bin/readlink "$link")" = "$binary" ]; then
          /bin/rm "$link"
        fi
        stop_service
        /bin/rm -f "$plist"
        /bin/rm -rf "$app"
        ;;
      *) exit 2 ;;
    esac
  SH
  installer script: {
    executable: "launch-agent.sh",
    args:       ["install", appdir.to_s, HOMEBREW_PREFIX.to_s],
    sudo:       false,
  }

  uninstall script: {
    executable: "launch-agent.sh",
    args:       ["uninstall", appdir.to_s, HOMEBREW_PREFIX.to_s],
    sudo:       false,
  }
end
