# Release Process

This document describes how to release ZipMerge.

## Local Release Script (Recommended)

The easiest way to create a release is using the local `release.sh` script:

```bash
./release.sh v1.0.0
```

This script will:
1. Build the app with Developer ID signing
2. Notarize the app with Apple
3. Create a GitHub release with the signed .zip
4. Calculate the SHA256 hash
5. Automatically update the Homebrew cask
6. Commit and push the cask update

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

## Creating a Release

Once secrets are configured:

```bash
# Ensure you're on main branch with latest changes
git checkout main
git pull

# Create and push a version tag
git tag v1.0.0
git push origin v1.0.0
```

The GitHub Actions workflow will automatically:
- Build and sign the app
- Notarize with Apple (takes 5-10 minutes)
- Create a GitHub release with ZipMerge.zip
- Include SHA256 hash in release notes

## Updating the Homebrew Cask

After the release completes:

1. Copy the SHA256 from the release notes
2. Update `/Users/jsp/dev/projects/homebrew-tap/Casks/zipmerge.rb`:
   ```ruby
   sha256 "THE_SHA256_FROM_RELEASE_NOTES"
   ```
3. Update version if needed
4. Commit and push to homebrew-tap:
   ```bash
   cd /Users/jsp/dev/projects/homebrew-tap
   git add Casks/zipmerge.rb
   git commit -m "Update zipmerge to v1.0.0"
   git push
   ```

Users can then install with:
```bash
brew tap jaspermayone/tap
brew install --cask zipmerge
```

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
