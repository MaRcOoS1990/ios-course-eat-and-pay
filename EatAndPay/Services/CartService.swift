import Foundation
import OpenAPIURLSession

protocol CartService: Sendable {
    func loadCart() async throws -> CartSnapshot
    func addProduct(id: Product.ID) async throws
    func removeProduct(id: Product.ID) async throws
}

struct OpenAPICartService: CartService {
    private let client: Client

    init(client: Client) {
        self.client = client
    }

    init(token: String = Secrets.accessToken) {
        client = Client(
            serverURL: try! Servers.Server1.url(),
            transport: URLSessionTransport(),
            middlewares: [BearerAuthMiddleware(token: token)]
        )
    }

    func loadCart() async throws -> CartSnapshot {
        let output = try await client.get_sol_cart(.init())

        switch output {
        case .ok(let response):
            let payload = try response.body.json
            var quantities: [Product.ID: Int] = [:]
            var products: [Product] = []

            for item in payload.items {
                let orderItem = item.value1
                quantities[orderItem.id, default: 0] += orderItem.quantity

                if !products.contains(where: { $0.id == orderItem.id }) {
                    products.append(
                        Product(
                            id: orderItem.id,
                            name: orderItem.name,
                            price: Decimal(orderItem.price),
                            imageURL: URL(string: orderItem.image),
                            weight: orderItem.weight
                        )
                    )
                }
            }

            return CartSnapshot(
                cart: Cart(quantities: quantities),
                products: products,
                deliveryTime: payload.deliveryTime,
                orderPrice: Decimal(payload.orderPrice),
                deliveryPrice: Decimal(payload.deliveryPrice),
                totalPrice: Decimal(payload.totalPrice)
            )
        case .unauthorized:
            throw APIServiceError.unauthorized
        case .`default`(let statusCode, _):
            throw APIServiceError.unexpectedStatusCode(statusCode)
        }
    }

    func addProduct(id: Product.ID) async throws {
        let output = try await client.post_sol_cart_sol_items(
            .init(query: .init(id: id))
        )

        switch output {
        case .ok:
            return
        case .unauthorized:
            throw APIServiceError.unauthorized
        case .notFound:
            throw APIServiceError.notFound
        case .`default`(let statusCode, _):
            throw APIServiceError.unexpectedStatusCode(statusCode)
        }
    }

    func removeProduct(id: Product.ID) async throws {
        let output = try await client.delete_sol_cart_sol_items_sol__lcub_id_rcub_(
            .init(path: .init(id: id))
        )

        switch output {
        case .ok:
            return
        case .unauthorized:
            throw APIServiceError.unauthorized
        case .notFound:
            throw APIServiceError.notFound
        case .`default`(let statusCode, _):
            throw APIServiceError.unexpectedStatusCode(statusCode)
        }
    }
}
