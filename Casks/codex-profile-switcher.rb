cask "codex-profile-switcher" do
  version "1.0.0"
  sha256 :no_check

  url "https://github.com/JakobStadlhuber/Codex-Profile-Switcher/releases/download/v#{version}/Codex-Profiles-#{version}.zip",
      verified: "github.com/JakobStadlhuber/Codex-Profile-Switcher/"
  name "Codex Profiles"
  desc "Menu bar app for switching local Codex CLI configuration profiles"
  homepage "https://github.com/JakobStadlhuber/Codex-Profile-Switcher"

  app "Codex Profiles.app"
end
