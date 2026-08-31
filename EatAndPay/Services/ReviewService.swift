import Foundation
import OpenAPIURLSession

protocol ReviewService: Sendable {
    func submit(_ draft: ReviewDraft, productID: Product.ID) async throws
}

struct OpenAPIReviewService: ReviewService {
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

    func submit(_ draft: ReviewDraft, productID: Product.ID) async throws {
        guard draft.isValid else { throw ReviewSubmissionError.invalidDraft }
        let output = try await client.post_sol_products_sol__lcub_id_rcub__sol_reviews(
            path: .init(id: productID),
            body: .json(.init(rating: draft.rating, content: draft.content, images: []))
        )
        switch output {
        case .ok: return
        case .badRequest: throw ReviewSubmissionError.rejected
        case .unauthorized: throw ReviewSubmissionError.unauthorized
        case .default: throw ReviewSubmissionError.unavailable
        }
    }
}

enum ReviewSubmissionError: LocalizedError {
    case invalidDraft, rejected, unauthorized, unavailable

    var errorDescription: String? {
        switch self {
        case .invalidDraft: "Выбери оценку от 1 до 5 и напиши отзыв."
        case .rejected: "Сервер не принял отзыв. Проверь оценку и текст."
        case .unauthorized: "Для отправки отзыва необходима авторизация."
        case .unavailable: "Не удалось отправить отзыв. Попробуй ещё раз."
        }
    }
}
