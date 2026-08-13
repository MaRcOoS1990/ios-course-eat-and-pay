//
//  CategoryService.swift
//  EatAndPay
//
//  Created by Codex on 13.08.2026.
//

import Foundation

protocol CategoryService {
    func loadCategories() async throws -> [Category]
}

struct MockCategoryService: CategoryService {
    func loadCategories() async throws -> [Category] {
        [
            Category(id: "bakery", name: "Выпечка", imageURL: nil),
            Category(id: "ready-food", name: "Готовая еда", imageURL: nil),
            Category(id: "drinks", name: "Напитки", imageURL: nil)
        ]
    }
}
