{ nix2container, lib, buildEnv, pkgs, base, nonRoot, ... }:

let
  # Caddy packages
  caddyPackages = with pkgs; [
    caddy
    bash
    coreutils
  ];

  # Use default non-root user environment
  userEnv = nonRoot.mkDefaultUserEnv pkgs [];

in
nix2container.buildImage {
  name = "caddy";
  tag = "latest";

  copyToRoot = [
    (buildEnv {
      name = "caddy-root";
      paths = base.basePackages ++ caddyPackages ++ [ userEnv ];
    })
  ];

  config = nonRoot.defaultConfig // {
    Env = base.defaultEnv ++ nonRoot.userEnv ++ [
      "PATH=${lib.makeBinPath caddyPackages}"
    ];
    Labels = base.defaultLabels;
  };
}
