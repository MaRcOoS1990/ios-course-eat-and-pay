//
//  ProductListView.swift
//  EatAndPay
//
//  Created by Чалов Алексей on 03.07.2026.
//

import SwiftUI
import EatAndPayDesignSystem

struct ProductListView: View {
    private let catalogService: any CatalogService
    private let onProductsLoaded: ([Product]) -> Void
    private let productDetailService: any ProductDetailService
    private let favoriteService: any FavoriteService
    private let category: Category?
    
    @State private var state: CatalogState = .loading
    @State private var searchText = ""
    @Binding private var cart: Cart
    @Binding private var favorites: Favorites
    
    init(
        catalogService: any CatalogService = MockCatalogService(),
        productDetailService: any ProductDetailService = MockProductDetailService(),
        favoriteService: any FavoriteService = MockFavoriteService(),
        category: Category? = nil,
        cart: Binding<Cart> = .constant(Cart()),
        favorites: Binding<Favorites> = .constant(Favorites()),
        onProductsLoaded: @escaping ([Product]) -> Void = { _ in }
    ) {
        self.catalogService = catalogService
        self.productDetailService = productDetailService
        self.favoriteService = favoriteService
        self.category = category
        self._cart = cart
        self._favorites = favorites
        self.onProductsLoaded = onProductsLoaded
    }
    
    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 3),
        GridItem(.flexible(), spacing: 3)
    ]
    
    var body: some View {
        Group {
            switch state {
            case .loading:
                ProgressView("Загрузка каталога...")

            case let .content(products):
                searchContent(products: products)

            case .empty:
                Text(emptyStateMessage)
                    .foregroundStyle(AppColors.secondaryText)
                    .padding()

            case let .error(message):
                Text(message)
                    .foregroundStyle(AppColors.errorText)
                    .padding()
            }
        }
        .navigationTitle(category?.name ?? "Каталог")
        .searchable(
            text: $searchText,
            prompt: "Поиск товаров"
        ) {
            ForEach(searchSuggestions, id: \.self) { suggestion in
                Text(suggestion)
                    .searchCompletion(suggestion)
            }
        }
        .task {
            if case .loading = state {
                await loadProducts()
            }
        }
    }

    @ViewBuilder
    private func searchContent(products: [Product]) -> some View {
        let filteredProducts = ProductSearch.filter(products, by: searchText)

        if filteredProducts.isEmpty {
            ContentUnavailableView {
                Label("Ничего не найдено", systemImage: "magnifyingglass")
            } description: {
                Text("Попробуй изменить поисковый запрос")
            }
        } else {
            catalogGrid(products: filteredProducts)
        }
    }

    private var searchSuggestions: [String] {
        guard case let .content(products) = state else {
            return []
        }

        return ProductSearch.suggestions(
            from: products,
            matching: searchText
        )
    }
    
    private func catalogGrid(products: [Product]) -> some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: AppSpacing.small) {
                ForEach(products) { product in
                    ProductCard(
                        product: product,
                        quantity: quantity(for: product),
                        isFavorite: favorites.contains(product.id),
                        destination: {
                            ProductDetailView(
                                product: product,
                                productDetailService: productDetailService,
                                quantity: quantity(for: product),
                                isFavorite: favorites.contains(product.id),
                                onAddToCart: { product in
                                    addToCart(product)
                                },
                                onRemoveFromCart: { product in
                                    removeFromCart(product)
                                },
                                onToggleFavorite: { product in
                                    Task {
                                        await toggleFavorite(product)
                                    }
                                }
                            )
                        },
                        onAddToCart: { product in
                            addToCart(product)
                        },
                        onRemoveFromCart: { product in
                            removeFromCart(product)
                        },
                        onToggleFavorite: { product in
                            Task {
                                await toggleFavorite(product)
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, AppSpacing.medium)
            .padding(.top, 10)
        }
        .background(AppColors.screenBackground)
    }
    
    private func loadProducts() async {
        state = .loading
        
        do {
            let products = try await catalogService.loadProducts(categoryID: category?.id)
            
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

    private var emptyStateMessage: String {
        category == nil
            ? "Каталог пока пуст"
            : "В этой категории пока нет товаров"
    }
    
    private func quantity(for product: Product) -> Int {
        cart.quantity(for: product.id)
    }
    
    private func addToCart(_ product: Product) {
        cart.add(product.id)
    }
    
    private func removeFromCart(_ product: Product) {
        cart.remove(product.id)
    }

    @MainActor
    private func toggleFavorite(_ product: Product) async {
        favorites.toggle(product.id)
        let newValue = favorites.contains(product.id)

        do {
            try await favoriteService.setFavorite(newValue, productID: product.id)
        } catch {
            favorites.toggle(product.id)
            print("Favorite update error:", error)
        }
    }
}
