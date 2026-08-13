//
//  ProductSearch.swift
//  EatAndPay
//
//  Created by Codex on 13.08.2026.
//

import Foundation

enum ProductSearch {
    static func filter(_ products: [Product], by query: String) -> [Product] {
        let query = normalized(query)

        guard !query.isEmpty else {
            return products
        }

        return products.filter {
            $0.name.localizedCaseInsensitiveContains(query)
        }
    }

    static func suggestions(
        from products: [Product],
        matching query: String,
        limit: Int = 5
    ) -> [String] {
        let query = normalized(query)

        guard !query.isEmpty else {
            return []
        }

        var usedNames = Set<String>()

        return products.compactMap { product in
            guard product.name.localizedCaseInsensitiveContains(query) else {
                return nil
            }

            let key = product.name.folding(
                options: [.caseInsensitive, .diacriticInsensitive],
                locale: .current
            )

            guard usedNames.insert(key).inserted else {
                return nil
            }

            return product.name
        }
        .prefix(limit)
        .map { $0 }
    }

    private static func normalized(_ query: String) -> String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
