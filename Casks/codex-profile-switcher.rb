cask "codex-profile-switcher" do
  version "1.0.11"
  sha256 "8ca969638fa1c9e866178097223c99c9feb4829b3177d615bff38d9bc305083a"

  url "https://github.com/doggy8088/Codex-Profile-Switcher/releases/download/v#{version}/CodexProfilesSwitcher.dmg"
  name "Codex Profile Swicher"
  desc "Menu bar app for switching local Codex CLI configuration profiles"
  homepage "https://github.com/doggy8088/Codex-Profile-Switcher"

  depends_on macos: :sonoma

  app "CodexProfileSwitcher.app"
end
