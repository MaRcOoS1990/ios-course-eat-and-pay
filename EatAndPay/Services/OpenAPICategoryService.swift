//
//  OpenAPICategoryService.swift
//  EatAndPay
//
//  Created by Codex on 13.08.2026.
//

import Foundation
import OpenAPIRuntime
import OpenAPIURLSession

final class OpenAPICategoryService: CategoryService {
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

    func loadCategories() async throws -> [Category] {
        let output = try await client.get_sol_categories()

        switch output {
        case .ok(let response):
            let categories = try response.body.json
            return categories.map { CategoryMapper.map($0) }

        case .unauthorized:
            throw OpenAPICategoryServiceError.unauthorized

        case .`default`(let statusCode, _):
            throw OpenAPICategoryServiceError.unexpectedStatusCode(statusCode)
        }
    }
}

private enum OpenAPICategoryServiceError: LocalizedError {
    case unauthorized
    case unexpectedStatusCode(Int)

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Не удалось авторизоваться для загрузки категорий"
        case .unexpectedStatusCode(let statusCode):
            return "Неожиданный статус ответа: \(statusCode)"
        }
    }
}
