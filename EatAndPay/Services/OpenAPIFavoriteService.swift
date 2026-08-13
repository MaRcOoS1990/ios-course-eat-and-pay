//
//  OpenAPIFavoriteService.swift
//  EatAndPay
//
//  Created by Codex on 13.08.2026.
//

import Foundation
import OpenAPIRuntime
import OpenAPIURLSession

final class OpenAPIFavoriteService: FavoriteService {
    private let client: Client

    init(token: String = Secrets.accessToken) {
        self.client = Client(
            serverURL: try! Servers.Server1.url(),
            transport: URLSessionTransport(),
            middlewares: [
                BearerAuthMiddleware(token: token)
            ]
        )
    }

    func setFavorite(_ isFavorite: Bool, productID: Product.ID) async throws {
        if isFavorite {
            try await addToFavorites(productID)
        } else {
            try await removeFromFavorites(productID)
        }
    }

    private func addToFavorites(_ productID: Product.ID) async throws {
        let output = try await client.post_sol_products_sol__lcub_id_rcub__sol_favourite(
            path: .init(id: productID)
        )

        switch output {
        case .ok:
            return
        case .unauthorized:
            throw OpenAPIFavoriteServiceError.unauthorized
        case .notFound:
            throw OpenAPIFavoriteServiceError.productNotFound
        case .`default`(let statusCode, _):
            throw OpenAPIFavoriteServiceError.unexpectedStatusCode(statusCode)
        }
    }

    private func removeFromFavorites(_ productID: Product.ID) async throws {
        let output = try await client.delete_sol_products_sol__lcub_id_rcub__sol_favourite(
            path: .init(id: productID)
        )

        switch output {
        case .ok:
            return
        case .unauthorized:
            throw OpenAPIFavoriteServiceError.unauthorized
        case .notFound:
            throw OpenAPIFavoriteServiceError.productNotFound
        case .`default`(let statusCode, _):
            throw OpenAPIFavoriteServiceError.unexpectedStatusCode(statusCode)
        }
    }
}

private enum OpenAPIFavoriteServiceError: LocalizedError {
    case unauthorized
    case productNotFound
    case unexpectedStatusCode(Int)

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Не удалось авторизоваться для изменения избранного"
        case .productNotFound:
            return "Товар не найден"
        case .unexpectedStatusCode(let statusCode):
            return "Неожиданный статус ответа: \(statusCode)"
        }
    }
}
