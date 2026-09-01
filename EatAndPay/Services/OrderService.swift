import Foundation
import OpenAPIURLSession

protocol OrderService: Sendable {
    func createOrder(addressID: DeliveryAddress.ID, paymentMethod: String) async throws
}

struct OpenAPIOrderService: OrderService {
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
}
