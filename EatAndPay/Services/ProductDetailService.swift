//
//  ProductDetailService.swift
//  EatAndPay
//
//  Created by Чалов Алексей Вячеславович on 21.07.2026.
//

import Foundation

protocol ProductDetailService {
    func loadProduct(id: String) async throws -> Product
}

struct MockProductDetailService: ProductDetailService {
    func loadProduct(id: String) async throws -> Product {
        Product.mockProducts.first { $0.id == id } ?? Product.mockProducts[0]
    }
}

struct ErrorProductDetailService: ProductDetailService {
    func loadProduct(id: String) async throws -> Product {
        throw ProductDetailServiceError.failedToLoadProduct
    }
}

enum ProductDetailServiceError: LocalizedError {
    case failedToLoadProduct
    case notFound
    case unauthorized
    case unexpectedStatusCode(Int)
    
    var errorDescription: String? {
        switch self {
        case .failedToLoadProduct:
            return "Не удалось загрузить товар"
        case .notFound:
            return "Товар не найден"
        case .unauthorized:
            return "Не удалось авторизоваться"
        case .unexpectedStatusCode(let statusCode):
            return "Неожиданный статус ответа: \(statusCode)"
        }
    }
}
