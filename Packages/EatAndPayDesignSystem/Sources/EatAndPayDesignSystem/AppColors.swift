import SwiftUI

public enum AppColors {
    public static let screenBackground = Color.white
    public static let cardBackground = Color.white
    public static let imageBackground = Color.gray.opacity(0.05)
    public static let catalogSecondaryText = Color(
        red: 151 / 255,
        green: 151 / 255,
        blue: 175 / 255
    )
    public static let favoriteInactive = Color(
        red: 189 / 255,
        green: 189 / 255,
        blue: 189 / 255
    )
    public static let favoriteActive = Color(
        red: 237 / 255,
        green: 60 / 255,
        blue: 202 / 255
    )
    public static let productImageOverlay = Color.black.opacity(0.03)
    public static let accent = Color.blue
    public static let primaryText = Color.primary
    public static let secondaryText = Color.secondary
    public static let errorText = Color.red
}
