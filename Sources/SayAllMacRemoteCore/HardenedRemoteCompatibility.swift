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
