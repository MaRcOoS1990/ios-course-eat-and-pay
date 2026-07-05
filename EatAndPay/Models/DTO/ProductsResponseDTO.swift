//
//  ProductsResponseDTO.swift
//  EatAndPay
//
//  Created by Чалов Алексей Вячеславович on 05.07.2026.
//

import Foundation

struct ProductsResponseDTO: Decodable {
    let currentPage: Int
    let totalPages: Int
    let data: [ProductDTO]
}
