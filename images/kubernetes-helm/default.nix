{ nix2container, lib, buildEnv, pkgs, base, nonRoot, ... }:

let
  # kubernetes-helm packages
  kubernetes_helmPackages = with pkgs; [
    kubernetes-helm
    bash
    coreutils
  ];

  # Use default non-root user environment
  userEnv = nonRoot.mkDefaultUserEnv pkgs [];

in
nix2container.buildImage {
  name = "kubernetes-helm";
  tag = "latest";

  copyToRoot = [
    (buildEnv {
      name = "kubernetes-helm-root";
      paths = base.basePackages ++ kubernetes_helmPackages ++ [ userEnv ];
    })
  ];

  config = nonRoot.defaultConfig // {
    Env = base.defaultEnv ++ nonRoot.userEnv ++ [
      "PATH=${lib.makeBinPath kubernetes_helmPackages}"
    ];
    Labels = base.defaultLabels;
  };
}
