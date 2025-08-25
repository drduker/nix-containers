{ nix2container, lib, buildEnv, pkgs, base, nonRoot, ... }:

let
  # BusyBox packages
  busyboxPackages = with pkgs; [
    busybox
  ];

  # Use default non-root user environment
  userEnv = nonRoot.mkDefaultUserEnv pkgs [];

in
nix2container.buildImage {
  name = "busybox";
  tag = "latest";

  copyToRoot = [
    (buildEnv {
      name = "busybox-root";
      paths = base.basePackages ++ busyboxPackages ++ [ userEnv ];
    })
  ];

  config = nonRoot.defaultConfig // {
    Env = base.defaultEnv ++ nonRoot.userEnv ++ [
      "PATH=${lib.makeBinPath busyboxPackages}"
    ];
    Labels = base.defaultLabels;
  };
}
