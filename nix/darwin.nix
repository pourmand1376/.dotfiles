# macOS system config (nix-darwin). Applied with ./apply.sh (darwin-rebuild switch).
{ pkgs, ... }:
{
  nixpkgs.hostPlatform = "aarch64-darwin";
  system.stateVersion = 7;
  system.primaryUser = "amirpourmand";

  # Determinate Nix manages the nix daemon and /etc/nix/nix.conf
  nix.enable = false;

  # CLI tools -> /run/current-system/sw/bin, GUI apps -> /Applications/Nix Apps
  environment.systemPackages =
    import ./packages.nix pkgs
    ++ (with pkgs; [
      iina
      keka
      keycastr
      macshot
      mos
      unnaturalscrollwheels
    ]);

  # fonts -> /Library/Fonts/Nix Fonts
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.meslo-lg
    nerd-fonts.symbols-only
    (noto-fonts.override { variants = [ "NotoSansArabic" ]; })
  ];

  # ---------------------------------------------------------------- Homebrew
  # nix-darwin writes a Brewfile from this and runs `brew bundle` on switch.
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = false; # `./apply.sh update` runs brew update/upgrade
      upgrade = false;
      cleanup = "none"; # unlisted brew apps are left alone
    };

    taps = [
      "appautomaton/tap"
      "ankitpokhrel/jira-cli"
      {
        name = "asmvik/formulae";
        clone_target = "https://github.com/asmvik/homebrew-formulae.git";
      }
      "atlassian/acli"
      "nikitabobko/tap"
      "tw93/tap"
      "y3owk1n/tap"
    ];

    # formulae nixpkgs can't provide on macOS
    brews = [
      "coder" # nixpkgs has no cached build
      "atlassian/acli/acli" # nixpkgs: not available on aarch64-darwin
      "container" # Apple's container runtime
      "appautomaton/tap/docker-for-apple-container" # not in nixpkgs
      "mole" # nixpkgs: not available on aarch64-darwin
      "wtfutil" # nixpkgs: not available on aarch64-darwin
      "mas" # used by brew bundle to install masApps below
      "gemini-cli" # nixpkgs marks it for removal
      "fastfetch" # nix build pulls in ~1 GB of compiler toolchain
    ];

    # GUI apps nixpkgs lacks, ships older, or that install system drivers/helpers
    casks = [
      "codex" # nix build is ~200 MB bigger than the cask
      "wezterm" # nix build pulls in ~1 GB of compiler toolchain
      "flashspace" # nixpkgs 3.3.39 is older than the 4.x you run
      "hammerspoon" # not in nixpkgs
      "karabiner-elements" # installs a DriverKit system extension
      "keyclu" # not in nixpkgs
      "y3owk1n/tap/neru" # not in nixpkgs
      "orbstack" # privileged helper + own updater
      "pearcleaner" # not in nixpkgs
      "visual-studio-code" # needed by the vscode extension lines below
    ];

    # App Store (needs you signed in to the App Store; installs only apps your Apple ID already has)
    masApps = {
      "TickTick" = 966085870;
      "Roozegar" = 1171425651;
      "Windows App" = 1295203466;
      "Tacque" = 6778518424;
    };

    # Brewfile lines nix-darwin has no option for
    extraConfig = ''
      vscode "anthropic.claude-code"
      vscode "esbenp.prettier-vscode"
      vscode "google.geminicodeassist"
      vscode "inferrinizzard.prettier-sql-vscode"
      vscode "ms-python.black-formatter"
      vscode "ms-python.debugpy"
      vscode "ms-python.isort"
      vscode "ms-python.python"
      vscode "ms-python.vscode-pylance"
      vscode "ms-python.vscode-python-envs"
      vscode "ms-toolsai.jupyter"
      vscode "ms-toolsai.jupyter-keymap"
      vscode "ms-toolsai.jupyter-renderers"
      vscode "ms-toolsai.vscode-jupyter-cell-tags"
      vscode "ms-toolsai.vscode-jupyter-slideshow"
      vscode "ms-vscode-remote.remote-ssh"
      vscode "ms-vscode-remote.remote-ssh-edit"
      vscode "ms-vscode.live-server"
      vscode "ms-vscode.makefile-tools"
      vscode "ms-vscode.remote-explorer"
      uv "gitlab-mr-mcp"
    '';
  };

  # ---------------------------------------------------------- macOS settings
  # (was macbook/defaults.sh and macbook/dockutils.sh)
  system.defaults = {
    dock = {
      orientation = "left";
      autohide = true;
      show-recents = false;
      wvous-tl-corner = 2; # top-left: Mission Control
      wvous-tr-corner = 12; # top-right: Notification Center
      persistent-apps = [
        "/System/Applications/Apps.app"
        "/System/Applications/Mail.app"
        "/Applications/Discord.app"
        "/Applications/TickTick.app"
        "/System/Applications/Calendar.app"
        "/Applications/Obsidian.app"
        "/Applications/Google Chrome.app"
        "/Applications/Microsoft Edge.app"
        "/Applications/WezTerm.app"
      ];
    };

    finder = {
      QuitMenuItem = true;
      ShowPathbar = true;
      ShowStatusBar = true;
      FXDefaultSearchScope = "SCcf"; # search the current folder
    };

    NSGlobalDomain = {
      KeyRepeat = 1;
      InitialKeyRepeat = 10;
    };

    LaunchServices.LSQuarantine = false; # no "Are you sure you want to open" dialog

    ActivityMonitor = {
      OpenMainWindow = true;
      IconType = 5; # CPU usage in the Dock icon
      SortColumn = "CPUUsage";
      SortDirection = 0;
    };

    # settings nix-darwin has no typed option for
    CustomUserPreferences = {
      "com.apple.dock" = {
        wvous-tl-modifier = 0;
        wvous-tr-modifier = 0;
      };
      "com.apple.HIToolbox".AppleFnUsageType = 1; # fn key changes input language
      NSGlobalDomain.AppleKeyboardUIMode = 2; # Tab moves focus between controls
      "com.apple.desktopservices".DSDontWriteNetworkStores = true;
      "com.apple.ActivityMonitor".ShowCategory = 0; # all processes
      "com.apple.Safari" = {
        IncludeDevelopMenu = true;
        WebKitDeveloperExtrasEnabledPreferenceKey = true;
        "com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled" = true;
      };
    };
  };
}
