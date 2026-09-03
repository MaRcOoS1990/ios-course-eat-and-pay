import Foundation

struct CustomerOrder: Identifiable, Equatable, Sendable {
    let id: String
    let status: OrderStatus
    let deliveryDate: Date?
    let address: OrderAddress
    let orderPrice: Decimal
    let deliveryPrice: Decimal
    let totalPrice: Decimal
    let totalItems: Int
    let items: [OrderProduct]
}

struct OrderAddress: Equatable, Sendable {
    let addressLine: String
    let floor: String
    let entrance: String
    let intercomCode: String
    let comment: String

    var details: String {
        [
            entrance.isEmpty ? nil : "подъезд \(entrance)",
            floor.isEmpty ? nil : "этаж \(floor)",
            intercomCode.isEmpty ? nil : "домофон \(intercomCode)"
        ]
        .compactMap { $0 }
        .joined(separator: ", ")
    }
}

struct OrderProduct: Identifiable, Equatable, Sendable {
    let id: String
    let imageURL: URL?
    let name: String
    let weight: Int
    let price: Decimal
    let quantity: Int

    var totalPrice: Decimal {
        price * Decimal(quantity)
    }
}

enum OrderStatus: String, CaseIterable, Equatable, Sendable {
    case created
    case processing
    case delivering
    case completed
    case canceled

    var title: String {
        switch self {
        case .created:
            "Заказ создан"
        case .processing:
            "Заказ собирается"
        case .delivering:
            "Заказ в пути"
        case .completed:
            "Заказ доставлен"
        case .canceled:
            "Заказ отменён"
        }
    }

    var systemImage: String {
        switch self {
        case .created:
            "checkmark.circle"
        case .processing:
            "shippingbox"
        case .delivering:
            "bicycle"
        case .completed:
            "checkmark.circle.fill"
        case .canceled:
            "xmark.circle.fill"
        }
    }

    var progressIndex: Int {
        switch self {
        case .created:
            0
        case .processing:
            1
        case .delivering:
            2
        case .completed:
            3
        case .canceled:
            0
        }
    }
}
