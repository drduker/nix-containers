{ nix2container, lib, buildEnv, pkgs, base, nonRoot, ... }:

let
  # SOPS tools and dependencies
  sopsPackages = with pkgs; [
    bash
    coreutils
    git
    sops
    jq
    kubectl
    vim
    gnupg
  ];

  # Use default non-root user environment
  userEnv = nonRoot.mkDefaultUserEnv pkgs [];

in
nix2container.buildImage {
  name = "sops-base";
  tag = "latest";

  copyToRoot = [
    (buildEnv {
      name = "sops-root";
      paths = base.basePackages ++ sopsPackages ++ [ userEnv ];
    })
  ];

  config = nonRoot.defaultConfig // {
    Env = base.defaultEnv ++ nonRoot.userEnv ++ [
      "PATH=${lib.makeBinPath sopsPackages}"
      "GNUPGHOME=~/.gnupg"
    ];
    Labels = base.defaultLabels;
  };
}