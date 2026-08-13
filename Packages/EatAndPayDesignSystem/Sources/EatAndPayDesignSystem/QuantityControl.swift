import SwiftUI

public struct QuantityControl: View {
    private let quantity: Int
    private let fillsWidth: Bool
    private let onDecrease: () -> Void
    private let onIncrease: () -> Void

    public init(
        quantity: Int,
        fillsWidth: Bool = false,
        onDecrease: @escaping () -> Void,
        onIncrease: @escaping () -> Void
    ) {
        self.quantity = quantity
        self.fillsWidth = fillsWidth
        self.onDecrease = onDecrease
        self.onIncrease = onIncrease
    }

    public var body: some View {
        HStack {
            Button(action: onDecrease) {
                Image(systemName: "minus")
                    .font(.system(size: 16, weight: .bold))
                    .frame(width: 36, height: 36)
            }

            if fillsWidth {
                Spacer()
            }

            Text("\(quantity)")
                .font(.system(size: 17, weight: .semibold))
                .frame(minWidth: 24)

            if fillsWidth {
                Spacer()
            }

            Button(action: onIncrease) {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .bold))
                    .frame(width: 36, height: 36)
            }
        }
        .foregroundStyle(AppColors.primaryText)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .frame(maxWidth: fillsWidth ? .infinity : nil)
        .background(Color.purple.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.button))
        .buttonStyle(.plain)
    }
}
