{ nix2container, lib, buildEnv, pkgs, base, nonRoot, ... }:

let
  # Cachix packages
  cachixPackages = with pkgs; [
    cachix
    bash
    coreutils
  ];

  # Use default non-root user environment
  userEnv = nonRoot.mkDefaultUserEnv pkgs [];

in
nix2container.buildImage {
  name = "cachix";
  tag = "latest";

  copyToRoot = [
    (buildEnv {
      name = "cachix-root";
      paths = base.basePackages ++ cachixPackages ++ [ userEnv ];
    })
  ];

  config = nonRoot.defaultConfig // {
    Env = base.defaultEnv ++ nonRoot.userEnv ++ [
      "PATH=${lib.makeBinPath cachixPackages}"
    ];
    Labels = base.defaultLabels;
  };
}
