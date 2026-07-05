//
//  CatalogService.swift
//  EatAndPay
//
//  Created by Чалов Алексей Вячеславович on 05.07.2026.
//

import Foundation

protocol CatalogService {
    func loadProducts() async throws -> [Product]
}

struct MockCatalogService: CatalogService {
    func loadProducts() async throws -> [Product] {
        let dtoProducts: [ProductDTO] = [
            ProductDTO(
                id: "1",
                name: "Выпечка",
                price: 120,
                image: "birthday.cake",
                weight: 300,
                rating: 4.8,
                reviewCount: 120,
                isFavorite: false,
                discount: nil
            ),
            ProductDTO(
                id: "2",
                name: "Готовая еда",
                price: 350,
                image: "takeoutbag.and.cup.and.straw",
                weight: 450,
                rating: 4.6,
                reviewCount: 98,
                isFavorite: false,
                discount: nil
            ),
            ProductDTO(
                id: "3",
                name: "Молочные продукты",
                price: 180,
                image: "cup.and.saucer",
                weight: 1000,
                rating: 4.7,
                reviewCount: 72,
                isFavorite: false,
                discount: nil
            )
        ]
        
        return dtoProducts.map { ProductMapper.map($0) }
    }
}

struct EmptyCatalogService: CatalogService {
    func loadProducts() async throws -> [Product] {
        []
    }
}

struct ErrorCatalogService: CatalogService {
    func loadProducts() async throws -> [Product] {
        throw CatalogServiceError.failedToLoadProducts
    }
}

enum CatalogServiceError: Error {
    case failedToLoadProducts
}
