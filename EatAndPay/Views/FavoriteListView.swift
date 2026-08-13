//
//  FavoriteListView.swift
//  EatAndPay
//
//  Created by Codex on 13.08.2026.
//

import SwiftUI
import EatAndPayDesignSystem

struct FavoriteListView: View {
    let products: [Product]
    let productDetailService: any ProductDetailService
    let favoriteService: any FavoriteService

    @Binding var cart: Cart
    @Binding var favorites: Favorites
    @State private var searchText = ""

    private let columns = [
        GridItem(.flexible(), spacing: 3),
        GridItem(.flexible(), spacing: 3)
    ]

    private var favoriteProducts: [Product] {
        products.filter { favorites.contains($0.id) }
    }

    private var displayedProducts: [Product] {
        ProductSearch.filter(favoriteProducts, by: searchText)
    }

    private var searchSuggestions: [String] {
        ProductSearch.suggestions(
            from: favoriteProducts,
            matching: searchText
        )
    }

    var body: some View {
        Group {
            if favoriteProducts.isEmpty {
                ContentUnavailableView {
                    Label("В избранном пока пусто", systemImage: "heart")
                } description: {
                    Text("Добавляй товары с помощью сердечка в каталоге")
                }
            } else if displayedProducts.isEmpty {
                ContentUnavailableView {
                    Label("Ничего не найдено", systemImage: "magnifyingglass")
                } description: {
                    Text("Попробуй изменить поисковый запрос")
                }
            } else {
                favoriteGrid
            }
        }
        .navigationTitle("Избранное")
        .searchable(text: $searchText, prompt: "Поиск товаров") {
            ForEach(searchSuggestions, id: \.self) { suggestion in
                Text(suggestion)
                    .searchCompletion(suggestion)
            }
        }
    }

    private var favoriteGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: AppSpacing.small) {
                ForEach(displayedProducts) { product in
                    ProductCard(
                        product: product,
                        quantity: cart.quantity(for: product.id),
                        isFavorite: true,
                        destination: {
                            ProductDetailView(
                                product: product,
                                productDetailService: productDetailService,
                                quantity: cart.quantity(for: product.id),
                                isFavorite: favorites.contains(product.id),
                                onAddToCart: { cart.add($0.id) },
                                onRemoveFromCart: { cart.remove($0.id) },
                                onToggleFavorite: { product in
                                    Task {
                                        await removeFromFavorites(product)
                                    }
                                }
                            )
                        },
                        onAddToCart: { cart.add($0.id) },
                        onRemoveFromCart: { cart.remove($0.id) },
                        onToggleFavorite: { product in
                            Task {
                                await removeFromFavorites(product)
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

    @MainActor
    private func removeFromFavorites(_ product: Product) async {
        favorites.toggle(product.id)

        do {
            try await favoriteService.setFavorite(false, productID: product.id)
        } catch {
            favorites.toggle(product.id)
            print("Favorite update error:", error)
        }
    }
}
