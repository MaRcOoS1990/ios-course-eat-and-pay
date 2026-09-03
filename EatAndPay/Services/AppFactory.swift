//
//  AppFactory.swift
//  EatAndPay
//

import Foundation

enum AppFactory {
    static func makeReviewService() -> any ReviewService {
        OpenAPIReviewService()
    }
    
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
        OpenAPICartService()
    }

    static func makeCartStore() -> CartStore {
        CartStore(service: makeCartService())
    }

    static func makeAddressService() -> any AddressService {
        OpenAPIAddressService()
    }

    static func makeOrderService() -> any OrderService {
        OpenAPIOrderService()
    }
    
    static func makeProductDetailService() -> any ProductDetailService {
        OpenAPIProductDetailService()
    }
}
