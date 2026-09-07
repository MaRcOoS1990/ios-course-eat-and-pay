import Foundation
import OpenAPIURLSession

enum OpenAPIClientFactory {
    static func makeClient(token: String = Secrets.accessToken) -> Client {
        Client(
            serverURL: APIConfiguration.serverURL,
            transport: URLSessionTransport(),
            middlewares: [BearerAuthMiddleware(token: token)]
        )
    }
}

private enum APIConfiguration {
    static let serverURL: URL = {
        if let generatedURL = try? Servers.Server1.url() {
            return generatedURL
        }

        guard let fallbackURL = URL(string: "https://eat-and-pay.t02.ru") else {
            preconditionFailure("Некорректный резервный URL API")
        }

        return fallbackURL
    }()
}
