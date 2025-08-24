{ nix2container, lib, buildEnv, pkgs, base, nonRoot, ... }:

let
  # Bash packages
  bashPackages = with pkgs; [
    bash
    coreutils
  ];

  # Use default non-root user environment
  userEnv = nonRoot.mkDefaultUserEnv pkgs [];

in
nix2container.buildImage {
  name = "bash";
  tag = "latest";

  copyToRoot = [
    (buildEnv {
      name = "bash-root";
      paths = base.basePackages ++ bashPackages ++ [ userEnv ];
    })
  ];

  config = nonRoot.defaultConfig // {
    Cmd = [ "${pkgs.bash}/bin/bash" ];
    Env = base.defaultEnv ++ nonRoot.userEnv ++ [
      "PATH=${lib.makeBinPath bashPackages}"
    ];
    Labels = base.defaultLabels;
  };
}
