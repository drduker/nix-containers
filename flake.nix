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
            jq
          ];
          shellHook = ''
            echo "🚀 Nix Containers Development Environment"
            echo "Available commands:"
            echo "  nix build .#<package-name>     - Build a container image"
            echo "  nix build .#load-all-to-docker - Load all images to Docker"
            echo "  docker images                  - List Docker images"
            echo ""
            echo "Available packages:"
            echo "  ${pkgs.lib.concatStringsSep ", " imageNames}"
          '';
        };
      };
    };
}