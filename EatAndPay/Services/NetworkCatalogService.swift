//
//  NetworkCatalogService.swift
//  EatAndPay
//
//  Created by Чалов Алексей Вячеславович on 05.07.2026.
//

import Foundation

struct NetworkCatalogService: CatalogService {
    private let baseURL = URL(string: "https://eat-and-pay.t02.ru")
    private let session: URLSession = .shared
    
    func loadProducts() async throws -> [Product] {
        guard let baseURL else {
            throw NetworkError.invalidURL
        }
        
        let url = baseURL.appending(path: "products")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(
            "Bearer \(Secrets.accessToken)",
            forHTTPHeaderField: "Authorization"
        )
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard 200..<300 ~= httpResponse.statusCode else {
            throw NetworkError.statusCode(httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        let productsResponse = try decoder.decode(
            ProductsResponseDTO.self,
            from: data
        )
        
        return productsResponse.data.map {
            ProductMapper.map($0)
        }
    }
}
