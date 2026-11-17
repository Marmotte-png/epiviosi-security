{
  description = "EPIVÍOSI SECURITY — chiffrement, vie privée et documentation hors-ligne pour EPIVÍOSI OS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
  };

  outputs =
    { self, nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      # Implémente `epiviosi.security.enable` (option déclarée par le socle EPIVÍOSI OS).
      nixosModules.default = import ./module.nix;

      checks.${system}.vm = import ./tests/security.nix {
        inherit pkgs;
        module = self.nixosModules.default;
      };
    };
}
