cask "codex-profile-switcher" do
  version "1.0.3"
  sha256 "224bca6c769d1b7875f62b42d2cd401e61162e37e4c52d42c4f3f0876f007b5d"

  url "https://github.com/JakobStadlhuber/Codex-Profile-Switcher/releases/download/v#{version}/Codex-Profiles-#{version}.zip"
  name "Codex Profiles"
  desc "Menu bar app for switching local Codex CLI configuration profiles"
  homepage "https://github.com/JakobStadlhuber/Codex-Profile-Switcher"

  depends_on macos: :sonoma

  app "Codex Profiles.app"

  postflight do
    system_command "/usr/bin/xattr",
                   args: ["-dr", "com.apple.quarantine", "#{appdir}/Codex Profiles.app"],
                   sudo: false
  end
end
