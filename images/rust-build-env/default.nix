{ mkUserEnvironment, nix2container, lib, buildEnv, pkgs, base, nonRoot, ... }:

let
  # Rust packages - Added binutils for linker
  rustBuildPkgs = with pkgs; [
    rustc
    cargo
    rustfmt
    rust-analyzer
    clippy
    gcc          # C compiler
    binutils     # Includes ld (linker)
    glibc.dev    # C library headers
    openssl
    openssl.dev
    pkg-config
    bash
    coreutils
    findutils
    which
    file
  ];

  # Create user environment with non-root user
  userEnv = mkUserEnvironment {
    user = nonRoot.user;
    workingDir = "/workspace";
    extraDirs = [ "/app" ];
  };

in
nix2container.buildImage {
  name = "rust-build-env";
  tag = "latest";

  copyToRoot = [
    (buildEnv {
      name = "rust-build-root";
      paths = base.basePackages ++ rustBuildPkgs ++ [ userEnv ];
    })
  ];

  config = {
    Cmd = [ "${pkgs.bash}/bin/bash" ];
    WorkingDir = "/workspace";
    User = nonRoot.userString;
    Env = base.defaultEnv ++ nonRoot.userEnv ++ [
      "PATH=${lib.makeBinPath rustBuildPkgs}"
      "CARGO_HTTP_CAINFO=${(builtins.head base.basePackages)}/etc/ssl/certs/ca-bundle.crt"
      # Cargo home directory for the non-root user
      "CARGO_HOME=/home/${nonRoot.user.name}/.cargo"
      # C compiler and linker configuration
      "CC=${pkgs.gcc}/bin/gcc"
      "CXX=${pkgs.gcc}/bin/g++"
      "LD=${pkgs.binutils}/bin/ld"
      "AR=${pkgs.binutils}/bin/ar"
      "STRIP=${pkgs.binutils}/bin/strip"
      # OpenSSL for Rust crates
      "OPENSSL_DIR=${pkgs.openssl.dev}"
      "OPENSSL_LIB_DIR=${pkgs.openssl.out}/lib"
      "OPENSSL_INCLUDE_DIR=${pkgs.openssl.dev}/include"
      "PKG_CONFIG_PATH=${pkgs.openssl.dev}/lib/pkgconfig:${lib.makeSearchPathOutput "dev" "lib/pkgconfig" rustBuildPkgs}"
      # Library path for linking
      "LIBRARY_PATH=${pkgs.glibc}/lib:${pkgs.gcc.cc.lib}/lib"
      "LD_LIBRARY_PATH=${pkgs.glibc}/lib:${pkgs.gcc.cc.lib}/lib"
    ];
    Labels = base.defaultLabels;
  };
}