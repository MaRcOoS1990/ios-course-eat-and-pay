//
//  ProductListView.swift
//  EatAndPay
//
//  Created by Чалов Алексей on 03.07.2026.
//

import SwiftUI

struct ProductListView: View {
    private let catalogService: any CatalogService
    private let onProductsLoaded: ([Product]) -> Void
    private let productDetailService: any ProductDetailService
    
    @State private var state: CatalogState = .loading
    @Binding private var cartQuantities: [String: Int]
    
    init(
        catalogService: any CatalogService = MockCatalogService(),
        productDetailService: any ProductDetailService = MockProductDetailService(),
        cartQuantities: Binding<[String: Int]> = .constant([:]),
        onProductsLoaded: @escaping ([Product]) -> Void = { _ in }
    ) {
        self.catalogService = catalogService
        self.productDetailService = productDetailService
        self._cartQuantities = cartQuantities
        self.onProductsLoaded = onProductsLoaded
    }
    
    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: AppSpacing.large),
        GridItem(.flexible(), spacing: AppSpacing.large)
    ]
    
    var body: some View {
        NavigationStack {
            Group {
                switch state {
                case .loading:
                    ProgressView("Загрузка каталога...")
                    
                case let .content(products):
                    catalogGrid(products: products)
                    
                case .empty:
                    Text("Каталог пока пуст")
                        .foregroundStyle(AppColors.secondaryText)
                        .padding()
                    
                case let .error(message):
                    Text(message)
                        .foregroundStyle(AppColors.errorText)
                        .padding()
                }
            }
            .navigationTitle("Каталог")
            .task {
                if case .loading = state {
                    await loadProducts()
                }
            }
        }
    }
    
    private func catalogGrid(products: [Product]) -> some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: AppSpacing.extraLarge) {
                ForEach(products) { product in
                    NavigationLink {
                        ProductDetailView(
                            product: product,
                            productDetailService: productDetailService,
                            quantity: quantity(for: product),
                            onAddToCart: { product in
                                addToCart(product)
                            },
                            onRemoveFromCart: { product in
                                removeFromCart(product)
                            }
                        )
                    } label: {
                        ProductCard(
                            product: product,
                            quantity: quantity(for: product),
                            onAddToCart: { product in
                                addToCart(product)
                            },
                            onRemoveFromCart: { product in
                                removeFromCart(product)
                            }
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, AppSpacing.large)
            .padding(.top, AppSpacing.large)
        }
        .background(AppColors.screenBackground)
    }
    
    private func loadProducts() async {
        state = .loading
        
        do {
            let products = try await catalogService.loadProducts()
            
            if products.isEmpty {
                state = .empty
                onProductsLoaded([])
            } else {
                state = .content(products)
                onProductsLoaded(products)
            }
        } catch {
    print("Catalog loading error:", error)
    state = .error("Не удалось загрузить каталог")
}
    }
    
    private func quantity(for product: Product) -> Int {
        cartQuantities[product.id, default: 0]
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
}
