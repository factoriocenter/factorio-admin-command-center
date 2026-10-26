# Publishing releases

The release workflow starts when a version tag is pushed or a GitHub release is published. Tags may use `X.Y.Z` or `vX.Y.Z` and must match the primary version in `info.json`. It packages the tagged commit for Factorio 2.1 and creates a separate Factorio 2.0 fallback using `compatibility/2.0.json`.

## One-time setup

1. Create an API key at https://factorio.com/profile with **ModPortal: Upload Mods** permission. Its account must have upload access to the mod.
2. In each GitHub repository, open **Settings > Secrets and variables > Actions** and add the repository secret **MOD_PORTAL_API_KEY**. An organization secret also works if both repositories are granted access.
3. Enable GitHub Actions. The built-in GitHub token creates releases; no personal GitHub token is needed.

Never put the key in repository files, workflow inputs, or logs. Both mods already have Mod Portal pages; this workflow uploads releases to those existing pages.

## Release a version

Update `info.json`, the compatibility manifest, and the changelog before tagging. Each package needs its own mod version. If the fallback content changes, bump its version too, including any cross-mod dependency minimums that need to follow it.

Push the commit, then create and push its version tag, or publish a release from GitHub. To retry an existing tag, use **Actions > Release and publish to Mod Portal > Run workflow** and enter that tag. Publication is serialized across runs, and repeated uploads of identical packages are skipped. Releases created by the workflow's built-in GitHub token do not trigger a second release workflow.

The workflow:

1. Checks that the tag, checked-out commit, and primary manifest agree.
2. Builds reproducible ZIPs from tracked files only, excluding development tools, tests, Python files, compatibility manifests, and GitHub configuration.
3. Stores the ZIPs as an Actions artifact for 30 days and attaches them to the GitHub release.
4. Downloads that artifact in a separate publishing job and uploads those exact packages to Mod Portal, with the 2.0 fallback first.

The main mod currently uses tag `4.4.0`; the locales repository uses `1.4.0`. Their fallback packages are `4.3.3` and `1.3.9`, respectively. Always use the current manifest versions for subsequent releases.

## Retry failures

A missing key fails the publishing job with a setup message; the artifact and GitHub release remain available. Add the secret and rerun the workflow.

A version already on Mod Portal is skipped only when its ZIP checksum and Factorio version match. Different content with the same version fails: bump the affected manifest version rather than replacing a published release. Rebuilding the same tag produces the same ZIPs.

The two portal uploads are separate requests. If one succeeds and the other fails, rerun the workflow: it verifies and skips the successful upload and retries the missing one. Ordinary branch pushes never publish anything.

API documentation: [Mod upload API](https://wiki.factorio.com/Mod_upload_API) and [Mod portal API](https://wiki.factorio.com/Mod_portal_API).
