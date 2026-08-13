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
    private let quantity: Int
    private let onAddToCart: (Product) -> Void
    private let onRemoveFromCart: (Product) -> Void
    
    @State private var displayedProduct: Product
    @State private var isLoadingDetails = false
    @State private var detailErrorMessage: String?
    
    init(
        product: Product,
        productDetailService: any ProductDetailService = MockProductDetailService(),
        quantity: Int = 0,
        onAddToCart: @escaping (Product) -> Void = { _ in },
        onRemoveFromCart: @escaping (Product) -> Void = { _ in }
    ) {
        self.product = product
        self.productDetailService = productDetailService
        self.quantity = quantity
        self.onAddToCart = onAddToCart
        self.onRemoveFromCart = onRemoveFromCart
        self._displayedProduct = State(initialValue: product)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                productImage
                
                productInfo
                
                cartControl
            }
            .padding(AppSpacing.large)
        }
        .background(AppColors.screenBackground)
        .navigationTitle(displayedProduct.name)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadProductDetails()
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
        } catch {
            detailErrorMessage = error.localizedDescription
        }
        
        isLoadingDetails = false
    }
}
