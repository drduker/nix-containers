{ buildCLIImage, kubectl, nonRoot, ... }:

buildCLIImage {
  # The derivation or package you want in the image
  drv = kubectl;

  # Optional: override the command/entrypoint  
  entrypoint = [ "kubectl" ];
  cmd = [ "--help" ];

  # Optional: environment variables baked into the image
  env = {
    KUBECONFIG = "/home/${nonRoot.user.name}/.kube/config";
    LANG = "C.UTF-8";
  };

  # Optional: labels for OCI metadata
  labels = {
    "org.opencontainers.image.title" = "kubectl";
    "org.opencontainers.image.source" = "https://github.com/kubernetes/kubectl";
    "org.opencontainers.image.version" = kubectl.version;
  };

  # Optional: user/group to run as
  user = nonRoot.userString; # non-root
}