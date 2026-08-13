//
//  FavoriteService.swift
//  EatAndPay
//
//  Created by Codex on 13.08.2026.
//

import Foundation

protocol FavoriteService {
    func setFavorite(_ isFavorite: Bool, productID: Product.ID) async throws
}

struct MockFavoriteService: FavoriteService {
    func setFavorite(_ isFavorite: Bool, productID: Product.ID) async throws {}
}
