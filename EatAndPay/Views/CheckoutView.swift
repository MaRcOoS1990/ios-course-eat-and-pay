import SwiftUI
import EatAndPayDesignSystem

struct CheckoutView: View {
    let products: [Product]
    let cart: Cart
    let deliveryPrice: Decimal
    let addressService: any AddressService
    let orderService: any OrderService
    let onOrderCompleted: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var addresses: [DeliveryAddress] = []
    @State private var selectedAddressID: DeliveryAddress.ID?
    @State private var isLoading = false
    @State private var isSubmitting = false
    @State private var alert: CheckoutAlert?

    private var productsPrice: Decimal {
        cart.totalPrice(for: products)
    }

    private var totalPrice: Decimal {
        productsPrice + deliveryPrice
    }

    var body: some View {
        List {
            Section("Адрес доставки") {
                if isLoading && addresses.isEmpty {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else if addresses.isEmpty {
                    ContentUnavailableView {
                        Label("Добавь адрес", systemImage: "mappin.and.ellipse")
                    } description: {
                        Text("Без адреса оформить заказ не получится")
                    }
                } else {
                    ForEach(addresses) { address in
                        Button {
                            selectedAddressID = address.id
                        } label: {
                            HStack(spacing: AppSpacing.medium) {
                                Image(systemName: selectedAddressID == address.id
                                      ? "checkmark.circle.fill"
                                      : "circle")
                                    .foregroundStyle(selectedAddressID == address.id
                                                     ? AppColors.favoriteActive
                                                     : AppColors.secondaryText)

                                Text(address.addressLine)
                                    .foregroundStyle(AppColors.primaryText)

                                Spacer()
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }

                NavigationLink {
                    AddressListView(addressService: addressService)
                } label: {
                    Label("Управлять адресами", systemImage: "mappin.and.ellipse")
                }
            }

            Section("Оплата") {
                Label("Картой онлайн", systemImage: "creditcard")
            }

            Section("Сумма заказа") {
                priceRow(title: "Товары", value: productsPrice)
                priceRow(title: "Доставка", value: deliveryPrice, freeWhenZero: true)
                priceRow(title: "Итого", value: totalPrice, emphasized: true)
            }
        }
        .navigationTitle("Оформление заказа")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            orderButton
        }
        .onAppear {
            Task { await loadAddresses() }
        }
        .alert(item: $alert) { alert in
            switch alert {
            case .error(let message):
                return Alert(
                    title: Text("Не удалось оформить заказ"),
                    message: Text(message),
                    dismissButton: .default(Text("Понятно"))
                )
            case .success:
                return Alert(
                    title: Text("Заказ оформлен"),
                    message: Text("Мы начали собирать Ваш заказ."),
                    dismissButton: .default(Text("Готово")) {
                        onOrderCompleted()
                        dismiss()
                    }
                )
            }
        }
    }

    private var orderButton: some View {
        Button {
            Task { await createOrder() }
        } label: {
            HStack {
                if isSubmitting {
                    ProgressView()
                        .tint(.white)
                }

                Text("Оформить за \(PriceFormatter.format(totalPrice))")
            }
        }
        .buttonStyle(AppPrimaryButtonStyle())
        .disabled(selectedAddressID == nil || isSubmitting)
        .padding(AppSpacing.medium)
        .background(.regularMaterial)
    }

    private func priceRow(
        title: String,
        value: Decimal,
        freeWhenZero: Bool = false,
        emphasized: Bool = false
    ) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(freeWhenZero && value == .zero ? "Бесплатно" : PriceFormatter.format(value))
        }
        .font(emphasized ? .headline : .body)
    }

    @MainActor
    private func loadAddresses() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            addresses = try await addressService.loadAddresses()
            if !addresses.contains(where: { $0.id == selectedAddressID }) {
                selectedAddressID = addresses.first?.id
            }
        } catch {
            alert = .error(error.localizedDescription)
        }
    }

    @MainActor
    private func createOrder() async {
        guard let selectedAddressID, !isSubmitting else { return }
        isSubmitting = true
        defer { isSubmitting = false }

        do {
            try await orderService.createOrder(
                addressID: selectedAddressID,
                paymentMethod: "card"
            )
            alert = .success
        } catch {
            alert = .error(error.localizedDescription)
        }
    }
}

private enum CheckoutAlert: Identifiable {
    case error(String)
    case success

    var id: String {
        switch self {
        case .error(let message):
            return "error-\(message)"
        case .success:
            return "success"
        }
    }
}
