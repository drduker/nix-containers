{ nix2container, lib, buildEnv, pkgs, base, nonRoot, ... }:

let
  # nix-unstable-static packages
  nix_unstable_staticPackages = with pkgs; [
    nixVersions.unstable
    bash
    coreutils
  ];

  # Use default non-root user environment
  userEnv = nonRoot.mkDefaultUserEnv pkgs [];

in
nix2container.buildImage {
  name = "nix-unstable-static";
  tag = "latest";

  copyToRoot = [
    (buildEnv {
      name = "nix-unstable-static-root";
      paths = base.basePackages ++ nix_unstable_staticPackages ++ [ userEnv ];
    })
  ];

  config = nonRoot.defaultConfig // {
    Env = base.defaultEnv ++ nonRoot.userEnv ++ [
      "PATH=${lib.makeBinPath nix_unstable_staticPackages}"
    ];
    Labels = base.defaultLabels;
  };
}
