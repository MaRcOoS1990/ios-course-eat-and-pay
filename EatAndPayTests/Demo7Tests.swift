import EatAndPayDesignSystem
import Foundation
import HTTPTypes
import OpenAPIRuntime
import Testing
@testable import EatAndPay

struct Demo7Tests {
    @Test func cartStoreSerializesConcurrentChanges() async throws {
        let service = CartServiceSpy()
        let store = CartStore(service: service)
        let product = Product(id: "product-1", name: "Хлеб", price: 65)

        _ = await store.restore(LocalCartSnapshot(cart: Cart(), products: [product]))

        async let first = store.add(product)
        async let second = store.add(product)
        _ = try await (first, second)

        let snapshot = await store.currentSnapshot()
        #expect(snapshot.cart.quantity(for: product.id) == 2)
        #expect(await service.maximumConcurrentRequests == 1)
    }

    @Test func cartStoreKeepsStateWhenRequestFails() async throws {
        let service = CartServiceSpy(shouldFail: true)
        let store = CartStore(service: service)
        let product = Product(id: "product-1", name: "Хлеб", price: 65)

        _ = await store.restore(LocalCartSnapshot(cart: Cart(), products: [product]))

        await #expect(throws: TestError.self) {
            _ = try await store.add(product)
        }

        #expect(await store.currentSnapshot().cart.isEmpty)
    }

    @Test func imageLoaderSharesOneRequestBetweenConcurrentConsumers() async throws {
        let counter = RequestCounter()
        let loader = ProductImageLoader { url in
            try await counter.load(url)
        }
        let url = try #require(URL(string: "https://example.com/product.png"))

        async let first = loader.data(for: url)
        async let second = loader.data(for: url)
        let values = try await (first, second)

        #expect(values.0 == Data("image".utf8))
        #expect(values.1 == Data("image".utf8))
        #expect(await counter.requestsCount == 1)
    }

    @Test func orderServiceLoadsOrderDetails() async throws {
        let response = Data(#"""
        [{
          "id":"order-1",
          "status":"active",
          "address":{
            "coordinates":[37.668,55.770],
            "addressLine":"Новая Басманная ул., 35",
            "floor":"3",
            "entrance":"4"
          },
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
            "quantity":2
          }]
        }]
        """#.utf8)
        let transport = Demo7Transport(responseData: response)
        let service = OpenAPIOrderService(
            client: Client(
                serverURL: URL(string: "https://example.com")!,
                transport: transport
            )
        )

        let orders = try await service.loadOrders()
        let order = try #require(orders.first)

        #expect(order.id == "order-1")
        #expect(order.status == .processing)
        #expect(order.address.floor == "3")
        #expect(order.items.first?.quantity == 2)
        #expect(order.totalPrice == 150)
        #expect(await transport.requestPath == "/orders")
    }

    @Test(arguments: OrderStatus.allCases)
    func everyOrderStatusHasDisplayData(_ status: OrderStatus) {
        #expect(!status.title.isEmpty)
        #expect(!status.systemImage.isEmpty)
    }
}

private enum TestError: Error {
    case failed
}

private actor CartServiceSpy: CartService {
    private let shouldFail: Bool
    private var concurrentRequests = 0
    private(set) var maximumConcurrentRequests = 0

    init(shouldFail: Bool = false) {
        self.shouldFail = shouldFail
    }

    func loadCart() async throws -> CartSnapshot {
        CartSnapshot(
            cart: Cart(),
            products: [],
            deliveryTime: 0,
            orderPrice: .zero,
            deliveryPrice: .zero,
            totalPrice: .zero
        )
    }

    func addProduct(id: Product.ID) async throws {
        try await performRequest()
    }

    func removeProduct(id: Product.ID) async throws {
        try await performRequest()
    }

    private func performRequest() async throws {
        concurrentRequests += 1
        maximumConcurrentRequests = max(maximumConcurrentRequests, concurrentRequests)
        defer { concurrentRequests -= 1 }

        try await Task.sleep(for: .milliseconds(30))
        if shouldFail {
            throw TestError.failed
        }
    }
}

private actor RequestCounter {
    private(set) var requestsCount = 0

    func load(_ url: URL) async throws -> Data {
        requestsCount += 1
        try await Task.sleep(for: .milliseconds(30))
        return Data("image".utf8)
    }
}

private actor Demo7Transport: ClientTransport {
    private let responseData: Data
    private(set) var requestPath: String?

    init(responseData: Data) {
        self.responseData = responseData
    }

    func send(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String
    ) async throws -> (HTTPResponse, HTTPBody?) {
        requestPath = request.path
        var response = HTTPResponse(status: .ok)
        response.headerFields[.contentType] = "application/json"
        return (response, HTTPBody(responseData))
    }
}
