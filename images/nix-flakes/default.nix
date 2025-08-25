{ nix2container, lib, buildEnv, pkgs, base, nonRoot, ... }:

let
  # nix-flakes packages
  nix_flakesPackages = with pkgs; [
    nix
    bash
    coreutils
  ];

  # Use default non-root user environment
  userEnv = nonRoot.mkDefaultUserEnv pkgs [];

in
nix2container.buildImage {
  name = "nix-flakes";
  tag = "latest";

  copyToRoot = [
    (buildEnv {
      name = "nix-flakes-root";
      paths = base.basePackages ++ nix_flakesPackages ++ [ userEnv ];
    })
  ];

  config = nonRoot.defaultConfig // {
    Env = base.defaultEnv ++ nonRoot.userEnv ++ [
      "PATH=${lib.makeBinPath nix_flakesPackages}"
    ];
    Labels = base.defaultLabels;
  };
}
