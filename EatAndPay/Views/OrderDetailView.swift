import SwiftUI
import EatAndPayDesignSystem

struct OrderDetailView: View {
    let order: CustomerOrder

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.extraLarge) {
                statusSection
                addressSection
                productsSection
                totalSection
            }
            .padding(AppSpacing.medium)
        }
        .background(AppColors.screenBackground)
        .navigationTitle("Заказ")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.large) {
            Text(statusHeading)
                .font(.system(size: 32, weight: .medium))
                .foregroundStyle(order.status == .canceled ? AppColors.errorText : AppColors.primaryText)
                .fixedSize(horizontal: false, vertical: true)

            if order.status == .canceled {
                Label(OrderStatus.canceled.title, systemImage: OrderStatus.canceled.systemImage)
                    .font(.headline)
                    .foregroundStyle(AppColors.errorText)
            } else {
                orderProgress
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var orderProgress: some View {
        VStack(spacing: AppSpacing.small) {
            ProgressView(value: Double(order.status.progressIndex), total: 3)
                .tint(AppColors.favoriteActive)

            HStack {
                ForEach(Array(progressStatuses.enumerated()), id: \.element) { index, status in
                    VStack(spacing: 4) {
                        Image(systemName: status.systemImage)
                            .foregroundStyle(index <= order.status.progressIndex
                                             ? AppColors.favoriteActive
                                             : AppColors.secondaryText)

                        Text(status.shortTitle)
                            .font(.caption2)
                            .foregroundStyle(AppColors.secondaryText)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Статус заказа: \(order.status.title)")
    }

    private var addressSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("Адрес доставки", systemImage: "mappin.and.ellipse")
                .font(.headline)

            Text(order.address.addressLine)
                .font(.body)

            if !order.address.details.isEmpty {
                Text(order.address.details)
                    .font(.subheadline)
                    .foregroundStyle(AppColors.secondaryText)
            }

            if !order.address.comment.isEmpty {
                Text(order.address.comment)
                    .font(.subheadline)
                    .foregroundStyle(AppColors.secondaryText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.large)
        .background(AppColors.imageBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card))
    }

    private var productsSection: some View {
        VStack(spacing: AppSpacing.large) {
            ForEach(order.items) { item in
                HStack(alignment: .top, spacing: AppSpacing.medium) {
                    ProductImageView(
                        imageURL: item.imageURL,
                        size: CGSize(width: 100, height: 100),
                        cornerRadius: AppRadius.smallCard,
                        contentMode: .fit,
                        allowsRetry: true
                    )

                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(PriceFormatter.format(item.price)), \(item.quantity) шт")
                            .font(.system(size: 17, weight: .semibold))

                        HStack(spacing: 6) {
                            Text(item.name)
                                .lineLimit(2)

                            Text("\(item.weight) г")
                                .foregroundStyle(AppColors.catalogSecondaryText)
                        }
                        .font(.system(size: 14, weight: .regular))

                        Spacer()

                        Text("Сумма: \(PriceFormatter.format(item.totalPrice))")
                            .font(.caption)
                            .foregroundStyle(AppColors.secondaryText)
                    }
                    .frame(maxWidth: .infinity, minHeight: 100, alignment: .leading)
                }
            }
        }
    }

    private var totalSection: some View {
        VStack(spacing: 4) {
            priceRow("Итого", value: order.totalPrice, emphasized: true)
            priceRow(itemsTitle, value: order.orderPrice)
            priceRow(
                "Доставка",
                value: order.deliveryPrice,
                freeWhenZero: true
            )
        }
        .padding(.vertical, AppSpacing.large)
    }

    private func priceRow(
        _ title: String,
        value: Decimal,
        freeWhenZero: Bool = false,
        emphasized: Bool = false
    ) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(freeWhenZero && value == .zero ? "Бесплатно" : PriceFormatter.format(value))
        }
        .font(emphasized ? .headline : .subheadline)
        .foregroundStyle(AppColors.primaryText)
    }

    private var statusHeading: String {
        switch order.status {
        case .created:
            "Заказ создан"
        case .processing, .delivering:
            if let deliveryDate = order.deliveryDate {
                "Доставим\n\(deliveryDate.formatted(date: .omitted, time: .shortened))"
            } else {
                "\(order.status.title)\nВремя доставки уточняется"
            }
        case .completed:
            if let deliveryDate = order.deliveryDate {
                "Доставлен\n\(deliveryDate.formatted(date: .abbreviated, time: .shortened))"
            } else {
                order.status.title
            }
        case .canceled:
            order.status.title
        }
    }

    private var progressStatuses: [OrderStatus] {
        [.created, .processing, .delivering, .completed]
    }

    private var itemsTitle: String {
        let lastTwoDigits = order.totalItems % 100
        let lastDigit = order.totalItems % 10

        if (11...14).contains(lastTwoDigits) {
            return "\(order.totalItems) товаров"
        }

        switch lastDigit {
        case 1:
            return "\(order.totalItems) товар"
        case 2...4:
            return "\(order.totalItems) товара"
        default:
            return "\(order.totalItems) товаров"
        }
    }
}

private extension OrderStatus {
    var shortTitle: String {
        switch self {
        case .created:
            "Создан"
        case .processing:
            "Сборка"
        case .delivering:
            "В пути"
        case .completed:
            "Доставлен"
        case .canceled:
            "Отменён"
        }
    }
}
