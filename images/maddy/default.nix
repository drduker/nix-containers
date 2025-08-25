{ nix2container, lib, buildEnv, pkgs, base, nonRoot, ... }:

let
  # maddy packages
  maddyPackages = with pkgs; [
    maddy
    bash
    coreutils
  ];

  # Use default non-root user environment
  userEnv = nonRoot.mkDefaultUserEnv pkgs [];

in
nix2container.buildImage {
  name = "maddy";
  tag = "latest";

  copyToRoot = [
    (buildEnv {
      name = "maddy-root";
      paths = base.basePackages ++ maddyPackages ++ [ userEnv ];
    })
  ];

  config = nonRoot.defaultConfig // {
    Env = base.defaultEnv ++ nonRoot.userEnv ++ [
      "PATH=${lib.makeBinPath maddyPackages}"
    ];
    Labels = base.defaultLabels;
  };
}
