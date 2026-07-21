//
//  QuantityControl.swift
//  EatAndPay
//
//  Created by Чалов Алексей Вячеславович on 21.07.2026.
//

import SwiftUI

struct QuantityControl: View {
    
    let quantity: Int
    let fillsWidth: Bool
    let onDecrease: () -> Void
    let onIncrease: () -> Void
    
    init(
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
    
    var body: some View {
        HStack {
            Button {
                onDecrease()
            } label: {
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
            
            Button {
                onIncrease()
            } label: {
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
