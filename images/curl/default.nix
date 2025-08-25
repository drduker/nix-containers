{ nix2container, lib, buildEnv, pkgs, base, nonRoot, ... }:

let
  # curl packages
  curlPackages = with pkgs; [
    curl
    bash
    coreutils
  ];

  # Use default non-root user environment
  userEnv = nonRoot.mkDefaultUserEnv pkgs [];

in
nix2container.buildImage {
  name = "curl";
  tag = "latest";

  copyToRoot = [
    (buildEnv {
      name = "curl-root";
      paths = base.basePackages ++ curlPackages ++ [ userEnv ];
    })
  ];

  config = nonRoot.defaultConfig // {
    Env = base.defaultEnv ++ nonRoot.userEnv ++ [
      "PATH=${lib.makeBinPath curlPackages}"
    ];
    Labels = base.defaultLabels;
  };
}
