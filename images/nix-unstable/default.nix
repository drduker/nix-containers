{ nix2container, lib, buildEnv, pkgs, base, nonRoot, ... }:

let
  # nix-unstable packages
  nix_unstablePackages = with pkgs; [
    nixVersions.latest
    bash
    coreutils
  ];

  # Use default non-root user environment
  userEnv = nonRoot.mkDefaultUserEnv pkgs [];

in
nix2container.buildImage {
  name = "nix-unstable";
  tag = "latest";

  copyToRoot = [
    (buildEnv {
      name = "nix-unstable-root";
      paths = base.basePackages ++ nix_unstablePackages ++ [ userEnv ];
    })
  ];

  config = nonRoot.defaultConfig // {
    Env = base.defaultEnv ++ nonRoot.userEnv ++ [
      "PATH=${lib.makeBinPath nix_unstablePackages}"
    ];
    Labels = base.defaultLabels;
  };
}
