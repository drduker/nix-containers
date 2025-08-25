{ nix2container, lib, buildEnv, pkgs, base, nonRoot, ... }:

let
  # docker-compose packages
  docker_composePackages = with pkgs; [
    docker-compose
    bash
    coreutils
  ];

  # Use default non-root user environment
  userEnv = nonRoot.mkDefaultUserEnv pkgs [];

in
nix2container.buildImage {
  name = "docker-compose";
  tag = "latest";

  copyToRoot = [
    (buildEnv {
      name = "docker-compose-root";
      paths = base.basePackages ++ docker_composePackages ++ [ userEnv ];
    })
  ];

  config = nonRoot.defaultConfig // {
    Env = base.defaultEnv ++ nonRoot.userEnv ++ [
      "PATH=${lib.makeBinPath docker_composePackages}"
    ];
    Labels = base.defaultLabels;
  };
}
