//
//  PriceFormatter.swift
//  EatAndPay
//
//  Created by Чалов Алексей Вячеславович on 05.07.2026.
//

import Foundation

enum PriceFormatter {
    static func format(_ price: Decimal) -> String {
        let number = NSDecimalNumber(decimal: price)
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₽"
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        formatter.locale = Locale(identifier: "ru_RU")
        
        return formatter.string(from: number) ?? "\(price) ₽"
    }
}
