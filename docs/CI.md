# Tests and releases

## Pull requests

`.github/workflows/test.yml` runs on macOS 15 for opened, updated (`synchronize`), reopened, and ready-for-review pull requests. Draft PRs skip the job. Converting a PR back to draft also triggers the workflow so concurrency can cancel its previous run without starting new tests. New commits cancel older runs for the same PR.

The job runs the Python release-tool tests, `swift test`, and an unsigned Debug build of the host and Finder extension. It uses the runner's installed Xcode, read-only repository permissions, and `pull_request` rather than `pull_request_target`, including for fork PRs. Repository approval policies may require a maintainer to approve a first-time contributor's run.

## Tag releases

`.github/workflows/release.yml` runs when a `v*` tag is pushed. Use `vMAJOR.MINOR.PATCH`, for example `v0.2.0`. Semantic-version prerelease and build suffixes are supported, such as `v0.2.0-rc.1`; malformed version tags fail before building. The tag must contain the workflow and packaging scripts.

The workflow:

1. Checks out the tag with complete history and tags.
2. Generates release notes from the nearest reachable version tag to the current tag, including merged commits. Both lightweight and annotated tags qualify; unrelated branch tags and non-version tags are excluded. The first version includes all commits. Two versions pointing to the same commit produce an empty-change note. This uses Git tags, not GitHub's latest-release timestamp.
3. Runs release-tool and Swift tests, then builds separate optimized arm64 and x86_64 apps with deployment target macOS 15.7.
4. Sets the host and embedded Finder extension bundle versions to the numeric tag version (for example, `1.2.3` for `v1.2.3-rc.1`), signs the extension and host ad hoc with their existing entitlements, and verifies signatures and architectures.
5. Uses [create-dmg](https://github.com/create-dmg/create-dmg) to make one DMG per architecture, with the app icon and an Applications drop link. Publishes a GitHub Release with the commit changelog and three assets: `gogo-vVERSION-arm64.dmg`, `gogo-vVERSION-x86_64.dmg`, and `SHA256SUMS.txt`. No ZIP is produced. Tags with a prerelease suffix create prereleases. The full tag remains in release titles and asset names.

Only the release job has `contents: write`; it uses the automatically supplied `GITHUB_TOKEN`. No Apple developer credentials or extra GitHub token are required. The app is not notarized, and users follow the README's first-launch instructions. Files are prepared and tested before the publish step. An existing release is not overwritten: use a new tag for changed binaries; rerunning a failed job is appropriate if no release was created.

The workflow files must be pushed before GitHub can run them. Creating a local tag alone does not publish anything; push that tag to trigger the release. Do not move an already published version tag.

## Local checks

```sh
brew install create-dmg
python3 -B -m unittest discover -s scripts/tests -v
swift test
./scripts/package-release.sh v0.2.0
```

The release workflow installs create-dmg through Homebrew. Packaging writes to `.build/release/`, uses separate build directories for each architecture, and does not upload, launch, or install the app. create-dmg uses Finder to arrange the DMG window; local runs may request permission to automate Finder. The tag argument supplies the version for local packaging and need not exist; generating release notes requires an actual local Git tag. Avoid keeping development app copies registered in LaunchServices or PlugInKit alongside an installed gogo app.

CI builds do not establish Finder behavior on all supported macOS versions. Downloaded-installation, Gatekeeper, and real Finder menu behavior still need runtime checks.

## Local validation

On September 16, 2026, create-dmg 1.3.0 successfully packaged separate Release arm64 and x86_64 DMGs for a local `v1.2.3-rc.1` test. Each mounted DMG contained only its expected architecture in both executables, bundle version 1.2.3, the exact configured entitlements, and valid signatures. Both contained the Applications link, volume icon, and Finder layout metadata; create-dmg's cosmetic Finder script completed for both. SHA-256 checksums matched and no ZIP was generated. The 7 release-tool tests, actionlint, and shell syntax checks passed. The 26 Swift tests passed before this packaging-only adjustment; app source did not change. Hosted workflow execution and downloaded-installation behavior remain pending. Local test artifacts were removed.
