import Foundation

/// Minimal, auditable compatibility surface for the hardened fork.
///
/// The upstream project obtains `SayAllMacRemoteCore` from a private package.
/// This local module is intentionally limited to inert value types first; network
/// listeners, relay clients, Bonjour discovery and Apple Watch/iPhone transports
/// will not be reimplemented for the Bluetooth-RC003-only fork.
public struct PhoneRemoteInvitation: Equatable, Sendable {
    public let url: URL?

    public init(url: URL? = nil) {
        self.url = url
    }
}

public enum WebRemoteSessionState: Equatable, Sendable {
    case disabled
    case unavailable

    public var isEnabled: Bool { false }
}

public enum RemoteVoiceStartResult: Equatable, Sendable {
    case started
    case busy
    case unavailable
}

/// Signal accumulator retained because the host uses it for diagnostics.
/// It performs no networking and stores no audio.
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
