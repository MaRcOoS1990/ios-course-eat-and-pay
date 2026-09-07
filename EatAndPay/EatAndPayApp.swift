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
                cartStore: AppFactory.makeCartStore(),
                productDetailService: AppFactory.makeProductDetailService(),
                addressService: AppFactory.makeAddressService(),
                orderService: AppFactory.makeOrderService(),
                profileService: AppFactory.makeProfileService(),
                cartPersistence: SwiftDataCartPersistence(context: modelContainer.mainContext)
            )
            .modelContainer(modelContainer)
        }
    }
}
