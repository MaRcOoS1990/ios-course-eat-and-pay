//
//  ProductCard.swift
//  EatAndPay
//
//  Created by Чалов Алексей Вячеславович on 05.07.2026.
//

import SwiftUI

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
            priceText
            productInfoRow
            ratingRow
            cartControl
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
    
    private var productImage: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppRadius.card)
                .fill(AppColors.screenBackground)
            
            if let imageURL = product.imageURL {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                        
                    case let .success(image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .clipped()
                        
                    case .failure:
                        placeholderImage
                        
                    @unknown default:
                        placeholderImage
                    }
                }
            } else {
                placeholderImage
            }
        }
        .frame(height: 170)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card))
    }
    
    private var priceText: some View {
        Text(PriceFormatter.format(product.price))
            .font(.system(size: 24, weight: .bold))
            .foregroundStyle(AppColors.primaryText)
    }
    
    private var productInfoRow: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(product.name)
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(AppColors.primaryText)
                .lineLimit(1)
            
            Spacer()
            
            if let weight = product.weight {
                Text("\(weight) г")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(AppColors.secondaryText)
            }
        }
    }
    
    private var ratingRow: some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .font(.system(size: 14, weight: .semibold))
            
            Text(ratingText)
                .font(.system(size: 16, weight: .regular))
            
            Image(systemName: "bubble")
                .font(.system(size: 14, weight: .regular))
            
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
                        .padding(.vertical, 10)
                        .background(Color.purple.opacity(0.10))
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.button))
                }
                .buttonStyle(.plain)
            } else {
                HStack {
                    Button {
                        onRemoveFromCart(product)
                    } label: {
                        Image(systemName: "minus")
                            .font(.system(size: 16, weight: .bold))
                            .frame(width: 36, height: 36)
                    }
                    
                    Spacer()
                    
                    Text("\(quantity)")
                        .font(.system(size: 17, weight: .semibold))
                    
                    Spacer()
                    
                    Button {
                        onAddToCart(product)
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                            .frame(width: 36, height: 36)
                    }
                }
                .foregroundStyle(AppColors.primaryText)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.purple.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.button))
                .buttonStyle(.plain)
            }
        }
    }
    
    private var placeholderImage: some View {
        Image(systemName: "cart")
            .resizable()
            .scaledToFit()
            .foregroundStyle(AppColors.accent)
            .padding(AppSpacing.extraLarge)
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

#Preview {
    ProductCard(product: Product.mockProducts[0])
        .frame(width: 170)
        .padding()
        .background(AppColors.cardBackground)
}
