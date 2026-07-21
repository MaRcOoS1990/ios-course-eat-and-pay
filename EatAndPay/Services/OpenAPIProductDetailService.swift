//
//  OpenAPIProductDetailService.swift
//  EatAndPay
//
//  Created by Чалов Алексей Вячеславович on 21.07.2026.
//

import Foundation
import OpenAPIURLSession

final class OpenAPIProductDetailService: ProductDetailService {
    
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
    
    func loadProduct(id: String) async throws -> Product {
        let output = try await client.get_sol_products_sol__lcub_id_rcub_(
            .init(
                path: .init(id: id)
            )
        )
        
        switch output {
        case .ok(let response):
            let product = try response.body.json
            return ProductMapper.map(product)
            
        case .unauthorized:
            throw ProductDetailServiceError.unauthorized
            
        case .notFound:
            throw ProductDetailServiceError.notFound
            
        case .`default`(let statusCode, _):
            throw ProductDetailServiceError.unexpectedStatusCode(statusCode)
        }
    }
}
