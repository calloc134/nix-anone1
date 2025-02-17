{
  description = "RAM-only NixOS with Tor and Cinnamon";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: {
    nixosConfigurations.torLive = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
        "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
        ({ config, pkgs, ... }: {
          system.stateVersion = "23.11";
          
          isoImage = {
            edition = "minimal";
            # compressImage = true;
            # makeEFIBootable = true;
            # makeUsbBootable = true;
          };
        })
      ];
    };

    # ISOイメージをパッケージとして公開
    packages.x86_64-linux.default = self.nixosConfigurations.torLive.config.system.build.isoImage;
  };
}