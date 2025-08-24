# Legacy shell.nix for nix-shell compatibility
# Prefer using 'nix develop' from flake.nix

{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    nix
    docker
    act
    jq
    git
    gh
    gnumake
    just
  ];

  shellHook = ''
    echo "=€ Nix Containers Development Environment (legacy shell.nix)"
    echo ""
    echo "=æ Local Building:"
    echo "  nix build .#<image-name>                    - Build container image"
    echo "  nix build .#load-<image-name>-to-docker     - Build and load to Docker"
    echo "  nix build .#load-all-to-docker && ./result/bin/load-all-to-docker"
    echo ""
    echo "=3 Docker Commands:"
    echo "  docker images                               - List Docker images"
    echo "  docker run -it <image-name> bash           - Run container interactively"
    echo ""
    echo "= GitHub Actions Testing:"
    echo "  act -l                                      - List available workflows"
    echo "  act -j build-containers                     - Test build workflow locally"
    echo "  act --container-architecture linux/amd64   - Force x86_64 architecture"
    echo ""
    echo "=¡ Quick start:"
    echo "  nix build .#load-cpp-runtime-to-docker     - Example: build and load cpp-runtime"
    echo ""
    echo "   Note: Consider using 'nix develop' instead for better flake integration"
  '';
}