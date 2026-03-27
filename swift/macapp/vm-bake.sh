#!/usr/bin/env bash
set -euo pipefail

if ! id franny &>/dev/null; then
  sudo dscl . -create /Users/franny
  sudo dscl . -create /Users/franny UserShell /bin/zsh
  sudo dscl . -create /Users/franny RealName Franny
  sudo dscl . -create /Users/franny UniqueID 502
  sudo dscl . -create /Users/franny PrimaryGroupID 20
  sudo dscl . -create /Users/franny NFSHomeDirectory /Users/franny
  sudo dscl . -passwd /Users/franny franny
  sudo createhomedir -c -u franny 2>/dev/null
  echo "franny ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/franny >/dev/null
  sudo touch /var/db/.AppleSetupDone
  BUDDY=$(/usr/bin/sw_vers -buildVersion)
  sudo -u franny defaults write com.apple.SetupAssistant LastSeenBuddyBuildVersion -string "$BUDDY"
  sudo -u franny defaults write com.apple.SetupAssistant LastSeenCloudProductVersion -string "$(sw_vers -productVersion)"
  sudo -u franny defaults write com.apple.SetupAssistant DidSeeCloudSetup -bool true
  sudo -u franny defaults write com.apple.SetupAssistant DidSeePrivacy -bool true
  sudo -u franny defaults write com.apple.SetupAssistant DidSeeAccessibility -bool true
  sudo -u franny defaults write com.apple.SetupAssistant DidSeeSiriSetup -bool true
  sudo -u franny defaults write com.apple.SetupAssistant DidSeeAppearanceSetup -bool true
  sudo -u franny defaults write com.apple.SetupAssistant DidSeeApplePaySetup -bool true
  sudo -u franny defaults write com.apple.SetupAssistant DidSeeiCloudLoginForStorageServices -bool true
  sudo -u franny defaults write com.apple.SetupAssistant DidSeeScreenTime -bool true
  sudo -u franny defaults write com.apple.SetupAssistant DidSeeSyncSetup -bool true
  sudo -u franny defaults write com.apple.SetupAssistant DidSeeSyncSetup2 -bool true
  sudo -u franny defaults write com.apple.SetupAssistant DidSeeTermsOfAddress -bool true
  sudo -u franny defaults write com.apple.SetupAssistant DidSeeTrueTonePrivacy -bool true
  sudo -u franny defaults write com.apple.SetupAssistant SkipFirstLoginOptimization -bool true
  echo "→ franny user created"
fi

sudo defaults write /Library/Preferences/com.apple.loginwindow autoLoginUser franny
sudo /usr/bin/python3 -c "
import struct
passwd = 'franny'
key = [125,137,82,35,210,188,221,234,163,185,31]
padded = (passwd + '\0' * (len(key) - len(passwd) % len(key))).encode()
encrypted = bytes([b ^ key[i % len(key)] for i, b in enumerate(padded)])
with open('/etc/kcpassword', 'wb') as f:
    f.write(encrypted)
" && sudo chmod 600 /etc/kcpassword

sudo -u franny defaults write com.apple.dock autohide -bool true
sudo -u franny defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false

if [ ! -f /opt/homebrew/bin/brew ]; then
  echo "→ installing homebrew..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

sudo systemsetup -setremotelogin on 2>/dev/null || true

echo "✓ franny baked into image"
