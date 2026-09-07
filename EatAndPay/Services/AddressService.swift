import Foundation

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
        client = OpenAPIClientFactory.makeClient(token: token)
    }

    func loadAddresses() async throws -> [DeliveryAddress] {
        let output = try await client.listAddresses(.init())

        switch output {
        case .ok(let response):
            return try response.body.json.compactMap { payload in
                let address = payload.value1
                let identity = payload.value2

                guard
                    let id = identity.id,
                    let coordinates = AddressCoordinatesDTO(address.coordinates)
                else {
                    return nil
                }

                return DeliveryAddress(
                    id: id,
                    addressLine: address.addressLine,
                    longitude: coordinates.longitude,
                    latitude: coordinates.latitude,
                    floor: address.floor ?? "",
                    entrance: address.entrance ?? "",
                    intercomCode: address.intercomCode ?? "",
                    comment: address.comment ?? ""
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
        let output = try await client.createAddress(
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
        let output = try await client.updateAddress(
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
        let output = try await client.deleteAddress(
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

private struct AddressCoordinatesDTO {
    let longitude: Double
    let latitude: Double

    init?(_ values: [Double]) {
        var iterator = values.makeIterator()

        guard
            let longitude = iterator.next(),
            let latitude = iterator.next(),
            iterator.next() == nil
        else {
            return nil
        }

        self.longitude = longitude
        self.latitude = latitude
    }
}

private extension String {
    var nilIfBlank: String? {
        let value = trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}
