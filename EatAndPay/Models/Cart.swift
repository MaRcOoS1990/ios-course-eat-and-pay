//
//  Cart.swift
//  EatAndPay
//
//  Created by Codex on 13.08.2026.
//

import Foundation

struct Cart {
    private(set) var quantities: [Product.ID: Int] = [:]

    var itemsCount: Int {
        quantities.values.reduce(0, +)
    }

    var isEmpty: Bool {
        quantities.isEmpty
    }

    func quantity(for productID: Product.ID) -> Int {
        quantities[productID, default: 0]
    }

    func totalPrice(for products: [Product]) -> Decimal {
        products.reduce(Decimal.zero) { result, product in
            result + product.price * Decimal(quantity(for: product.id))
        }
    }

    func canCheckout(with products: [Product]) -> Bool {
        !isEmpty && totalPrice(for: products) > .zero
    }

    mutating func add(_ productID: Product.ID) {
        quantities[productID, default: 0] += 1
    }

    mutating func remove(_ productID: Product.ID) {
        let currentQuantity = quantity(for: productID)

        if currentQuantity <= 1 {
            quantities[productID] = nil
        } else {
            quantities[productID] = currentQuantity - 1
        }
    }

    mutating func removeAll() {
        quantities.removeAll()
    }
}
