import Foundation
import HTTPTypes
import OpenAPIRuntime
import Testing
@testable import EatAndPay

struct Demo8Tests {
    @Test func reviewSortOrdersReviewsByRatingAndDate() {
        let olderFiveStarReview = Review(
            rating: 5,
            author: "Иван",
            createdAt: Date(timeIntervalSince1970: 100),
            content: "Отлично"
        )
        let newerFiveStarReview = Review(
            rating: 5,
            author: "Анна",
            createdAt: Date(timeIntervalSince1970: 300),
            content: "Понравилось"
        )
        let fourStarReview = Review(
            rating: 4,
            author: "Олег",
            createdAt: Date(timeIntervalSince1970: 200),
            content: "Хорошо"
        )
        let reviews = [olderFiveStarReview, fourStarReview, newerFiveStarReview]

        let byRating = ReviewSort.highestRating.sort(reviews)
        let byLowestRating = ReviewSort.lowestRating.sort(reviews)
        let byDate = ReviewSort.newest.sort(reviews)
        let byOldestDate = ReviewSort.oldest.sort(reviews)

        #expect(byRating.map(\.id) == [newerFiveStarReview.id, olderFiveStarReview.id, fourStarReview.id])
        #expect(byLowestRating.map(\.id) == [fourStarReview.id, newerFiveStarReview.id, olderFiveStarReview.id])
        #expect(byDate.map(\.id) == [newerFiveStarReview.id, fourStarReview.id, olderFiveStarReview.id])
        #expect(byOldestDate.map(\.id) == [olderFiveStarReview.id, fourStarReview.id, newerFiveStarReview.id])
    }

    @Test func profileDraftValidatesServerFormat() {
        let validDraft = UserProfileDraft(
            name: " Алексей ",
            birthday: "01.01.1999",
            imageURI: "https://example.com/avatar.jxl"
        )
        let invalidBirthday = UserProfileDraft(
            name: "Алексей",
            birthday: "31.02.1999",
            imageURI: "https://example.com/avatar.jxl"
        )
        let invalidBirthdayFormat = UserProfileDraft(
            name: "Алексей",
            birthday: "1.1.1999",
            imageURI: "https://example.com/avatar.jxl"
        )
        let invalidImage = UserProfileDraft(
            name: "Алексей",
            birthday: "01.01.1999",
            imageURI: "https://example.com/avatar.jpg"
        )
        let invalidImageScheme = UserProfileDraft(
            name: "Алексей",
            birthday: "01.01.1999",
            imageURI: "file:///tmp/avatar.jxl"
        )

        #expect(validDraft.isValid)
        #expect(!invalidBirthday.isValid)
        #expect(!invalidBirthdayFormat.isValid)
        #expect(!invalidImage.isValid)
        #expect(!invalidImageScheme.isValid)
    }

    @Test func profileServiceLoadsCurrentUser() async throws {
        let response = Data(#"""
        {
          "name":"Алексей",
          "phone":"+7 900 000-00-00",
          "birthday":"01.01.1999",
          "imageUrl":"https://example.com/avatar.jxl"
        }
        """#.utf8)
        let transport = Demo8Transport(responseData: response)
        let serverURL = try #require(URL(string: "https://example.com"))
        let service = OpenAPIProfileService(
            client: Client(serverURL: serverURL, transport: transport)
        )

        let profile = try await service.loadProfile()

        #expect(profile.name == "Алексей")
        #expect(profile.phone == "+7 900 000-00-00")
        #expect(profile.birthday == "01.01.1999")
        #expect(profile.imageURL?.pathExtension == "jxl")
        #expect(await transport.requestPath == "/users/me")
        #expect(await transport.requestMethod == .get)
    }

    @Test func profileServiceUpdatesCurrentUser() async throws {
        let transport = Demo8Transport()
        let serverURL = try #require(URL(string: "https://example.com"))
        let service = OpenAPIProfileService(
            client: Client(serverURL: serverURL, transport: transport)
        )
        let draft = UserProfileDraft(
            name: " Алексей ",
            birthday: "01.01.1999",
            imageURI: " https://example.com/avatar.jxl "
        )

        try await service.updateProfile(draft)

        let requestBody = try #require(await transport.requestBody)
        let payload = try JSONDecoder().decode(ProfileUpdatePayload.self, from: requestBody)
        #expect(await transport.requestPath == "/users/me")
        #expect(await transport.requestMethod == .put)
        #expect(payload.name == "Алексей")
        #expect(payload.birthday == "01.01.1999")
        #expect(payload.imageUri == "https://example.com/avatar.jxl")
    }
}

private actor Demo8Transport: ClientTransport {
    private let responseData: Data?
    private(set) var requestPath: String?
    private(set) var requestMethod: HTTPRequest.Method?
    private(set) var requestBody: Data?

    init(responseData: Data? = nil) {
        self.responseData = responseData
    }

    func send(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String
    ) async throws -> (HTTPResponse, HTTPBody?) {
        requestPath = request.path
        requestMethod = request.method
        if let body {
            requestBody = try await Data(collecting: body, upTo: 1_000_000)
        }
        var response = HTTPResponse(status: .ok)
        if responseData != nil {
            response.headerFields[.contentType] = "application/json"
        }
        return (response, responseData.map(HTTPBody.init))
    }
}

private struct ProfileUpdatePayload: Decodable {
    let name: String
    let birthday: String
    let imageUri: String
}
