//
//  EatAndPayApp.swift
//  EatAndPay
//

import SwiftUI
import SwiftData

@main
struct EatAndPayApp: App {
    private let modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try ModelContainer(for: CartItemEntity.self)
        } catch {
            fatalError("Не удалось создать локальное хранилище корзины: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootTabView(
                catalogService: AppFactory.makeCatalogService(),
                categoryService: AppFactory.makeCategoryService(),
                favoriteService: AppFactory.makeFavoriteService(),
                cartService: AppFactory.makeCartService(),
                productDetailService: AppFactory.makeProductDetailService(),
                addressService: AppFactory.makeAddressService(),
                orderService: AppFactory.makeOrderService(),
                cartPersistence: SwiftDataCartPersistence(context: modelContainer.mainContext)
            )
            .modelContainer(modelContainer)
        }
    }
}
