//
//  ProductDTO.swift
//  EatAndPay
//
//  Created by Чалов Алексей Вячеславович on 05.07.2026.
//

import Foundation

struct ProductDTO: Decodable {
    let id: String
    let name: String
    let price: Decimal
    let image: String?
    let weight: Int?
    let rating: Double?
    let reviewCount: Int?
    let isFavorite: Bool?
    let discount: Int?
}
