{ nix2container, lib, buildEnv, pkgs, base, nonRoot, ... }:

let
  # pocket-id packages
  pocket_idPackages = with pkgs; [
    pocket-id
    bash
    coreutils
  ];

  # Use default non-root user environment
  userEnv = nonRoot.mkDefaultUserEnv pkgs [];

in
nix2container.buildImage {
  name = "pocket-id";
  tag = "latest";

  copyToRoot = [
    (buildEnv {
      name = "pocket-id-root";
      paths = base.basePackages ++ pocket_idPackages ++ [ userEnv ];
    })
  ];

  config = nonRoot.defaultConfig // {
    Env = base.defaultEnv ++ nonRoot.userEnv ++ [
      "PATH=${lib.makeBinPath pocket_idPackages}"
    ];
    Labels = base.defaultLabels;
  };
}
