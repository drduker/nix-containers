{ nix2container, lib, buildEnv, pkgs, base, nonRoot, ... }:

let
  # nix packages
  nixPackages = with pkgs; [
    nix
    bash
    coreutils
  ];

  # Use default non-root user environment
  userEnv = nonRoot.mkDefaultUserEnv pkgs [];

in
nix2container.buildImage {
  name = "nix";
  tag = "latest";

  copyToRoot = [
    (buildEnv {
      name = "nix-root";
      paths = base.basePackages ++ nixPackages ++ [ userEnv ];
    })
  ];

  config = nonRoot.defaultConfig // {
    Env = base.defaultEnv ++ nonRoot.userEnv ++ [
      "PATH=${lib.makeBinPath nixPackages}"
    ];
    Labels = base.defaultLabels;
  };
}
