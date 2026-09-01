import Foundation
import Testing
import HTTPTypes
import OpenAPIRuntime
@testable import EatAndPay

struct ReviewTests {
    @Test func apiSendsRatingAndTrimmedTextToProductEndpoint() async throws {
        let transport = ReviewTransport(status: .ok)
        let client = Client(serverURL: URL(string: "https://example.com")!, transport: transport)
        let service = OpenAPIReviewService(client: client)

        try await service.submit(ReviewDraft(rating: 5, text: "  Свежий хлеб \n"), productID: "product-1")

        #expect(await transport.request?.method == .post)
        #expect(await transport.request?.path == "/products/product-1/reviews")
        let data = try #require(await transport.data)
        let payload = try JSONDecoder().decode(ReviewPayload.self, from: data)
        #expect(payload.rating == 5)
        #expect(payload.content == "Свежий хлеб")
        #expect(payload.images.isEmpty)
    }

    @Test(arguments: [400, 401, 500])
    func apiDoesNotTreatErrorResponseAsSuccess(status: Int) async {
        let transport = ReviewTransport(status: .init(code: status))
        let service = OpenAPIReviewService(client: Client(
            serverURL: URL(string: "https://example.com")!, transport: transport
        ))
        await #expect(throws: (any Error).self) {
            try await service.submit(ReviewDraft(rating: 5, text: "Текст"), productID: "p1")
        }
    }
    @Test func draftRequiresRatingAndNonblankText() {
        #expect(!ReviewDraft(rating: 0, text: "Текст").isValid)
        #expect(!ReviewDraft(rating: 6, text: "Текст").isValid)
        #expect(!ReviewDraft(rating: 5, text: " \n\t ").isValid)
        #expect(ReviewDraft(rating: 1, text: "Текст").isValid)
        #expect(ReviewDraft(rating: 5, text: "Текст").isValid)
    }

    @Test func draftTrimsOnlySurroundingWhitespace() {
        #expect(ReviewDraft(rating: 5, text: " \nСвежий хлеб\nВкусный! \n").content
                == "Свежий хлеб\nВкусный!")
    }

    @Test @MainActor func successfulSubmissionCannotBeRepeated() async {
        let service = RecordingReviewService()
        let state = ReviewFormState()
        state.draft = ReviewDraft(rating: 4, text: "Хороший товар")

        #expect(await state.submit(productID: "product-1", using: service))
        #expect(state.didSubmit)
        #expect(!state.canSubmit)
        #expect(!state.isSubmitting)
        #expect(state.errorMessage == nil)
        #expect(await !state.submit(productID: "product-1", using: service))
        #expect(await service.calls == 1)
        #expect(await service.lastProductID == "product-1")
        #expect(await service.lastDraft?.rating == 4)
    }

    @Test @MainActor func failedSubmissionKeepsDraftAndAllowsRetry() async {
        let state = ReviewFormState()
        state.draft = ReviewDraft(rating: 3, text: "Мой отзыв")

        #expect(await !state.submit(productID: "product-1", using: FailingReviewService()))
        #expect(state.errorMessage != nil)
        #expect(state.draft.text == "Мой отзыв")
        #expect(state.canSubmit)
        #expect(!state.didSubmit)
        #expect(!state.isSubmitting)
        #expect(await state.submit(productID: "product-1", using: RecordingReviewService()))
    }

    @Test @MainActor func invalidDraftDoesNotMakeRequest() async {
        let service = RecordingReviewService()
        let state = ReviewFormState()
        #expect(await !state.submit(productID: "product-1", using: service))
        #expect(await service.calls == 0)
    }

    @Test @MainActor func secondTapCannotSendWhileRequestIsRunning() async {
        let service = SuspendedReviewService()
        let state = ReviewFormState()
        state.draft = ReviewDraft(rating: 5, text: "Текст")
        let first = Task { await state.submit(productID: "p1", using: service) }
        await service.waitUntilStarted()

        #expect(state.isSubmitting)
        #expect(!state.canSubmit)
        #expect(await !state.submit(productID: "p1", using: service))

        await service.finish()
        #expect(await first.value)
    }

    @Test func productMapperPreservesReviewData() throws {
        let data = Data(#"{"id":"p1","name":"Хлеб","description":"Свежий хлеб","price":65,"image":"https://example.com/bread.png","weight":500,"rating":4,"isFavorite":false,"reviews":[{"rating":4,"author":"Автор","createdAt":"2026-08-30T12:00:00Z","content":"Свежий","images":[]}]}"#.utf8)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let dto = try decoder.decode(Components.Schemas.Product.self, from: data)
        let product = ProductMapper.map(dto)

        #expect(product.reviewCount == 1)
        #expect(product.rating == 4)
        #expect(product.reviews.first?.author == "Автор")
        #expect(product.reviews.first?.content == "Свежий")
        #expect(product.reviews.first?.rating == 4)
        #expect(product.imageURL?.absoluteString == "https://example.com/bread.png")
    }
}

private struct ReviewPayload: Decodable {
    let rating: Int
    let content: String
    let images: [String]
}

private actor ReviewTransport: ClientTransport {
    let status: HTTPResponse.Status
    private(set) var request: HTTPRequest?
    private(set) var data: Data?

    init(status: HTTPResponse.Status) {
        self.status = status
    }

    func send(_ request: HTTPRequest, body: HTTPBody?, baseURL: URL,
              operationID: String) async throws -> (HTTPResponse, HTTPBody?) {
        self.request = request
        if let body {
            data = try await Data(collecting: body, upTo: 1_000_000)
        }
        return (HTTPResponse(status: status), nil)
    }
}

private actor RecordingReviewService: ReviewService {
    private(set) var calls = 0
    private(set) var lastProductID: String?
    private(set) var lastDraft: ReviewDraft?

    func submit(_ draft: ReviewDraft, productID: Product.ID) async throws {
        calls += 1
        lastProductID = productID
        lastDraft = draft
    }
}

private struct FailingReviewService: ReviewService {
    func submit(_ draft: ReviewDraft, productID: Product.ID) async throws {
        throw ReviewSubmissionError.unavailable
    }
}

private actor SuspendedReviewService: ReviewService {
    private var pending: CheckedContinuation<Void, Never>?
    private var started: CheckedContinuation<Void, Never>?

    func submit(_ draft: ReviewDraft, productID: Product.ID) async throws {
        await withCheckedContinuation { continuation in
            pending = continuation
            started?.resume()
            started = nil
        }
    }

    func waitUntilStarted() async {
        guard pending == nil else { return }
        await withCheckedContinuation { started = $0 }
    }

    func finish() {
        pending?.resume()
        pending = nil
    }
}
