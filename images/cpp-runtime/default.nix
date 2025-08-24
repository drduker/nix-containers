{ mkUserEnvironment, nix2container, lib, buildEnv, pkgs, base, nonRoot, ... }:

let
  # Minimal runtime packages - only what's needed to run C++ and Rust binaries
  runtimePkgs = with pkgs; [
    glibc
    openssl.out
    gcc.cc.lib    # Runtime C++ standard library
    bash
    coreutils
  ];

  # Create user environment with non-root user
  userEnv = mkUserEnvironment {
    user = nonRoot.user;
    workingDir = "/app";
  };

in
nix2container.buildImage {
  name = "cpp-runtime";
  tag = "latest";

  copyToRoot = [
    (buildEnv {
      name = "runtime-root";
      paths = base.basePackages ++ runtimePkgs ++ [ userEnv ];
    })
  ];

  config = {
    Cmd = [ "${pkgs.bash}/bin/bash" ];
    WorkingDir = "/app";
    User = nonRoot.userString;
    Env = base.defaultEnv ++ nonRoot.userEnv ++ [
      "PATH=${lib.makeBinPath runtimePkgs}"
      "LD_LIBRARY_PATH=${pkgs.glibc}/lib:${pkgs.openssl.out}/lib:${pkgs.gcc.cc.lib}/lib"
    ];
    Labels = base.defaultLabels;
  };
}