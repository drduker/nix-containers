# Base configuration shared across all container images
{ cacert, lib, ... }:

{
  # Base packages that should be included in all images
  basePackages = [ cacert ];
  
  # Default environment variables for all containers
  defaultEnv = [
    "SSL_CERT_FILE=${cacert}/etc/ssl/certs/ca-bundle.crt"
  ];
  
  # Default labels for all containers
  defaultLabels = {
    "org.opencontainers.image.source" = "https://github.com/drduker/nix-containers";
    "org.label-schema.vcs-url" = "https://github.com/drduker/nix-containers";
  };
}