//
//  Product.swift
//  EatAndPay
//
//  Created by Чалов Алексей Вячеславович on 05.07.2026.
//

import Foundation

struct Product: Identifiable {
    let id: String
    let name: String
    let price: Decimal
    let imageURL: URL?
    let weight: Int?
    let rating: Double?
    let reviewCount: Int?
    let isFavorite: Bool
    let discount: Int?
    let description: String?
    
    init(
        id: String = UUID().uuidString,
        name: String,
        price: Decimal,
        imageURL: URL? = nil,
        weight: Int? = nil,
        rating: Double? = nil,
        reviewCount: Int? = nil,
        isFavorite: Bool = false,
        discount: Int? = nil,
        description: String? = nil
    ) {
        self.id = id
        self.name = name
        self.price = price
        self.imageURL = imageURL
        self.weight = weight
        self.rating = rating
        self.reviewCount = reviewCount
        self.isFavorite = isFavorite
        self.discount = discount
        self.description = description
    }
}

extension Product {
    static let mockProducts: [Product] = [
        Product(
            name: "Выпечка",
            price: 120,
            imageURL: nil,
            weight: 300,
            rating: 4.8,
            reviewCount: 120
        ),
        Product(
            name: "Готовая еда",
            price: 350,
            imageURL: nil,
            weight: 450,
            rating: 4.6,
            reviewCount: 98
        ),
        Product(
            name: "Молочные продукты",
            price: 180,
            imageURL: nil,
            weight: 1000,
            rating: 4.7,
            reviewCount: 72
        ),
        Product(
            name: "Напитки",
            price: 100,
            imageURL: nil,
            weight: 500,
            rating: 4.5,
            reviewCount: 64
        ),
        Product(
            name: "Сладости",
            price: 220,
            imageURL: nil,
            weight: 250,
            rating: 4.9,
            reviewCount: 140
        ),
        Product(
            name: "Товары для дома",
            price: 450,
            imageURL: nil,
            weight: nil,
            rating: 4.4,
            reviewCount: 51
        ),
        Product(
            name: "Фрукты",
            price: 190,
            imageURL: nil,
            weight: 1000,
            rating: 4.8,
            reviewCount: 200
        )
    ]
}
