//
//  CartView.swift
//  EatAndPay
//
//  Created by Чалов Алексей Вячеславович on 05.07.2026.
//

import SwiftUI
import EatAndPayDesignSystem

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
        ProductImageView(
            imageURL: product.imageURL,
            size: CGSize(width: 72, height: 72),
            cornerRadius: AppRadius.button
        )
    }
    
    private func quantityControl(for product: Product) -> some View {
        QuantityControl(
            quantity: quantities[product.id, default: 0],
            fillsWidth: false,
            onDecrease: {
                onRemoveFromCart(product)
            },
            onIncrease: {
                onAddToCart(product)
            }
        )
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
}

//#Preview {
//    NavigationStack {
//        CartView(
//            products: Product.mockProducts,
//            quantities: [
//                Product.mockProducts[0].id: 2,
//                Product.mockProducts[1].id: 1
//            ],
//            onAddToCart: { _ in },
//            onRemoveFromCart: { _ in },
//            onCheckout: {}
//        )
//    }
//}
