//
//  Untitled.swift
//  EatAndPay
//
//  Created by Чалов Алексей Вячеславович on 21.07.2026.
//

import SwiftUI
import EatAndPayDesignSystem

struct ProductDetailView: View {
    
    private let product: Product
    private let productDetailService: any ProductDetailService
    private let reviewService: any ReviewService
    private let quantity: Int
    private let isFavorite: Bool
    private let onAddToCart: (Product) -> Void
    private let onRemoveFromCart: (Product) -> Void
    private let onToggleFavorite: (Product) -> Void

    @Environment(\.productUpdateAction) private var productUpdateAction
    
    @State private var displayedProduct: Product
    @State private var isLoadingDetails = false
    @State private var detailErrorMessage: String?
    @State private var showsReviewForm = false
    @State private var reviewWasSubmitted = false
    @State private var reviewSort = ReviewSort.newest
    
    init(
        product: Product,
        productDetailService: any ProductDetailService = MockProductDetailService(),
        reviewService: any ReviewService = AppFactory.makeReviewService(),
        quantity: Int = 0,
        isFavorite: Bool = false,
        onAddToCart: @escaping (Product) -> Void = { _ in },
        onRemoveFromCart: @escaping (Product) -> Void = { _ in },
        onToggleFavorite: @escaping (Product) -> Void = { _ in }
    ) {
        self.product = product
        self.productDetailService = productDetailService
        self.reviewService = reviewService
        self.quantity = quantity
        self.isFavorite = isFavorite
        self.onAddToCart = onAddToCart
        self.onRemoveFromCart = onRemoveFromCart
        self.onToggleFavorite = onToggleFavorite
        self._displayedProduct = State(initialValue: product)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                productImage
                
                productInfo
                
                cartControl
                reviewsSection
            }
            .padding(AppSpacing.large)
        }
        .background(AppColors.screenBackground)
        .navigationTitle(displayedProduct.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    onToggleFavorite(displayedProduct)
                } label: {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(
                            isFavorite
                            ? AppColors.favoriteActive
                            : AppColors.favoriteInactive
                        )
                }
                .accessibilityLabel(
                    isFavorite
                    ? "Удалить из избранного"
                    : "Добавить в избранное"
                )
            }
        }
        .task {
            await loadProductDetails()
        }
        .sheet(isPresented: $showsReviewForm) {
            ReviewFormView(product: displayedProduct, service: reviewService) {
                reviewWasSubmitted = true
                await loadProductDetails()
            }
        }
    }
    
    private var productImage: some View {
        ProductImageView(
            imageURL: displayedProduct.imageURL,
            size: CGSize(width: 320, height: 320),
            cornerRadius: AppRadius.card
        )
        .frame(maxWidth: .infinity)
    }
    
    private var productInfo: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text(displayedProduct.name)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(AppColors.primaryText)
            
            Text(PriceFormatter.format(displayedProduct.price))
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(AppColors.primaryText)
            
            if let weight = displayedProduct.weight {
                Text("\(weight) г")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(AppColors.secondaryText)
            }
            
            ratingRow
            
            Text(productDescription)
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(AppColors.secondaryText)
                .padding(.top, AppSpacing.small)
        }
        .padding(AppSpacing.large)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card))
    }
    
    private var productDescription: String {
        guard let description = displayedProduct.description,
              description.isEmpty == false else {
            return "Описание товара пока недоступно"
        }
        
        return description
    }
    
    private var ratingRow: some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .font(.system(size: 15, weight: .semibold))
            
            Text(ratingText)
                .font(.system(size: 16, weight: .regular))
            
            Image(systemName: "bubble")
                .font(.system(size: 15, weight: .regular))
            
            Text(reviewCountText)
                .font(.system(size: 16, weight: .regular))
        }
        .foregroundStyle(AppColors.primaryText)
    }
    
    private var cartControl: some View {
        Group {
            if quantity == 0 {
                Button {
                    onAddToCart(product)
                } label: {
                    Text("В корзину")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(AppColors.primaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.purple.opacity(0.10))
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.button))
                }
                .buttonStyle(.plain)
            } else {
                QuantityControl(
                    quantity: quantity,
                    fillsWidth: true,
                    onDecrease: {
                        onRemoveFromCart(displayedProduct)
                    },
                    onIncrease: {
                        onAddToCart(displayedProduct)
                    }
                )
            }
        }
    }
    
    private var ratingText: String {
        if let rating = displayedProduct.rating {
            String(format: "%.1f", rating)
        } else {
            "0.0"
        }
    }
    
    private var reviewCountText: String {
        "\(displayedProduct.reviewCount ?? 0)"
    }

    private var reviewsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.large) {
            HStack {
                Text("Отзывы · \(reviewCountText)")
                    .font(.title2.bold())

                Spacer()

                if displayedProduct.reviews.count > 1 {
                    Picker("Сортировка отзывов", selection: $reviewSort) {
                        ForEach(ReviewSort.allCases) { sort in
                            Text(sort.title).tag(sort)
                        }
                    }
                    .pickerStyle(.menu)
                    .accessibilityIdentifier("reviews.sort")
                }
            }
            ratingRow
            if reviewWasSubmitted {
                Label("Отзыв отправлен", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(AppColors.accent)
            }
            if isLoadingDetails {
                ProgressView("Загрузка отзывов…")
            } else if detailErrorMessage != nil {
                Text(reviewWasSubmitted
                     ? "Отзыв принят, но обновить данные не удалось. Повтори загрузку."
                     : "Не удалось загрузить данные товара и отзывы.")
                    .foregroundStyle(AppColors.errorText)
                Button("Повторить загрузку") {
                    Task { await loadProductDetails() }
                }
            } else if displayedProduct.reviews.isEmpty {
                Text("Отзывов пока нет. Поделись первым впечатлением!")
                    .foregroundStyle(AppColors.secondaryText)
            }
            Button("Написать отзыв") {
                showsReviewForm = true
            }
            .buttonStyle(AppPrimaryButtonStyle())
            .disabled(isLoadingDetails)
            .accessibilityIdentifier("review.write")

            ForEach(reviewSort.sort(displayedProduct.reviews)) { review in
                VStack(alignment: .leading, spacing: AppSpacing.small) {
                    HStack {
                        Text(review.author).font(.headline)
                        Spacer()
                        Text(review.createdAt, format: .dateTime.day().month().year())
                            .font(.caption)
                            .foregroundStyle(AppColors.secondaryText)
                    }
                    HStack(spacing: 3) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= review.rating ? "star.fill" : "star")
                        }
                    }
                    .foregroundStyle(AppColors.accent)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Оценка \(review.rating) из 5")
                    Text(review.content)
                        .fixedSize(horizontal: false, vertical: true)
                    if !review.imageURLs.isEmpty {
                        ScrollView(.horizontal) {
                            HStack {
                                ForEach(Array(review.imageURLs.enumerated()), id: \.offset) { _, url in
                                    ProductImageView(imageURL: url, size: CGSize(width: 80, height: 80))
                                }
                            }
                        }
                    }
                }
                Divider()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(AppMotion.standard, value: reviewSort)
    }
    
    @MainActor
    private func loadProductDetails() async {
        guard isLoadingDetails == false else {
            return
        }
        
        isLoadingDetails = true
        detailErrorMessage = nil
        
        do {
            let loadedProduct = try await productDetailService.loadProduct(id: product.id)
            displayedProduct = loadedProduct
            productUpdateAction(loadedProduct)
        } catch {
            detailErrorMessage = error.localizedDescription
        }
        
        isLoadingDetails = false
    }
}
