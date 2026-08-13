//
//  Favorites.swift
//  EatAndPay
//
//  Created by Codex on 13.08.2026.
//

import Foundation

struct Favorites {
    private(set) var productIDs: Set<Product.ID>

    init(productIDs: Set<Product.ID> = []) {
        self.productIDs = productIDs
    }

    var isEmpty: Bool {
        productIDs.isEmpty
    }

    var count: Int {
        productIDs.count
    }

    func contains(_ productID: Product.ID) -> Bool {
        productIDs.contains(productID)
    }

    mutating func toggle(_ productID: Product.ID) {
        if productIDs.contains(productID) {
            productIDs.remove(productID)
        } else {
            productIDs.insert(productID)
        }
    }

    mutating func synchronize(with products: [Product]) {
        for product in products {
            if product.isFavorite {
                productIDs.insert(product.id)
            } else {
                productIDs.remove(product.id)
            }
        }
    }
}
