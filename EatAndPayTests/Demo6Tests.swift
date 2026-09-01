import Foundation
import HTTPTypes
import OpenAPIRuntime
import SwiftData
import Testing
@testable import EatAndPay

struct Demo6Tests {
    @Test func cartInitializerDropsInvalidQuantities() {
        let cart = Cart(quantities: ["valid": 2, "zero": 0, "negative": -1])

        #expect(cart.quantities == ["valid": 2])
        #expect(cart.itemsCount == 2)
    }

    @Test func addressDraftValidatesCoordinatesAndAddressLine() {
        var draft = AddressDraft()
        #expect(!draft.isValid)

        draft.addressLine = "Новая Басманная ул., 35"
        draft.longitude = "37,668"
        draft.latitude = "55.770"
        #expect(draft.isValid)
        #expect(draft.coordinates?.longitude == 37.668)

        draft.latitude = "100"
        #expect(!draft.isValid)
    }

    @Test @MainActor func swiftDataRestoresCartAndProductMetadata() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: CartItemEntity.self,
            configurations: configuration
        )
        let persistence = SwiftDataCartPersistence(context: container.mainContext)
        let product = Product(
            id: "product-1",
            name: "Хлеб",
            price: 65,
            imageURL: URL(string: "https://example.com/bread.png"),
            weight: 500
        )
        let cart = Cart(quantities: [product.id: 2])

        try persistence.save(cart: cart, products: [product])
        let restored = try persistence.load()

        #expect(restored.cart == cart)
        #expect(restored.products.first?.id == product.id)
        #expect(restored.products.first?.name == "Хлеб")
        #expect(restored.products.first?.price == 65)
        #expect(restored.products.first?.imageURL == product.imageURL)

        try persistence.clear()
        #expect(try persistence.load().cart.isEmpty)
    }

    @Test func cartServiceLoadsServerCart() async throws {
        let response = Data(#"""
        {
          "deliveryTime":15,
          "orderPrice":130,
          "deliveryPrice":20,
          "totalPrice":150,
          "totalItems":2,
          "items":[{
            "id":"product-1",
            "image":"https://example.com/bread.png",
            "name":"Хлеб",
            "weight":500,
            "price":65,
            "quantity":2,
            "available":true
          }]
        }
        """#.utf8)
        let transport = Demo6Transport(responseData: response)
        let service = OpenAPICartService(client: makeClient(transport: transport))

        let snapshot = try await service.loadCart()

        #expect(snapshot.cart.quantity(for: "product-1") == 2)
        #expect(snapshot.products.first?.name == "Хлеб")
        #expect(snapshot.products.first?.imageURL?.absoluteString == "https://example.com/bread.png")
        #expect(snapshot.deliveryPrice == 20)
        #expect(await transport.requests.first?.method == .get)
        #expect(await transport.requests.first?.path == "/cart")
    }

    @Test func cartServiceUsesPostAndDeleteForQuantityChanges() async throws {
        let transport = Demo6Transport(responseData: Data(#"{"total":1}"#.utf8))
        let service = OpenAPICartService(client: makeClient(transport: transport))

        try await service.addProduct(id: "product-1")
        try await service.removeProduct(id: "product-1")

        let requests = await transport.requests
        #expect(requests.count == 2)
        #expect(requests[0].method == .post)
        #expect(requests[0].path == "/cart/items")
        #expect(requests[0].query == "id=product-1")
        #expect(requests[1].method == .delete)
        #expect(requests[1].path == "/cart/items/product-1")
    }

    @Test func addressServiceMapsServerAddress() async throws {
        let response = Data(#"""
        [{
          "id":"address-1",
          "coordinates":[37.668,55.770],
          "addressLine":"Новая Басманная ул., 35",
          "floor":"4"
        }]
        """#.utf8)
        let transport = Demo6Transport(responseData: response)
        let service = OpenAPIAddressService(client: makeClient(transport: transport))

        let addresses = try await service.loadAddresses()

        #expect(addresses.count == 1)
        #expect(addresses[0].id == "address-1")
        #expect(addresses[0].addressLine == "Новая Басманная ул., 35")
        #expect(addresses[0].longitude == 37.668)
        #expect(addresses[0].floor == "4")
    }

    @Test func orderServiceSendsSelectedAddressAndPaymentMethod() async throws {
        let transport = Demo6Transport()
        let service = OpenAPIOrderService(client: makeClient(transport: transport))

        try await service.createOrder(addressID: "address-1", paymentMethod: "card")

        let request = try #require(await transport.requests.first)
        #expect(request.method == .post)
        #expect(request.path == "/orders")
        let body = try #require(request.body)
        let payload = try JSONDecoder().decode(OrderPayload.self, from: body)
        #expect(payload.addressID == "address-1")
        #expect(payload.paymentMethod == "card")
    }

    private func makeClient(transport: Demo6Transport) -> Client {
        Client(
            serverURL: URL(string: "https://example.com")!,
            transport: transport
        )
    }
}

private struct OrderPayload: Decodable {
    let paymentMethod: String
    let addressID: String
}

private struct CapturedRequest: Sendable {
    let method: HTTPRequest.Method
    let path: String
    let query: String?
    let body: Data?
}

private actor Demo6Transport: ClientTransport {
    private let status: HTTPResponse.Status
    private let responseData: Data?
    private(set) var requests: [CapturedRequest] = []

    init(status: HTTPResponse.Status = .ok, responseData: Data? = nil) {
        self.status = status
        self.responseData = responseData
    }

    func send(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String
    ) async throws -> (HTTPResponse, HTTPBody?) {
        let requestBody: Data?
        if let body {
            requestBody = try await Data(collecting: body, upTo: 1_000_000)
        } else {
            requestBody = nil
        }

        let components = request.path.flatMap { URLComponents(string: $0) }
        requests.append(
            CapturedRequest(
                method: request.method,
                path: components?.path ?? request.path ?? "",
                query: components?.query,
                body: requestBody
            )
        )

        var response = HTTPResponse(status: status)
        if responseData != nil {
            response.headerFields[.contentType] = "application/json"
        }
        return (response, responseData.map(HTTPBody.init))
    }
}
