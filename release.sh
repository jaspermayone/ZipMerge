#!/bin/bash
set -e

# ZipMerge Local Release Script
# This script builds, signs, notarizes, and releases ZipMerge

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
HOMEBREW_TAP_PATH="/Users/jsp/dev/projects/homebrew-tap"
APPLE_ID="${APPLE_ID:-}"  # Set via environment variable or it will prompt
TEAM_ID="M67B42LX8D"

echo -e "${GREEN}🚀 ZipMerge Release Script${NC}"
echo ""

# Check for version argument
if [ -z "$1" ]; then
    echo -e "${RED}Error: Version number required${NC}"
    echo "Usage: ./release.sh v1.0.0"
    exit 1
fi

VERSION="$1"
echo -e "Release version: ${YELLOW}${VERSION}${NC}"
echo ""

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo -e "${RED}Error: gh CLI not found. Install with: brew install gh${NC}"
    exit 1
fi

# Check if logged in to gh
if ! gh auth status &> /dev/null; then
    echo -e "${YELLOW}Please login to GitHub CLI:${NC}"
    gh auth login
fi

# Prompt for Apple ID if not set
if [ -z "$APPLE_ID" ]; then
    echo -e "${YELLOW}Enter your Apple ID email:${NC}"
    read APPLE_ID
fi

# Prompt for app-specific password
echo -e "${YELLOW}Enter your Apple ID app-specific password:${NC}"
echo "(Create one at: https://appleid.apple.com/account/manage)"
read -s APPLE_PASSWORD
echo ""

# Clean previous builds
echo -e "${GREEN}🧹 Cleaning previous builds...${NC}"
rm -rf build/
rm -f ZipMerge.zip

# Build the app
echo -e "${GREEN}🔨 Building ZipMerge...${NC}"
xcodebuild -project ZipMerge.xcodeproj \
    -scheme ZipMerge \
    -configuration Release \
    -derivedDataPath ./build \
    CODE_SIGN_IDENTITY="Developer ID Application" \
    clean build

if [ $? -ne 0 ]; then
    echo -e "${RED}Build failed!${NC}"
    exit 1
fi

APP_PATH="./build/Build/Products/Release/ZipMerge.app"

# Verify code signing
echo -e "${GREEN}✅ Verifying code signature...${NC}"
codesign -dv --verbose=4 "$APP_PATH"

# Create zip for notarization
echo -e "${GREEN}📦 Creating archive...${NC}"
cd build/Build/Products/Release
zip -r ../../../../ZipMerge.zip ZipMerge.app
cd ../../../../

# Notarize the app
echo -e "${GREEN}🔐 Submitting for notarization...${NC}"
echo "This may take 5-10 minutes..."

xcrun notarytool submit ZipMerge.zip \
    --apple-id "$APPLE_ID" \
    --team-id "$TEAM_ID" \
    --password "$APPLE_PASSWORD" \
    --wait

if [ $? -ne 0 ]; then
    echo -e "${RED}Notarization failed!${NC}"
    exit 1
fi

# Staple the notarization ticket
echo -e "${GREEN}📎 Stapling notarization ticket...${NC}"
unzip -q ZipMerge.zip
xcrun stapler staple ZipMerge.app
rm ZipMerge.zip
zip -r -q ZipMerge.zip ZipMerge.app
rm -rf ZipMerge.app

# Calculate SHA256
echo -e "${GREEN}🔢 Calculating SHA256...${NC}"
SHA256=$(shasum -a 256 ZipMerge.zip | awk '{print $1}')
echo -e "SHA256: ${YELLOW}${SHA256}${NC}"

# Create git tag
echo -e "${GREEN}🏷️  Creating git tag...${NC}"
git tag -a "$VERSION" -m "Release $VERSION" || echo "Tag already exists"
git push origin "$VERSION" || echo "Tag already pushed"

# Create GitHub release
echo -e "${GREEN}📤 Creating GitHub release...${NC}"
gh release create "$VERSION" ZipMerge.zip \
    --title "ZipMerge $VERSION" \
    --notes "## Installation

### Via Homebrew
\`\`\`bash
brew tap jaspermayone/tap
brew install --cask zipmerge
\`\`\`

### Manual Installation
1. Download ZipMerge.zip
2. Unzip and move ZipMerge.app to /Applications

## SHA256 Checksum
\`\`\`
$SHA256
\`\`\`"

if [ $? -ne 0 ]; then
    echo -e "${RED}GitHub release failed!${NC}"
    exit 1
fi

# Update Homebrew cask
echo -e "${GREEN}🍺 Updating Homebrew cask...${NC}"

CASK_FILE="$HOMEBREW_TAP_PATH/Casks/zipmerge.rb"

if [ ! -f "$CASK_FILE" ]; then
    echo -e "${RED}Error: Cask file not found at $CASK_FILE${NC}"
    exit 1
fi

# Update version and SHA256 in cask file
sed -i '' "s/version \".*\"/version \"${VERSION#v}\"/" "$CASK_FILE"
sed -i '' "s/sha256 .*/sha256 \"$SHA256\"/" "$CASK_FILE"

echo -e "${GREEN}✅ Cask file updated${NC}"

# Commit and push cask update
echo -e "${GREEN}📝 Committing cask update...${NC}"
cd "$HOMEBREW_TAP_PATH"
git add Casks/zipmerge.rb
git commit -m "Update zipmerge to $VERSION"
git push

echo ""
echo -e "${GREEN}✨ Release complete!${NC}"
echo ""
echo "Users can now install with:"
echo -e "${YELLOW}brew tap jaspermayone/tap${NC}"
echo -e "${YELLOW}brew install --cask zipmerge${NC}"
echo ""
echo "SHA256: $SHA256"
