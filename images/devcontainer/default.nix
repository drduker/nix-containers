{ nix2container, lib, buildEnv, pkgs, base, nonRoot, ... }:

let
  # devcontainer packages
  devcontainerPackages = with pkgs; [
    devcontainer
    bash
    coreutils
  ];

  # Use default non-root user environment
  userEnv = nonRoot.mkDefaultUserEnv pkgs [];

in
nix2container.buildImage {
  name = "devcontainer";
  tag = "latest";

  copyToRoot = [
    (buildEnv {
      name = "devcontainer-root";
      paths = base.basePackages ++ devcontainerPackages ++ [ userEnv ];
    })
  ];

  config = nonRoot.defaultConfig // {
    Env = base.defaultEnv ++ nonRoot.userEnv ++ [
      "PATH=${lib.makeBinPath devcontainerPackages}"
    ];
    Labels = base.defaultLabels;
  };
}
