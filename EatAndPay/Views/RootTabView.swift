//
//  RootTabView.swift
//  EatAndPay
//
//  Created by Чалов Алексей Вячеславович on 21.07.2026.
//

import SwiftUI

struct RootTabView: View {
    
    private let catalogService: any CatalogService
    private let categoryService: any CategoryService
    private let favoriteService: any FavoriteService
    private let cartService: any CartService
    private let productDetailService: any ProductDetailService
    
    @State private var products: [Product] = []
    @State private var cart = Cart()
    @State private var favorites = Favorites()
    
    init(
        catalogService: any CatalogService,
        categoryService: any CategoryService,
        favoriteService: any FavoriteService,
        cartService: any CartService,
        productDetailService: any ProductDetailService
    ) {
        self.catalogService = catalogService
        self.categoryService = categoryService
        self.favoriteService = favoriteService
        self.cartService = cartService
        self.productDetailService = productDetailService
    }
    
    var body: some View {
        TabView {
            NavigationStack {
                ProductListView(
                    catalogService: catalogService,
                    productDetailService: productDetailService,
                    favoriteService: favoriteService,
                    cart: $cart,
                    favorites: $favorites,
                    onProductsLoaded: { loadedProducts in
                        mergeProducts(loadedProducts)
                    }
                )
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        NavigationLink {
                            CategoryListView(
                                categoryService: categoryService,
                                catalogService: catalogService,
                                productDetailService: productDetailService,
                                favoriteService: favoriteService,
                                cart: $cart,
                                favorites: $favorites,
                                onProductsLoaded: { loadedProducts in
                                    mergeProducts(loadedProducts)
                                }
                            )
                        } label: {
                            Label("Категории", systemImage: "square.grid.3x3")
                        }
                    }
                }
            }
            .tabItem {
                Label("Каталог", systemImage: "square.grid.2x2")
            }

            NavigationStack {
                FavoriteListView(
                    products: products,
                    productDetailService: productDetailService,
                    favoriteService: favoriteService,
                    cart: $cart,
                    favorites: $favorites
                )
            }
            .tabItem {
                Label("Избранное", systemImage: "heart.fill")
            }
            .badge(favorites.count)
            
            NavigationStack {
                CartView(
                    products: products,
                    cart: cart,
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
        cart.itemsCount
    }
    
    private func addToCart(_ product: Product) {
        cart.add(product.id)
    }
    
    private func removeFromCart(_ product: Product) {
        cart.remove(product.id)
    }
    
    private func checkout() {
        print("Checkout:", cart.quantities)
        cart.removeAll()
    }

    private func mergeProducts(_ loadedProducts: [Product]) {
        favorites.synchronize(with: loadedProducts)
        let loadedProductIDs = Set(loadedProducts.map(\.id))
        products.removeAll { loadedProductIDs.contains($0.id) }
        products.append(contentsOf: loadedProducts)
    }
}
