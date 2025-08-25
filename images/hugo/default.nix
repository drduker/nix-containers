{ nix2container, lib, buildEnv, pkgs, base, nonRoot, ... }:

let
  # hugo packages
  hugoPackages = with pkgs; [
    hugo
    bash
    coreutils
  ];

  # Use default non-root user environment
  userEnv = nonRoot.mkDefaultUserEnv pkgs [];

in
nix2container.buildImage {
  name = "hugo";
  tag = "latest";

  copyToRoot = [
    (buildEnv {
      name = "hugo-root";
      paths = base.basePackages ++ hugoPackages ++ [ userEnv ];
    })
  ];

  config = nonRoot.defaultConfig // {
    Env = base.defaultEnv ++ nonRoot.userEnv ++ [
      "PATH=${lib.makeBinPath hugoPackages}"
    ];
    Labels = base.defaultLabels;
  };
}
