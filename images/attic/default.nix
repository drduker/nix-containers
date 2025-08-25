{ nix2container, lib, buildEnv, pkgs, base, nonRoot, ... }:

let
  # Attic packages
  atticPackages = with pkgs; [
    attic-client
    bash
    coreutils
  ];

  # Use default non-root user environment
  userEnv = nonRoot.mkDefaultUserEnv pkgs [];

in
nix2container.buildImage {
  name = "attic";
  tag = "latest";

  copyToRoot = [
    (buildEnv {
      name = "attic-root";
      paths = base.basePackages ++ atticPackages ++ [ userEnv ];
    })
  ];

  config = nonRoot.defaultConfig // {
    Env = base.defaultEnv ++ nonRoot.userEnv ++ [
      "PATH=${lib.makeBinPath atticPackages}"
    ];
    Labels = base.defaultLabels;
  };
}
