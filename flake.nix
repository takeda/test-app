{
  description = "test-app";

  inputs = {
#    nixpkgs.url = "github:nixos/nixpkgs/09f5e7d840154e63b710ece7c66a4d4a130b14d3"; # working
    nixpkgs.url = "github:nixos/nixpkgs/8eff2eea8cbe5893055e1dc831f49c4a40d60179"; # broken
    flake-utils.url = "github:numtide/flake-utils";
    nix-cde.url = "github:takeda/nix-cde";
    nix-cde.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, flake-utils, nix-cde, nixpkgs }: flake-utils.lib.eachDefaultSystem (build_system:
  let
    cde = is_shell: nix-cde.lib.mkCDE ./project.nix { inherit build_system is_shell self; };
    cde-musl = nix-cde.lib.mkCDE ./project.nix {
      inherit build_system self;
      host_system = "x86_64-linux";
      cross_system = nixpkgs.lib.systems.examples.musl64;
    };
  in rec {
    packages.default = (cde false).outputs.out_python;
    packages.docker = cde-musl.outputs.out_docker;
    devShells.default = (cde true).outputs.out_shell;
  });
}
