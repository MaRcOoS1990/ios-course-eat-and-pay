//
//  OpenAPICatalogService.swift
//  EatAndPay
//
//  Created by Чалов Алексей Вячеславович on 08.07.2026.
//

import Foundation
import HTTPTypes
import OpenAPIRuntime
import OpenAPIURLSession

final class OpenAPICatalogService: CatalogService {
    
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
    
    func loadProducts(categoryID: String?) async throws -> [Product] {
        let output = try await client.get_sol_products(
            query: .init(
                category: categoryID,
                page: 1,
                pageSize: 20
            )
        )
        
        switch output {
        case .ok(let response):
            let payload = try response.body.json
            return payload.data.map { ProductMapper.map($0) }
            
        case .badRequest:
            throw OpenAPICatalogServiceError.badRequest
            
        case .unauthorized:
            throw OpenAPICatalogServiceError.unauthorized
            
        case .`default`(let statusCode, _):
            throw OpenAPICatalogServiceError.unexpectedStatusCode(statusCode)
        }
    }
}

private enum OpenAPICatalogServiceError: LocalizedError {
    case badRequest
    case unauthorized
    case unexpectedStatusCode(Int)
    
    var errorDescription: String? {
        switch self {
        case .badRequest:
            return "Некорректный запрос каталога"
        case .unauthorized:
            return "Не удалось авторизоваться для загрузки каталога"
        case .unexpectedStatusCode(let statusCode):
            return "Неожиданный статус ответа: \(statusCode)"
        }
    }
}
