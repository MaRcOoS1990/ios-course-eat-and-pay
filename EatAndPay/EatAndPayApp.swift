//
//  EatAndPayApp.swift
//  EatAndPay
//

import SwiftUI

@main
struct EatAndPayApp: App {
    var body: some Scene {
        WindowGroup {
            RootTabView(
                catalogService: AppFactory.makeCatalogService(),
                categoryService: AppFactory.makeCategoryService(),
                favoriteService: AppFactory.makeFavoriteService(),
                cartService: AppFactory.makeCartService(),
                productDetailService: AppFactory.makeProductDetailService()
            )
        }
    }
}
