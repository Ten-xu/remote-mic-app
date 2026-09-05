# Security hardening audit

Audit date: 2026-09-05

Baseline: `HD838A/remote-mic-app` / fork baseline commit `4cc7be24d5a2462d8673090fe1d19fc451a34d52`.

Target branch: `security-hardening`.

## Current verdict

**Not yet approved for production/high-sensitivity deployment.**

The fork has removed several avoidable trust and network risks and now has a build mode that excludes the inaccessible `GetSayAll/sayall-mac-remote` package. The remaining gate is completing the local compatibility interface and obtaining a clean application build/test result in that mode.

## Fixed in this branch

### 1. Sparkle dependency

The baseline pinned Sparkle 2.9.4. The hardening branch requires and pins Sparkle 2.9.6.

### 2. Upstream automatic update trust path

The baseline configured `download.sayall.app` as the Sparkle feed and automatically started Sparkle for stable builds.

The hardening branch:

- removes the upstream `SUFeedURL` from the application Info.plist;
- disables automatic checks and automatic updates in Info.plist;
- prevents the application from starting the updater automatically;
- prevents About/settings views from initiating background update-information refreshes;
- keeps updater startup explicit-only.

This prevents an independently reviewed fork from silently replacing itself with an upstream binary built from a different/private release graph.

### 3. Private package injection hooks

The baseline package manifest accepted environment-controlled paths for proprietary/private packages, including AI, macro, membership and private artifact modules.

The hardening branch removes those production package injection hooks. The hardware simulation package hook remains test-only.

### 4. Local Network / Bonjour declarations

The Bluetooth-only hardening target removes:

- `NSLocalNetworkUsageDescription`;
- `_remotemic._tcp` from `NSBonjourServices`.

The Bluetooth permission description is narrowed to supported Bluetooth remote controls.

### 5. Upstream release/agent workflows

Upstream workflows that depend on private deploy keys, signing repositories, upstream release infrastructure and SayAll Agent automation have been removed.

The remaining `mac-ci.yml` is fork-specific, uses read-only repository permissions, enforces the security baseline, checks that the local compatibility layer contains no remote transport implementation, and defines an independent hardened-remote build gate.

### 6. Switchable local remote compatibility mode

The fork contains local, auditable modules under:

- `Sources/SayAllMacRemoteCore/`;
- `Sources/SayAllMacRemoteUI/`.

`Package.swift` now supports:

`REMOTE_MIC_HARDENED_REMOTE=1`

When enabled, SwiftPM does **not** add `GetSayAll/sayall-mac-remote` to the dependency graph and instead supplies local targets named `SayAllMacRemoteCore` and `SayAllMacRemoteUI`. Existing host imports therefore do not need to change.

The compatibility modules are intentionally inert and must not implement Bonjour discovery, nearby phone/watch listeners, URLSession/WebSocket relay logic or other remote transports. CI and Swift tests enforce that boundary.

Known fail-closed compatibility surface now includes:

- `PhoneRemoteInvitation`;
- `WebRemoteSessionState`;
- `WebRemoteConfiguration.relayURL()` returning `nil`;
- `RemoteVoiceStartResult`;
- `WatchBluetoothAudioSignalMetrics`;
- no-op `PhoneRemoteServer` lifecycle/state APIs;
- no-op `WatchBluetoothRemoteServer` lifecycle/state APIs;
- no-op `WebRemoteRelayClient` lifecycle/state/audio APIs;
- no-op button-title updates.

The remaining compatibility gap is concentrated in callbacks that directly cross into host action/button types, especially mobile/Watch button events and Web Remote command/button callbacks.

### 7. Recording asset path traversal hardening

`RecordingAssetPathPolicy` now:

- rejects absolute paths;
- rejects empty path segments;
- rejects `.` and `..` segments;
- rejects backslash-separated paths;
- restricts each component to an explicit safe character set;
- standardizes the resulting URL and verifies it remains below the recording root.

`RecordingAssetStore` uses this policy when loading manifests, resolving media files and running integrity checks. Regression tests cover traversal, absolute paths, empty segments and unexpected characters.

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

MCP should still remain disabled unless explicitly needed.

### Transcript and original-audio recording

Fresh installs default both local transcript history and original-audio recording to disabled. Keep those defaults for sensitive deployments.

## Open findings / blockers

### BLOCKER: hardened-remote host build is not yet verified

The manifest still contains the pinned upstream package as a transitional fallback for normal builds, but `REMOTE_MIC_HARDENED_REMOTE=1` excludes it from the dependency graph.

The next requirement is to make the entire host compile in hardened mode. The remaining known interface coupling is primarily:

- mobile/Watch `onButtonEvent` callbacks tied to host button/action types;
- Web Remote command/button callbacks tied to host action decoding;
- tests that directly expect behavior from the private package.

The target architecture is not to recreate those transports. Those callbacks should be removed or made inert so the RC003 Bluetooth path remains independent.

### OPEN: GitHub Actions not executing on the fork

The hardened workflow is committed, but the repository currently reports zero workflow runs for `security-hardening` despite pushes to the branch. Until repository Actions are enabled, CI definitions cannot provide runtime build evidence.

## Recommended deployment permissions

For a Bluetooth RC003-only deployment:

| Capability | Default |
|---|---|
| Bluetooth | Allow |
| Local Network | Not declared by hardened build |
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
3. Do not restore environment-controlled private production package injection.
4. Hardened compatibility modules must remain transport-free.
5. Do not merge `security-hardening` into `main` until the hardened-remote mode passes a clean resolve, full tests and release build.
6. Do not distribute a signed release until the transitional upstream remote dependency is removed from the manifest and runtime network/permission observation passes.

## Next gate

1. Finish/remove the remaining host-coupled button/command callbacks.
2. Build with `REMOTE_MIC_HARDENED_REMOTE=1` and verify the private package is absent from `swift package show-dependencies`.
3. Run full tests and Apple Silicon/Intel release builds.
4. Remove the transitional upstream `sayall-mac-remote` declaration and its `Package.resolved` pin.
5. Remove remaining dead mobile/Watch/Web UI and lifecycle code.
6. Perform runtime network and permission observation before approving deployment.
