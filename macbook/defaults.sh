# https://macos-defaults.com/
#
# dock to the bottom
defaults write com.apple.dock "orientation" -string "left" && killall Dock
defaults write com.apple.dock "autohide" -bool "true" && killall Dock
defaults write com.apple.dock "show-recents" -bool "false" && killall Dock

# Set the icon size of Dock items to 36 pixels
# defaults write com.apple.dock tilesize -int 36

# Top left screen corner → Notification Center
defaults write com.apple.dock wvous-tl-corner -int 2
defaults write com.apple.dock wvous-tl-modifier -int 0

# top right corent -> mission control
defaults write com.apple.dock wvous-tr-corner -int 12
defaults write com.apple.dock wvous-tr-modifier -int 0

# Display the Finder "Quit" option
defaults write com.apple.finder "QuitMenuItem" -bool "true" && killall Finder

# Show path bar in the bottom of the Finder windows
defaults write com.apple.finder "ShowPathbar" -bool "true" && killall Finder

# Set the default search scope when performing a search. Search the current folder
defaults write com.apple.finder "FXDefaultSearchScope" -string "SCcf" && killall Finder

# Show status bar in the bottom of the Finder windows
defaults write com.apple.finder "ShowStatusBar" -bool "true" && killall Finder

# fn key to change language
defaults write com.apple.HIToolbox AppleFnUsageType -int "1"

# enable focus changing with tab , shift+tab
defaults write NSGlobalDomain AppleKeyboardUIMode -int "2"

# Disable the "Are you sure you want to open this application?" dialog
defaults write com.apple.LaunchServices LSQuarantine -bool false

# Set a blazingly fast keyboard repeat rate
# https://dev.to/tomgranot/quick-tip-increase-keyboard-repeat-rate-for-faster-typing-4d8g
defaults write NSGlobalDomain KeyRepeat -int 1
defaults write NSGlobalDomain InitialKeyRepeat -int 10

# Avoid creating .DS_Store files on network volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true

# Enable the Develop menu and the Web Inspector in Safari
defaults write com.apple.Safari IncludeDevelopMenu -bool true
defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled -bool true

# Show the main window when launching Activity Monitor
defaults write com.apple.ActivityMonitor OpenMainWindow -bool true

# Visualize CPU usage in the Activity Monitor Dock icon
defaults write com.apple.ActivityMonitor IconType -int 5

# Show all processes in Activity Monitor
defaults write com.apple.ActivityMonitor ShowCategory -int 0

# Sort Activity Monitor results by CPU usage
defaults write com.apple.ActivityMonitor SortColumn -string "CPUUsage"
defaults write com.apple.ActivityMonitor SortDirection -int 0

# for app in "Activity Monitor" "Address Book" "Calendar" "Contacts" "cfprefsd" \
#   "Dock" "Finder" "Mail" "Messages" "Safari" "SizeUp" "SystemUIServer" \
#   "Terminal" "Transmission" "Twitter" "iCal"; do
#   killall "${app}" >/dev/null 2>&1
# done
