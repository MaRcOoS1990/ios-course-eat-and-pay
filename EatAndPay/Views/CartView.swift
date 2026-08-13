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
    let cart: Cart
    let onAddToCart: (Product) -> Void
    let onRemoveFromCart: (Product) -> Void
    let onCheckout: () -> Void
    
    private var cartProducts: [Product] {
        products.filter { product in
            cart.quantity(for: product.id) > 0
        }
    }
    
    private var totalPrice: Decimal {
        cart.totalPrice(for: products)
    }

    private var canCheckout: Bool {
        cart.canCheckout(with: products)
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
        .safeAreaInset(edge: .bottom) {
            checkoutSection
        }
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
                
            }
            .padding(AppSpacing.large)
        }
        .background(AppColors.screenBackground)
    }

    private var checkoutSection: some View {
        checkoutButton
            .padding(.horizontal, AppSpacing.medium)
            .padding(.vertical, AppSpacing.medium)
            .background {
                if canCheckout {
                    AppGradients.smoky
                } else {
                    AppColors.screenBackground
                }
            }
    }
    
    private var checkoutButton: some View {
        Button {
            onCheckout()
        } label: {
            Text("Оформить заказ")
                .font(.headline)
                .foregroundStyle(canCheckout ? Color.white : AppColors.secondaryText)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background {
                    if canCheckout {
                        AppGradients.violet
                    } else {
                        AppGradients.smoky
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.button))
        }
        .buttonStyle(.plain)
        .disabled(!canCheckout)
        .accessibilityHint(canCheckout ? "Оформить товары из корзины" : "Добавьте товары в корзину")
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
                
                Text("\(PriceFormatter.format(product.price)) × \(cart.quantity(for: product.id))")
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
            quantity: cart.quantity(for: product.id),
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
        VStack(spacing: 4) {
            HStack {
                Text("Итого")
                    .font(.headline)

                Spacer()

                Text(PriceFormatter.format(totalPrice))
                    .font(.headline)
            }

            HStack {
                Text("Товаров: \(cart.itemsCount)")

                Spacer()

                Text(PriceFormatter.format(totalPrice))
            }
            .font(.subheadline)

            HStack {
                Text("Доставка")

                Spacer()

                Text("Бесплатно")
            }
            .font(.subheadline)
        }
        .foregroundStyle(AppColors.primaryText)
        .padding(AppSpacing.large)
        .background(AppGradients.smoky)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card))
    }
    
    private func totalPrice(for product: Product) -> Decimal {
        let quantity = Decimal(cart.quantity(for: product.id))
        return product.price * quantity
    }
}
