# Nix Containers

A collection of container images built with nix2container, featuring dynamic discovery and multi-layer architecture.

## Architecture

- **Auto-build latest images** - Multiple patterns to build latest images securely (github actions, etc) 
- **Multi-layer images** - Base packages in separate layers for better caching
- **Non-root users** - All images run as UID 1000 for security
- **Dynamic discovery** - Images automatically discovered from `images/` folder
- **Shared libraries and layers** - Common functionality in `lib/` folder
  - `base.nix` - Common packages, environment, and labels - optional layer
  - `nonRoot.nix` - A common Non-root user configuration - optional layer
  - `buildCLIImage.nix` - CLI application wrapper
  - `mkUserEnvironment.nix` - User environment setup


## Container Image Ecosystem Comparison

<div align="center">

| Provider | <img src="https://nixos.org/favicon.ico" width="20" height="20"> Nix Containers | <img src="https://images.chainguard.dev/favicon.svg" width="20" height="20"> Chainguard | <img src="https://securebuild.com/favicon.ico" width="20" height="20"> Replicated SecureBuild |
|----------|:-----------:|:-----------:|:-----------:|
| **Public Images** | **27** | **51** | **31 (zero public)** |
| **Build System** | Nix + nix2container | apko + melange | Buildpacks |
| **Base** | NixOS/nixpkgs | Alpine/glibc | Various |
| **Security Focus** | Reproducible builds & minimal attack surface | Minimal attack surface | Supply chain security |
| **License** | Open Source | Open Source For Now | Commercial |

</div>

*Last updated: 2025-08-24*

---
## Available Images

*Updated: 2025-08-24*

### Content & Communication

- **hugo** - Fast and modern static site generator
- **maddy** - Modern mail server with SMTP, IMAP, and more

### Runtime Environments

- **cpp-runtime** - Minimal runtime for C++ and Rust binaries
- **bash** - GNU Bash shell environment
- **busybox** - Minimal Unix utilities in a single executable

### Nix Ecosystem

- **nix** - Nix package manager and build system
- **nix-flakes** - Nix with flakes experimental feature enabled
- **nix-unstable** - Nix unstable version with latest features
- **nix-unstable-static** - Statically linked Nix unstable version
- **attic** - Multi-tenant Nix binary cache client
- **cachix** - Binary cache service for Nix packages
- **cachix-flakes** - Binary cache service with Nix flakes support

### Kubernetes & DevOps

- **kubectl** - Kubernetes command-line tool
- **kubernetes-helm** - Package manager for Kubernetes
- **dragonfly-operator** - Kubernetes operator for Dragonfly instances
- **external-dns** - External DNS controller for Kubernetes
- **docker-compose** - Tool for defining multi-container Docker applications

### Development Tools

- **cpp-build-env** - Complete C++ development environment with GCC, CMake, GTest
- **rust-build-env** - Complete Rust development environment with Cargo, Clippy, rust-analyzer
- **devcontainer** - Development container with common tools
- **devenv** - Fast, declarative, reproducible development environments

### Security & Auth

- **sops** - SOPS encryption tool with GPG support
- **pocket-id** - Personal identity provider for OAuth2/OIDC

### Web Servers & Networking

- **nginx** - High-performance HTTP server and reverse proxy
- **caddy** - Modern HTTP/2 web server with automatic HTTPS
- **curl** - Command line tool for transferring data with URLs

### Quick Build Commands

```bash
# Build and load specific images
nix build .#load-<image-name>-to-docker

# Examples:
nix build .#load-nginx-to-docker        # Web server
nix build .#load-cpp-build-env-to-docker  # C++ development
nix build .#load-rust-build-env-to-docker # Rust development
nix build .#load-kubectl-to-docker        # Kubernetes CLI

# Build and load all images at once
nix build .#load-all-to-docker && ./result/bin/load-all-to-docker
```

---
## Local Development

### Build and Load Single Image to Docker

```bash
# Build and load a specific image to Docker in one command
nix build .#load-<image-name>-to-docker
example:
nix build .#load-sops-to-docker
```

### Build and Load All Images at Once

```bash
# Build and load all images to Docker
nix build .#load-all-to-docker && ./result/bin/load-all-to-docker
```

### Verify Images in Docker

```bash
# List loaded images
docker images | grep -E "(cpp-runtime|cpp-build-env|rust-build-env|kubectl|dragonfly-operator|external-dns|sops-base)"
```

## Registry Management

### Tag and Push to Different Registry

After building images locally, you can retag and push them to your own registry:

```bash
# Tag and push cpp-runtime
docker tag cpp-runtime your-registry.com/cpp-runtime:latest
docker push your-registry.com/cpp-runtime:latest

# Tag and push cpp-build-env
docker tag cpp-build-env your-registry.com/cpp-build-env:latest
docker push your-registry.com/cpp-build-env:latest

# Tag and push rust-build-env
docker tag rust-build-env your-registry.com/rust-build-env:latest
docker push your-registry.com/rust-build-env:latest

# Tag and push kubectl
docker tag kubectl your-registry.com/kubectl:latest
docker push your-registry.com/kubectl:latest

# Tag and push dragonfly-operator
docker tag dragonfly-operator your-registry.com/dragonfly-operator:latest
docker push your-registry.com/dragonfly-operator:latest

# Tag and push external-dns
docker tag external-dns your-registry.com/external-dns:latest
docker push your-registry.com/external-dns:latest

# Tag and push sops-base
docker tag sops-base your-registry.com/sops-base:latest
docker push your-registry.com/sops-base:latest
```

### Bulk Push Script

```bash
#!/bin/bash
REGISTRY="your-registry.com"
IMAGES_RAW=($(find images -name "default.nix" -exec dirname {} \; | sort | xargs -I {} basename {}))

for image in "${IMAGES[@]}"; do
    echo "= Pushing $image..."
    docker tag "$image" "$REGISTRY/$image:latest"
    docker push "$REGISTRY/$image:latest"
    echo " $image pushed successfully!"
done
```

## Development Environment

```bash
# Enter development shell with all tools
nix develop
```

The development shell includes:
- **nix** - Nix package manager and build tools
- **docker** & **docker-compose** - Container runtime and orchestration
- **act** - Run GitHub Actions locally for pipeline testing
- **jq** - JSON processing for workflow debugging
- **git** & **gh** - Version control and GitHub CLI
- **just** & **gnumake** - Build automation tools

### Testing GitHub Actions Locally

```bash
# List available workflows
act -l

# Test the build workflow locally
act -j build-containers

# Force x86_64 architecture (if needed on ARM systems)
act --container-architecture linux/amd64
```