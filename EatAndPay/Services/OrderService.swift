import Foundation

protocol OrderService: Sendable {
    func loadOrders() async throws -> [CustomerOrder]
    func createOrder(addressID: DeliveryAddress.ID, paymentMethod: String) async throws
}

struct OpenAPIOrderService: OrderService {
    private let client: Client

    init(client: Client) {
        self.client = client
    }

    init(token: String = Secrets.accessToken) {
        client = OpenAPIClientFactory.makeClient(token: token)
    }

    func loadOrders() async throws -> [CustomerOrder] {
        let output = try await client.get_sol_orders(.init())

        switch output {
        case .ok(let response):
            return try response.body.json.map(Self.mapOrder)
        case .unauthorized:
            throw APIServiceError.unauthorized
        case .`default`(let statusCode, _):
            throw APIServiceError.unexpectedStatusCode(statusCode)
        }
    }

    func createOrder(addressID: DeliveryAddress.ID, paymentMethod: String = "card") async throws {
        let output = try await client.post_sol_orders(
            .init(
                body: .json(
                    .init(paymentMethod: paymentMethod, addressID: addressID)
                )
            )
        )

        switch output {
        case .ok:
            return
        case .badRequest:
            throw APIServiceError.rejected
        case .unauthorized:
            throw APIServiceError.unauthorized
        case .`default`(let statusCode, _):
            throw APIServiceError.unexpectedStatusCode(statusCode)
        }
    }

    private static func mapOrder(_ payload: Components.Schemas.Order) -> CustomerOrder {
        let address = payload.address

        return CustomerOrder(
            id: payload.id,
            status: mapStatus(payload.status),
            deliveryDate: payload.deliveryDate.flatMap(parseDate),
            address: OrderAddress(
                addressLine: address.addressLine,
                floor: address.floor ?? "",
                entrance: address.entrance ?? "",
                intercomCode: address.intercomCode ?? "",
                comment: address.comment ?? ""
            ),
            orderPrice: Decimal(payload.orderPrice),
            deliveryPrice: Decimal(payload.deliveryPrice),
            totalPrice: Decimal(payload.totalPrice),
            totalItems: payload.totalItems,
            items: payload.items.map { item in
                OrderProduct(
                    id: item.id,
                    imageURL: URL(string: item.image),
                    name: item.name,
                    weight: item.weight,
                    price: Decimal(item.price),
                    quantity: item.quantity
                )
            }
        )
    }

    private static func mapStatus(
        _ status: Components.Schemas.Order.statusPayload
    ) -> OrderStatus {
        switch status {
        case .active:
            .processing
        case .completed:
            .completed
        }
    }

    private static func parseDate(_ value: String) -> Date? {
        ISO8601DateFormatter().date(from: value)
    }
}
