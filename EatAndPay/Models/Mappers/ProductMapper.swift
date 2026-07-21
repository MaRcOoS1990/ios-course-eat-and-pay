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

extension ProductMapper {
    
    static func map(_ preview: Components.Schemas.ProductPreview) -> Product {
        Product(
            id: preview.id,
            name: preview.name,
            price: Decimal(preview.price),
            imageURL: makeImageURL(from: preview.image),
            weight: Int(preview.weight),
            rating: Double(preview.rating),
            reviewCount: preview.reviewCount,
            isFavorite: preview.isFavorite,
            discount: preview.discount.map { Int($0) }
        )
    }
    
    static func map(_ product: Components.Schemas.Product) -> Product {
        Product(
            id: product.id,
            name: product.name,
            price: Decimal(product.price),
            imageURL: makeImageURL(from: product.image),
            weight: Int(product.weight),
            rating: Double(product.rating),
            reviewCount: product.reviews?.count,
            isFavorite: product.isFavorite,
            discount: product.discount.map { Int($0) },
            description: product.description
        )
    }
}
