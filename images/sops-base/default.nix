{ mkUserEnvironment, nix2container, lib, buildEnv, pkgs, base, nonRoot, ... }:

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

  # Create user environment with non-root user  
  userEnv = mkUserEnvironment {
    user = nonRoot.user;
    workingDir = "/app";
    extraDirs = [ "/workspace" ];
  };

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

  config = {
    Cmd = [ "${pkgs.bash}/bin/bash" ];
    WorkingDir = "/app";
    User = nonRoot.userString;
    Env = base.defaultEnv ++ nonRoot.userEnv ++ [
      "PATH=${lib.makeBinPath sopsPackages}"
      "GNUPGHOME=/workspace/.gnupg"
    ];
    Labels = base.defaultLabels;
  };
}