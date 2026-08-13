//
//  AppFactory.swift
//  EatAndPay
//

import Foundation

enum AppFactory {
    
    static func makeCatalogService() -> any CatalogService {
        OpenAPICatalogService()
    }

    static func makeCategoryService() -> any CategoryService {
        OpenAPICategoryService()
    }

    static func makeFavoriteService() -> any FavoriteService {
        OpenAPIFavoriteService()
    }
    
    static func makeCartService() -> any CartService {
        MockCartService()
    }
    
    static func makeProductDetailService() -> any ProductDetailService {
        OpenAPIProductDetailService()
    }
}
