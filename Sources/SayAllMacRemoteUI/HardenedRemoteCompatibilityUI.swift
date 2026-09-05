import SwiftUI
import SayAllMacRemoteCore

/// Marker protocol used by the hardened fork while the upstream private remote
/// UI package is being removed. The RC003-only build intentionally provides no
/// web/phone/watch remote controls.
public protocol WebRemoteSessionModel: AnyObject {}

public struct WebRemoteSessionLocalization {
    public let locale: Locale
    public let text: (String) -> String

    public init(locale: Locale, text: @escaping (String) -> String) {
        self.locale = locale
        self.text = text
    }
}

public struct WebRemoteSessionView<Model: WebRemoteSessionModel>: View {
    private let model: Model
    private let localization: WebRemoteSessionLocalization

    public init(model: Model, localization: WebRemoteSessionLocalization) {
        self.model = model
        self.localization = localization
    }

    public var body: some View {
        EmptyView()
    }
}
