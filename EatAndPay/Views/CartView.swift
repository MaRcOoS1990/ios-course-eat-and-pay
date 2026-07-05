//
//  CartView.swift
//  EatAndPay
//
//  Created by Чалов Алексей Вячеславович on 05.07.2026.
//

import SwiftUI

struct CartView: View {
    let products: [Product]
    let quantities: [String: Int]
    let onAddToCart: (Product) -> Void
    let onRemoveFromCart: (Product) -> Void
    let onCheckout: () -> Void
    
    private var cartProducts: [Product] {
        products.filter { product in
            quantities[product.id, default: 0] > 0
        }
    }
    
    private var totalPrice: Decimal {
        cartProducts.reduce(Decimal(0)) { result, product in
            let quantity = Decimal(quantities[product.id, default: 0])
            return result + product.price * quantity
        }
    }
    
    var body: some View {
        Group {
            if cartProducts.isEmpty {
                emptyView
            } else {
                cartContent
            }
        }
        .navigationTitle("Корзина")
        .navigationBarTitleDisplayMode(.large)
    }
    
    private var emptyView: some View {
        VStack(spacing: AppSpacing.medium) {
            Image(systemName: "cart")
                .font(.system(size: 48, weight: .regular))
                .foregroundStyle(AppColors.secondaryText)
            
            Text("Корзина пуста")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(AppColors.primaryText)
            
            Text("Добавьте товары из каталога")
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(AppColors.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.screenBackground)
    }
    
    private var cartContent: some View {
        ScrollView {
            VStack(spacing: AppSpacing.large) {
                ForEach(cartProducts) { product in
                    cartRow(for: product)
                }
                
                totalView
                
                checkoutButton
            }
            .padding(AppSpacing.large)
        }
        .background(AppColors.screenBackground)
    }
    
    private var checkoutButton: some View {
        Button {
            onCheckout()
        } label: {
            Text("Оформить заказ")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.purple)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.button))
        }
        .buttonStyle(.plain)
    }
    
    private func cartRow(for product: Product) -> some View {
        HStack(spacing: AppSpacing.medium) {
            productImage(for: product)
            
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(product.name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(AppColors.primaryText)
                        .lineLimit(2)
                    
                    Spacer()
                    
                    Text(PriceFormatter.format(totalPrice(for: product)))
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(AppColors.primaryText)
                }
                
                Text("\(PriceFormatter.format(product.price)) × \(quantities[product.id, default: 0])")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(AppColors.secondaryText)
                
                quantityControl(for: product)
            }
        }
        .padding(AppSpacing.medium)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card))
    }
    
    private func productImage(for product: Product) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppRadius.button)
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
                            .frame(width: 72, height: 72)
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
        .frame(width: 72, height: 72)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.button))
    }
    
    private func quantityControl(for product: Product) -> some View {
        HStack(spacing: 12) {
            Button {
                onRemoveFromCart(product)
            } label: {
                Image(systemName: "minus")
                    .font(.system(size: 14, weight: .bold))
                    .frame(width: 28, height: 28)
            }
            
            Text("\(quantities[product.id, default: 0])")
                .font(.system(size: 16, weight: .semibold))
                .frame(minWidth: 20)
            
            Button {
                onAddToCart(product)
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .bold))
                    .frame(width: 28, height: 28)
            }
        }
        .foregroundStyle(AppColors.primaryText)
        .background(Color.purple.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.button))
        .buttonStyle(.plain)
    }
    
    private var totalView: some View {
        HStack {
            Text("Итого")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(AppColors.primaryText)
            
            Spacer()
            
            Text(PriceFormatter.format(totalPrice))
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(AppColors.primaryText)
        }
        .padding(AppSpacing.large)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card))
    }
    
    private func totalPrice(for product: Product) -> Decimal {
        let quantity = Decimal(quantities[product.id, default: 0])
        return product.price * quantity
    }
    
    private var placeholderImage: some View {
        Image(systemName: "cart")
            .resizable()
            .scaledToFit()
            .foregroundStyle(AppColors.accent)
            .padding(AppSpacing.medium)
    }
}

#Preview {
    NavigationStack {
        CartView(
            products: Product.mockProducts,
            quantities: [
                Product.mockProducts[0].id: 2,
                Product.mockProducts[1].id: 1
            ],
            onAddToCart: { _ in },
            onRemoveFromCart: { _ in },
            onCheckout: {}
        )
    }
}
