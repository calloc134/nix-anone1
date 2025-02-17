{ config, pkgs, ... }:

{
  # RAM-only filesystem configuration
  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
    options = [ "size=8G" "mode=755" ];
  };

  # Basic system configuration
  boot = {
    kernelParams = [ "boot.shell_on_fail" ];
    loader.grub.enable = false;
    loader.systemd-boot.enable = true;
    supportedFilesystems = [ "tmpfs" ];
  };

  # Network configuration with Tor
  networking = {
    networkmanager = {
      enable = true;
      # wifi.backend = "iwd"; # この行を削除
    };
    # wireless関連の設定はNetworkManagerに任せる
    wireless.enable = false;    # 明示的に無効化
    wireless.iwd.enable = false; # 明示的に無効化
    
    firewall = {
      enable = true;
      allowedTCPPorts = [ 9050 9051 ];
    };
  };

  # NetworkManagerのWi-Fi管理を有効化
  programs.nm-applet.enable = true;  # NetworkManagerのGUIツール

  # Enable Tor service
  services = {
    tor = {
      enable = true;
      client.enable = true;
      torsocks.enable = true;
    };
    # Enable X11 and desktop environment
    xserver = {
      enable = true;
      displayManager.lightdm.enable = true;
      desktopManager.cinnamon.enable = true;
    };
  };

  # Modern audio configuration using PipeWire
  security.rtkit.enable = true;  # リアルタイムスケジューリングのために必要
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;        # PulseAudioの互換レイヤーを有効化
  };
  # sound.enable = true;        # 削除：非推奨オプション
  # hardware.pulseaudio.enable = true;  # 削除：PipeWireと競合

  # User configuration
  users.users.calloc134 = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    initialPassword = "nixos";
  };

  # System packages
  environment.systemPackages = with pkgs; [
    firefox-esr
    # veracrypt
    git
    wget
    vim
    # torsocks
  ];

  
  # Enable transparent proxy through Tor
  networking.nameservers = [ "127.0.0.1" ];
  services.tor.settings = {
    DNSPort = 53;        # 文字列"53"から数値53に変更
    TransPort = 9040;    # 一貫性のため、こちらも数値として設定
  };

  # Configure firewall to redirect all traffic through Tor
  networking.firewall.extraCommands = ''
    # Clear existing rules
    iptables -F
    iptables -t nat -F

    # Don't route Tor traffic through itself
    iptables -t nat -A OUTPUT -m owner --uid-owner tor -j RETURN

    # Route DNS through Tor
    iptables -t nat -A OUTPUT -p udp --dport 53 -j REDIRECT --to-ports 53
    iptables -t nat -A OUTPUT -p tcp --dport 53 -j REDIRECT --to-ports 53

    # Route all TCP traffic through Tor
    iptables -t nat -A OUTPUT -p tcp --syn -j REDIRECT --to-ports 9040

    # Allow only Tor traffic
    iptables -A OUTPUT -m owner --uid-owner tor -j ACCEPT
    iptables -A OUTPUT -j REJECT
  '';

  # System configuration
  system.stateVersion = "23.11";
}