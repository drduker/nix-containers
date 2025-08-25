{ nix2container, lib, buildEnv, pkgs, base, nonRoot, ... }:

let
  # cachix-flakes packages
  cachix_flakesPackages = with pkgs; [
    cachix
    bash
    coreutils
  ];

  # Use default non-root user environment
  userEnv = nonRoot.mkDefaultUserEnv pkgs [];

in
nix2container.buildImage {
  name = "cachix-flakes";
  tag = "latest";

  copyToRoot = [
    (buildEnv {
      name = "cachix-flakes-root";
      paths = base.basePackages ++ cachix_flakesPackages ++ [ userEnv ];
    })
  ];

  config = nonRoot.defaultConfig // {
    Env = base.defaultEnv ++ nonRoot.userEnv ++ [
      "PATH=${lib.makeBinPath cachix_flakesPackages}"
    ];
    Labels = base.defaultLabels;
  };
}
