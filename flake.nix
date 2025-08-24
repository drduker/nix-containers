{
  description = "Nix Container Images Collection";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix2container.url = "github:nlewo/nix2container";
    nix2container.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, nix2container }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      # Import lib functions following docker-nixpkgs pattern
      lib = {
        base = pkgs.callPackage ./lib/base.nix {};
        nonRoot = pkgs.callPackage ./lib/nonRoot.nix {};
        buildCLIImage = pkgs.callPackage ./lib/buildCLIImage.nix { 
          nix2container = nix2container.packages.${system}.nix2container;
          inherit (pkgs) lib;
          base = pkgs.callPackage ./lib/base.nix {};
        };
        mkUserEnvironment = pkgs.callPackage ./lib/mkUserEnvironment.nix {};
        importDir = pkgs.callPackage ./lib/importDir.nix {};
      };

      # Dynamically discover and import all image folders in images/
      imagesPath = ./images;
      images = lib.importDir imagesPath (imagePath: 
        pkgs.callPackage imagePath {
          inherit (lib) buildCLIImage mkUserEnvironment base nonRoot;
          nix2container = nix2container.packages.${system}.nix2container;
          inherit pkgs;
        }
      );
      
      # Get image names for helper scripts
      imageNames = builtins.attrNames images;

      # Helper script to load all images to Docker at once
      loadAllScript = pkgs.writeShellScript "load-all-images" ''
        echo "🔄 Loading all container images to Docker..."
        
        ${pkgs.lib.concatStringsSep "\n" (pkgs.lib.mapAttrsToList (name: image: ''
          echo "🔄 Loading ${name} to Docker..."
          ${image.copyToDockerDaemon}/bin/copy-to-docker-daemon
        '') images)}
        
        echo "✅ All images loaded successfully!"
        echo ""
        echo "Available Docker images:"
        docker images | grep -E "(${pkgs.lib.concatStringsSep "|" imageNames})" || echo "No images found (run 'docker images' to verify)"
      '';

    in {
      packages.${system} = images // 
        # Dynamically generate Docker loaders for all images
        (builtins.listToAttrs (map (imageName: {
          name = "load-${imageName}-to-docker";
          value = images.${imageName}.copyToDockerDaemon;
        }) imageNames)) // {
        
        # Load all images at once
        load-all-to-docker = pkgs.stdenv.mkDerivation {
          name = "load-all-to-docker";
          buildCommand = ''
            mkdir -p $out/bin
            cp ${loadAllScript} $out/bin/load-all-to-docker
            chmod +x $out/bin/load-all-to-docker
          '';
        };
      };

      # Development shells for each image
      devShells.${system} = {
        default = pkgs.mkShell {
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
            echo "🚀 Nix Containers Development Environment"
            echo ""
            echo "📦 Local Building:"
            echo "  nix build .#<image-name>                    - Build container image"
            echo "  nix build .#load-<image-name>-to-docker     - Build and load to Docker"
            echo "  nix build .#load-all-to-docker && ./result/bin/load-all-to-docker"
            echo ""
            echo "🐳 Docker Commands:"
            echo "  docker images                               - List Docker images"
            echo "  docker run -it <image-name> bash           - Run container interactively"
            echo ""
            echo "🔄 GitHub Actions Testing:"
            echo "  act -l                                      - List available workflows"
            echo "  act -j build-containers                     - Test build workflow locally"
            echo "  act --container-architecture linux/amd64   - Force x86_64 architecture"
            echo ""
            echo "📊 Scripts:"
            echo "  ./scripts/update-image-stats.sh            - Update README comparison chart"
            echo "  ./scripts/update-readme-images.sh          - Update README available images section"
            echo ""
            echo "📋 Available images:"
            echo "  ${pkgs.lib.concatStringsSep ", " imageNames}"
            echo ""
            echo "💡 Quick start:"
            echo "  nix build .#load-cpp-runtime-to-docker     - Example: build and load cpp-runtime"
          '';
        };
      };
    };
}