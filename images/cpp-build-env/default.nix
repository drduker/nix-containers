{ mkUserEnvironment, nix2container, lib, buildEnv, pkgs, base, nonRoot, ... }:

let
  # C++ build packages - collect for convenience
  buildPackages = with pkgs; [
    gcc
    cmake
    gnumake
    openssl
    openssl.dev
    gtest
    gtest.dev
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
  name = "cpp-build-env";
  tag = "latest";

  copyToRoot = [
    (buildEnv {
      name = "cpp-build-root";
      paths = base.basePackages ++ buildPackages ++ [ userEnv ];
    })
  ];

  config = {
    Cmd = [ "${pkgs.bash}/bin/bash" ];
    WorkingDir = "/workspace";
    User = nonRoot.userString;
    Env = base.defaultEnv ++ nonRoot.userEnv ++ [
      "PATH=${lib.makeBinPath buildPackages}"
      # OpenSSL environment variables for CMake
      "OPENSSL_ROOT_DIR=${pkgs.openssl.dev}"
      "OPENSSL_INCLUDE_DIR=${pkgs.openssl.dev}/include"
      "OPENSSL_CRYPTO_LIBRARY=${pkgs.openssl.out}/lib/libcrypto.so"
      "OPENSSL_SSL_LIBRARY=${pkgs.openssl.out}/lib/libssl.so"
      # GTest environment variables for CMake
      "GTEST_ROOT=${pkgs.gtest.dev}"
      "GTEST_INCLUDE_DIR=${pkgs.gtest.dev}/include"
      "GTEST_LIBRARY=${pkgs.gtest}/lib/libgtest.so.1.17.0"
      "GTEST_MAIN_LIBRARY=${pkgs.gtest}/lib/libgtest_main.so.1.17.0"
      # PKG_CONFIG path
      "PKG_CONFIG_PATH=${pkgs.openssl.dev}/lib/pkgconfig:${pkgs.gtest.dev}/lib/pkgconfig:${lib.makeSearchPathOutput "dev" "lib/pkgconfig" buildPackages}"
    ];
    Labels = base.defaultLabels;
  };
}