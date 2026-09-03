import Foundation
import OpenAPIURLSession

protocol AddressService: Sendable {
    func loadAddresses() async throws -> [DeliveryAddress]
    func createAddress(_ draft: AddressDraft) async throws
    func updateAddress(id: DeliveryAddress.ID, draft: AddressDraft) async throws
    func deleteAddress(id: DeliveryAddress.ID) async throws
}

struct OpenAPIAddressService: AddressService {
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

    func loadAddresses() async throws -> [DeliveryAddress] {
        let output = try await client.get_sol_addresses(.init())

        switch output {
        case .ok(let response):
            return try response.body.json.compactMap { payload in
                guard
                    let id = payload.value2.id,
                    payload.value1.coordinates.count == 2
                else {
                    return nil
                }

                return DeliveryAddress(
                    id: id,
                    addressLine: payload.value1.addressLine,
                    longitude: payload.value1.coordinates[0],
                    latitude: payload.value1.coordinates[1],
                    floor: payload.value1.floor ?? "",
                    entrance: payload.value1.entrance ?? "",
                    intercomCode: payload.value1.intercomCode ?? "",
                    comment: payload.value1.comment ?? ""
                )
            }
        case .unauthorized:
            throw APIServiceError.unauthorized
        case .`default`(let statusCode, _):
            throw APIServiceError.unexpectedStatusCode(statusCode)
        }
    }

    func createAddress(_ draft: AddressDraft) async throws {
        let address = try makeAddress(from: draft)
        let output = try await client.post_sol_addresses(
            .init(body: .json(address))
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

    func updateAddress(id: DeliveryAddress.ID, draft: AddressDraft) async throws {
        let address = try makeAddress(from: draft)
        let output = try await client.put_sol_addresses_sol__lcub_id_rcub_(
            .init(path: .init(id: id), body: .json(address))
        )

        switch output {
        case .ok:
            return
        case .badRequest:
            throw APIServiceError.rejected
        case .unauthorized:
            throw APIServiceError.unauthorized
        case .notFound:
            throw APIServiceError.notFound
        case .`default`(let statusCode, _):
            throw APIServiceError.unexpectedStatusCode(statusCode)
        }
    }

    func deleteAddress(id: DeliveryAddress.ID) async throws {
        let output = try await client.delete_sol_addresses_sol__lcub_id_rcub_(
            .init(path: .init(id: id))
        )

        switch output {
        case .ok:
            return
        case .unauthorized:
            throw APIServiceError.unauthorized
        case .notFound:
            throw APIServiceError.notFound
        case .`default`(let statusCode, _):
            throw APIServiceError.unexpectedStatusCode(statusCode)
        }
    }

    private func makeAddress(from draft: AddressDraft) throws -> Components.Schemas.Address {
        guard let coordinates = draft.coordinates else {
            throw APIServiceError.invalidData
        }

        return Components.Schemas.Address(
            coordinates: [coordinates.longitude, coordinates.latitude],
            addressLine: draft.addressLine.trimmingCharacters(in: .whitespacesAndNewlines),
            floor: draft.floor.nilIfBlank,
            entrance: draft.entrance.nilIfBlank,
            intercomCode: draft.intercomCode.nilIfBlank,
            comment: draft.comment.nilIfBlank
        )
    }
}

private extension String {
    var nilIfBlank: String? {
        let value = trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}
