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
                cartService: AppFactory.makeCartService(),
                productDetailService: AppFactory.makeProductDetailService()
            )
        }
    }
}
