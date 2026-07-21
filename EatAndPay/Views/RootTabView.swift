//
//  RootTabView.swift
//  EatAndPay
//
//  Created by Чалов Алексей Вячеславович on 21.07.2026.
//

import SwiftUI

struct RootTabView: View {
    
    private let catalogService: any CatalogService
    private let cartService: any CartService
    private let productDetailService: any ProductDetailService
    
    @State private var products: [Product] = []
    @State private var cartQuantities: [String: Int] = [:]
    
    init(
        catalogService: any CatalogService,
        cartService: any CartService,
        productDetailService: any ProductDetailService
    ) {
        self.catalogService = catalogService
        self.cartService = cartService
        self.productDetailService = productDetailService
    }
    
    var body: some View {
        TabView {
            ProductListView(
                catalogService: catalogService,
                productDetailService: productDetailService,
                cartQuantities: $cartQuantities,
                onProductsLoaded: { loadedProducts in
                    products = loadedProducts
                }
            )
            .tabItem {
                Label("Каталог", systemImage: "square.grid.2x2")
            }
            
            NavigationStack {
                CartView(
                    products: products,
                    quantities: cartQuantities,
                    onAddToCart: { product in
                        addToCart(product)
                    },
                    onRemoveFromCart: { product in
                        removeFromCart(product)
                    },
                    onCheckout: {
                        checkout()
                    }
                )
            }
            .tabItem {
                Label("Корзина", systemImage: "cart")
            }
            .badge(cartItemsCount)
        }
    }
    
    private var cartItemsCount: Int {
        cartQuantities.values.reduce(0, +)
    }
    
    private func addToCart(_ product: Product) {
        cartQuantities[product.id, default: 0] += 1
    }
    
    private func removeFromCart(_ product: Product) {
        let currentQuantity = cartQuantities[product.id, default: 0]
        
        if currentQuantity <= 1 {
            cartQuantities[product.id] = nil
        } else {
            cartQuantities[product.id] = currentQuantity - 1
        }
    }
    
    private func checkout() {
        print("Checkout:", cartQuantities)
        cartQuantities = [:]
    }
}
