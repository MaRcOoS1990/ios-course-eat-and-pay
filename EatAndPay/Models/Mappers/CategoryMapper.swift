//
//  CategoryMapper.swift
//  EatAndPay
//
//  Created by Codex on 13.08.2026.
//

import Foundation

enum CategoryMapper {
    static func map(_ category: Components.Schemas.Category) -> Category {
        Category(
            id: category.id,
            name: category.name,
            imageURL: URL(string: category.image)
        )
    }
}
