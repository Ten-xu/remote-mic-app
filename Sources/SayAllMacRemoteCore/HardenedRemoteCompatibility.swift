import Foundation

/// Minimal, auditable compatibility surface for the hardened fork.
///
/// The upstream project obtains `SayAllMacRemoteCore` from a private package.
/// This local module is intentionally inert: it does not implement network
/// listeners, relay clients, Bonjour discovery, or Apple Watch/iPhone transports.
public struct PhoneRemoteInvitation: Equatable, Sendable {
    public let url: URL?

    public init(url: URL? = nil) {
        self.url = url
    }
}

public enum WebRemoteSessionState: Equatable, Sendable {
    case disabled
    case unavailable
    case connecting
    case waitingForPhone(URL, String, String?)
    case awaitingApproval(URL, String, String?)
    case connected(String)
    case failed(String?)

    /// Web Remote is intentionally unavailable in the RC003-only hardened fork.
    public var isEnabled: Bool { false }
}

/// Hardened fork policy: there is no relay endpoint. Keeping this API returning
/// nil makes any legacy Web Remote entry point fail closed while dead UI/state
/// code is removed in follow-up commits.
public enum WebRemoteConfiguration {
    public static func relayURL() -> URL? { nil }
}

public enum RemoteVoiceStartResult: Equatable, Sendable {
    case started
    case busy
    case unavailable
}

public typealias RemoteApprovalCompletion = (Bool) -> Void
public typealias RemoteVoiceStartCompletion = (RemoteVoiceStartResult) -> Void

/// No-op stand-in for the private nearby-phone listener.
///
/// Button-event callbacks are deliberately not modeled here yet because the
/// upstream package couples those callbacks to host button types. The hardened
/// extraction removes that coupling before the final dependency switch.
public final class PhoneRemoteServer {
    public var isIdentityTrusted: ((String) -> Bool)?
    public var onConnectionStateChange: ((Bool) -> Void)?
    public var onInvitationChange: ((PhoneRemoteInvitation?) -> Void)?
    public var onApprovalCancelled: (() -> Void)?
    public var onApprovalRequested: ((String, String, String?, RemoteApprovalCompletion) -> Void)?
    public var onVoiceStartResult: ((RemoteVoiceStartCompletion) -> Void)?
    public var onVoiceStop: (() -> Void)?
    public var onAudio: (([Int16]) -> Void)?
    public var onButtonEventsReset: (() -> Void)?

    private let logger: (String) -> Void

    public init(logger: @escaping (String) -> Void = { _ in }) {
        self.logger = logger
    }

    public func start() {
        logger("HARDENED PHONE REMOTE blocked")
        onConnectionStateChange?(false)
        onInvitationChange?(nil)
    }

    public func stop() {
        onConnectionStateChange?(false)
        onInvitationChange?(nil)
    }

    public func updateButtonTitles(_: [String: String]) {}
}

/// No-op stand-in for the private Watch BLE remote server.
public final class WatchBluetoothRemoteServer {
    public var isIdentityTrusted: ((String) -> Bool)?
    public var onConnectionStateChange: ((Bool) -> Void)?
    public var onApprovalCancelled: (() -> Void)?
    public var onApprovalRequested: ((String, String, String?, RemoteApprovalCompletion) -> Void)?
    public var onVoiceStartResult: ((RemoteVoiceStartCompletion) -> Void)?
    public var onVoiceStop: (() -> Void)?
    public var onAudio: (([Int16]) -> Void)?
    public var onButtonEventsReset: (() -> Void)?

    private let logger: (String) -> Void

    public init(logger: @escaping (String) -> Void = { _ in }) {
        self.logger = logger
    }

    public func start() {
        logger("HARDENED WATCH REMOTE blocked")
        onConnectionStateChange?(false)
    }

    public func stop() {
        onConnectionStateChange?(false)
    }

    public func updateButtonTitles(_: [String: String]) {}
}

/// No-op stand-in for the private WebSocket relay client.
public final class WebRemoteRelayClient {
    public var onStateChange: ((WebRemoteSessionState) -> Void)?
    public var onApprovalCancelled: (() -> Void)?
    public var onApprovalRequested: ((String, String, RemoteApprovalCompletion) -> Void)?
    public var onVoiceStart: ((RemoteVoiceStartCompletion) -> Void)?
    public var onVoiceStop: (() -> Void)?
    public var onAudio: (([Int16]) -> Void)?

    public init() {}

    public func start(
        relayURL _: URL,
        macName _: String,
        appVersion _: String?,
        buttonTitles _: [String: String]
    ) {
        onStateChange?(.unavailable)
    }

    public func stop() {
        onStateChange?(.disabled)
    }

    public func updateButtonTitles(_: [String: String]) {}
}

/// Signal accumulator retained because the host uses it for diagnostics.
/// It performs no networking and stores no audio beyond aggregate counters.
public struct WatchBluetoothAudioSignalMetrics: Equatable, Sendable {
    public private(set) var sampleCount = 0
    public private(set) var nonZeroSampleCount = 0
    public private(set) var peak = 0
    public private(set) var rms = 0

    public init() {}

    public mutating func append(_ samples: [Int16]) {
        guard !samples.isEmpty else { return }
        sampleCount += samples.count
        nonZeroSampleCount += samples.reduce(into: 0) { count, sample in
            if sample != 0 { count += 1 }
        }
        peak = max(peak, samples.map { abs(Int($0)) }.max() ?? 0)
        let squareSum = samples.reduce(into: Double(0)) { result, sample in
            let value = Double(sample)
            result += value * value
        }
        rms = Int((squareSum / Double(samples.count)).squareRoot().rounded())
    }
}
