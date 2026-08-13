import SwiftUI

public enum AppGradients {
    public static let smoky = LinearGradient(
        colors: [
            Color(red: 254 / 255, green: 241 / 255, blue: 251 / 255),
            Color(red: 249 / 255, green: 239 / 255, blue: 253 / 255),
            Color(red: 244 / 255, green: 237 / 255, blue: 1)
        ],
        startPoint: .leading,
        endPoint: .trailing
    )

    public static let violet = LinearGradient(
        colors: [
            Color(red: 237 / 255, green: 60 / 255, blue: 202 / 255),
            Color(red: 174 / 255, green: 26 / 255, blue: 232 / 255),
            Color(red: 102 / 255, green: 0, blue: 1)
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
}
