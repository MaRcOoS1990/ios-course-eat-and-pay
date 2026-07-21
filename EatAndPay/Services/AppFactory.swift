//
//  AppFactory.swift
//  EatAndPay
//

import Foundation

enum AppFactory {
    
    static func makeCatalogService() -> any CatalogService {
        OpenAPICatalogService()
    }
    
    static func makeCartService() -> any CartService {
        MockCartService()
    }
    
    static func makeProductDetailService() -> any ProductDetailService {
        OpenAPIProductDetailService()
    }
}
