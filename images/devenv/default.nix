{ nix2container, lib, buildEnv, pkgs, base, nonRoot, ... }:

let
  # devenv packages
  devenvPackages = with pkgs; [
    devenv
    bash
    coreutils
  ];

  # Use default non-root user environment
  userEnv = nonRoot.mkDefaultUserEnv pkgs [];

in
nix2container.buildImage {
  name = "devenv";
  tag = "latest";

  copyToRoot = [
    (buildEnv {
      name = "devenv-root";
      paths = base.basePackages ++ devenvPackages ++ [ userEnv ];
    })
  ];

  config = nonRoot.defaultConfig // {
    Env = base.defaultEnv ++ nonRoot.userEnv ++ [
      "PATH=${lib.makeBinPath devenvPackages}"
    ];
    Labels = base.defaultLabels;
  };
}
