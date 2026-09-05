# Security hardening audit

Audit date: 2026-09-05

Baseline: `HD838A/remote-mic-app` / fork baseline commit `4cc7be24d5a2462d8673090fe1d19fc451a34d52`.

Target branch: `security-hardening`.

## Current verdict

**Not yet approved for production/high-sensitivity deployment.**

The fork removes several avoidable trust and network risks, but a required dependency (`GetSayAll/sayall-mac-remote`) is not publicly accessible from an unauthenticated/normal external GitHub client. Until that dependency is made reviewable or replaced, this repository cannot be treated as a fully independent, reproducible, publicly auditable build.

## Fixed in this branch

### 1. Sparkle dependency

The baseline pinned Sparkle 2.9.4. The hardening branch requires and pins Sparkle 2.9.6.

Reason: the fork must not retain a dependency version known to be affected by Sparkle security advisories fixed in 2.9.6.

### 2. Upstream automatic update trust path

The baseline configured `download.sayall.app` as the Sparkle feed and automatically started Sparkle for stable builds.

The hardening branch:

- removes the upstream `SUFeedURL` from the application Info.plist;
- disables automatic checks and automatic updates in Info.plist;
- prevents the application from starting the updater automatically;
- prevents About/settings views from initiating background update-information refreshes;
- keeps updater startup explicit-only.

This prevents an independently reviewed fork from silently replacing itself with an upstream binary that was built using a different/private release graph.

### 3. Private package injection hooks

The baseline package manifest accepted environment-controlled paths for proprietary/private packages, including AI, macro, membership and private artifact modules.

The hardening branch removes those package injection hooks. Production code in this fork should be constrained to dependencies explicitly visible in the package manifest.

The hardware simulation package hook remains test-only.

## Positive controls retained

### Local Agent / MCP

The public MCP implementation has useful defensive controls:

- disabled by default when no access state exists;
- 32-byte cryptographically random bearer tokens;
- only token hashes are persisted;
- constant-time token-hash comparison;
- revocable authorization records;
- private directories use mode 0700;
- private files use mode 0600;
- append paths use `O_NOFOLLOW` and file-type checks.

MCP should still remain disabled unless it is explicitly needed.

### Transcript and original-audio recording

Fresh installs default both local transcript history and original-audio recording to disabled. Keep those defaults for sensitive deployments.

## Open findings / blockers

### BLOCKER: `sayall-mac-remote` is not independently auditable

`Package.swift` still requires:

`https://github.com/GetSayAll/sayall-mac-remote.git`

at revision:

`7d1b3c2e1d88913bafaa3a401c939eb218a1f363`

The upstream release/CI workflows normally obtain this package using a deploy key and a local SwiftPM mirror. An external GitHub repository lookup currently returns Not Found.

**Required resolution before deployment:** one of the following:

1. obtain legitimate read access and audit the exact pinned revision;
2. have the dependency published for independent review;
3. replace it with an auditable local implementation with equivalent required interfaces.

Do not remove the dependency blindly: it contains functionality used by the application and doing so without a compatible replacement would produce an incomplete or non-building product.

### OPEN: upstream release workflows are not suitable for this fork

The copied release workflows expect upstream repository identity, private dependency deploy keys, private signing repositories, membership/AI/macro packages, and private release secrets.

Do not use those workflows to publish this fork. A fork-specific build/release workflow should be created only after all runtime dependencies are independently accessible.

### OPEN: local recording manifest path hardening

`RecordingAssetStore` accepts a manifest-provided relative media path. The current character-based validation allows slash-separated path text and does not reject every `..` path segment before `mediaURLWithoutQueue` derives a filesystem location.

Normal application-generated manifests do not contain traversal paths, so this is not currently assessed as a remote exploit. However a locally tampered manifest could influence later lookup/delete behavior.

**Mitigation now:** original-audio recording remains off by default and should remain off for sensitive deployments.

**Required code fix before enabling recording:** validate every relative path component, reject empty/`.`/`..` components and absolute paths, standardize the resulting URL, and verify the standardized/resolved URL remains below the recording root before playback, integrity checks or deletion.

### OPEN: Local Network / Bonjour attack surface

The app still declares Local Network access and `_remotemic._tcp` Bonjour discovery for nearby iPhone/iPad/Watch features.

For a Bluetooth-remote-only deployment, deny Local Network permission. Removal from the binary should wait until the inaccessible shared remote package can be audited, because that package participates in the nearby-device implementation.

## Recommended deployment permissions

For a Bluetooth RC003-only deployment:

| Capability | Default |
|---|---|
| Bluetooth | Allow |
| Local Network | Deny |
| Accessibility | Deny initially |
| Input Monitoring | Deny initially |
| Local transcript history | Off |
| Original audio recording | Off |
| Local Agent / MCP | Off |
| Private AI / membership / macro packages | Not included by this fork manifest |
| Automatic updater | Off |

Only grant Accessibility/Input Monitoring if a specific custom mapping or key-injection feature is actually required.

## Release policy for this fork

1. Upstream updates are reviewed as source diffs before integration.
2. Do not consume upstream prebuilt application updates through Sparkle.
3. Keep dependency revisions/version floors explicit.
4. Do not restore environment-controlled private production package injection.
5. Do not merge `security-hardening` into `main` until an independent clean build and test run succeeds.
6. Do not distribute a signed release until the `sayall-mac-remote` blocker is resolved and the release workflow no longer depends on upstream private secrets.

## Next gate

The next security gate is **dependency independence**. Once `sayall-mac-remote` is accessible/replaced, run a clean SwiftPM resolve, full tests, release build for Apple Silicon and Intel, inspect resulting entitlements/signatures, and then perform runtime network/permission observation before approving deployment.
