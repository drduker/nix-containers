#!/usr/bin/env bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 Updating Available Images section in README...${NC}"

# Dynamically generate IMAGES array from folders
echo -e "${YELLOW}Discovering images from folders...${NC}"
IMAGES_RAW=($(find images -name "default.nix" -exec dirname {} \; | sort | xargs -I {} basename {}))
IMAGES_STRING=$(printf '"%s" ' "${IMAGES_RAW[@]}")
IMAGES_ARRAY="IMAGES=(${IMAGES_STRING})"

echo -e "${GREEN}Generated IMAGES array: ${IMAGES_ARRAY}${NC}"

# Image descriptions mapping
declare -A descriptions=(
  ["attic"]="Multi-tenant Nix binary cache client"
  ["bash"]="GNU Bash shell environment"
  ["busybox"]="Minimal Unix utilities in a single executable"
  ["cachix"]="Binary cache service for Nix packages"
  ["cachix-flakes"]="Binary cache service with Nix flakes support"
  ["caddy"]="Modern HTTP/2 web server with automatic HTTPS"
  ["cpp-build-env"]="Complete C++ development environment with GCC, CMake, GTest"
  ["cpp-runtime"]="Minimal runtime for C++ and Rust binaries"
  ["curl"]="Command line tool for transferring data with URLs"
  ["devcontainer"]="Development container with common tools"
  ["devenv"]="Fast, declarative, reproducible development environments"
  ["docker-compose"]="Tool for defining multi-container Docker applications"
  ["dragonfly-operator"]="Kubernetes operator for Dragonfly instances"
  ["external-dns"]="External DNS controller for Kubernetes"
  ["hugo"]="Fast and modern static site generator"
  ["kubectl"]="Kubernetes command-line tool"
  ["kubernetes-helm"]="Package manager for Kubernetes"
  ["maddy"]="Modern mail server with SMTP, IMAP, and more"
  ["nginx"]="High-performance HTTP server and reverse proxy"
  ["nix"]="Nix package manager and build system"
  ["nix-flakes"]="Nix with flakes experimental feature enabled"
  ["nix-unstable"]="Nix unstable version with latest features"
  ["nix-unstable-static"]="Statically linked Nix unstable version"
  ["pocket-id"]="Personal identity provider for OAuth2/OIDC"
  ["rust-build-env"]="Complete Rust development environment with Cargo, Clippy, rust-analyzer"
  ["sops"]="SOPS encryption tool with GPG support"
)

# Categories for organization
declare -A categories=(
  ["Development Tools"]="cpp-build-env rust-build-env devcontainer devenv"
  ["Runtime Environments"]="cpp-runtime bash busybox"
  ["Web Servers & Networking"]="nginx caddy curl"
  ["Kubernetes & DevOps"]="kubectl kubernetes-helm dragonfly-operator external-dns docker-compose"
  ["Nix Ecosystem"]="nix nix-flakes nix-unstable nix-unstable-static attic cachix cachix-flakes"
  ["Security & Auth"]="sops pocket-id"
  ["Content & Communication"]="hugo maddy"
)

# Get current date
UPDATED_DATE=$(date '+%Y-%m-%d')

# Generate the Available Images section
IMAGES_SECTION="## Available Images

*Updated: ${UPDATED_DATE}*

"

# Add categorized images
for category in "${!categories[@]}"; do
  IMAGES_SECTION+="### ${category}

"
  
  # Get images for this category
  for image in ${categories[$category]}; do
    if [ -d "images/$image" ]; then
      description="${descriptions[$image]:-"Container image for $image"}"
      IMAGES_SECTION+="- **${image}** - ${description}
"
    fi
  done
  
  IMAGES_SECTION+="
"
done

# Add build commands section
IMAGES_SECTION+="### Quick Build Commands

\`\`\`bash
# Build and load specific images
nix build .#load-<image-name>-to-docker

# Examples:
nix build .#load-nginx-to-docker        # Web server
nix build .#load-cpp-build-env-to-docker  # C++ development
nix build .#load-rust-build-env-to-docker # Rust development
nix build .#load-kubectl-to-docker        # Kubernetes CLI

# Build and load all images at once
nix build .#load-all-to-docker && ./result/bin/load-all-to-docker
\`\`\`

---"

echo -e "${YELLOW}Generated images section for $(find images -name "default.nix" | wc -l) images...${NC}"

# Update README.md
README_FILE="README.md"
TEMP_README=$(mktemp)

# Find the Available Images section and replace it
if grep -q "^## Available Images" "$README_FILE"; then
  echo -e "${YELLOW}Updating existing Available Images section...${NC}"
  
  # Extract content before Available Images section
  sed '/^## Available Images/,$d' "$README_FILE" > "$TEMP_README"
  
  # Add new images section
  echo "$IMAGES_SECTION" >> "$TEMP_README"
  
  # Add content after the old Available Images section (find next ## section)
  if grep -A999999 "^## Available Images" "$README_FILE" | \
     grep -n "^## [^A]" | head -1 | cut -d: -f1 > /dev/null 2>&1; then
    
    NEXT_SECTION_LINE=$(grep -A999999 "^## Available Images" "$README_FILE" | \
                       grep -n "^## [^A]" | head -1 | cut -d: -f1)
    SKIP_LINES=$(($(grep -n "^## Available Images" "$README_FILE" | cut -d: -f1) + NEXT_SECTION_LINE - 2))
    
    tail -n +$((SKIP_LINES + 1)) "$README_FILE" >> "$TEMP_README"
  fi
else
  echo -e "${YELLOW}Adding new Available Images section...${NC}"
  
  # Find a good place to insert (after comparison section if it exists)
  if grep -q "^## Container Image Ecosystem Comparison" "$README_FILE"; then
    # Insert after comparison section
    COMP_LINE=$(grep -n "^## Container Image Ecosystem Comparison" "$README_FILE" | cut -d: -f1)
    NEXT_LINE=$(tail -n +$((COMP_LINE + 1)) "$README_FILE" | grep -n "^## " | head -1 | cut -d: -f1)
    
    if [ -n "$NEXT_LINE" ]; then
      INSERT_LINE=$((COMP_LINE + NEXT_LINE))
      head -n $((INSERT_LINE - 1)) "$README_FILE" > "$TEMP_README"
      echo -e "\n$IMAGES_SECTION\n" >> "$TEMP_README"
      tail -n +$INSERT_LINE "$README_FILE" >> "$TEMP_README"
    else
      # Comparison is the last section
      cat "$README_FILE" > "$TEMP_README"
      echo -e "\n$IMAGES_SECTION" >> "$TEMP_README"
    fi
  else
    # Insert near the beginning
    head -n 10 "$README_FILE" > "$TEMP_README"
    echo -e "\n$IMAGES_SECTION\n" >> "$TEMP_README"
    tail -n +11 "$README_FILE" >> "$TEMP_README"
  fi
fi

# Replace original README
mv "$TEMP_README" "$README_FILE"

echo -e "${GREEN}✅ Available Images section updated successfully!${NC}"
echo -e "${BLUE}Updated with organized categories and build commands${NC}"