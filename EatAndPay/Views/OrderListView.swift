import SwiftUI
import EatAndPayDesignSystem

struct OrderListView: View {
    let orderService: any OrderService

    @State private var orders: [CustomerOrder] = []
    @State private var isLoading = false
    @State private var didLoad = false
    @State private var alert: UserAlert?

    var body: some View {
        Group {
            if isLoading && !didLoad {
                ProgressView("Загрузка заказов...")
            } else if orders.isEmpty {
                ContentUnavailableView {
                    Label("Заказов пока нет", systemImage: "shippingbox")
                } description: {
                    Text("Оформленные заказы появятся здесь")
                } actions: {
                    if isLoading {
                        ProgressView()
                    } else {
                        Button("Обновить") {
                            Task { await loadOrders() }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            } else {
                List(orders) { order in
                    NavigationLink {
                        OrderDetailView(order: order)
                    } label: {
                        orderRow(order)
                    }
                }
                .listStyle(.plain)
                .refreshable {
                    await loadOrders()
                }
            }
        }
        .navigationTitle("Мои заказы")
        .task {
            if !didLoad {
                await loadOrders()
            }
        }
        .alert(item: $alert) { alert in
            Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                dismissButton: .default(Text("Понятно"))
            )
        }
    }

    private func orderRow(_ order: CustomerOrder) -> some View {
        HStack(spacing: AppSpacing.medium) {
            orderPreview(order)

            VStack(alignment: .leading, spacing: 4) {
                Text(order.status.title)
                    .font(.headline)
                    .foregroundStyle(order.status == .canceled ? AppColors.errorText : AppColors.primaryText)

                Text("Заказ №\(order.id)")
                    .font(.caption)
                    .foregroundStyle(AppColors.secondaryText)
                    .lineLimit(1)

                Text("\(order.totalItems) шт. · \(PriceFormatter.format(order.totalPrice))")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.primaryText)
            }
        }
        .padding(.vertical, AppSpacing.small)
    }

    private func orderPreview(_ order: CustomerOrder) -> some View {
        ZStack(alignment: .bottomTrailing) {
            ProductImageView(
                imageURL: order.items.first?.imageURL,
                size: CGSize(width: 64, height: 64),
                cornerRadius: AppRadius.button,
                contentMode: .fit,
                allowsRetry: true
            )

            if order.items.count > 1 {
                Text("+\(order.items.count - 1)")
                    .font(.caption2.bold())
                    .foregroundStyle(.white)
                    .padding(5)
                    .background(AppColors.favoriteActive)
                    .clipShape(Circle())
                    .offset(x: 4, y: 4)
            }
        }
    }

    @MainActor
    private func loadOrders() async {
        guard !isLoading else { return }
        isLoading = true
        defer {
            isLoading = false
            didLoad = true
        }

        do {
            let loadedOrders = try await orderService.loadOrders()
            withAnimation(AppMotion.standard) {
                orders = loadedOrders
            }
            let imageURLs = orders.flatMap(\.items).compactMap(\.imageURL)
            await ProductImageLoader.shared.prefetch(imageURLs)
        } catch {
            alert = .error(error, title: "Не удалось загрузить заказы")
        }
    }
}
