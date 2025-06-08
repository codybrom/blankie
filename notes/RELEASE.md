# Release Process

This document outlines the process for releasing new versions of Blankie.

## Version Numbering

Blankie follows [Semantic Versioning](https://semver.org/):

- MAJOR version for incompatible API changes
- MINOR version for new functionality in a backwards compatible manner
- PATCH version for backwards compatible bug fixes

## Pre-Release Checklist

Before creating a release, ensure:

- [ ] All tests pass
- [ ] Version numbers are updated in:
  - `Blankie.xcodeproj/project.pbxproj` (MARKETING_VERSION)
  - `CHANGELOG.md` (move items from Unreleased to new version section)
- [ ] CHANGELOG.md follows [Keep a Changelog](https://keepachangelog.com/) format
- [ ] All new features are documented
- [ ] Credits are updated for any new contributors

## Creating a Release

1. **Tag the Release**

   ```bash
   git tag -a v1.0.11 -m "chore: bump marketing version to v1.0.11"
   git push origin v1.0.11
   ```

2. **Build the Release**
   - Archive the app in Xcode (Product → Archive)
   - This will open the Organizer window when complete

3. **App Store Release**
   - From the Organizer, select the archive and click "Distribute App"
   - Choose "App Store Connect" → "Upload"
   - Follow the prompts to upload to App Store Connect
   - In App Store Connect:
     - Add the new build to the version
     - Update the "What's New" section with release notes from CHANGELOG.md
     - Submit for review
     - Once approved, release immediately or schedule release

4. **GitHub Release**
   - From the same archive in Organizer, click "Distribute App" again
   - Choose "Direct Distribution"
   - After a brief check, the app will be available to be exported
   - Export to a folder, then create a ZIP file named **`Blankie.zip`** containing only the exported `Blankie.app` at the root level

5. **Create GitHub Release**
   - Go to GitHub releases page
   - Create a new release from the tag
   - Copy the relevant section from CHANGELOG.md as the release notes
   - Upload `Blankie.zip` as the release asset

## Post-Release Tasks

### Update Homebrew Cask

After the GitHub release is published:

1. Wait for the release ZIP to be available on GitHub
2. Run the following command to update the Homebrew cask:

   ```bash
   brew bump-cask-pr --version [version] blankie
   ```

   Replace `[version]` with the new version number (e.g., `1.0.11`)

3. The command will automatically:
   - Download the new release
   - Calculate the SHA256 checksum
   - Update the cask formula
   - Create a pull request to the Homebrew cask repository

4. Monitor the pull request for any feedback from Homebrew maintainers

**Note:** You need to have Homebrew and the `homebrew/cask` tap installed to run this command.

If the `brew bump-cask-pr` command fails:

- Ensure you have the latest Homebrew: `brew update`
- Check that you have push access to your Homebrew fork
- Manually create a PR if needed, updating the version and sha256 in the cask file
