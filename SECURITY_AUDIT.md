# Security hardening audit

Audit date: 2026-09-05

Baseline: `HD838A/remote-mic-app` / fork baseline commit `4cc7be24d5a2462d8673090fe1d19fc451a34d52`.

Target branch: `security-hardening`.

## Current verdict

**Not yet approved for production/high-sensitivity deployment.**

The fork removes several avoidable trust and network risks, but a required dependency (`GetSayAll/sayall-mac-remote`) is not publicly accessible from an unauthenticated/normal external GitHub client. Until that dependency is replaced and an independent build succeeds, this repository cannot be treated as a fully independent, reproducible, publicly auditable build.

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

### 4. Local Network / Bonjour declarations

The Bluetooth-only hardening target does not require nearby iPhone/iPad/Watch LAN discovery.

The hardening branch therefore removes:

- `NSLocalNetworkUsageDescription`;
- `_remotemic._tcp` from `NSBonjourServices`.

The Bluetooth permission description is narrowed to supported Bluetooth remote controls. This prevents the hardened binary from requesting Local Network access while the mobile/Watch/Web code is being removed from the source graph.

### 5. Upstream release/agent workflows

Upstream workflows that depend on private deploy keys, private signing repositories, upstream release infrastructure and SayAll Agent automation have been removed from the hardening branch.

The remaining `mac-ci.yml` is fork-specific and uses read-only repository permissions. It currently enforces the security baseline and will only run the independent Swift build gate after the private `sayall-mac-remote` dependency is removed.

### 6. Local compatibility-layer extraction started

The hardening branch now contains local, auditable compatibility modules under:

- `Sources/SayAllMacRemoteCore/`;
- `Sources/SayAllMacRemoteUI/`.

These modules are intentionally inert. They are not yet wired into `Package.swift`; the current private dependency remains the active build dependency until all required host-side interfaces have been modeled and the switch can be made without breaking the RC003 Bluetooth path.

The compatibility layer will not reimplement Bonjour discovery, phone/watch listeners, WebSocket relay logic or cloud/Web Remote functionality.

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

The direct public-source dependency surface is limited enough to support a staged removal. Direct imports are concentrated in:

- `Sources/RemoteMic/BridgeAppModel.swift`;
- `Sources/RemoteMic/SettingsView.swift`;
- `Sources/RemoteMic/OnboardingView.swift`;
- `Sources/RemoteMic/PhoneRemoteInvitationView.swift`;
- `Tests/RemoteMicTests/WatchBluetoothVoiceJourneyTests.swift` (test-only).

`BridgeAppModel` is the main coupling point and currently owns nearby phone, nearby Watch and Web Remote state/servers in the same model as the Xiaomi Bluetooth path.

**Current replacement strategy:** model the minimum compile-time interface locally, make all mobile/Watch/Web behavior inert, then switch SwiftPM from the private package to the local compatibility targets. After the switch succeeds, physically remove obsolete UI/state/callback code in smaller follow-up commits.

**Required resolution before deployment:**

1. finish the local compatibility interface required by the host;
2. replace `SayAllMacRemoteCore/UI` package products with local targets;
3. remove the private dependency and pin from `Package.swift` / `Package.resolved`;
4. run a clean build and test suite without any mirror/deploy key;
5. remove remaining dead mobile/Watch/Web UI and lifecycle code.

### OPEN: local recording manifest path hardening

`RecordingAssetStore` accepts a manifest-provided relative media path. The current character-based validation allows slash-separated path text and does not reject every `..` path segment before `mediaURLWithoutQueue` derives a filesystem location.

Normal application-generated manifests do not contain traversal paths, so this is not currently assessed as a remote exploit. However a locally tampered manifest could influence later lookup/delete behavior.

**Mitigation now:** original-audio recording remains off by default and should remain off for sensitive deployments.

**Required code fix before enabling recording:** validate every relative path component, reject empty/`.`/`..` components and absolute paths, standardize the resulting URL, and verify the standardized/resolved URL remains below the recording root before playback, integrity checks or deletion.

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
3. Keep dependency revisions/version floors explicit.
4. Do not restore environment-controlled private production package injection.
5. Do not merge `security-hardening` into `main` until an independent clean build and test run succeeds.
6. Do not distribute a signed release until the `sayall-mac-remote` blocker is resolved.

## Next gate

The next security gate is **switching from the inaccessible remote package to the local compatibility modules**, followed by a clean SwiftPM resolve/test/release build. After that succeeds, remove dead mobile/Watch/Web code and perform runtime network/permission observation before approving deployment.
