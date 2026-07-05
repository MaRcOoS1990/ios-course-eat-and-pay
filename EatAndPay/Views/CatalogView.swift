//
//  CatalogView.swift
//  EatAndPay
//
//  Created by Чалов Алексей on 03.07.2026.
//

import SwiftUI

struct CatalogView: View {
    private let catalogService: any CatalogService
    private let cartService: any CartService
    
    @State private var state: CatalogState = .loading
    @State private var cartQuantities: [String: Int] = [:]
    @State private var alertMessage: String?
    @State private var isCartPresented = false
    
    init(
        catalogService: any CatalogService = MockCatalogService(),
        cartService: any CartService = MockCartService()
    ) {
        self.catalogService = catalogService
        self.cartService = cartService
    }
    
    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: AppSpacing.large),
        GridItem(.flexible(), spacing: AppSpacing.large)
    ]
    
    private var isAlertPresented: Binding<Bool> {
        Binding(
            get: {
                alertMessage != nil
            },
            set: { isPresented in
                if !isPresented {
                    alertMessage = nil
                }
            }
        )
    }
    
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
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    cartButton
                }
            }
            .navigationDestination(isPresented: $isCartPresented) {
                CartView(
                    products: currentProducts,
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
            .task {
                if case .loading = state {
                    await loadProducts()
                }
            }
            .alert("Корзина", isPresented: isAlertPresented) {
                Button("Ок", role: .cancel) {}
            } message: {
                Text(alertMessage ?? "")
            }
        }
    }
    
    private func checkout() {
        print("Checkout:", cartQuantities)
        alertMessage = "Заказ оформлен"
        cartQuantities = [:]
        isCartPresented = false
    }
    
    private var currentProducts: [Product] {
        if case let .content(products) = state {
            return products
        } else {
            return []
        }
    }
    
    private var cartButton: some View {
        Button {
            isCartPresented = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "cart")
                    .font(.system(size: 15, weight: .semibold))
                
                Text("\(cartItemsCount)")
                    .font(.system(size: 17, weight: .semibold))
            }
            .foregroundStyle(AppColors.primaryText)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Color.white.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.button))
        }
        .buttonStyle(.plain)
    }
    
    private func catalogGrid(products: [Product]) -> some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: AppSpacing.extraLarge) {
                ForEach(products) { product in
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
            } else {
                state = .content(products)
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
    
    private var cartItemsCount: Int {
        cartQuantities.values.reduce(0, +)
    }
    
    @MainActor
    private func addToCart(_ product: Product) async {
        do {
            try await cartService.addProduct(id: product.id)
            alertMessage = "\(product.name) добавлен в корзину"
        } catch {
            print("Add to cart error:", error)
            alertMessage = "Не удалось добавить товар в корзину"
        }
    }
}

#Preview("Catalog Network") {
    CatalogView(catalogService: NetworkCatalogService())
}
