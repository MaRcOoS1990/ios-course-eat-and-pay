//
//  ProductCard.swift
//  EatAndPay
//
//  Created by Чалов Алексей Вячеславович on 05.07.2026.
//

import SwiftUI
import EatAndPayDesignSystem

struct ProductCard: View {
    let product: Product
    let quantity: Int
    let onAddToCart: (Product) -> Void
    let onRemoveFromCart: (Product) -> Void
    
    init(
        product: Product,
        quantity: Int = 0,
        onAddToCart: @escaping (Product) -> Void = { _ in },
        onRemoveFromCart: @escaping (Product) -> Void = { _ in }
    ) {
        self.product = product
        self.quantity = quantity
        self.onAddToCart = onAddToCart
        self.onRemoveFromCart = onRemoveFromCart
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            productImage
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                VStack(alignment: .leading, spacing: 0) {
                    productInfoRow
                    ratingRow
                        .padding(.top, 3)
                }
                cartControl
            }
            .padding(.bottom, 10)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(AppColors.cardBackground)
    }
    
    private var productImage: some View {
        GeometryReader { proxy in
            ProductImageView(
                imageURL: product.imageURL,
                size: proxy.size,
                cornerRadius: AppRadius.productImage
            )
        }
        .aspectRatio(174 / 256, contentMode: .fit)
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.productImage)
                .fill(AppColors.productImageOverlay)
                .allowsHitTesting(false)
        }
        .overlay(alignment: .topTrailing) {
            favoriteIndicator
                .padding(7)
        }
        .shadow(
            color: AppShadow.cardColor,
            radius: AppShadow.cardRadius,
            x: AppShadow.cardX,
            y: AppShadow.cardY
        )
    }
    
    private var favoriteIndicator: some View {
        Image(systemName: "heart.fill")
            .font(.system(size: 22, weight: .semibold))
            .foregroundStyle(
                product.isFavorite
                ? AppColors.favoriteActive
                : AppColors.favoriteInactive
            )
            .frame(width: 34, height: 34)
            .accessibilityLabel(product.isFavorite ? "В избранном" : "Не в избранном")
    }
    
    private var productInfoRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(product.name)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(AppColors.primaryText)
                .lineLimit(1)
                .truncationMode(.tail)
            
            if let weight = product.weight {
                Text("\(weight)г")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(AppColors.catalogSecondaryText)
                    .fixedSize()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var ratingRow: some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .font(.system(size: 11, weight: .semibold))
            
            Text(ratingText)
                .font(.system(size: 14, weight: .regular))
            
            Image(systemName: "bubble")
                .font(.system(size: 13, weight: .regular))
            
            Text(reviewCountText)
                .font(.system(size: 14, weight: .regular))
        }
        .foregroundStyle(AppColors.primaryText)
    }
    
    private var cartControl: some View {
        HStack(spacing: 5) {
            if quantity > 0 {
                Button {
                    onRemoveFromCart(product)
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 12, weight: .semibold))
                        .frame(width: 16, height: 16)
                }

                Text("\(quantity)")
                    .font(.system(size: 14, weight: .semibold))
                    .contentTransition(.numericText())
                    .accessibilityLabel("Количество: \(quantity)")
            }

            Button {
                onAddToCart(product)
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .semibold))
                    .frame(width: 16, height: 16)
            }

            Text(PriceFormatter.format(product.price))
                .font(.system(size: 14, weight: .semibold))
                .lineLimit(1)
                .fixedSize()
        }
        .foregroundStyle(quantity > 0 ? Color.white : AppColors.primaryText)
        .padding(.horizontal, AppSpacing.medium)
        .frame(minWidth: 96, minHeight: 32)
        .background {
            if quantity > 0 {
                AppGradients.violet
            } else {
                AppGradients.smoky
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.compactButton))
        .buttonStyle(.plain)
    }
    
    private var ratingText: String {
        if let rating = product.rating {
            String(format: "%.1f", rating)
        } else {
            "0.0"
        }
    }
    
    private var reviewCountText: String {
        "\(product.reviewCount ?? 0)"
    }
}
