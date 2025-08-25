{ nix2container, lib, buildEnv, pkgs, base, nonRoot, ... }:

let
  # nginx packages
  nginxPackages = with pkgs; [
    nginx
    bash
    coreutils
  ];

  # Use default non-root user environment
  userEnv = nonRoot.mkDefaultUserEnv pkgs [];

in
nix2container.buildImage {
  name = "nginx";
  tag = "latest";

  copyToRoot = [
    (buildEnv {
      name = "nginx-root";
      paths = base.basePackages ++ nginxPackages ++ [ userEnv ];
    })
  ];

  config = nonRoot.defaultConfig // {
    Env = base.defaultEnv ++ nonRoot.userEnv ++ [
      "PATH=${lib.makeBinPath nginxPackages}"
    ];
    Labels = base.defaultLabels;
  };
}
