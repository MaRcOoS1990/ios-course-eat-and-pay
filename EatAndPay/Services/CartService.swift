//
//  CartService.swift
//  EatAndPay
//
//  Created by Чалов Алексей Вячеславович on 05.07.2026.
//

import Foundation

protocol CartService {
    func addProduct(id: String) async throws
}

struct MockCartService: CartService {
    func addProduct(id: String) async throws {
        print("Mock add product to cart:", id)
    }
}

struct ErrorCartService: CartService {
    func addProduct(id: String) async throws {
        throw CartServiceError.failedToAddProduct
    }
}

enum CartServiceError: Error {
    case failedToAddProduct
}
