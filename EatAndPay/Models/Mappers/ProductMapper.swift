//
//  ProductMapper.swift
//  EatAndPay
//
//  Created by Чалов Алексей Вячеславович on 05.07.2026.
//

import Foundation

enum ProductMapper {
    static func map(_ dto: ProductDTO) -> Product {
        Product(
            id: dto.id,
            name: dto.name,
            price: dto.price,
            imageURL: makeImageURL(from: dto.image),
            weight: dto.weight,
            rating: dto.rating,
            reviewCount: dto.reviewCount,
            isFavorite: dto.isFavorite ?? false,
            discount: dto.discount
        )
    }
    
    private static func makeImageURL(from image: String?) -> URL? {
        guard let image, !image.isEmpty else {
            return nil
        }
        
        return URL(string: image)
    }
}
