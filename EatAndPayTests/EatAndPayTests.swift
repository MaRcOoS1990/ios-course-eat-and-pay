//
//  EatAndPayTests.swift
//  EatAndPayTests
//
//  Created by Чалов Алексей on 03.07.2026.
//

import Foundation
import Testing
@testable import EatAndPay

struct EatAndPayTests {

    @Test func addingProductIncreasesItsQuantity() {
        var cart = Cart()

        cart.add("product-1")
        cart.add("product-1")

        #expect(cart.quantity(for: "product-1") == 2)
        #expect(cart.itemsCount == 2)
    }

    @Test func removingLastProductRemovesItFromCart() {
        var cart = Cart()
        cart.add("product-1")

        cart.remove("product-1")

        #expect(cart.quantity(for: "product-1") == 0)
        #expect(cart.isEmpty)
    }

    @Test func removingProductDecreasesItsQuantity() {
        var cart = Cart()
        cart.add("product-1")
        cart.add("product-1")

        cart.remove("product-1")

        #expect(cart.quantity(for: "product-1") == 1)
        #expect(cart.itemsCount == 1)
    }

    @Test func removingMissingProductKeepsCartEmpty() {
        var cart = Cart()

        cart.remove("missing-product")

        #expect(cart.isEmpty)
        #expect(cart.itemsCount == 0)
    }

    @Test func totalPriceUsesProductQuantity() {
        let firstProduct = Product(id: "product-1", name: "Первый товар", price: 125)
        let secondProduct = Product(id: "product-2", name: "Второй товар", price: 80)
        var cart = Cart()
        cart.add(firstProduct.id)
        cart.add(firstProduct.id)
        cart.add(secondProduct.id)

        let totalPrice = cart.totalPrice(for: [firstProduct, secondProduct])

        #expect(totalPrice == Decimal(330))
    }

    @Test func removeAllClearsCart() {
        var cart = Cart()
        cart.add("product-1")
        cart.add("product-2")

        cart.removeAll()

        #expect(cart.isEmpty)
        #expect(cart.itemsCount == 0)
    }

    @Test func checkoutIsAvailableForProductWithPositivePrice() {
        let product = Product(id: "product-1", name: "Товар", price: 100)
        var cart = Cart()
        cart.add(product.id)

        #expect(cart.canCheckout(with: [product]))
    }

    @Test func checkoutIsUnavailableForEmptyCart() {
        let product = Product(id: "product-1", name: "Товар", price: 100)
        let cart = Cart()

        #expect(!cart.canCheckout(with: [product]))
    }

    @Test func emptySearchQueryReturnsAllProducts() {
        let products = searchProducts

        let result = ProductSearch.filter(products, by: "   ")

        #expect(result.map(\.id) == products.map(\.id))
    }

    @Test func searchIgnoresLetterCase() {
        let result = ProductSearch.filter(searchProducts, by: "хЛеБ")

        #expect(result.map(\.name) == ["Хлеб", "Хлеб зерновой"])
    }

    @Test func suggestionsDoNotContainDuplicateNames() {
        let products = searchProducts + [
            Product(id: "product-4", name: "Хлеб", price: 75)
        ]

        let suggestions = ProductSearch.suggestions(
            from: products,
            matching: "хлеб"
        )

        #expect(suggestions == ["Хлеб", "Хлеб зерновой"])
    }

    @Test func suggestionsRespectLimit() {
        let products = (1...7).map { index in
            Product(
                id: "product-\(index)",
                name: "Хлеб \(index)",
                price: 50
            )
        }

        let suggestions = ProductSearch.suggestions(
            from: products,
            matching: "хлеб",
            limit: 5
        )

        #expect(suggestions == ["Хлеб 1", "Хлеб 2", "Хлеб 3", "Хлеб 4", "Хлеб 5"])
    }

    @Test func togglingFavoriteAddsAndRemovesProduct() {
        var favorites = Favorites()

        favorites.toggle("product-1")

        #expect(favorites.contains("product-1"))
        #expect(favorites.count == 1)

        favorites.toggle("product-1")

        #expect(!favorites.contains("product-1"))
        #expect(favorites.isEmpty)
    }

    @Test func favoritesDoNotContainDuplicateProducts() {
        var favorites = Favorites(productIDs: ["product-1"])

        favorites.synchronize(with: [
            Product(id: "product-1", name: "Хлеб", price: 65, isFavorite: true)
        ])

        #expect(favorites.count == 1)
    }

    @Test func synchronizationUsesServerFavoriteValue() {
        var favorites = Favorites(productIDs: ["product-1"])

        favorites.synchronize(with: [
            Product(id: "product-1", name: "Хлеб", price: 65, isFavorite: false),
            Product(id: "product-2", name: "Молоко", price: 90, isFavorite: true)
        ])

        #expect(!favorites.contains("product-1"))
        #expect(favorites.contains("product-2"))
    }

    @Test func synchronizationKeepsFavoritesMissingFromPartialCatalog() {
        var favorites = Favorites(productIDs: ["product-from-another-category"])

        favorites.synchronize(with: [
            Product(id: "product-1", name: "Хлеб", price: 65, isFavorite: true)
        ])

        #expect(favorites.contains("product-from-another-category"))
        #expect(favorites.contains("product-1"))
        #expect(favorites.count == 2)
    }

    private var searchProducts: [Product] {
        [
            Product(id: "product-1", name: "Хлеб", price: 65),
            Product(id: "product-2", name: "Хлеб зерновой", price: 85),
            Product(id: "product-3", name: "Молоко", price: 90)
        ]
    }

}
