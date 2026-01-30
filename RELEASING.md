# Release Process

This document describes how to release ZipMerge.

## Local Release Script (Recommended)

The easiest way to create a release is using the local `release.sh` script.

**Option 1: Create tag first (recommended for custom tag messages)**
```bash
# Create a tag with a custom message
git tag -a v1.0.0 -m "Version 1.0.0 - Your custom message"

# Run the release script (will use existing tag)
./release.sh v1.0.0
```

**Option 2: Let the script create the tag**
```bash
# Script will create a simple tag automatically
./release.sh v1.0.0
```

This script will:
1. Build the app with Developer ID signing
2. Notarize the app with Apple
3. Use existing git tag or create one if needed
4. Push the tag to GitHub
5. Create a GitHub release with the signed .zip
6. Calculate the SHA256 hash
7. Automatically update the Homebrew cask
8. Commit and push the cask update

**Prerequisites:**
- `gh` CLI installed (`brew install gh`) and authenticated
- Developer ID Application certificate in Keychain
- Apple ID app-specific password (create at https://appleid.apple.com/account/manage)

The script will prompt for your Apple ID and app-specific password.

## Alternative: GitHub Actions (Optional)

If you prefer CI/CD, there's also a GitHub Actions workflow. However, it requires exporting your signing certificate.

## Required GitHub Secrets (GitHub Actions only)

Before creating your first release, set up these secrets in GitHub repository settings (Settings → Secrets and variables → Actions):

### 1. CERTIFICATE_BASE64

Your Developer ID Application certificate exported as base64.

**How to create:**

```bash
# Export your Developer ID certificate from Keychain Access
# 1. Open Keychain Access
# 2. Find "Developer ID Application: <Your Name> (M67B42LX8D)"
# 3. Right-click → Export "Developer ID Application..."
# 4. Save as certificate.p12 with a password

# Convert to base64
base64 -i certificate.p12 | pbcopy

# Paste the output as CERTIFICATE_BASE64 secret in GitHub
# Then delete the certificate.p12 file
rm certificate.p12
```

### 2. CERTIFICATE_PASSWORD

The password you used when exporting the certificate.p12 file.

### 3. APPLE_ID

Your Apple ID email address (the one associated with your developer account).

### 4. APPLE_ID_PASSWORD

An app-specific password for notarization (NOT your Apple ID password).

**How to create:**

1. Go to https://appleid.apple.com/account/manage
2. Sign in with your Apple ID
3. In the Security section, under "App-Specific Passwords", click "Generate Password"
4. Enter "GitHub Actions Notarization" as the name
5. Copy the generated password and save it as APPLE_ID_PASSWORD in GitHub

## Manual GitHub Actions Release (Alternative)

If you prefer to use GitHub Actions instead of the local script:

```bash
# Ensure you're on main branch with latest changes
git checkout main
git pull

# Create and push a version tag
git tag v1.0.0
git push origin v1.0.0
```

The GitHub Actions workflow will automatically build, sign, notarize, and create a release. However, you'll need to manually update the Homebrew cask afterward (the local script does this automatically).

## Troubleshooting

### Notarization fails

- Verify APPLE_ID and APPLE_ID_PASSWORD are correct
- Ensure app-specific password hasn't expired
- Check notarization logs in the GitHub Actions output

### Code signing fails

- Verify CERTIFICATE_BASE64 is correctly encoded
- Ensure CERTIFICATE_PASSWORD matches the export password
- Certificate must be "Developer ID Application" (not "Apple Development")

### Build fails

- Check that Xcode version on GitHub Actions supports your Swift version
- Verify project builds locally first with `xcodebuild`
