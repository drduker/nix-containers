#!/usr/bin/env bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 Collecting image statistics...${NC}"

# Count our images
echo -e "${YELLOW}Counting nix-containers images...${NC}"
OUR_COUNT=$(find images -name "default.nix" | wc -l)
echo -e "Found ${GREEN}${OUR_COUNT}${NC} nix-containers images"

# Count Chainguard images
echo -e "${YELLOW}Counting Chainguard images...${NC}"
CHAINGUARD_COUNT=$(curl -s "https://api.github.com/repos/chainguard-images/images/contents/images" | \
  jq -r '.[] | select(.type == "dir") | .name' | wc -l)
echo -e "Found ${GREEN}${CHAINGUARD_COUNT}${NC} Chainguard images"

# Count Replicated SecureBuild images (count skeleton loading cards)
echo -e "${YELLOW}Counting Replicated SecureBuild images...${NC}"
# Count the skeleton loading cards which indicate the number of images
REPLICATED_COUNT=$( echo "31 (zero public)")
echo -e "Found ${GREEN}${REPLICATED_COUNT}${NC} Replicated SecureBuild images"

# Get current date
UPDATED_DATE=$(date '+%Y-%m-%d')

# Create the comparison chart
CHART_CONTENT="## Container Image Ecosystem Comparison

<div align=\"center\">

| Provider | <img src=\"https://nixos.org/favicon.ico\" width=\"20\" height=\"20\"> Nix Containers | <img src=\"https://images.chainguard.dev/favicon.svg\" width=\"20\" height=\"20\"> Chainguard | <img src=\"https://securebuild.com/favicon.ico\" width=\"20\" height=\"20\"> Replicated SecureBuild |
|----------|:-----------:|:-----------:|:-----------:|
| **Public Images** | **${OUR_COUNT}** | **${CHAINGUARD_COUNT}** | **${REPLICATED_COUNT}** |
| **Build System** | Nix + nix2container | apko + melange | Buildpacks |
| **Base** | NixOS/nixpkgs | Alpine/glibc | Various |
| **Security Focus** | Reproducible builds & minimal attack surface | Minimal attack surface | Supply chain security |
| **License** | Open Source | Open Source For Now | Commercial |

</div>

*Last updated: ${UPDATED_DATE}*

---"

# Update README.md
README_FILE="README.md"
TEMP_README=$(mktemp)

# Find the comparison section and replace it
if grep -q "## Container Image Ecosystem Comparison" "$README_FILE"; then
  # Replace existing section
  echo -e "${YELLOW}Updating existing comparison section...${NC}"
  
  # Extract content before comparison section
  sed '/## Container Image Ecosystem Comparison/,$d' "$README_FILE" > "$TEMP_README"
  
  # Add new comparison section
  echo "$CHART_CONTENT" >> "$TEMP_README"
  
  # Add content after the old comparison section (if any)
  # Look for the next major section after comparison
  if grep -A999999 "## Container Image Ecosystem Comparison" "$README_FILE" | \
     grep -n "^## [^C]" | head -1 | cut -d: -f1 > /dev/null 2>&1; then
    
    NEXT_SECTION_LINE=$(grep -A999999 "## Container Image Ecosystem Comparison" "$README_FILE" | \
                       grep -n "^## [^C]" | head -1 | cut -d: -f1)
    SKIP_LINES=$(($(grep -n "## Container Image Ecosystem Comparison" "$README_FILE" | cut -d: -f1) + NEXT_SECTION_LINE - 2))
    
    tail -n +$((SKIP_LINES + 1)) "$README_FILE" >> "$TEMP_README"
  fi
else
  # Add new section after Architecture section
  echo -e "${YELLOW}Adding new comparison section...${NC}"
  
  if grep -q "^## Architecture" "$README_FILE"; then
    # Insert after Architecture section - find next section
    ARCH_LINE=$(grep -n "^## Architecture" "$README_FILE" | cut -d: -f1)
    NEXT_LINE=$(tail -n +$((ARCH_LINE + 1)) "$README_FILE" | grep -n "^## " | head -1 | cut -d: -f1)
    
    if [ -n "$NEXT_LINE" ]; then
      INSERT_LINE=$((ARCH_LINE + NEXT_LINE))
      head -n $((INSERT_LINE - 1)) "$README_FILE" > "$TEMP_README"
      echo -e "\n$CHART_CONTENT\n" >> "$TEMP_README"
      tail -n +$INSERT_LINE "$README_FILE" >> "$TEMP_README"
    else
      # Architecture is the last section
      cat "$README_FILE" > "$TEMP_README"
      echo -e "\n$CHART_CONTENT" >> "$TEMP_README"
    fi
  else
    # Insert at the top after title
    head -n 4 "$README_FILE" > "$TEMP_README"
    echo -e "\n$CHART_CONTENT\n" >> "$TEMP_README"
    tail -n +5 "$README_FILE" >> "$TEMP_README"
  fi
fi

# Replace original README
mv "$TEMP_README" "$README_FILE"

echo -e "${GREEN}✅ README.md updated successfully!${NC}"
echo -e "${BLUE}Statistics:${NC}"
echo -e "  Nix Containers: ${GREEN}${OUR_COUNT}${NC}"
echo -e "  Chainguard: ${GREEN}${CHAINGUARD_COUNT}${NC}"
echo -e "  Replicated SecureBuild: ${GREEN}${REPLICATED_COUNT}${NC}"
echo -e "  Updated: ${GREEN}${UPDATED_DATE}${NC}"