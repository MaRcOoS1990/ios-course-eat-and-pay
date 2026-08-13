//
//  CategoryListView.swift
//  EatAndPay
//
//  Created by Codex on 13.08.2026.
//

import SwiftUI
import EatAndPayDesignSystem

struct CategoryListView: View {
    private let categoryService: any CategoryService
    private let catalogService: any CatalogService
    private let productDetailService: any ProductDetailService
    private let favoriteService: any FavoriteService
    private let onProductsLoaded: ([Product]) -> Void

    @Binding private var cart: Cart
    @Binding private var favorites: Favorites
    @State private var state: CategoryState = .loading

    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]

    init(
        categoryService: any CategoryService,
        catalogService: any CatalogService,
        productDetailService: any ProductDetailService,
        favoriteService: any FavoriteService,
        cart: Binding<Cart>,
        favorites: Binding<Favorites>,
        onProductsLoaded: @escaping ([Product]) -> Void
    ) {
        self.categoryService = categoryService
        self.catalogService = catalogService
        self.productDetailService = productDetailService
        self.favoriteService = favoriteService
        self._cart = cart
        self._favorites = favorites
        self.onProductsLoaded = onProductsLoaded
    }

    var body: some View {
        Group {
            switch state {
            case .loading:
                ProgressView("Загрузка категорий...")

            case let .content(categories):
                categoryGrid(categories)

            case .empty:
                ContentUnavailableView(
                    "Категорий пока нет",
                    systemImage: "square.grid.3x3"
                )

            case let .error(message):
                ContentUnavailableView(
                    "Не удалось загрузить категории",
                    systemImage: "exclamationmark.triangle",
                    description: Text(message)
                )
            }
        }
        .navigationTitle("Категории")
        .navigationBarTitleDisplayMode(.large)
        .task {
            if case .loading = state {
                await loadCategories()
            }
        }
    }

    private func categoryGrid(_ categories: [Category]) -> some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(categories) { category in
                    NavigationLink {
                        ProductListView(
                            catalogService: catalogService,
                            productDetailService: productDetailService,
                            favoriteService: favoriteService,
                            category: category,
                            cart: $cart,
                            favorites: $favorites,
                            onProductsLoaded: onProductsLoaded
                        )
                    } label: {
                        categoryCard(category)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, AppSpacing.medium)
            .padding(.vertical, AppSpacing.small)
        }
        .background(AppColors.screenBackground)
    }

    private func categoryCard(_ category: Category) -> some View {
        ZStack(alignment: .bottomLeading) {
            AsyncImage(url: category.imageURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()

                case .failure:
                    categoryPlaceholder

                case .empty:
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                @unknown default:
                    categoryPlaceholder
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppColors.imageBackground)
            .clipped()

            LinearGradient(
                colors: [.clear, Color.white.opacity(0.9)],
                startPoint: .center,
                endPoint: .bottom
            )

            Text(category.name)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(AppColors.primaryText)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .padding(AppSpacing.small)
        }
        .frame(height: 132)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.button))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Категория \(category.name)")
    }

    private var categoryPlaceholder: some View {
        Image(systemName: "photo")
            .font(.title2)
            .foregroundStyle(AppColors.secondaryText)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func loadCategories() async {
        state = .loading

        do {
            let categories = try await categoryService.loadCategories()
            state = categories.isEmpty ? .empty : .content(categories)
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}
