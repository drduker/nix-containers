{ buildCLIImage, fetchFromGitHub, buildGoModule, lib, ... }:

let
  version = "0.16.1";
  externalDns = buildGoModule {
    pname = "external-dns";
    inherit version;

    src = fetchFromGitHub {
      owner = "kubernetes-sigs";
      repo = "external-dns";
      rev = "v${version}";
      hash = "sha256-5SoqRYKS506vVI8RsuAGrlKR/6OuuZkzO5U8cAMv51I=";
    };

    vendorHash = "sha256-TwuJ4WRCBWpFm5Xeeh8FqGw6cyEQEGN6wjCWxvq2HL0=";

    env.CGO_ENABLED = 0;

    postInstall = ''
      mkdir -p $out/usr/bin
      mv $out/bin/external-dns $out/usr/bin/external-dns
      rm -rf $out/bin
    '';

    doCheck = false;

    meta = with lib; {
      description = "Configure external DNS servers (AWS Route53, Google CloudDNS and others) for Kubernetes Ingresses and Services";
      homepage = "https://github.com/kubernetes-sigs/external-dns";
      license = licenses.asl20;
    };
  };

in
buildCLIImage {
  # The derivation containing our binary  
  drv = externalDns;
  
  # Optional: override defaults
  name = "external-dns";
  tag = "v${version}";
  entrypoint = [ "/usr/bin/external-dns" ];
  cmd = [ "--help" ];
  
  # Optional: environment variables
  env = {
    LANG = "C.UTF-8";
  };
  
  # Optional: labels for OCI metadata
  labels = {
    "org.opencontainers.image.title" = "external-dns";
    "org.opencontainers.image.description" = "Configure external DNS servers for Kubernetes Ingresses and Services";
    "org.opencontainers.image.version" = version;
  };
}