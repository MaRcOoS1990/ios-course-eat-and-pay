import Foundation

protocol ProfileService: Sendable {
    func loadProfile() async throws -> UserProfile
    func updateProfile(_ draft: UserProfileDraft) async throws
}

struct OpenAPIProfileService: ProfileService {
    private let client: Client

    init(client: Client) {
        self.client = client
    }

    init(token: String = Secrets.accessToken) {
        client = OpenAPIClientFactory.makeClient(token: token)
    }

    func loadProfile() async throws -> UserProfile {
        let output = try await client.getCurrentUserProfile(.init())

        switch output {
        case .ok(let response):
            let profile = try response.body.json
            return UserProfile(
                name: profile.name,
                phone: profile.phone,
                birthday: profile.birthday,
                imageURL: profile.imageUrl.flatMap(URL.init(string:))
            )
        case .unauthorized:
            throw APIServiceError.unauthorized
        case .`default`(let statusCode, _):
            throw APIServiceError.unexpectedStatusCode(statusCode)
        }
    }

    func updateProfile(_ draft: UserProfileDraft) async throws {
        guard draft.isValid else {
            throw APIServiceError.invalidData
        }

        let output = try await client.updateCurrentUserProfile(
            .init(
                body: .json(
                    .init(
                        name: draft.trimmedName,
                        birthday: draft.trimmedBirthday,
                        imageUri: draft.trimmedImageURI
                    )
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
