import SwiftUI

public struct AppPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 50)
            .background(AppGradients.violet)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.button))
            .opacity(isEnabled ? 1 : 0.45)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(AppMotion.quick, value: configuration.isPressed)
    }
}
